import 'dart:convert';

class CognitoUserAttribute {
  String? name;
  String? value;

  CognitoUserAttribute({this.name, this.value});

  getValue() {
    return this.value;
  }

  CognitoUserAttribute setValue(String value) {
    this.value = value;
    return this;
  }

  getName() {
    return this.name;
  }

  CognitoUserAttribute setName(String name) {
    this.name = name;
    return this;
  }

  String toString() {
    var attributes = toJson();
    var encoded = json.encode(attributes);
    return encoded.toString();
  }

  Map<String, String?> toJson() {
    return {
      'Name': name,
      'Value': value,
    };
  }
}
