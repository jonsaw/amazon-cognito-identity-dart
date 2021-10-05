import 'attribute_arg.dart';

class AuthenticationDetails {
  String? username;
  String? password;
  List<AttributeArg>? validationData;
  List<AttributeArg>? authParameters;
  AuthenticationDetails({
    this.username,
    this.password,
    this.validationData,
    this.authParameters,
  });

  String? getUsername() {
    return this.username;
  }

  String? getPassword() {
    return this.password;
  }

  List<AttributeArg>? getValidationData() {
    return this.validationData;
  }

  List<AttributeArg>? getAuthParameters() {
    return this.authParameters;
  }
}
