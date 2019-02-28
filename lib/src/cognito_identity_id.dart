import 'dart:async';
import 'cognito_user_pool.dart';
import 'client.dart';

class CognitoIdentityId {
  String identityId;
  String _identityPoolId;
  String _userPoolId;
  CognitoUserPool _pool;
  Client _client;
  String _region;
  CognitoIdentityId(String identityPoolId, CognitoUserPool pool) {
    _identityPoolId = identityPoolId;
    _pool = pool;
    _userPoolId = pool.getUserPoolId();
    _region = pool.getRegion();
    _client = pool.client;
  }

  /// Get AWS Identity Id for authenticated user
  Future<String> getIdentityId(token, [String authenticator]) async {
    final identityIdKey = 'aws.cognito.identity-id.$_identityPoolId';
    String identityId = await _pool.storage.getItem(identityIdKey);
    if (identityId != null) {
      this.identityId = identityId;
      return identityId;
    }
    authenticator ??= 'cognito-idp.$_region.amazonaws.com/$_userPoolId';
    final Map<String, String> loginParam = {
      authenticator: token,
    };
    final Map<String, dynamic> paramsReq = {
      'IdentityPoolId': _identityPoolId,
      'Logins': loginParam,
    };
    final data = await _client.request('GetId', paramsReq,
        service: 'AWSCognitoIdentityService',
        endpoint: 'https://cognito-identity.$_region.amazonaws.com/');

    this.identityId = data['IdentityId'];
    await _pool.storage.setItem(identityIdKey, this.identityId);

    return this.identityId;
  }

  /// Remove AWS Identity Id from storage
  Future<String> removeIdentityId() async {
    final identityIdKey = 'aws.cognito.identity-id.$_identityPoolId';
    return await _pool.storage.removeItem(identityIdKey);
  }
}
