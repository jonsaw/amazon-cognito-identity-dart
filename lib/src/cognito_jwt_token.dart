import 'dart:convert';

class CognitoJwtToken {
  String? jwtToken;
  var payload;
  CognitoJwtToken(String? token) {
    this.jwtToken = token;
    this.payload = decodePayload();
  }

  String? getJwtToken() {
    return this.jwtToken;
  }

  int getExpiration() {
    return this.payload['exp'] ?? 0;
  }

  int getIssuedAt() {
    return this.payload['iat'] ?? 0;
  }

  decodePayload() {
    var payload = this.jwtToken!.split('.')[1];
    if (payload.length % 4 > 0) {
      payload =
          payload.padRight(payload.length + (4 - payload.length % 4), '=');
    }
    try {
      return json.decode(utf8.decode(base64.decode(payload)));
    } catch (err) {
      return {};
    }
  }
}
