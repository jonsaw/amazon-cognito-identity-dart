import 'dart:async';
import 'cognito_user_pool.dart';
import 'package:amazon_cognito_identity_dart/client.dart';
import 'package:amazon_cognito_identity_dart/cognito_identity_id.dart';

class CognitoCredentials {
  String _region;
  String _userPoolId;
  String _identityPoolId;
  CognitoUserPool _pool;
  Client _client;
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

  /**
   * Get AWS Credentials for authenticated user
   */
  Future<void> getAwsCredentials(token) async {
    if (expireTime == null ||
        new DateTime.now().millisecondsSinceEpoch > expireTime - 60000) {
      final identityId = new CognitoIdentityId(_identityPoolId, _pool);
      final identityIdId = await identityId.getIdentityId(token);

      final authenticator =
          'cognito-idp.${_region}.amazonaws.com/${_userPoolId}';
      final Map<String, String> loginParam = {
        authenticator: token,
      };
      final Map<String, dynamic> paramsReq = {
        'IdentityId': identityIdId,
        'Logins': loginParam,
      };
      final data = await _client.request('GetCredentialsForIdentity', paramsReq,
          service: 'AWSCognitoIdentityService',
          endpoint: 'https://cognito-identity.${_region}.amazonaws.com/');

      accessKeyId = data['Credentials']['AccessKeyId'];
      secretAccessKey = data['Credentials']['SecretKey'];
      sessionToken = data['Credentials']['SessionToken'];
    }
  }
}
