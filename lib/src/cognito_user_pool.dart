import 'dart:async';
import 'client.dart';
import 'attribute_arg.dart';
import 'cognito_storage.dart';
import 'cognito_user.dart';

class CognitoUserPoolData {
  CognitoUser user;
  bool userConfirmed;
  String userSub;
  CognitoUserPoolData(this.user, {this.userConfirmed, this.userSub});
}

class CognitoUserPool {
  String _userPoolId;
  String _clientId;
  String _region;
  bool advancedSecurityDataCollectionFlag;
  Client client;
  CognitoStorage storage;

  CognitoUserPool(
    String userPoolId,
    String clientId, {
    String endpoint,
    this.storage,
    this.advancedSecurityDataCollectionFlag = true,
  }) {
    _userPoolId = userPoolId;
    _clientId = clientId;
    RegExp regExp = new RegExp(r'^[\w-]+_.+$');
    if (!regExp.hasMatch(userPoolId)) {
      throw new ArgumentError('Invalid userPoolId format.');
    }
    _region = userPoolId.split('_')[0];
    client = new Client(region: _region, endpoint: endpoint);

    if (this.storage == null) {
      this.storage = storage =
          (new CognitoStorageHelper(new CognitoMemoryStorage())).getStorage();
    }
  }

  String getUserPoolId() {
    return _userPoolId;
  }

  String getClientId() {
    return _clientId;
  }

  String getRegion() {
    return _region;
  }

  Future<CognitoUser> getCurrentUser() async {
    final lastUserKey =
        'CognitoIdentityServiceProvider.$_clientId.LastAuthUser';

    final lastAuthUser = await storage.getItem(lastUserKey);
    if (lastAuthUser != null) {
      return new CognitoUser(
        lastAuthUser,
        this,
        storage: this.storage,
      );
    }

    return null;
  }

  /// This method returns the encoded data string used for cognito advanced security feature.
  /// This would be generated only when developer has included the JS used for collecting the
  /// data on their client. Please refer to documentation to know more about using AdvancedSecurity
  /// features
  /// TODO: not supported at the moment
  String getUserContextData(String username) {
    return null;
  }

  Future<CognitoUserPoolData> signUp(
    String username,
    String password, {
    List<AttributeArg> userAttributes,
    List<AttributeArg> validationData,
  }) async {
    final Map<String, dynamic> params = {
      'ClientId': _clientId,
      'Username': username,
      'Password': password,
      'UserAttributes': userAttributes,
      'ValidationData': validationData,
    };

    final data = await this.client.request('SignUp', params);
    if (data == null) {
      return null;
    }
    CognitoUser cognitoUser = new CognitoUser(
      username,
      this,
      storage: storage,
    );
    return new CognitoUserPoolData(
      cognitoUser,
      userConfirmed: data['UserConfirmed'] ?? false,
      userSub: data['UserSub'],
    );
  }
}
