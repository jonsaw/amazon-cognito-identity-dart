class CognitoRefreshToken {
  String? token;
  CognitoRefreshToken([String? refereshToken = '']) {
    this.token = refereshToken;
  }

  getToken() {
    return this.token;
  }
}
