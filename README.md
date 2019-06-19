# Amazon Cognito Identity SDK for Dart
Unofficial Amazon Cognito Identity SDK written in Dart for [Dart](https://www.dartlang.org/).

Based on [amazon-cognito-identity-js](https://github.com/aws/aws-amplify/tree/master/packages/amazon-cognito-identity-js).

Need ideas to get started?

- Check out use cases [below](https://github.com/jonsaw/amazon-cognito-identity-dart/#usage).
- Example Flutter app can be found [here](https://github.com/jonsaw/amazon-cognito-identity-dart/tree/master/example).
- Authenticated access to:
    - AppSync + GraphQL found [here](https://github.com/jonsaw/amazon-cognito-identity-dart/#for-appsyncs-graphql).
    - API Gateway + Lambda found [here](https://github.com/jonsaw/amazon-cognito-identity-dart/#for-api-gateway--lambda).
    - S3 Presigned Post found [here](https://github.com/jonsaw/amazon-cognito-identity-dart/#for-s3-uploads).
    - S3 GET Object with Authorization found [here](https://github.com/jonsaw/amazon-cognito-identity-dart/#for-s3-get-object).
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

#### For S3 Uploads

S3 Uploads using HTTP Presigned Post.

```dart
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:amazon_cognito_identity_dart/cognito.dart';
import 'package:amazon_cognito_identity_dart/sig_v4.dart';

class Policy {
  String expiration;
  String region;
  String bucket;
  String key;
  String credential;
  String datetime;
  String sessionToken;
  int maxFileSize;

  Policy(this.key, this.bucket, this.datetime, this.expiration, this.credential,
      this.maxFileSize, this.sessionToken,
      {this.region = 'us-east-1'});

  factory Policy.fromS3PresignedPost(
    String key,
    String bucket,
    int expiryMinutes,
    String accessKeyId,
    int maxFileSize,
    String sessionToken, {
    String region,
  }) {
    final datetime = SigV4.generateDatetime();
    final expiration = (DateTime.now())
        .add(Duration(minutes: expiryMinutes))
        .toUtc()
        .toString()
        .split(' ')
        .join('T');
    final cred =
        '$accessKeyId/${SigV4.buildCredentialScope(datetime, region, 's3')}';
    final p = Policy(
        key, bucket, datetime, expiration, cred, maxFileSize, sessionToken,
        region: region);
    return p;
  }

  String encode() {
    final bytes = utf8.encode(toString());
    return base64.encode(bytes);
  }

  @override
  String toString() {
    return '''
{ "expiration": "${this.expiration}",
  "conditions": [
    {"bucket": "${this.bucket}"},
    ["starts-with", "\$key", "${this.key}"],
    {"acl": "public-read"},
    ["content-length-range", 1, ${this.maxFileSize}],
    {"x-amz-credential": "${this.credential}"},
    {"x-amz-algorithm": "AWS4-HMAC-SHA256"},
    {"x-amz-date": "${this.datetime}" },
    {"x-amz-security-token": "${this.sessionToken}" }
  ]
}
''';
  }
}

void main() async {
  const _awsUserPoolId = 'ap-southeast-xxxxxxxxxxx';
  const _awsClientId = 'xxxxxxxxxxxxxxxxxxxxxxxxxx';

  const _identityPoolId =
      'ap-southeast-1:xxxxxxxxx-xxxx-xxxx-xxxxxxxxxxx';
  final _userPool = CognitoUserPool(_awsUserPoolId, _awsClientId);

  final _cognitoUser = CognitoUser('+60100000000', _userPool);
  final authDetails =
      AuthenticationDetails(username: '+60100000000', password: 'p&ssW0RD');

  CognitoUserSession _session;
  try {
    _session = await _cognitoUser.authenticateUser(authDetails);
  } catch (e) {
    print(e);
  }

  final _credentials = CognitoCredentials(_identityPoolId, _userPool);
  await _credentials.getAwsCredentials(_session.getIdToken().getJwtToken());

  const _region = 'ap-southeast-1';
  const _s3Endpoint =
      'https://my-s3-bucket.s3-ap-southeast-1.amazonaws.com';

  final file = File(path.join('/path/to/my/folder', 'square-cinnamon.jpg'));

  final stream = http.ByteStream(DelegatingStream.typed(file.openRead()));
  final length = await file.length();

  final uri = Uri.parse(_s3Endpoint);
  final req = http.MultipartRequest("POST", uri);
  final multipartFile = http.MultipartFile('file', stream, length,
      filename: path.basename(file.path));

  final policy = Policy.fromS3PresignedPost(
      'test/square-cinnamon.jpg',
      'my-s3-bucket',
      15,
      _credentials.accessKeyId,
      length,
      _credentials.sessionToken,
      region: _region);
  final key = SigV4.calculateSigningKey(
      _credentials.secretAccessKey, policy.datetime, _region, 's3');
  final signature = SigV4.calculateSignature(key, policy.encode());

  req.files.add(multipartFile);
  req.fields['key'] = policy.key;
  req.fields['acl'] = 'public-read';
  req.fields['X-Amz-Credential'] = policy.credential;
  req.fields['X-Amz-Algorithm'] = 'AWS4-HMAC-SHA256';
  req.fields['X-Amz-Date'] = policy.datetime;
  req.fields['Policy'] = policy.encode();
  req.fields['X-Amz-Signature'] = signature;
  req.fields['x-amz-security-token'] = _credentials.sessionToken;

  try {
    final res = await req.send();
    await for (var value in res.stream.transform(utf8.decoder)) {
      print(value);
    }
  } catch (e) {
    print(e.toString());
  }
}
```

#### For S3 GET Object

Signing S3 GET Object using `Authorization` header.

```dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:amazon_cognito_identity_dart/cognito.dart';
import 'package:amazon_cognito_identity_dart/sig_v4.dart';
import 'package:http/http.dart' as http;

void main() {
  const _awsUserPoolId = 'ap-southeast-1_xxxxxxxx';
  const _awsClientId = 'xxxxxxxxxxxxxxxxxxxxxxxxxx';

  const _identityPoolId =
      'ap-southeast-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
  final _userPool = CognitoUserPool(_awsUserPoolId, _awsClientId);

  final _cognitoUser = CognitoUser('+60100000000', _userPool);
  final authDetails =
      AuthenticationDetails(username: '+60100000000', password: 'p@ssW0rd');

  CognitoUserSession _session;
  try {
    _session = await _cognitoUser.authenticateUser(authDetails);
  } catch (e) {
    print(e);
    return;
  }

  final _credentials = CognitoCredentials(_identityPoolId, _userPool);
  await _credentials.getAwsCredentials(_session.getIdToken().getJwtToken());

  final host = 's3.ap-southeast-1.amazonaws.com';
  final region = 'ap-southeast-1';
  final service = 's3';
  final key =
      'my-s3-bucket/ap-southeast-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/square-cinnamon.jpg';
  final payload = SigV4.hashCanonicalRequest('');
  final datetime = SigV4.generateDatetime();
  final canonicalRequest = '''GET
${'/$key'.split('/').map((s) => Uri.encodeComponent(s)).join('/')}

host:$host
x-amz-content-sha256:$payload
x-amz-date:$datetime
x-amz-security-token:${_credentials.sessionToken}

host;x-amz-content-sha256;x-amz-date;x-amz-security-token
$payload''';
  final credentialScope =
      SigV4.buildCredentialScope(datetime, region, service);
  final stringToSign = SigV4.buildStringToSign(datetime, credentialScope,
      SigV4.hashCanonicalRequest(canonicalRequest));
  final signingKey = SigV4.calculateSigningKey(
      _credentials.secretAccessKey, datetime, region, service);
  final signature = SigV4.calculateSignature(signingKey, stringToSign);

  final authorization = [
    'AWS4-HMAC-SHA256 Credential=${_credentials.accessKeyId}/$credentialScope',
    'SignedHeaders=host;x-amz-content-sha256;x-amz-date;x-amz-security-token',
    'Signature=$signature',
  ].join(',');

  final uri = Uri.https(host, key);
  http.Response response;
  try {
    response = await http.get(uri, headers: {
      'Authorization': authorization,
      'x-amz-content-sha256': payload,
      'x-amz-date': datetime,
      'x-amz-security-token': _credentials.sessionToken,
    });
  } catch (e) {
    print(e);
    return;
  }

  final file = File(path.join(
      '/path/to/my/folder',
      'square-cinnamon-downloaded.jpg'));

  try {
    await file.writeAsBytes(response.bodyBytes);
  } catch (e) {
    print(e.toString());
    return;
  }

  print('complete!');
}
```

#### For PreSign S3 url


```dart
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:amazon_cognito_identity_dart/cognito.dart';
import 'package:amazon_cognito_identity_dart/sig_v4.dart';
import 'package:http/http.dart' as http;

void main() {
  const _awsUserPoolId = 'ap-southeast-1_xxxxxxxx';
  const _awsClientId = 'xxxxxxxxxxxxxxxxxxxxxxxxxx';

  const _identityPoolId =
      'ap-southeast-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
  final _userPool = CognitoUserPool(_awsUserPoolId, _awsClientId);

  final _cognitoUser = CognitoUser('+60100000000', _userPool);
  final authDetails =
      AuthenticationDetails(username: '+60100000000', password: 'p@ssW0rd');

  CognitoUserSession _session;
  try {
    _session = await _cognitoUser.authenticateUser(authDetails);
  } catch (e) {
    print(e);
    return;
  }

  final _credentials = CognitoCredentials(_identityPoolId, _userPool);
  await _credentials.getAwsCredentials(_session.getIdToken().getJwtToken());

  final service = 's3';
  final region = 'ap-southeast-1';
  final bucket = 'bucket-name'
  final host = '$bucket.$service.$region.amazonaws.com';
  final headers = {"Host": host};
  final key = 'public/square-cinnamon.jpg';

  Map<String, String> params = {};

  final datetime = SigV4.generateDatetime();
  final credentialScope = SigV4.buildCredentialScope(datetime, region, service);

  params['X-Amz-Security-Token'] = _credentials.sessionToken;
  params['X-Amz-Algorithm'] = aws_sha_256;
  params['X-Amz-Date'] = datetime;
  params['X-Amz-SignedHeaders'] = SigV4.buildCanonicalSignedHeaders(headers);
  params['X-Amz-Expires'] = '3599';
  params['X-Amz-Credential'] = '${credentials.accessKeyId}/$credentialScope';

  final canonicalRequest = SigV4.buildCanonicalRequest(
      'GET',
      '/$key',
      params,
      headers,
      'UNSIGNED-PAYLOAD', false);

  final stringToSign = SigV4.buildStringToSign(datetime, credentialScope, SigV4.hashCanonicalRequest(canonicalRequest));

  final signingKey = SigV4.calculateSigningKey(_credentials.secretAccessKey, datetime, region, service);
  final signature = SigV4.calculateSignature(signingKey, stringToSign);

  params['X-Amz-Signature'] = signature;

  final url = 'https://$host${'/$key'.split('/').map((s) => Uri.encodeComponent(s)).join('/')}?'
    + params.keys.map((key) => '$key=${Uri.encodeComponent(params[key])}').join('&');

  http.Response response;
  try {
    response = await http.get(url);
  } catch (e) {
    print(e);
    return;
  }

  final file = File(path.join(
      '/path/to/my/folder',
      'square-cinnamon-downloaded.jpg'));

  try {
    await file.writeAsBytes(response.bodyBytes);
  } catch (e) {
    print(e.toString());
    return;
  }

  print('complete!');
}
```

#### For AppSync's GraphQL

Authenticating Amazon Cognito User Pool using JWT Tokens.

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:amazon_cognito_identity_dart/cognito.dart';

void main() async {
  const _awsUserPoolId = 'ap-southeast-1_xxxxxxxxx';
  const _awsClientId = 'xxxxxxxxxxxxxxxxxxxxxxxxxx';

  const _identityPoolId = 'ap-southeast-1:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx';
  final _userPool = CognitoUserPool(_awsUserPoolId, _awsClientId);

  final _cognitoUser = CognitoUser('+60100000000', _userPool);
  final authDetails =
      AuthenticationDetails(username: '+60100000000', password: 'p@ssW0rd');

  CognitoUserSession _session;
  try {
    _session = await _cognitoUser.authenticateUser(authDetails);
  } catch (e) {
    print(e);
    return;
  }

  final _credentials = CognitoCredentials(_identityPoolId, _userPool);
  await _credentials.getAwsCredentials(_session.getIdToken().getJwtToken());

  final _endpoint =
      'https://xxxxxxxxxxxxxxxxxxxxxxxxxx.appsync-api.ap-southeast-1.amazonaws.com';

  final body = {
    'operationName': 'CreateItem',
    'query': '''mutation CreateItem {
        createItem(name: "Some Name") {
          name
        }
      }''',
  };
  http.Response response;
  try {
    response = await http.post(
      '$_endpoint/graphql',
      headers: {
        'Authorization': _session.getAccessToken().getJwtToken(),
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );
  } catch (e) {
    print(e);
  }
  print(response.body);
}
```

Signing GraphQL requests for authenticated users with IAM Authorization type for access to AppSync data.

```dart
import 'package:http/http.dart' as http;
import 'package:amazon_cognito_identity_dart/cognito.dart';
import 'package:amazon_cognito_identity_dart/sig_v4.dart';

void main() async {
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
}
```

#### For API Gateway & Lambda

Signing requests for authenticated users for access to secured routes to API Gateway and Lambda.

```dart
import 'package:http/http.dart' as http;
import 'package:amazon_cognito_identity_dart/cognito.dart';
import 'package:amazon_cognito_identity_dart/sig_v4.dart';

void main() async {
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
}
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
