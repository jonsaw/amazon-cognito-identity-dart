# Amazon Cognito Identity SDK for Dart
Unofficial Amazon Cognito Identity SDK written in Dart for [Dart](https://www.dartlang.org/).

Based on [amazon-cognito-identity-js](https://github.com/aws/aws-amplify/tree/master/packages/amazon-cognito-identity-js).

Need ideas to get started?

- Check out use cases [below](https://github.com/jonsaw/amazon-cognito-identity-dart/#usage).
- Example Flutter app can be found [here](https://github.com/jonsaw/amazon-cognito-identity-dart/tree/master/example).
- Authenticated access to AppSync + GraphQL or API Gateway + Lambda found [here](https://github.com/jonsaw/amazon-cognito-identity-dart/#signing-requests).
- Follow the tutorial on [Serverless Stack](https://serverless-stack.com/chapters/create-a-cognito-user-pool.html) for best Cognito setup.

Please note that this package is _not_ production ready.

## Usage
__Use Case 1.__ Registering a user with the application. One needs to create a CognitoUserPool object by providing a UserPoolId and a ClientId and signing up by using a username, password, attribute list, and validation data.

```dart
import 'package:amazon_cognito_identity_dart/cognito.dart';

final userPool = new CognitoUserPool(
    'ap-southeast-1_xxxxxxxxx', 'xxxxxxxxxxxxxxxxxxxxxxxxxx');
final userAttributes = [
  new AttributeArg(name: 'first_name', value: 'Jimmy'),
  new AttributeArg(name: 'last_name', value: 'Wong'),
];

var data;
try {
  data = await userPool.signUp('email@inspire.my', 'Password001',
      userAttributes: userAttributes);
} catch (e) {
  print(e);
}
```

__Use case 2.__ Confirming a registered, unauthenticated user using a confirmation code received via SMS/email.

```dart
import 'package:amazon_cognito_identity_dart/cognito.dart';

final userPool = new CognitoUserPool(
    'ap-southeast-1_xxxxxxxxx', 'xxxxxxxxxxxxxxxxxxxxxxxxxx');

final cognitoUser = new CognitoUser(
    'email@inspire.my', userPool);

bool registrationConfirmed = false;
try {
  registrationConfirmed = await cognitoUser.confirmRegistration('123456');
} catch (e) {
  print(e);
}
print(registrationConfirmed);
```

__Use case 3.__ Resending a confirmation code via SMS/email for confirming registration for unauthenticated users.

```dart
import 'package:amazon_cognito_identity_dart/cognito.dart';

final userPool = new CognitoUserPool(
    'ap-southeast-1_xxxxxxxxx', 'xxxxxxxxxxxxxxxxxxxxxxxxxx');
final cognitoUser = new CognitoUser(
    'email@inspire.my', userPool);
final String status;
try {
  status = await cognitoUser.resendConfirmationCode();
} catch (e) {
  print(e);
}
```

__Use case 4.__ Authenticating a user and establishing a user session with the Amazon Cognito Identity service.

```dart
import 'package:amazon_cognito_identity_dart/cognito.dart';

final userPool = new CognitoUserPool(
    'ap-southeast-1_xxxxxxxxx', 'xxxxxxxxxxxxxxxxxxxxxxxxxx');
final cognitoUser = new CognitoUser(
    'email@inspire.my', userPool);
final authDetails = new AuthenticationDetails(
    username: 'email@inspire.my', password: 'Password001');
CognitoUserSession session;
try {
  session = await cognitoUser.authenticateUser(authDetails);
} on CognitoUserNewPasswordRequiredException catch (e) {
  // handle New Password challenge
} on CognitoUserMfaRequiredException catch (e) {
  // handle SMS_MFA challenge
} on CognitoUserSelectMfaTypeException catch (e) {
  // handle SELECT_MFA_TYPE challenge
} on CognitoUserMfaSetupException catch (e) {
  // handle MFA_SETUP challenge
} on CognitoUserTotpRequiredException catch (e) {
  // handle SOFTWARE_TOKEN_MFA challenge
} on CognitoUserCustomChallengeException catch (e) {
  // handle CUSTOM_CHALLENGE challenge
} on CognitoUserConfirmationNecessaryException catch (e) {
  // handle User Confirmation Necessary
} catch (e) {
  print(e);
}
print(session.getAccessToken().getJwtToken());
```

__Use case 5.__ Retrieve user attributes for authenticated users.

```dart
List<CognitoUserAttribute> attributes;
try {
  attributes = await cognitoUser.getUserAttributes();
} catch (e) {
  print(e);
}
attributes.forEach((attribute) {
  print('attribute ${attribute.getName()} has value ${attribute.getValue()}');
});
```

__Use case 6.__ Verify user attribute for an authenticated user.

```dart
var data;
try {
  data = await cognitoUser.getAttributeVerificationCode('email');
} catch {
  print(e);
}
print(data);

// obtain verification code...

bool attributeVerified = false;
try {
  attributeVerified = await cognitoUser.verifyAttribute(
      'email', '123456');
} catch (e) {
  print(e);
}
print(attributeVerified);
```

__Use case 7.__ Delete user attributes for authenticated users.

```dart
try {
  final List<String> attributeList = ['nickname'];
  cognitoUser.deleteAttributes(attributeList);
} catch (e) {
  print(e);
}
```

__Use case 8.__ Update user attributes for authenticated users.

```dart
final List<CognitoUserAttribute> attributes = [];
attributes.add(new CognitoUserAttribute(name: 'nickname', value: 'joe'));

try {
  await cognitoUser.updateAttributes(attributes);
} catch (e) {
  print(e);
}
```

__Use case 9.__ Enabling MFA for a user on a pool that has an optional MFA setting for authenticated users.

```dart
bool mfaEnabled = false;
try {
  mfaEnabled = await cognitoUser.enableMfa();
} catch (e) {
  print(e);
}
print(mfaEnabled);
```

__Use case 10.__ Disabling MFA for a user on a pool that has an optional MFA setting for authenticated users.

```dart
bool mfaDisabled = false;
try {
  mfaDisabled = await cognitoUser.disableMfa();
} catch (e) {
  print(e);
}
print(mfaDisabled);
```

__Use case 11.__ Changing the current password for authenticated users.

```dart
bool passwordChanged = false;
try {
  passwordChanged = await cognitoUser.changePassword(
      'oldPassword', 'newPassword');
} catch (e) {
  print(e);
}
print(passwordChanged);
```

__Use case 12.__ Starting and completing a forgot password flow for an unauthenticated user.

```dart
import 'package:amazon_cognito_identity_dart/cognito.dart';

final userPool = new CognitoUserPool(
    'ap-southeast-1_xxxxxxxxx', 'xxxxxxxxxxxxxxxxxxxxxxxxxx');
final cognitoUser = new CognitoUser(
    'email@inspire.my', userPool);

var data;
try {
  data = await cognitoUser.forgotPassword();
} catch (e) {
  print(e);
}
print('Code sent to $data');

// prompt user for verification input...

bool passwordConfirmed = false;
try {
  passwordConfirmed = await cognitoUser.confirmPassword(
      '123456', 'newPassword');
} catch (e) {
  print(e);
}
print(passwordConfirmed);
```

__Use case 13.__ Deleting authenticated users.

```dart
bool userDeleted = false
try {
  userDeleted = await cognitoUser.deleteUser();
} catch (e) {
  print(e);
}
print(userDeleted);
```

__Use case 14.__ Signing out from the application.

```dart
await cognitoUser.signOut();
```

__Use case 15.__ Global signout for authenticated users (invalidates all issued tokens).

```dart
await cognitoUser.globalSignOut();
```

## Addtional Features

### Get AWS Credentials

Get a authenticated user's AWS Credentials. Use with other signing processes like [Signature Version 4](https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html).

```dart
import 'package:amazon_cognito_identity_dart/cognito.dart';

final userPool = new CognitoUserPool(
    'ap-southeast-1_xxxxxxxxx', 'xxxxxxxxxxxxxxxxxxxxxxxxxx');
final cognitoUser = new CognitoUser(
    'email@inspire.my', userPool);
final authDetails = new AuthenticationDetails(
    username: 'email@inspire.my', password: 'Password001'
);
final session = await cognitoUser.authenticateUser(authDetails);

final credentials = new CognitoCredentials(
    'ap-southeast-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx', userPool);
await credentials.getAwsCredentials(session.getIdToken().getJwtToken());
print(credentials.accessKeyId);
print(credentials.secretAccessKey);
print(credentials.sessionToken);
```

### Signing Requests

#### For AppSync's GraphQL

Signing GraphQL requests for authenticated users with IAM Authorization type for access to AppSync data.

```dart
import 'package:http/http.dart' as http;
import 'package:amazon_cognito_identity_dart/cognito.dart';
import 'package:amazon_cognito_identity_dart/sig_v4.dart';

final credentials = new CognitoCredentials(
    'ap-southeast-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx', userPool);
await credentials.getAwsCredentials(session.getIdToken().getJwtToken());

const endpoint =
    'https://xxxxxxxxxxxxxxxxxxxxxxxxxx.appsync-api.ap-southeast-1.amazonaws.com';

final awsSigV4Client = new AwsSigV4Client(
    credentials.accessKeyId, credentials.secretAccessKey, endpoint,
    serviceName: 'appsync',
    sessionToken: credentials.sessionToken,
    region: 'ap-southeast-1');

final String query = '''query GetEvent {
  getEvent(id: "3dcd52c3-1fd6-4e4d-8da6-946ef4a0c94d") {
    id
    name
    comments(limit: 10) {
      items {
        content
        createdAt
      }
    }
  }
}''';

final signedRequest = new SigV4Request(awsSigV4Client,
    method: 'POST', path: '/graphql',
    headers: new Map<String, String>.from(
        {'Content-Type': 'application/graphql; charset=utf-8'}),
    body: new Map<String, String>.from({
        'operationName': 'GetEvent',
        'query': query}));

http.Response response;
try {
  response = await http.post(
      signedRequest.url,
      headers: signedRequest.headers, body: signedRequest.body);
} catch (e) {
  print(e);
}
print(response.body);
```

#### For API Gateway & Lambda

Signing requests for authenticated users for access to secured routes to API Gateway and Lambda.

```dart
import 'package:http/http.dart' as http;
import 'package:amazon_cognito_identity_dart/cognito.dart';
import 'package:amazon_cognito_identity_dart/sig_v4.dart';

final credentials = new CognitoCredentials(
    'ap-southeast-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx', userPool);
await credentials.getAwsCredentials(session.getIdToken().getJwtToken());

const endpoint =
    'https://xxxx.execute-api.ap-southeast-1.amazonaws.com/dev';
final awsSigV4Client = new AwsSigV4Client(
    credentials.accessKeyId, credentials.secretAccessKey, endpoint,
    sessionToken: credentials.sessionToken,
    region: 'ap-southeast-1');

final signedRequest = new SigV4Request(awsSigV4Client,
    method: 'POST',
    path: '/projects',
    headers: new Map<String, String>.from(
        {'header-1': 'one', 'header-2': 'two'}),
    queryParams: new Map<String, String>.from({'tracking': 'x123'}),
    body: new Map<String, dynamic>.from({'color': 'blue'}));

http.Response response;
try {
  response = await http.post(
      signedRequest.url,
      headers: signedRequest.headers, body: signedRequest.body);
} catch (e) {
  print(e);
}
print(response.body);
```

### Use Custom Storage

Persist user session using custom storage.

[Shared Preferences Plugin](https://pub.dartlang.org/packages/shared_preferences) storage example found [here](https://github.com/jonsaw/amazon-cognito-identity-dart/blob/master/example/lib/main.dart#L72).

```dart
import 'dart:convert';
import 'package:amazon_cognito_identity_dart/cognito.dart';

Map<String, String> _storage = {};

class CustomStorage extends CognitoStorage {
  String prefix;
  CustomStorage(this.prefix);

  @override
  Future setItem(String key, value) async {
    _storage[prefix+key] = json.encode(value);
    return _storage[prefix+key];
  }

  @override
  Future getItem(String key) async {
    if (_storage[prefix+key] != null) {
      return json.decode(_storage[prefix+key]);
    }
    return null;
  }

  @override
  Future removeItem(String key) async {
    return _storage.remove(prefix+key);
  }

  @override
  Future<void> clear() async {
    _storage = {};
  }
}

final customStore = new CustomStorage('custom:');

final userPool = new CognitoUserPool(
    'ap-southeast-1_xxxxxxxxx', 'xxxxxxxxxxxxxxxxxxxxxxxxxx',
    storage: customStore);
final cognitoUser = new CognitoUser(
    'email@inspire.my', userPool,
    storage: customStore);
final authDetails = new AuthenticationDetails(
    username: 'email@inspire.my', password: 'Password001');
await cognitoUser.authenticateUser(authDetails);

// some time later...
final user = await userPool.getCurrentUser();
final session = await user.getSession();
print(session.isValid());
```
