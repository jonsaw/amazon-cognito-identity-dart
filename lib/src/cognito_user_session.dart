import 'dart:math';
import 'cognito_access_token.dart';
import 'cognito_id_token.dart';
import 'cognito_refresh_token.dart';

class CognitoUserSession {
  CognitoIdToken idToken;
  CognitoRefreshToken? refreshToken;
  CognitoAccessToken accessToken;
  int? clockDrift;
  bool _invalidated = false;

  CognitoUserSession(
    this.idToken,
    this.accessToken, {
    this.refreshToken,
    int? clockDrift,
  }) {
    this.clockDrift =
        clockDrift == null ? this.calculateClockDrift() : clockDrift;
  }

  /// Get the session's Id token
  CognitoIdToken getIdToken() {
    return this.idToken;
  }

  /// Get the session's refresh token
  CognitoRefreshToken? getRefreshToken() {
    return this.refreshToken;
  }

  /// Get the session's access token
  CognitoAccessToken getAccessToken() {
    return this.accessToken;
  }

  /// Get the session's clock drift
  int? getClockDrift() {
    return this.clockDrift;
  }

  /// Calculate computer's clock drift
  int calculateClockDrift() {
    final now = (new DateTime.now().millisecondsSinceEpoch / 1000).floor();
    final iat = min(accessToken.getIssuedAt(), idToken.getIssuedAt());
    return (now - iat);
  }

  /// Invalidate this tokens. All succeeding calls to isValid() will return false. Use cognitoUser
  /// .getSession() to refresh the cognito session with the cognito server.
  invalidateToken() {
    _invalidated = true;
  }

  /// Checks to see if the session is still valid based on session expiry information found
  /// in tokens and the current time (adjusted with clock drift)
  bool isValid() {
    if (_invalidated) {
      return false;
    }
    final now = (new DateTime.now().millisecondsSinceEpoch / 1000).floor();
    final adjusted = now - clockDrift!;

    return adjusted < accessToken.getExpiration() &&
        adjusted < idToken.getExpiration();
  }
}
