import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amazon_cognito_identity_dart/cognito.dart';
import 'package:amazon_cognito_identity_dart/sig_v4.dart';

// Setup AWS User Pool Id & Client Id settings here:
const _awsUserPoolId = 'ap-southeast-1_xxxxxxxxx';
const _awsClientId = 'xxxxxxxxxxxxxxxxxxxxxxxxxx';

const _identityPoolId = 'ap-southeast-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';

// Setup endpoints here:
const _region = 'ap-southeast-1';
const _endpoint =
    'https://xxxxxxxxxx.execute-api.ap-southeast-1.amazonaws.com/dev';

final userPool = new CognitoUserPool(_awsUserPoolId, _awsClientId);

/// Extend CognitoStorage with Shared Preferences to persist account
/// login sessions
class Storage extends CognitoStorage {
  SharedPreferences _prefs;
  Storage(this._prefs);

  @override
  Future getItem(String key) async {
    String item;
    try {
      item = json.decode(_prefs.getString(key));
    } catch (e) {
      return null;
    }
    return item;
  }

  @override
  Future setItem(String key, value) async {
    _prefs.setString(key, json.encode(value));
    return getItem(key);
  }

  @override
  Future removeItem(String key) async {
    final item = getItem(key);
    if (item != null) {
      _prefs.remove(key);
      return item;
    }
    return null;
  }

  @override
  Future<void> clear() async {
    _prefs.clear();
  }
}

class Counter {
  int count;
  Counter(this.count);

  factory Counter.fromJson(json) {
    return new Counter(json['count']);
  }
}

class User {
  String email;
  String name;
  String password;
  bool confirmed = false;
  bool hasAccess = false;

  User({this.email, this.name});

  /// Decode user from Cognito User Attributes
  factory User.fromUserAttributes(List<CognitoUserAttribute> attributes) {
    final user = User();
    attributes.forEach((attribute) {
      if (attribute.getName() == 'email') {
        user.email = attribute.getValue();
      } else if (attribute.getName() == 'name') {
        user.name = attribute.getValue();
      }
    });
    return user;
  }
}

class CounterService {
  AwsSigV4Client awsSigV4Client;
  CounterService(this.awsSigV4Client);

  /// Retrieve user's previous count from Lambda + DynamoDB
  Future<Counter> getCounter() async {
    final signedRequest =
        new SigV4Request(awsSigV4Client, method: 'GET', path: '/counter');
    final response =
        await http.get(signedRequest.url, headers: signedRequest.headers);
    return new Counter.fromJson(json.decode(response.body));
  }

  /// Increment user's count in DynamoDB
  Future<Counter> incrementCounter() async {
    final signedRequest =
        new SigV4Request(awsSigV4Client, method: 'PUT', path: '/counter');
    final response =
        await http.put(signedRequest.url, headers: signedRequest.headers);
    return new Counter.fromJson(json.decode(response.body));
  }
}

class UserService {
  CognitoUserPool _userPool;
  CognitoUser _cognitoUser;
  CognitoUserSession _session;
  UserService(this._userPool);
  CognitoCredentials credentials;

  /// Initiate user session from local storage if present
  Future<bool> init() async {
    final prefs = await SharedPreferences.getInstance();
    final storage = new Storage(prefs);
    _userPool.storage = storage;

    _cognitoUser = await _userPool.getCurrentUser();
    if (_cognitoUser == null) {
      return false;
    }
    _session = await _cognitoUser.getSession();
    return _session.isValid();
  }

  /// Get existing user from session with his/her attributes
  Future<User> getCurrentUser() async {
    if (_cognitoUser == null || _session == null) {
      return null;
    }
    if (!_session.isValid()) {
      return null;
    }
    final attributes = await _cognitoUser.getUserAttributes();
    if (attributes == null) {
      return null;
    }
    final user = new User.fromUserAttributes(attributes);
    user.hasAccess = true;
    return user;
  }

  /// Retrieve user credentials -- for use with other AWS services
  Future<CognitoCredentials> getCredentials() async {
    if (_cognitoUser == null || _session == null) {
      return null;
    }
    credentials = new CognitoCredentials(_identityPoolId, _userPool);
    await credentials.getAwsCredentials(_session.getIdToken().getJwtToken());
    return credentials;
  }

  /// Login user
  Future<User> login(String email, String password) async {
    _cognitoUser =
        new CognitoUser(email, _userPool, storage: _userPool.storage);

    final authDetails = new AuthenticationDetails(
      username: email,
      password: password,
    );

    bool isConfirmed;
    try {
      _session = await _cognitoUser.authenticateUser(authDetails);
      isConfirmed = true;
    } on CognitoClientException catch (e) {
      if (e.code == 'UserNotConfirmedException') {
        isConfirmed = false;
      } else {
        throw e;
      }
    }

    if (!_session.isValid()) {
      return null;
    }

    final attributes = await _cognitoUser.getUserAttributes();
    final user = new User.fromUserAttributes(attributes);
    user.confirmed = isConfirmed;
    user.hasAccess = true;

    return user;
  }

  /// Confirm user's account with confirmation code sent to email
  Future<bool> confirmAccount(String email, String confirmationCode) async {
    _cognitoUser =
        new CognitoUser(email, _userPool, storage: _userPool.storage);

    return await _cognitoUser.confirmRegistration(confirmationCode);
  }

  /// Resend confirmation code to user's email
  Future<void> resendConfirmationCode(String email) async {
    _cognitoUser =
        new CognitoUser(email, _userPool, storage: _userPool.storage);
    await _cognitoUser.resendConfirmationCode();
  }

  /// Check if user's current session is valid
  Future<bool> checkAuthenticated() async {
    if (_cognitoUser == null || _session == null) {
      return false;
    }
    return _session.isValid();
  }

  /// Sign up new user
  Future<User> signUp(String email, String password, String name) async {
    CognitoUserPoolData data;
    final userAttributes = [
      new AttributeArg(name: 'name', value: name),
    ];
    data =
        await _userPool.signUp(email, password, userAttributes: userAttributes);

    final user = new User();
    user.email = email;
    user.name = name;
    user.confirmed = data.userConfirmed;

    return user;
  }

  Future<void> signOut() async {
    if (credentials != null) {
      await credentials.resetAwsCredentials();
    }
    if (_cognitoUser != null) {
      return _cognitoUser.signOut();
    }
  }
}

void main() => runApp(new SecureCounterApp());

class SecureCounterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Cognito on Flutter',
      theme: new ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: HomePage(title: 'Cognito on Flutter'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: new Center(
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Container(
              padding:
                  new EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              width: screenSize.width,
              child: new RaisedButton(
                child: new Text(
                  'Sign Up',
                  style: new TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (context) => new SignUpScreen()),
                  );
                },
                color: Colors.blue,
              ),
            ),
            new Container(
              padding:
                  new EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              width: screenSize.width,
              child: new RaisedButton(
                child: new Text(
                  'Confirm Account',
                  style: new TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (context) => new ConfirmationScreen()),
                  );
                },
                color: Colors.blue,
              ),
            ),
            new Container(
              padding:
                  new EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              width: screenSize.width,
              child: new RaisedButton(
                child: new Text(
                  'Login',
                  style: new TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (context) => new LoginScreen()),
                  );
                },
                color: Colors.blue,
              ),
            ),
            new Container(
              padding:
                  new EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
              width: screenSize.width,
              child: new RaisedButton(
                child: new Text(
                  'Secure Counter',
                  style: new TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    new MaterialPageRoute(
                        builder: (context) => new SecureCounterScreen()),
                  );
                },
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => new _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  User _user = new User();
  final userService = new UserService(userPool);

  void submit(BuildContext context) async {
    _formKey.currentState.save();

    String message;
    bool signUpSuccess = false;
    try {
      _user = await userService.signUp(_user.email, _user.password, _user.name);
      signUpSuccess = true;
      message = 'User sign up successful!';
    } on CognitoClientException catch (e) {
      if (e.code == 'UsernameExistsException' ||
          e.code == 'InvalidParameterException' ||
          e.code == 'ResourceNotFoundException') {
        message = e.message;
      } else {
        message = 'Unknown client error occurred';
      }
    } catch (e) {
      message = 'Unknown error occurred';
    }

    final snackBar = new SnackBar(
      content: new Text(message),
      action: new SnackBarAction(
        label: 'OK',
        onPressed: () {
          if (signUpSuccess) {
            Navigator.pop(context);
            if (!_user.confirmed) {
              Navigator.push(
                context,
                new MaterialPageRoute(
                    builder: (context) =>
                        new ConfirmationScreen(email: _user.email)),
              );
            }
          }
        },
      ),
      duration: new Duration(seconds: 30),
    );

    Scaffold.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Sign Up'),
      ),
      body: new Builder(
        builder: (BuildContext context) {
          return new Container(
            child: new Form(
              key: _formKey,
              child: new ListView(
                children: <Widget>[
                  new ListTile(
                    leading: const Icon(Icons.account_box),
                    title: new TextFormField(
                      decoration: new InputDecoration(labelText: 'Name'),
                      onSaved: (String name) {
                        _user.name = name;
                      },
                    ),
                  ),
                  new ListTile(
                    leading: const Icon(Icons.email),
                    title: new TextFormField(
                      decoration: new InputDecoration(
                          hintText: 'example@inspire.my', labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (String email) {
                        _user.email = email;
                      },
                    ),
                  ),
                  new ListTile(
                    leading: const Icon(Icons.lock),
                    title: new TextFormField(
                      decoration: new InputDecoration(
                        hintText: 'Password!',
                      ),
                      obscureText: true,
                      onSaved: (String password) {
                        _user.password = password;
                      },
                    ),
                  ),
                  new Container(
                    padding: new EdgeInsets.all(20.0),
                    width: screenSize.width,
                    child: new RaisedButton(
                      child: new Text(
                        'Sign Up',
                        style: new TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        submit(context);
                      },
                      color: Colors.blue,
                    ),
                    margin: new EdgeInsets.only(
                      top: 10.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ConfirmationScreen extends StatefulWidget {
  ConfirmationScreen({Key key, this.email}) : super(key: key);

  final String email;

  @override
  _ConfirmationScreenState createState() => new _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  String confirmationCode;
  User _user = new User();
  final _userService = new UserService(userPool);

  _submit(BuildContext context) async {
    _formKey.currentState.save();
    bool accountConfirmed;
    String message;
    try {
      accountConfirmed =
          await _userService.confirmAccount(_user.email, confirmationCode);
      message = 'Account successfully confirmed!';
    } on CognitoClientException catch (e) {
      if (e.code == 'InvalidParameterException' ||
          e.code == 'CodeMismatchException' ||
          e.code == 'NotAuthorizedException' ||
          e.code == 'UserNotFoundException' ||
          e.code == 'ResourceNotFoundException') {
        message = e.message;
      } else {
        message = 'Unknown client error occurred';
      }
    } catch (e) {
      message = 'Unknown error occurred';
    }

    final snackBar = new SnackBar(
      content: new Text(message),
      action: new SnackBarAction(
        label: 'OK',
        onPressed: () {
          if (accountConfirmed) {
            Navigator.pop(context);
            Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) => new LoginScreen(email: _user.email)),
            );
          }
        },
      ),
      duration: new Duration(seconds: 30),
    );

    Scaffold.of(context).showSnackBar(snackBar);
  }

  _resendConfirmation(BuildContext context) async {
    _formKey.currentState.save();
    String message;
    try {
      await _userService.resendConfirmationCode(_user.email);
      message = 'Confirmation code sent to ${_user.email}!';
    } on CognitoClientException catch (e) {
      if (e.code == 'LimitExceededException' ||
          e.code == 'InvalidParameterException' ||
          e.code == 'ResourceNotFoundException') {
        message = e.message;
      } else {
        message = 'Unknown client error occurred';
      }
    } catch (e) {
      message = 'Unknown error occurred';
    }

    final snackBar = new SnackBar(
      content: new Text(message),
      action: new SnackBarAction(
        label: 'OK',
        onPressed: () {},
      ),
      duration: new Duration(seconds: 30),
    );

    Scaffold.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Confirm Account'),
      ),
      body: new Builder(
          builder: (BuildContext context) => new Container(
                child: new Form(
                  key: _formKey,
                  child: new ListView(
                    children: <Widget>[
                      new ListTile(
                        leading: const Icon(Icons.email),
                        title: new TextFormField(
                          initialValue: widget.email,
                          decoration: new InputDecoration(
                              hintText: 'example@inspire.my',
                              labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (String email) {
                            _user.email = email;
                          },
                        ),
                      ),
                      new ListTile(
                        leading: const Icon(Icons.lock),
                        title: new TextFormField(
                          decoration: new InputDecoration(
                              labelText: 'Confirmation Code'),
                          onSaved: (String code) {
                            confirmationCode = code;
                          },
                        ),
                      ),
                      new Container(
                        padding: new EdgeInsets.all(20.0),
                        width: screenSize.width,
                        child: new RaisedButton(
                          child: new Text(
                            'Submit',
                            style: new TextStyle(color: Colors.white),
                          ),
                          onPressed: () {
                            _submit(context);
                          },
                          color: Colors.blue,
                        ),
                        margin: new EdgeInsets.only(
                          top: 10.0,
                        ),
                      ),
                      new Center(
                        child: new InkWell(
                          child: new Text(
                            'Resend Confirmation Code',
                            style: new TextStyle(color: Colors.blueAccent),
                          ),
                          onTap: () {
                            _resendConfirmation(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )),
    );
  }
}

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key, this.email}) : super(key: key);

  final String email;

  @override
  _LoginScreenState createState() => new _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  final _userService = new UserService(userPool);
  User _user = new User();
  bool _isAuthenticated = false;

  Future<UserService> _getValues() async {
    await _userService.init();
    _isAuthenticated = await _userService.checkAuthenticated();
    return _userService;
  }

  submit(BuildContext context) async {
    _formKey.currentState.save();
    String message;
    try {
      _user = await _userService.login(_user.email, _user.password);
      message = 'User sucessfully logged in!';
      if (!_user.confirmed) {
        message = 'Please confirm user account';
      }
    } on CognitoClientException catch (e) {
      if (e.code == 'InvalidParameterException' ||
          e.code == 'NotAuthorizedException' ||
          e.code == 'UserNotFoundException' ||
          e.code == 'ResourceNotFoundException') {
        message = e.message;
      } else {
        message = 'An unknown client error occured';
      }
    } catch (e) {
      message = 'An unknown error occurred';
    }
    final snackBar = new SnackBar(
      content: new Text(message),
      action: new SnackBarAction(
        label: 'OK',
        onPressed: () async {
          if (_user.hasAccess) {
            Navigator.pop(context);
            if (!_user.confirmed) {
              Navigator.push(
                context,
                new MaterialPageRoute(
                    builder: (context) =>
                        new ConfirmationScreen(email: _user.email)),
              );
            }
          }
        },
      ),
      duration: new Duration(seconds: 30),
    );

    Scaffold.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return new FutureBuilder(
        future: _getValues(),
        builder: (context, AsyncSnapshot<UserService> snapshot) {
          if (snapshot.hasData) {
            if (_isAuthenticated) {
              return new SecureCounterScreen();
            }
            final Size screenSize = MediaQuery.of(context).size;
            return new Scaffold(
              appBar: new AppBar(
                title: new Text('Login'),
              ),
              body: new Builder(
                builder: (BuildContext context) {
                  return new Container(
                    child: new Form(
                      key: _formKey,
                      child: new ListView(
                        children: <Widget>[
                          new ListTile(
                            leading: const Icon(Icons.email),
                            title: new TextFormField(
                              initialValue: widget.email,
                              decoration: new InputDecoration(
                                  hintText: 'example@inspire.my',
                                  labelText: 'Email'),
                              keyboardType: TextInputType.emailAddress,
                              onSaved: (String email) {
                                _user.email = email;
                              },
                            ),
                          ),
                          new ListTile(
                            leading: const Icon(Icons.lock),
                            title: new TextFormField(
                              decoration:
                                  new InputDecoration(labelText: 'Password'),
                              obscureText: true,
                              onSaved: (String password) {
                                _user.password = password;
                              },
                            ),
                          ),
                          new Container(
                            padding: new EdgeInsets.all(20.0),
                            width: screenSize.width,
                            child: new RaisedButton(
                              child: new Text(
                                'Login',
                                style: new TextStyle(color: Colors.white),
                              ),
                              onPressed: () {
                                submit(context);
                              },
                              color: Colors.blue,
                            ),
                            margin: new EdgeInsets.only(
                              top: 10.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
          return new Scaffold(
              appBar: new AppBar(title: new Text('Loading...')));
        });
  }
}

class SecureCounterScreen extends StatefulWidget {
  SecureCounterScreen({Key key}) : super(key: key);

  @override
  _SecureCounterScreenState createState() => new _SecureCounterScreenState();
}

class _SecureCounterScreenState extends State<SecureCounterScreen> {
  final _userService = new UserService(userPool);
  CounterService _counterService;
  AwsSigV4Client _awsSigV4Client;
  User _user = new User();
  Counter _counter = new Counter(0);
  bool _isAuthenticated = false;

  void _incrementCounter() async {
    final counter = await _counterService.incrementCounter();
    setState(() {
      _counter = counter;
    });
  }

  Future<UserService> _getValues(BuildContext context) async {
    try {
      await _userService.init();
      _isAuthenticated = await _userService.checkAuthenticated();
      if (_isAuthenticated) {
        // get user attributes from cognito
        _user = await _userService.getCurrentUser();

        // get session credentials
        final credentials = await _userService.getCredentials();
        _awsSigV4Client = new AwsSigV4Client(
            credentials.accessKeyId, credentials.secretAccessKey, _endpoint,
            region: _region, sessionToken: credentials.sessionToken);

        // get previous count
        _counterService = new CounterService(_awsSigV4Client);
        _counter = await _counterService.getCounter();
      }
      return _userService;
    } on CognitoClientException catch (e) {
      if (e.code == 'NotAuthorizedException') {
        await _userService.signOut();
        Navigator.pop(context);
      }
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return new FutureBuilder(
        future: _getValues(context),
        builder: (context, AsyncSnapshot<UserService> snapshot) {
          if (snapshot.hasData) {
            if (!_isAuthenticated) {
              return new LoginScreen();
            }

            return new Scaffold(
              appBar: new AppBar(
                title: new Text('Secure Counter'),
              ),
              body: new Center(
                child: new Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    new Text(
                      'Welcome ${_user.name}!',
                      style: Theme.of(context).textTheme.display1,
                    ),
                    new Divider(),
                    new Text(
                      'You have pushed the button this many times:',
                    ),
                    new Text(
                      '${_counter.count}',
                      style: Theme.of(context).textTheme.display1,
                    ),
                    new Divider(),
                    new Center(
                      child: new InkWell(
                        child: new Text(
                          'Logout',
                          style: new TextStyle(color: Colors.blueAccent),
                        ),
                        onTap: () {
                          _userService.signOut();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              floatingActionButton: new FloatingActionButton(
                onPressed: () {
                  if (snapshot.hasData) {
                    _incrementCounter();
                  }
                },
                tooltip: 'Increment',
                child: new Icon(Icons.add),
              ),
            );
          }
          return new Scaffold(
              appBar: new AppBar(title: new Text('Loading...')));
        });
  }
}
