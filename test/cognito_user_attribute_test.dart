import 'package:test/test.dart';
import 'dart:convert';
import 'package:amazon_cognito_identity_dart/cognito.dart';

void main() {
  test('.toString() returns a string representation of the record', () {
    var userAttribute = new CognitoUserAttribute(name: 'name', value: 'Jon');
    expect(userAttribute.toString(), equals('{"Name":"name","Value":"Jon"}'));
  });

  test('.toJson() returns flat Map representing the record', () {
    var userAttribute = new CognitoUserAttribute(name: 'name', value: 'Jason');
    Map<String, String> attributeResult = {
      'Name': 'name',
      'Value': 'Jason',
    };
    expect(userAttribute.toJson(), equals(attributeResult));
  });
  test('json.encode(userAttribute) returns valid JSON string', () {
    var userAttribute = new CognitoUserAttribute(name: 'name', value: 'Jeremy');
    expect(
        json.encode(userAttribute), equals('{"Name":"name","Value":"Jeremy"}'));
  });
  test('json.encode(List<CognitoUserAttribute>) returns valid JSON string', () {
    List<CognitoUserAttribute> attributes = [
      new CognitoUserAttribute(name: 'first_name', value: 'Josh'),
      new CognitoUserAttribute(name: 'last_name', value: 'Ong'),
    ];
    expect(
      json.encode(attributes),
      equals(
          '[{"Name":"first_name","Value":"Josh"},{"Name":"last_name","Value":"Ong"}]'),
    );
  });
}
