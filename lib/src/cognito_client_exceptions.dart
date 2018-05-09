class CognitoClientException implements Exception {
  int statusCode;
  String code;
  String name;
  String message;
  CognitoClientException(
    this.message, {
    this.code,
    this.statusCode,
    this.name,
  });
}
