import 'dart:async';
import 'package:flutter/material.dart';
import 'package:amazon_cognito_identity_dart/cognito.dart';

// Setup AWS User Pool Id & Client Id settings here:
const _awsUserPoolId = 'ap-southeast-1_xxxxxxxxx';
const _awsClientId = 'xxxxxxxxxxxxxxxxxxxxxxxxxx';

final userPool = new CognitoUserPool(_awsUserPoolId, _awsClientId);

void main() => runApp(new SecureCounterApp());

class User {
  String name = '';
  String email = '';
  String password = '';
  bool userConfirmed = false;
  bool isAuthenticated = false;

  getUserAttributes() async {
    List<CognitoUserAttribute> attributes;
    final user = await userPool.getCurrentUser();
    await user.getSession();
    attributes = await user.getUserAttributes();
    if (attributes != null) {
      attributes.forEach((attribute) {
        if (attribute.getName() == 'email') {
          email = attribute.getValue();
        } else if (attribute.getName() == 'name') {
          name = attribute.getValue();
        }
      });
    }
  }

  Future<bool> authenticated() async {
    CognitoUserSession session;
    try {
      final cognitoUser = await userPool.getCurrentUser();
      if (cognitoUser == null) {
        return false;
      }
      session = await cognitoUser.getSession();
    } catch (e) {
      throw e;
    }
    isAuthenticated = false;
    if (session.isValid()) {
      isAuthenticated = true;
    }
    return isAuthenticated;
  }

  Future<String> signUp() async {
    CognitoUserPoolData data;
    try {
      final userAttributes = [
        new AttributeArg(name: 'name', value: name),
      ];
      data = await userPool.signUp(this.email, this.password,
          userAttributes: userAttributes);
    } on CognitoClientException catch (e) {
      if (e.code == 'UsernameExistsException' ||
          e.code == 'InvalidParameterException') {
        return e.message;
      }
      throw e;
    }

    userConfirmed = data.userConfirmed;
    if (userConfirmed == false) {
      return 'Please confirm your email';
    }

    return 'User successfully created';
  }

  signOut() async {
    final cognitoUser = await userPool.getCurrentUser();
    if (cognitoUser != null) {
      return cognitoUser.signOut();
    }
  }

  Future<String> confirmAccount(String confirmationCode) async {
    final cognitoUser = new CognitoUser(email, userPool);

    String result;
    try {
      result = await cognitoUser.confirmRegistration(confirmationCode);
    } on CognitoClientException catch (e) {
      if (e.code == 'InvalidParameterException' ||
          e.code == 'CodeMismatchException' ||
          e.code == 'NotAuthorizedException' ||
          e.code == 'UserNotFoundException') {
        return e.message;
      }
      throw e;
    }

    return result;
  }

  Future<String> resendConfirmationCode() async {
    final cognitoUser = new CognitoUser(email, userPool);

    String result;
    try {
      result = await cognitoUser.resendConfirmationCode();
    } on CognitoClientException catch (e) {
      if (e.code == 'LimitExceededException' ||
          e.code == 'InvalidParameterException') {
        return e.message;
      }
      throw e;
    }

    return result;
  }

  Future<String> login() async {
    final cognitoUser = new CognitoUser(email, userPool);
    final authDetails = new AuthenticationDetails(
      username: email,
      password: password,
    );

    CognitoUserSession session;
    try {
      session = await cognitoUser.authenticateUser(authDetails);
    } on CognitoClientException catch (e) {
      if (e.code == 'InvalidParameterException' ||
          e.code == 'UserNotConfirmedException' ||
          e.code == 'NotAuthorizedException' ||
          e.code == 'UserNotFoundException') {
        return e.message;
      }
      throw e;
    }
    if (!session.isValid()) {
      return 'Invalid login';
    }
    isAuthenticated = true;
    return 'Successfully logged in!';
  }
}

class SecureCounterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Cognito Dart',
      theme: new ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: HomePage(title: 'Cognito Dart Demo'),
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
  final userData = new User();

  void submit(BuildContext context) async {
    _formKey.currentState.save();

    String message;
    try {
      message = await userData.signUp();
    } catch (e) {
      message = 'Unknown error occurred';
    }

    final snackBar = new SnackBar(
      content: new Text(message),
      action: new SnackBarAction(
        label: 'OK',
        onPressed: () {
          if (!userData.userConfirmed) {
            Navigator.pop(context);
            Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) =>
                      new ConfirmationScreen(email: userData.email)),
            );
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
                        userData.name = name;
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
                        userData.email = email;
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
                        userData.password = password;
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
  final userData = new User();

  _submit(BuildContext context) async {
    _formKey.currentState.save();
    String message;
    try {
      message = await userData.confirmAccount(confirmationCode);
    } catch (e) {
      message = 'Unknown error occurred';
    }

    final snackBar = new SnackBar(
      content: new Text(message),
      action: new SnackBarAction(
        label: 'OK',
        onPressed: () {
          if (message == 'SUCCESS') {
            Navigator.pop(context);
            Navigator.push(
              context,
              new MaterialPageRoute(
                  builder: (context) =>
                      new LoginScreen(email: userData.email)),
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
      message = await userData.resendConfirmationCode();
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
                        hintText: 'example@inspire.my', labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    onSaved: (String email) {
                      userData.email = email;
                    },
                  ),
                ),
                new ListTile(
                  leading: const Icon(Icons.lock),
                  title: new TextFormField(
                    decoration:
                        new InputDecoration(labelText: 'Confirmation Code'),
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
        )
      ),
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
  final userData = new User();

  submit(BuildContext context) async {
    _formKey.currentState.save();
    String message;
    try {
      message = await userData.login();
    } catch (e) {
      message = 'An unknown error occurred';
    }

    final snackBar = new SnackBar(
      content: new Text(message),
      action: new SnackBarAction(
        label: 'OK',
        onPressed: () {
          if (userData.isAuthenticated) {
            Navigator.pop(context);
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
                          hintText: 'example@inspire.my', labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (String email) {
                        userData.email = email;
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
                        userData.password = password;
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
}

class SecureCounterScreen extends StatefulWidget {
  SecureCounterScreen({Key key}) : super(key: key);

  @override
  _SecureCounterScreenState createState() => new _SecureCounterScreenState();
}

class _SecureCounterScreenState extends State<SecureCounterScreen> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<User> _getAuthenticatedUser() async {
    final user = new User();

    try {
      await user.authenticated();
    } catch (e) {
      return null;
    }
    if (user.isAuthenticated) {
      await user.getUserAttributes();
      return user;
    }
    return user;
  }

  @override
  Widget build(BuildContext context) {
    return new FutureBuilder(
      future: _getAuthenticatedUser(),
      builder: (context, AsyncSnapshot<User> snapshot) {
        if (snapshot.hasData) {
          if (!snapshot.data.isAuthenticated) {
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
                    'Welcome ${snapshot.data.name}!',
                    style: Theme.of(context).textTheme.display1,
                  ),
                  new Divider(),
                  new Text(
                    'You have pushed the button this many times:',
                  ),
                  new Text(
                    '$_counter',
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
                        snapshot.data.signOut();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],

              ),
            ),
            floatingActionButton: new FloatingActionButton(
              onPressed: _incrementCounter,
              tooltip: 'Increment',
              child: new Icon(Icons.add),
            ),
          );
        }
        return new Scaffold(appBar: new AppBar(title: new Text('Loading...')));
      }
    );
  }
}
