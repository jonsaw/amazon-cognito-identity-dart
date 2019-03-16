import 'dart:async';
import 'cognito_user_pool.dart';
import 'client.dart';
import 'cognito_client_exceptions.dart';
import 'cognito_identity_id.dart';

class CognitoCredentials {
  String _region;
  String _userPoolId;
  String _identityPoolId;
  CognitoUserPool _pool;
  Client _client;
  int _retryCount = 0;
  String accessKeyId;
  String secretAccessKey;
  String sessionToken;
  int expireTime;
  CognitoCredentials(String identityPoolId, CognitoUserPool pool,
      {String region, String userPoolId}) {
    _pool = pool;
    _region = region ?? pool.getRegion();
    _userPoolId = userPoolId ?? pool.getUserPoolId();
    _identityPoolId = identityPoolId;
    _client = pool.client;
  }

  /// Get AWS Credentials for authenticated user
  Future<void> getAwsCredentials(token, [String authenticator]) async {
    if (expireTime == null ||
        new DateTime.now().millisecondsSinceEpoch > expireTime - 60000) {
      final identityId = new CognitoIdentityId(_identityPoolId, _pool);
      final identityIdId = await identityId.getIdentityId(token, authenticator);

      authenticator ??= 'cognito-idp.$_region.amazonaws.com/$_userPoolId';
      final Map<String, String> loginParam = {
        authenticator: token,
      };
      final Map<String, dynamic> paramsReq = {
        'IdentityId': identityIdId,
        'Logins': loginParam,
      };

      var data;
      try {
        data = await _client.request('GetCredentialsForIdentity', paramsReq,
            service: 'AWSCognitoIdentityService',
            endpoint: 'https://cognito-identity.$_region.amazonaws.com/');
      } on CognitoClientException catch (e) {
        // remove cached Identity Id and try again
        await identityId.removeIdentityId();
        if (e.code == 'NotAuthorizedException' && _retryCount < 1) {
          _retryCount++;
          return await getAwsCredentials(token);
        }

        _retryCount = 0;
        throw e;
      }

      _retryCount = 0;

      accessKeyId = data['Credentials']['AccessKeyId'];
      secretAccessKey = data['Credentials']['SecretKey'];
      sessionToken = data['Credentials']['SessionToken'];

      expireTime = (data['Credentials']['Expiration']).toInt() * 1000;
    }
  }

  /// Reset AWS Credentials; removes Identity Id from local storage
  Future<void> resetAwsCredentials() async {
    await new CognitoIdentityId(_identityPoolId, _pool).removeIdentityId();
    expireTime = null;
    accessKeyId = null;
    secretAccessKey = null;
    sessionToken = null;
  }
}
