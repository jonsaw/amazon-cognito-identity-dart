import 'package:test/test.dart';
import 'package:amazon_cognito_identity_dart/src/random_string_helper.dart';

void main() {
  test('.generates() generates correct length', () {
    expect(new RandomString().generate(length: 16).length, equals(16));
  });
  test('.generates() generates with default hex chars', () {
    expect(
        new RandomString().generate(),
        contains(new RegExp(r'[0-9a-f]*')));
  });
}
