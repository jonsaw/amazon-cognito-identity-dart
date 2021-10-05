class CognitoClientException implements Exception {
  int? statusCode;
  String? code;
  String? name;
  String? message;
  CognitoClientException(
    this.message, {
    this.code,
    this.statusCode,
    this.name,
  });

  @override
  String toString() {
    return 'CognitoClientException{statusCode: $statusCode, code: $code, name: $name, message: $message}';
  }
}
