import 'dart:async';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'attribute_arg.dart';
import 'cognito_user_attribute.dart';
import 'cognito_user_exceptions.dart';
import 'cognito_user_pool.dart';
import 'cognito_user_session.dart';
import 'cognito_id_token.dart';
import 'cognito_access_token.dart';
import 'cognito_refresh_token.dart';
import 'client.dart';
import 'cognito_client_exceptions.dart';
import 'cognito_storage.dart';
import 'authentication_details.dart';
import 'authentication_helper.dart';
import 'date_helper.dart';

class CognitoUserAuthResult {
  String challengeName;
  String session;
  dynamic authenticationResult;
  CognitoUserAuthResult({
    this.challengeName,
    this.session,
    this.authenticationResult,
  });
}

class CognitoUser {
  String _deviceKey;
  String _randomPassword;
  String _deviceGroupKey;
  String _session;
  CognitoUserSession _signInUserSession;
  String username;
  CognitoUserPool pool;
  Client client;
  String authenticationFlowType;
  String deviceName;
  String verifierDevices;
  CognitoStorage storage;

  CognitoUser(
    this.username,
    this.pool, {
    this.storage,
    this.deviceName = 'Dart-device',
  }) {
    client = pool.client;
    authenticationFlowType = 'USER_SRP_AUTH';

    if (this.storage == null) {
      this.storage =
          (new CognitoStorageHelper(new CognitoMemoryStorage())).getStorage();
    }
  }

  Future<CognitoUserSession> _authenticateUserInternal(
      dataAuthenticate, AuthenticationHelper authenticationHelper) async {
    final String challengeName = dataAuthenticate['ChallengeName'];
    var challengeParameters = dataAuthenticate['ChallengeParameters'];

    if (challengeName == 'SMS_MFA') {
      _session = dataAuthenticate['Session'];
      throw new CognitoUserMfaRequiredException(
          challengeName: challengeName,
          challengeParameters: challengeParameters);
    }

    if (challengeName == 'SELECT_MFA_TYPE') {
      _session = dataAuthenticate['Session'];
      throw new CognitoUserSelectMfaTypeException(
          challengeName: challengeName,
          challengeParameters: challengeParameters);
    }

    if (challengeName == 'MFA_SETUP') {
      _session = dataAuthenticate['Session'];
      throw new CognitoUserMfaSetupException(
          challengeName: challengeName,
          challengeParameters: challengeParameters);
    }

    if (challengeName == 'SOFTWARE_TOKEN_MFA') {
      _session = dataAuthenticate['Session'];
      throw new CognitoUserTotpRequiredException(
          challengeName: challengeName,
          challengeParameters: challengeParameters);
    }

    if (challengeName == 'CUSTOM_CHALLENGE') {
      _session = dataAuthenticate['Session'];
      throw new CognitoUserCustomChallengeException(
          challengeName: challengeName,
          challengeParameters: challengeParameters);
    }

    if (challengeName == 'DEVICE_SRP_AUTH') {
      await this.getDeviceResponse();
      return _signInUserSession;
    }
    _signInUserSession =
        this.getCognitoUserSession(dataAuthenticate['AuthenticationResult']);
    await this.cacheTokens();

    final newDeviceMetadata =
        dataAuthenticate['AuthenticationResult']['NewDeviceMetadata'];
    if (newDeviceMetadata == null) {
      return _signInUserSession;
    }

    authenticationHelper.generateHashDevice(
      dataAuthenticate['AuthenticationResult']['NewDeviceMetadata']
          ['DeviceGroupKey'],
      dataAuthenticate['AuthenticationResult']['NewDeviceMetadata']
          ['DeviceKey'],
    );

    final Map<String, String> deviceSecretVerifierConfig = {
      'Salt': base64.encode(hex.decode(authenticationHelper.getSaltDevices())),
      'PasswordVerifier':
          base64.encode(hex.decode(authenticationHelper.getVerifierDevices()))
    };

    verifierDevices = deviceSecretVerifierConfig['PasswordVerifier'];
    _deviceGroupKey = newDeviceMetadata['DeviceGroupKey'];
    _randomPassword = authenticationHelper.getRandomPassword();

    final Map<String, dynamic> paramsConfirmDevice = {
      'DeviceKey': newDeviceMetadata['DeviceKey'],
      'AccessToken': _signInUserSession.getAccessToken().getJwtToken(),
      'DeviceSecretVerifierConfig': deviceSecretVerifierConfig,
      'DeviceName': deviceName,
    };

    final dataConfirm =
        await client.request('ConfirmDevice', paramsConfirmDevice);

    _deviceKey = dataAuthenticate['AuthenticationResult']['NewDeviceMetadata']
        ['DeviceKey'];
    await cacheDeviceKeyAndPassword();

    if (dataConfirm['UserConfirmationNecessary'] == true) {
      throw new CognitoUserConfirmationNecessaryException(
          signInUserSession: _signInUserSession);
    }
    return _signInUserSession;
  }

  /// This is used to get a session, either from the session object
  /// or from  the local storage, or by using a refresh token
  Future<CognitoUserSession> getSession() async {
    if (username == null) {
      throw new Exception('Username is null. Cannot retrieve a new session');
    }

    if (_signInUserSession != null && _signInUserSession.isValid()) {
      return _signInUserSession;
    }

    final keyPrefix =
        'CognitoIdentityServiceProvider.${pool.getClientId()}.$username';
    final idTokenKey = '$keyPrefix.idToken';
    final accessTokenKey = '$keyPrefix.accessToken';
    final refreshTokenKey = '$keyPrefix.refreshToken';
    final clockDriftKey = '$keyPrefix.clockDrift';

    if (await storage.getItem(idTokenKey) != null) {
      final idToken = new CognitoIdToken(await storage.getItem(idTokenKey));
      final accessToken =
          new CognitoAccessToken(await storage.getItem(accessTokenKey));
      final refreshToken =
          new CognitoRefreshToken(await storage.getItem(refreshTokenKey));
      final clockDrift = int.parse(await storage.getItem(clockDriftKey)) ?? 0;

      final cachedSession = new CognitoUserSession(
        idToken,
        accessToken,
        refreshToken: refreshToken,
        clockDrift: clockDrift,
      );

      if (cachedSession.isValid()) {
        _signInUserSession = cachedSession;
        return _signInUserSession;
      }

      if (refreshToken.getToken() == null) {
        throw new Exception(
            'Cannot retrieve a new session. Please authenticate.');
      }

      return refreshSession(refreshToken);
    }
    throw new Exception(
        'Local storage is missing an ID Token, Please authenticate');
  }

  /// This is used to initiate an attribute confirmation request
  Future getAttributeVerificationCode(String attributeName) async {
    if (_signInUserSession == null || !_signInUserSession.isValid()) {
      throw new Exception('User is not authenticated');
    }

    final Map<String, String> paramsReq = {
      'AttributeName': attributeName,
      'AccessToken': _signInUserSession.getAccessToken().getJwtToken(),
    };

    return await client.request('GetUserAttributeVerificationCode', paramsReq);
  }

  /// This is used to confirm an attribute using a confirmation code
  Future<bool> verifyAttribute(attributeName, confirmationCode) async {
    if (_signInUserSession == null || !_signInUserSession.isValid()) {
      throw new Exception('User is not authenticated');
    }

    final Map<String, String> paramsReq = {
      'AttributeName': attributeName,
      'Code': confirmationCode,
      'AccessToken': _signInUserSession.getAccessToken().getJwtToken(),
    };
    await client.request('VerifyUserAttribute', paramsReq);

    return true;
  }

  /// This uses the refreshToken to retrieve a new session
  Future<CognitoUserSession> refreshSession(
      CognitoRefreshToken refreshToken) async {
    final Map<String, String> authParameters = {
      'REFRESH_TOKEN': refreshToken.getToken(),
    };
    final keyPrefix = 'CognitoIdentityServiceProvider.${pool.getClientId()}';
    final lastUserKey = '$keyPrefix.LastAuthUser';

    if (await storage.getItem(lastUserKey) != null) {
      this.username = await storage.getItem(lastUserKey);
      final deviceKeyKey = '$keyPrefix.${this.username}.deviceKey';
      _deviceKey = await this.storage.getItem(deviceKeyKey);
      authParameters['DEVICE_KEY'] = _deviceKey;
    }

    final Map<String, dynamic> paramsReq = {
      'ClientId': pool.getClientId(),
      'AuthFlow': 'REFRESH_TOKEN_AUTH',
      'AuthParameters': authParameters,
    };
    if (getUserContextData() != null) {
      paramsReq['UserContextData'] = getUserContextData();
    }

    var authResult;
    try {
      authResult = await client.request('InitiateAuth', paramsReq);
    } on CognitoClientException catch (e) {
      if (e.code == 'NotAuthorizedException') {
        await clearCachedTokens();
      }
      throw e;
    }

    if (authResult != null) {
      final authenticationResult = authResult['AuthenticationResult'];
      if (authenticationResult['RefreshToken'] == null) {
        authenticationResult['RefreshToken'] = refreshToken.getToken();
      }
      _signInUserSession = this.getCognitoUserSession(authenticationResult);
      await this.cacheTokens();
      return _signInUserSession;
    }
    return null;
  }

  CognitoUserSession getSignInUserSession() {
    return _signInUserSession;
  }

  String getUsername() {
    return username;
  }

  String getAuthenticationFlowType() {
    return authenticationFlowType;
  }

  /// sets authentication flow type
  void setAuthenticationFlowType(String authenticationFlowType) {
    this.authenticationFlowType = authenticationFlowType;
  }

  getCachedDeviceKeyAndPassword() async {
    final String keyPrefix =
        'CognitoIdentityServiceProvider.${pool.getClientId()}.$username';
    final String deviceKeyKey = '$keyPrefix.deviceKey';
    final String randomPasswordKey = '$keyPrefix.randomPasswordKey';
    final String deviceGroupKeyKey = '$keyPrefix.deviceGroupKey';

    if (await storage.getItem(deviceKeyKey) != null) {
      _deviceKey = await storage.getItem(deviceKeyKey);
      _deviceGroupKey = await storage.getItem(deviceGroupKeyKey);
      _randomPassword = await storage.getItem(randomPasswordKey);
    }
  }

  /// This returns the user context data for advanced security feature.
  String getUserContextData() {
    return pool.getUserContextData(username);
  }

  /// This is used to build a user session from tokens retrieved in the authentication result
  CognitoUserSession getCognitoUserSession(Map<String, dynamic> authResult) {
    final idToken = new CognitoIdToken(authResult['IdToken']);
    final accessToken = new CognitoAccessToken(authResult['AccessToken']);
    final refreshToken = new CognitoRefreshToken(authResult['RefreshToken']);

    return new CognitoUserSession(idToken, accessToken,
        refreshToken: refreshToken);
  }

  /// This is used to get a session using device authentication. It is called at the end of user
  /// authentication
  Future<CognitoUserSession> getDeviceResponse() async {
    final authenticationHelper = new AuthenticationHelper(_deviceGroupKey);
    final dateHelper = new DateHelper();

    final Map<String, String> authParameters = {
      'USERNAME': this.username,
      'DEVICE_KEY': this._deviceKey,
    };
    final aValue = authenticationHelper.getLargeAValue();
    authParameters['SRP_A'] = aValue.toRadixString(16);

    Map<String, dynamic> params = {
      'ChallengeName': 'DEVICE_SRP_AUTH',
      'ClientId': pool.getClientId(),
      'ChallengeResponses': authParameters,
    };

    if (getUserContextData() != null) {
      params['UserContextData'] = getUserContextData();
    }

    final data = await client.request('RespondToAuthChallenge', params);
    final challengeParameters = data['ChallengeParameters'];
    final serverBValue = BigInt.parse(challengeParameters['SRP_B'], radix: 16);
    final salt = BigInt.parse(challengeParameters['SALT'], radix: 16);

    final hkdf = authenticationHelper.getPasswordAuthenticationKey(
        _deviceKey, _randomPassword, serverBValue, salt);

    final dateNow = dateHelper.getNowString();

    final signature = new Hmac(sha256, hkdf);
    final List<int> signatureData = [];
    signatureData
      ..addAll(utf8.encode(_deviceGroupKey))
      ..addAll(utf8.encode(_deviceKey))
      ..addAll(base64.decode(challengeParameters['SECRET_BLOCK']))
      ..addAll(utf8.encode(dateNow));
    final dig = signature.convert(signatureData);
    final signatureString = base64.encode(dig.bytes);

    Map<String, dynamic> challengeResponses = {
      'USERNAME': this.username,
      'PASSWORD_CLAIM_SECRET_BLOCK': challengeParameters['SECRET_BLOCK'],
      'TIMESTAMP': dateNow,
      'PASSWORD_CLAIM_SIGNATURE': signatureString,
      'DEVICE_KEY': _deviceKey,
    };

    Map<String, dynamic> paramsResp = {
      'ChallengeName': 'DEVICE_PASSWORD_VERIFIER',
      'ClientId': pool.getClientId(),
      'ChallengeResponses': challengeResponses,
      'Session': data['Session'],
    };

    if (getUserContextData() != null) {
      paramsResp['UserContextData'] = getUserContextData();
    }

    final dataAuthenticate =
        await client.request('RespondToAuthChallenge', paramsResp);

    _signInUserSession =
        this.getCognitoUserSession(dataAuthenticate['AuthenticationResult']);
    await this.cacheTokens();
    return _signInUserSession;
  }

  /// This is used for authenticating the user through the custom authentication flow.
  Future<CognitoUserSession> initiateAuth(
      AuthenticationDetails authDetails) async {
    final authParameters = authDetails.getAuthParameters();
    authParameters.add(new AttributeArg(
      name: 'USERNAME',
      value: username,
    ));

    final Map<String, dynamic> paramsReq = {
      'AuthFlow': 'CUSTOM_AUTH',
      'ClientId': pool.getClientId(),
      'AuthParameters': authParameters,
      'ClientMetadata': authDetails.getValidationData(),
    };

    if (getUserContextData() != null) {
      paramsReq['UserContextData'] = getUserContextData();
    }

    final data = await client.request('InitiateAuth', paramsReq);

    final String challengeName = data['ChallengeName'];
    final challengeParameters = data['ChallengeParameters'];
    if (challengeName == 'CUSTOM_CHALLENGE') {
      _session = data['Session'];
      throw new CognitoUserCustomChallengeException(
          challengeParameters: challengeParameters);
    }

    _signInUserSession = getCognitoUserSession(data['AuthenticationResult']);
    await cacheTokens();

    return _signInUserSession;
  }

  /// This is used for authenticating the user.
  Future<CognitoUserSession> authenticateUser(
      AuthenticationDetails authDetails) async {
    if (authenticationFlowType == 'USER_PASSWORD_AUTH') {
      return await _authenticateUserPlainUsernamePassword(authDetails);
    } else if (authenticationFlowType == 'USER_SRP_AUTH') {
      return await _authenticateUserDefaultAuth(authDetails);
    }
    throw new UnimplementedError('Authentication flow type is not supported.');
  }

  /// This is used for the user to signOut of the application and clear the cached tokens.
  Future<void> signOut() async {
    _signInUserSession = null;
    await clearCachedTokens();
  }

  /// This is used to globally revoke all tokens issued to a user
  Future<void> globalSignOut() async {
    if (_signInUserSession == null || !_signInUserSession.isValid()) {
      throw new Exception('User is not authenticated');
    }
    final Map<String, String> paramsReq = {
      'AccessToken': _signInUserSession.getAccessToken().getJwtToken(),
    };
    await client.request('GlobalSignOut', paramsReq);
    await clearCachedTokens();
  }

  Future<CognitoUserSession> _authenticateUserPlainUsernamePassword(
      AuthenticationDetails authDetails) async {
    final Map<String, String> authParameters = {
      'USERNAME': this.username,
      'PASSWORD': authDetails.getPassword(),
    };
    if (authParameters['PASSWORD'] == null) {
      throw new ArgumentError('PASSWORD parameter is required');
    }

    final authenticationHelper = new AuthenticationHelper(
      pool.getUserPoolId().split('_')[1],
    );

    getCachedDeviceKeyAndPassword();
    if (_deviceKey != null) {
      authParameters['DEVICE_KEY'] = _deviceKey;
    }

    Map<String, dynamic> paramsReq = {
      'AuthFlow': 'USER_PASSWORD_AUTH',
      'ClientId': pool.getClientId(),
      'AuthParameters': authParameters,
      'ClientMetadata': authDetails.getValidationData(),
    };

    if (getUserContextData() != null) {
      paramsReq['UserContextData'] = getUserContextData();
    }
    final authResult = await client.request('InitiateAuth', paramsReq);

    return _authenticateUserInternal(authResult, authenticationHelper);
  }

  Future<CognitoUserSession> _authenticateUserDefaultAuth(
    AuthenticationDetails authDetails,
  ) async {
    final authenticationHelper = new AuthenticationHelper(
      pool.getUserPoolId().split('_')[1],
    );
    final dateHelper = new DateHelper();
    BigInt serverBValue;
    BigInt salt;

    Map<String, String> authParameters = {};
    if (_deviceKey != null) {
      authParameters['DEVICE_KEY'] = _deviceKey;
    }
    authParameters['USERNAME'] = username;

    final srpA = authenticationHelper.getLargeAValue();
    authParameters['SRP_A'] = srpA.toRadixString(16);

    if (authenticationFlowType == 'CUSTOM_AUTH') {
      authParameters['CHALLENGE_NAME'] = 'SRP_A';
    }

    Map<String, dynamic> params = {
      'AuthFlow': authenticationFlowType,
      'ClientId': pool.getClientId(),
      'AuthParameters': authParameters,
      'ClientMetadata': authDetails.getValidationData(),
    };

    if (getUserContextData() != null) {
      params['UserContextData'] = getUserContextData();
    }

    final data = await client.request('InitiateAuth', params);
    final challengeParameters = data['ChallengeParameters'];

    this.username = challengeParameters['USER_ID_FOR_SRP'];
    serverBValue = BigInt.parse(challengeParameters['SRP_B'], radix: 16);
    salt = BigInt.parse(challengeParameters['SALT'], radix: 16);
    getCachedDeviceKeyAndPassword();

    var hkdf = authenticationHelper.getPasswordAuthenticationKey(
      this.username,
      authDetails.getPassword(),
      serverBValue,
      salt,
    );

    final dateNow = dateHelper.getNowString();

    final signature = new Hmac(sha256, hkdf);
    final List<int> signatureData = [];
    signatureData
      ..addAll(utf8.encode(pool.getUserPoolId().split('_')[1]))
      ..addAll(utf8.encode(this.username))
      ..addAll(base64.decode(challengeParameters['SECRET_BLOCK']))
      ..addAll(utf8.encode(dateNow));
    final dig = signature.convert(signatureData);
    final signatureString = base64.encode(dig.bytes);

    Map<String, dynamic> challengeResponses = {
      'USERNAME': this.username,
      'PASSWORD_CLAIM_SECRET_BLOCK': challengeParameters['SECRET_BLOCK'],
      'TIMESTAMP': dateNow,
      'PASSWORD_CLAIM_SIGNATURE': signatureString,
    };

    if (_deviceKey != null) {
      challengeResponses['DEVICE_KEY'] = _deviceKey;
    }

    Future<dynamic> respondToAuthChallenge(challenge) async {
      var dataChallenge;
      try {
        dataChallenge =
            await client.request('RespondToAuthChallenge', challenge);
      } on CognitoClientException catch (e) {
        if (e.code == 'ResourceNotFoundException' &&
            e.message.toLowerCase().indexOf('device') != -1) {
          challengeResponses['DEVICE_KEY'] = null;
          _deviceKey = null;
          _randomPassword = null;
          _deviceGroupKey = null;
          await clearCachedDeviceKeyAndPassword();
          return await respondToAuthChallenge(challenge);
        }
        throw e;
      } catch (e) {
        throw e;
      }
      return dataChallenge;
    }

    Map<String, dynamic> jsonReqResp = {
      'ChallengeName': 'PASSWORD_VERIFIER',
      'ClientId': pool.getClientId(),
      'ChallengeResponses': challengeResponses,
      'Session': data['Session'],
    };

    if (getUserContextData() != null) {
      jsonReqResp['UserContextData'] = getUserContextData();
    }

    final dataAuthenticate = await respondToAuthChallenge(jsonReqResp);

    final challengeName = dataAuthenticate['ChallengeName'];
    if (challengeName == 'NEW_PASSWORD_REQUIRED') {
      _session = dataAuthenticate['Session'];
      var userAttributes;
      var rawRequiredAttributes;
      final requiredAttributes = [];
      final userAttributesPrefix = authenticationHelper
          .getNewPasswordRequiredChallengeUserAttributePrefix();

      if (dataAuthenticate['ChallengeParameters'] != null) {
        userAttributes = json
            .decode(dataAuthenticate['ChallengeParameters']['userAttributes']);
        rawRequiredAttributes = json.decode(
            dataAuthenticate['ChallengeParameters']['requiredAttributes']);
      }

      if (rawRequiredAttributes != null) {
        rawRequiredAttributes.forEach((attribute) {
          requiredAttributes
              .add(attribute.substring(userAttributesPrefix.length));
        });
      }

      throw new CognitoUserNewPasswordRequiredException(
          userAttributes: userAttributes,
          requiredAttributes: requiredAttributes);
    }
    return _authenticateUserInternal(dataAuthenticate, authenticationHelper);
  }

  /// This is used for a certain user to confirm the registration by using a confirmation code
  Future<bool> confirmRegistration(String confirmationCode,
      [bool forceAliasCreation = false]) async {
    Map<String, dynamic> params = {
      'ClientId': pool.getClientId(),
      'ConfirmationCode': confirmationCode,
      'Username': username,
      'ForceAliasCreation': forceAliasCreation,
    };

    if (getUserContextData() != null) {
      params['UserContextData'] = getUserContextData();
    }

    await client.request('ConfirmSignUp', params);
    return true;
  }

  /// This is used by a user to resend a confirmation code
  resendConfirmationCode() async {
    Map<String, dynamic> params = {
      'ClientId': pool.getClientId(),
      'Username': username,
    };
    var data = await client.request('ResendConfirmationCode', params);

    return data;
  }

  Future<void> completeNewPasswordChallenge(String newPassword) async {
    final Map<String, String> challengeResponses = {
      'USERNAME': this.username,
      'NEW_PASSWORD': newPassword,
    };

    final data = await respondToChallenge(
      'NEW_PASSWORD_REQUIRED',
      challengeResponses
    );
  }

  /// This is used by the user once he has the responses to a custom challenge
  Future<CognitoUserSession> sendCustomChallengeAnswer(
      String answerChallenge) async {
    final Map<String, String> challengeResponses = {
      'USERNAME': this.username,
      'ANSWER': answerChallenge,
    };

    final data = await respondToChallenge(
      'CUSTOM_CHALLENGE',
      challengeResponses
    );

    final authenticationHelper =
        new AuthenticationHelper(pool.getUserPoolId().split('_')[1]);

    return _authenticateUserInternal(data, authenticationHelper);
  }

  Future<dynamic> respondToChallenge(
      String challengeName,
      Map<String, String> responses
  ) async {
    getCachedDeviceKeyAndPassword();
    if (_deviceKey != null) {
      responses['DEVICE_KEY'] = _deviceKey;
    }

    final Map<String, dynamic> paramsReq = {
      'ChallengeName': challengeName,
      'ChallengeResponses': responses,
      'ClientId': this.pool.getClientId(),
      'Session': _session,
    };

    if (getUserContextData() != null) {
      paramsReq['UserContextData'] = getUserContextData();
    }

    return await client.request('RespondToAuthChallenge', paramsReq);
  }

  /// This is used by the user once he has an MFA code
  Future<CognitoUserSession> sendMFACode(String confirmationCode,
      [String mfaType = 'SMS_MFA']) async {
    final Map<String, String> challengeResponses = {
      'USERNAME': this.username,
      'SMS_MFA_CODE': confirmationCode,
    };
    if (mfaType == 'SOFTWARE_TOKEN_MFA') {
      challengeResponses['SOFTWARE_TOKEN_MFA_CODE'] = confirmationCode;
    }

    if (_deviceKey != null) {
      challengeResponses['DEVICE_KEY'] = _deviceKey;
    }

    final Map<String, dynamic> paramsReq = {
      'ChallengeName': mfaType,
      'ChallengeResponses': challengeResponses,
      'ClientId': pool.getClientId(),
      'Session': _session,
    };
    if (getUserContextData() != null) {
      paramsReq['UserContextData'] = getUserContextData();
    }

    final dataAuthenticate =
        await client.request('RespondToAuthChallenge', paramsReq);

    final String challengeName = dataAuthenticate['ChallengeName'];

    if (challengeName == 'DEVICE_SRP_AUTH') {
      return getDeviceResponse();
    }

    _signInUserSession =
        getCognitoUserSession(dataAuthenticate['AuthenticationResult']);
    await cacheTokens();

    if (dataAuthenticate['AuthenticationResult']['NewDeviceMetadata'] == null) {
      return _signInUserSession;
    }

    final authenticationHelper =
        new AuthenticationHelper(pool.getUserPoolId().split('_')[1]);
    authenticationHelper.generateHashDevice(
        dataAuthenticate['AuthenticationResult']['NewDeviceMetadata']
            ['DeviceGroupKey'],
        dataAuthenticate['AuthenticationResult']['NewDeviceMetadata']
            ['DeviceKey']);

    final Map<String, String> deviceSecretVerifierConfig = {
      'Salt': base64.encode(hex.decode(authenticationHelper.getSaltDevices())),
      'PasswordVerifier':
          base64.encode(hex.decode(authenticationHelper.getVerifierDevices())),
    };

    verifierDevices = deviceSecretVerifierConfig['PasswordVerifier'];
    _deviceGroupKey = dataAuthenticate['AuthenticationResult']
        ['NewDeviceMetadata']['DeviceGroupKey'];
    _randomPassword = authenticationHelper.getRandomPassword();

    final Map<String, dynamic> confirmDeviceParamsReq = {
      'DeviceKey': dataAuthenticate['AuthenticationResult']['NewDeviceMetadata']
          ['DeviceKey'],
      'AccessToken': _signInUserSession.getAccessToken().getJwtToken(),
      'DeviceSecretVerifierConfig': deviceSecretVerifierConfig,
      'DeviceName': deviceName,
    };
    final dataConfirm =
        await client.request('ConfirmDevice', confirmDeviceParamsReq);
    _deviceKey = dataAuthenticate['AuthenticationResult']['NewDeviceMetadata']
        ['DeviceKey'];
    await cacheDeviceKeyAndPassword();
    if (dataConfirm['UserConfirmationNecessary'] == true) {
      throw new CognitoUserConfirmationNecessaryException(
          signInUserSession: _signInUserSession);
    }

    return _signInUserSession;
  }

  /// This is used by an authenticated user to change the current password
  Future<bool> changePassword(
      String oldUserPassword, String newUserPassword) async {
    if (!(_signInUserSession != null && _signInUserSession.isValid())) {
      throw new Exception('User is not authenticated');
    }

    final Map<String, String> paramsReq = {
      'PreviousPassword': oldUserPassword,
      'ProposedPassword': newUserPassword,
      'AccessToken': _signInUserSession.getAccessToken().getJwtToken(),
    };
    await client.request('ChangePassword', paramsReq);

    return true;
  }

  /// This is used by authenticated users to enable MFA for him/herself
  Future<bool> enableMfa() async {
    if (_signInUserSession == null || !_signInUserSession.isValid()) {
      throw new Exception('User is not authenticated');
    }

    final List<Map<String, String>> mfaOptions = [];
    final Map<String, String> mfaEnabled = {
      'DeliveryMedium': 'SMS',
      'AttributeName': 'phone_number',
    };
    mfaOptions.add(mfaEnabled);

    final Map<String, dynamic> paramsReq = {
      'MFAOptions': mfaOptions,
      'AccessToken': _signInUserSession.getAccessToken().getJwtToken(),
    };

    await client.request('SetUserSettings', paramsReq);
    return true;
  }

  /// This is used by an authenticated user to disable MFA for him/herself
  Future<bool> disableMfa() async {
    if (_signInUserSession == null || !_signInUserSession.isValid()) {
      throw new Exception('User is not authenticated');
    }

    final List<Map<String, String>> mfaOptions = [];

    final Map<String, dynamic> paramsReq = {
      'MFAOptions': mfaOptions,
      'AccessToken': _signInUserSession.getAccessToken().getJwtToken(),
    };

    await client.request('SetUserSettings', paramsReq);
    return true;
  }

  /// This is used to initiate a forgot password request
  Future forgotPassword() async {
    final Map<String, String> paramsReq = {
      'ClientId': pool.getClientId(),
      'Username': username,
    };
    if (getUserContextData() != null) {
      paramsReq['UserContextData'] = getUserContextData();
    }

    return await client.request('ForgotPassword', paramsReq);
  }

  /// This is used to confirm a new password using a confirmation code
  Future<bool> confirmPassword(
      String confirmationCode, String newPassword) async {
    final Map<String, String> paramsReq = {
      'ClientId': pool.getClientId(),
      'Username': username,
      'ConfirmationCode': confirmationCode,
      'Password': newPassword,
    };
    if (getUserContextData() != null) {
      paramsReq['UserContextData'] = getUserContextData();
    }

    await client.request('ConfirmForgotPassword', paramsReq);
    return true;
  }

  /// This is used to save the session tokens to local storage
  Future<void> cacheTokens() async {
    final keyPrefix = 'CognitoIdentityServiceProvider.${pool.getClientId()}';
    final idTokenKey = '$keyPrefix.$username.idToken';
    final accessTokenKey = '$keyPrefix.$username.accessToken';
    final refreshTokenKey = '$keyPrefix.$username.refreshToken';
    final clockDriftKey = '$keyPrefix.$username.clockDrift';
    final lastUserKey = '$keyPrefix.LastAuthUser';

    await Future.wait([
      storage.setItem(
          idTokenKey, _signInUserSession.getIdToken().getJwtToken()),
      storage.setItem(
          accessTokenKey, _signInUserSession.getAccessToken().getJwtToken()),
      storage.setItem(
          refreshTokenKey, _signInUserSession.getRefreshToken().getToken()),
      storage.setItem(clockDriftKey, '${_signInUserSession.getClockDrift()}'),
      storage.setItem(lastUserKey, username),
    ]);
  }

  /// This is used to clear the session tokens from local storage
  Future<void> clearCachedTokens() async {
    final keyPrefix = 'CognitoIdentityServiceProvider.${pool.getClientId()}';
    final idTokenKey = '$keyPrefix.${this.username}.idToken';
    final accessTokenKey = '$keyPrefix.${this.username}.accessToken';
    final refreshTokenKey = '$keyPrefix.${this.username}.refreshToken';
    final lastUserKey = '$keyPrefix.LastAuthUser';

    await Future.wait([
      storage.removeItem(idTokenKey),
      storage.removeItem(accessTokenKey),
      storage.removeItem(refreshTokenKey),
      storage.removeItem(lastUserKey),
    ]);
  }

  /// This is used to cache the device key and device group and device password
  Future<void> cacheDeviceKeyAndPassword() async {
    final keyPrefix =
        'CognitoIdentityServiceProvider.${pool.getClientId()}.$username';
    final deviceKeyKey = '$keyPrefix.deviceKey';
    final randomPasswordKey = '$keyPrefix.randomPasswordKey';
    final deviceGroupKeyKey = '$keyPrefix.deviceGroupKey';

    await Future.wait([
      storage.setItem(deviceKeyKey, _deviceKey),
      storage.setItem(randomPasswordKey, _randomPassword),
      storage.setItem(deviceGroupKeyKey, _deviceGroupKey),
    ]);
  }

  /// This is used to clear the device key info from local storage
  Future<void> clearCachedDeviceKeyAndPassword() async {
    final keyPrefix =
        'CognitoIdentityServiceProvider.${pool.getClientId()}.$username';
    final deviceKeyKey = '$keyPrefix.deviceKey';
    final randomPasswordKey = '$keyPrefix.randomPasswordKey';
    final deviceGroupKeyKey = '$keyPrefix.deviceGroupKey';

    await Future.wait([
      storage.removeItem(deviceKeyKey),
      storage.removeItem(randomPasswordKey),
      storage.removeItem(deviceGroupKeyKey),
    ]);
  }

  /// This is used by authenticated users to get a list of attributes
  Future<List<CognitoUserAttribute>> getUserAttributes() async {
    if (!(_signInUserSession != null && _signInUserSession.isValid())) {
      throw new Exception('User is not authenticated');
    }

    final Map<String, dynamic> paramsReq = {
      'AccessToken': _signInUserSession.getAccessToken().getJwtToken(),
    };
    final userData = await client.request('GetUser', paramsReq);

    if (userData['UserAttributes'] == null) {
      return null;
    }

    final List<CognitoUserAttribute> attributeList = [];
    userData['UserAttributes'].forEach((attr) {
      attributeList.add(
          new CognitoUserAttribute(name: attr['Name'], value: attr['Value']));
    });
    return attributeList;
  }

  /// This is used by authenticated users to change a list of attributes
  updateAttributes(List<CognitoUserAttribute> attributes) async {
    if (_signInUserSession == null || !_signInUserSession.isValid()) {
      throw new Exception('User is not authenticated');
    }

    final Map<String, dynamic> paramsReq = {
      'AccessToken': _signInUserSession.getAccessToken().getJwtToken(),
      'UserAttributes': attributes,
    };
    await client.request('UpdateUserAttributes', paramsReq);
  }

  /// This is used by an authenticated user to delete a list of attributes
  deleteAttributes(List<String> attributeList) async {
    if (!(_signInUserSession != null && _signInUserSession.isValid())) {
      throw new Exception('User is not authenticated');
    }

    final Map<String, dynamic> paramsReq = {
      'AccessToken': _signInUserSession.getAccessToken().getJwtToken(),
      'UserAttributeNames': attributeList,
    };
    await client.request('DeleteUserAttributes', paramsReq);
  }

  /// This is used by an authenticated user to delete him/herself
  Future<bool> deleteUser() async {
    if (_signInUserSession == null || !_signInUserSession.isValid()) {
      throw new Exception('User is not authenticated');
    }

    final Map<String, dynamic> paramsReq = {
      'AccessToken': _signInUserSession.getAccessToken().getJwtToken(),
    };
    await client.request('DeleteUser', paramsReq);
    await clearCachedTokens();

    return true;
  }
}
