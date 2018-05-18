import 'package:test/test.dart';
import 'package:amazon_cognito_identity_dart/cognito.dart';

void main() {
  test('throw CognitoUserNewPasswordRequiredException generates message', () {
    final t = () => throw new CognitoUserNewPasswordRequiredException();
    try {
      t();
    } on CognitoUserNewPasswordRequiredException catch (e) {
      expect(e.toString(), equals('CognitoUserException: New Password required'));
    }
    try {
      t();
    } on CognitoUserException catch (e) {
      expect(e.toString(), equals('CognitoUserException: New Password required'));
    }
    try {
      t();
    } catch (e) {
      expect(e.toString(), equals('CognitoUserException: New Password required'));
    }
  });
  test('throw CognitoUserMfaRequiredException generates message', () {
    final t = () => throw new CognitoUserMfaRequiredException();
    try {
      t();
    } on CognitoUserMfaRequiredException catch (e) {
      expect(e.toString(), equals('CognitoUserException: "SMS_MFA"'));
    }
    try {
      t();
    } on CognitoUserException catch (e) {
      expect(e.toString(), equals('CognitoUserException: "SMS_MFA"'));
    }
    try {
      t();
    } catch (e) {
      expect(e.toString(), equals('CognitoUserException: "SMS_MFA"'));
    }
  });
  test('throw CognitoUserSelectMfaTypeException generates message', () {
    final t = () => throw new CognitoUserSelectMfaTypeException();
    try {
      t();
    } on CognitoUserSelectMfaTypeException catch (e) {
      expect(e.toString(), equals('CognitoUserException: "SELECT_MFA_TYPE"'));
    }
    try {
      t();
    } on CognitoUserException catch (e) {
      expect(e.toString(), equals('CognitoUserException: "SELECT_MFA_TYPE"'));
    }
    try {
      t();
    } catch (e) {
      expect(e.toString(), equals('CognitoUserException: "SELECT_MFA_TYPE"'));
    }
  });
  test('throw CognitoUserMfaSetupException generates message', () {
    final t = () => throw new CognitoUserMfaSetupException();
    try {
      t();
    } on CognitoUserMfaSetupException catch (e) {
      expect(e.toString(), equals('CognitoUserException: "MFA_SETUP"'));
    }
    try {
      t();
    } on CognitoUserException catch (e) {
      expect(e.toString(), equals('CognitoUserException: "MFA_SETUP"'));
    }
    try {
      t();
    } catch (e) {
      expect(e.toString(), equals('CognitoUserException: "MFA_SETUP"'));
    }
  });
  test('throw CognitoUserTotpRequiredException generates message', () {
    final t = () => throw new CognitoUserTotpRequiredException();
    try {
      t();
    } on CognitoUserTotpRequiredException catch (e) {
      expect(e.toString(), equals('CognitoUserException: "SOFTWARE_TOKEN_MFA"'));
    }
    try {
      t();
    } on CognitoUserException catch (e) {
      expect(e.toString(), equals('CognitoUserException: "SOFTWARE_TOKEN_MFA"'));
    }
    try {
      t();
    } catch (e) {
      expect(e.toString(), equals('CognitoUserException: "SOFTWARE_TOKEN_MFA"'));
    }
  });
  test('throw CognitoUserCustomChallengeException generates message', () {
    final t = () => throw new CognitoUserCustomChallengeException();
    try {
      t();
    } on CognitoUserCustomChallengeException catch (e) {
      expect(e.toString(), equals('CognitoUserException: "CUSTOM_CHALLENGE"'));
    }
    try {
      t();
    } on CognitoUserException catch (e) {
      expect(e.toString(), equals('CognitoUserException: "CUSTOM_CHALLENGE"'));
    }
    try {
      t();
    } catch (e) {
      expect(e.toString(), equals('CognitoUserException: "CUSTOM_CHALLENGE"'));
    }
  });
  test('throw CognitoUserConfirmationNecessaryException generates message', () {
    final t = () => throw new CognitoUserConfirmationNecessaryException();
    try {
      t();
    } on CognitoUserConfirmationNecessaryException catch (e) {
      expect(e.toString(), equals('CognitoUserException: User Confirmation Necessary'));
    }
    try {
      t();
    } on CognitoUserException catch (e) {
      expect(e.toString(), equals('CognitoUserException: User Confirmation Necessary'));
    }
    try {
      t();
    } catch (e) {
      expect(e.toString(), equals('CognitoUserException: User Confirmation Necessary'));
    }
  });
}
