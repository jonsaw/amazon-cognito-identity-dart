import 'dart:async';
import 'package:amazon_cognito_identity_dart/client.dart';
import 'package:amazon_cognito_identity_dart/storage_helper.dart';
import 'package:amazon_cognito_identity_dart/attribute_arg.dart';
import 'package:amazon_cognito_identity_dart/cognito_user.dart';

class CognitoUserPoolData {
  CognitoUser user;
  bool userConfirmed;
  String userSub;
  CognitoUserPoolData(this.user, {this.userConfirmed, this.userSub});
}

class CognitoUserPool {
  bool advancedSecurityDataCollectionFlag;
  String userPoolId;
  String clientId;
  Client client;
  Storage storage;

  CognitoUserPool(
    this.userPoolId,
    this.clientId,
    {
      String endpoint,
      this.storage,
      this.advancedSecurityDataCollectionFlag = true,
    }
  ) {
    RegExp regExp = new RegExp(r'^[\w-]+_.+$');
    if (!regExp.hasMatch(userPoolId)) {
      throw new ArgumentError('Invalid userPoolId format.');
    }
    final region = userPoolId.split('_')[0];
    client = new Client(region: region, endpoint: endpoint);

    if (this.storage == null) {
      this.storage = storage = (new StorageHelper(new MemoryStorage())).getStorage();
    }
  }

  String getUserPoolId() {
    return this.userPoolId;
  }

  String getClientId() {
    return this.clientId;
  }

  Future<CognitoUser> getCurrentUser() async {
    final lastUserKey = 'CognitoIdentityServiceProvider.${this.clientId}.LastAuthUser';

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

  /**
   * This method returns the encoded data string used for cognito advanced security feature.
   * This would be generated only when developer has included the JS used for collecting the
   * data on their client. Please refer to documentation to know more about using AdvancedSecurity
   * features
   * TODO: not supported at the moment
   */
  String getUserContextData(String username) {
    return null;
  }

  Future<CognitoUserPoolData> signUp(
    String username,
    String password,
    {
      List<AttributeArg> userAttributes,
      List<AttributeArg> validationData,
    }
  ) async {
    var params = new Map();
    params['ClientId'] = this.clientId;
    params['Username'] = username;
    params['Password'] = password;
    params['UserAttributes'] = userAttributes;
    params['ValidationData'] = validationData;
    var data = await this.client.request('SignUp', params);
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
