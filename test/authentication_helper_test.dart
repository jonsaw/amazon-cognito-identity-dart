import 'dart:convert';
import 'package:test/test.dart';
import 'package:amazon_cognito_identity_dart/src/authentication_helper.dart';

void main() {
  test('constructor should generate valid k', () {
    final AuthenticationHelper h = new AuthenticationHelper('pool_name');
    expect(
        h.k.toRadixString(16),
        equals(
            '538282c4354742d7cbbde2359fcf67f9f5b3a6b08791e5011b43b8a5b66d9ee6'));
  });
  test('.getLargeAValue() returns largeAValue', () {
    final AuthenticationHelper h = new AuthenticationHelper('pool_name');
    expect(h.getLargeAValue(), TypeMatcher<BigInt>());
  });
  test('.getSmallAValue() returns largeAValue', () {
    final AuthenticationHelper h = new AuthenticationHelper('pool_name');
    expect(h.getSmallAValue(), TypeMatcher<BigInt>());
  });
  test('.generateRandomSmallA() returns 128-length BigInteger', () {
    final AuthenticationHelper h = new AuthenticationHelper('pool_name');
    expect(h.generateRandomSmallA(), TypeMatcher<BigInt>());
    expect(h.generateRandomSmallA().toRadixString(16).length, equals(128));
  });
  test('.hexHash() generates valid hash', () {
    final AuthenticationHelper h = new AuthenticationHelper('pool_name');
    expect(
        h.hexHash('1ab23cd4'),
        equals(
            '7999d2b0d9387917b38fcbd522f14229cafc44bf34f59aadb4a4766056697273'));
  });
  test('.generateHashDevice() generates verifierDevices', () {
    final AuthenticationHelper h = new AuthenticationHelper('pool_name');
    h.generateHashDevice('macbook:key', 'see.saw@email.com');
    expect(h.getVerifierDevices()!.length, anyOf([766, 768, 770]));
  });
  test('.padHex() with odd length pads left', () {
    final AuthenticationHelper h = new AuthenticationHelper('pool_name');
    expect(h.padHex(BigInt.parse('123af', radix: 16)), equals('0123af'));
  });
  test('.padHex() with leading 89ABCDEFabcdef pads left', () {
    final AuthenticationHelper h = new AuthenticationHelper('pool_name');
    final Map<String, String> tests = {
      '8afff8': '008afff8',
      '9afff9': '009afff9',
      'aafffa': '00aafffa',
      'bafffb': '00bafffb',
      'cafffc': '00cafffc',
      'dafffd': '00dafffd',
      'eafffe': '00eafffe',
      'faffff': '00faffff',
      '0afff0': '0afff0',
      '1afff1': '1afff1',
      '2afff2': '2afff2',
      '3afff3': '3afff3',
      '4afff4': '4afff4',
      '5afff5': '5afff5',
      '6afff6': '6afff6',
      '7afff7': '7afff7'
    };
    tests.forEach((input, expected) {
      expect(h.padHex(BigInt.parse(input, radix: 16)), equals(expected));
    });
  });
  test('.computehkdf() generates valid base64 encodable string', () {
    final AuthenticationHelper h = new AuthenticationHelper('pool_name');
    final r =
        h.computehkdf(utf8.encode('Password01'), utf8.encode('Salty Item'));
    expect(base64.encode(r), equals('xqedift4s107XDR5zHZMHw=='));
  });
  test('.calculateU() generates valid BigInt', () {
    final AuthenticationHelper h = new AuthenticationHelper('pool_name');
    final a = BigInt.parse('aff001', radix: 16);
    final b = BigInt.parse('bff002', radix: 16);
    expect(
        h.calculateU(a, b).toRadixString(16),
        equals(
            '1c3e2e616cd39a68b10c71ac12ce400798579792df1464e5519ff41446095a57'));
  });
  test('.getPasswordAuthenticationKey() should return valid random base64', () {
    final AuthenticationHelper h = new AuthenticationHelper('pool_name');
    final serverBValue = BigInt.parse('aff001', radix: 16);
    final salt = BigInt.parse('bff002', radix: 16);
    final hkdf = h.getPasswordAuthenticationKey(
        'see.saw@gmail.com', 'Password01!', serverBValue, salt);
    expect(base64.encode(hkdf).length, equals(24));
  });
}
