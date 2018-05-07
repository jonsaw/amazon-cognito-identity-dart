import 'package:amazon_cognito_identity_dart/cognito_user_session.dart';

class CognitoUserNewPasswordRequiredException implements Exception {
  String message;
  dynamic userAttributes;
  List<dynamic> requiredAttributes;
  CognitoUserNewPasswordRequiredException(
      this.message, this.userAttributes, this.requiredAttributes);
}

class CognitoUserMfaRequiredException implements Exception {
  String message;
  String challengeName;
  dynamic challengeParameters;
  CognitoUserMfaRequiredException(this.message,
      {this.challengeName, this.challengeParameters});
}

class CognitoUserSelectMfaTypeException implements Exception {
  String message;
  String challengeName;
  dynamic challengeParameters;
  CognitoUserSelectMfaTypeException(this.message,
      {this.challengeName, this.challengeParameters});
}

class CognitoUserMfaSetupException implements Exception {
  String message;
  String challengeName;
  dynamic challengeParameters;
  CognitoUserMfaSetupException(this.message,
      {this.challengeName, this.challengeParameters});
}

class CognitoUserTotpRequiredException implements Exception {
  String message;
  String challengeName;
  dynamic challengeParameters;
  CognitoUserTotpRequiredException(this.message,
      {this.challengeName, this.challengeParameters});
}

class CognitoUserCustomChallengeException implements Exception {
  String message;
  dynamic challengeParameters;
  CognitoUserCustomChallengeException(this.message, {this.challengeParameters});
}

class CognitoUserConfirmationNecessaryException implements Exception {
  String message;
  CognitoUserSession signInUserSession;
  CognitoUserConfirmationNecessaryException(
      this.message, this.signInUserSession);
}
