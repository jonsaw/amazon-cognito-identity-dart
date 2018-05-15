import 'package:test/test.dart';
import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:amazon_cognito_identity_dart/sig_v4.dart';

void main() {
  test('.hash() generates valid hash', () {
    expect(
        hex.encode(new SigV4().hash(utf8.encode('{"one":1}'))),
        equals(
            '335929a4e59b0860ec04c620c1284dace74c00f7eadaadce7a18d6deba6c544e'));
  });
  test('.buildCanonicalQueryString() builds valid query string', () {
    final Map<String, String> params = {
      'One': '1',
      'Two': '1 + 1',
      'Three': '3',
    };
    expect(new SigV4().buildCanonicalQueryString(params),
        equals('One=1&Three=3&Two=1%20%2B%201'));
  });
  test('.buildCanonicalHeaders() builds canonical header', () {
    final Map<String, String> headers = {
      'Header-2': 'head 002',
      'header-1': 'head 001',
    };
    expect(new SigV4().buildCanonicalHeaders(headers),
        equals('header-1:head 001\nheader-2:head 002\n'));
  });
  test('.buildCanonicalSignedHeaders() builds canonical header', () {
    final Map<String, String> headers = {
      'Header-2': 'head 002',
      'header-1': 'head 001',
    };
    expect(new SigV4().buildCanonicalSignedHeaders(headers),
        equals('header-1;header-2'));
  });
  test('.buildCanonicalRequest() builds canonical request', () {
    final canonicalReq = new SigV4().buildCanonicalRequest(
        'POST',
        '/dev/projects/123',
        new Map<String, String>.from({
          'color': 'orange red',
        }),
        new Map<String, String>.from({
          'header-1': 'one',
          'header-2': 'two',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'x-amz-date': '20180515T011950Z',
          'host': 'api.inspire.my'
        }),
        '{"color":"green"}');
    expect(
        canonicalReq,
        equals('POST\n' +
            '/dev/projects/123\n' +
            'color=orange%20red\n' +
            'accept:application/json\n' +
            'content-type:application/json\n' +
            'header-1:one\n' +
            'header-2:two\n' +
            'host:api.inspire.my\n' +
            'x-amz-date:20180515T011950Z\n' +
            '\n' +
            'accept;content-type;header-1;header-2;host;x-amz-date\n' +
            'b1c0d2a81c6839b36839e8d9b273cb17279370ab430e5e3fc8218e2bcaa6373b'));
  });
  test('.buildCredentialScope() builds credential scope', () {
    final credentialScope = new SigV4().buildCredentialScope(
        '20180515T011950Z', 'ap-southeast-1', 'execute-api');
    expect(credentialScope,
        equals('20180515/ap-southeast-1/execute-api/aws4_request'));
  });
  test('.buildStringToSign(), builds signed string', () {
    final sigV4 = new SigV4();
    final hashedCanonicalRequest = sigV4.buildCanonicalRequest(
        'POST',
        '/dev/projects/123',
        new Map<String, String>.from({
          'color': 'orange red',
        }),
        new Map<String, String>.from({
          'header-1': 'one',
          'header-2': 'two',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'x-amz-date': '20180515T011950Z',
          'host': 'api.inspire.my',
        }),
        '{"color":"green"}');
    final credentialScope = new SigV4().buildCredentialScope(
        '20180515T011950Z', 'ap-southeast-1', 'execute-api');
    final stringToSign = sigV4.buildStringToSign(
        '20180515T011950Z', credentialScope, hashedCanonicalRequest);
    expect(
        stringToSign,
        equals('AWS4-HMAC-SHA256\n' +
            '20180515T011950Z\n' +
            '20180515/ap-southeast-1/execute-api/aws4_request\n' +
            'POST\n' +
            '/dev/projects/123\n' +
            'color=orange%20red\n' +
            'accept:application/json\n' +
            'content-type:application/json\n' +
            'header-1:one\n' +
            'header-2:two\n' +
            'host:api.inspire.my\n' +
            'x-amz-date:20180515T011950Z\n' +
            '\n' +
            'accept;content-type;header-1;header-2;host;x-amz-date\n' +
            'b1c0d2a81c6839b36839e8d9b273cb17279370ab430e5e3fc8218e2bcaa6373b'));
  });
  test('.calculateSignature() returns valid signature', () {
    final s = new SigV4();
    final stringToSign = 'AWS4-HMAC-SHA256\n' +
        '20180515T011950Z\n' +
        '20180515/ap-southeast-1/execute-api/aws4_request\n' +
        'POST\n' +
        '/dev/projects/123\n' +
        'color=orange%20red\n' +
        'accept:application/json\n' +
        'content-type:application/json\n' +
        'header-1:one\n' +
        'header-2:two\n' +
        'host:api.inspire.my\n' +
        'x-amz-date:20180515T011950Z\n' +
        '\n' +
        'accept;content-type;header-1;header-2;host;x-amz-date\n' +
        'b1c0d2a81c6839b36839e8d9b273cb17279370ab430e5e3fc8218e2bcaa6373b';
    final signingKey = s.calculateSigningKey(
        '000000000000000000000000/000000000000000',
        '20180515T011950Z',
        'ap-southeast-1',
        'execute-api');
    final signature = s.calculateSignature(signingKey, stringToSign);
    expect(
        signature,
        equals(
            '6fe6cf9ba017c591fc404eb9883442355bde3c61233e5f1f7ea8ea38a80070df'));
  });
  test('.buildAuthorizationHeader() builds authorization header', () {
    final s = new SigV4();
    final credentialScope = s.buildCredentialScope(
        '20180515T011950Z', 'ap-southeast-1', 'execute-api');
    final authHeader = s.buildAuthorizationHeader(
        'AXXXXXXXXXXXXXXXXXXX',
        credentialScope,
        {
          'header-1': 'one',
          'header-2': 'two',
          'accept': 'application/json',
          'content-type': 'application/json',
          'x-amz-date': '20180515T011950Z',
          'host': 'api.inspire.my'
        },
        '6fe6cf9ba017c591fc404eb9883442355bde3c61233e5f1f7ea8ea38a80070df');
    expect(
        authHeader,
        equals('AWS4-HMAC-SHA256 ' +
            'Credential=AXXXXXXXXXXXXXXXXXXX/20180515/ap-southeast-1/execute-api/aws4_request, ' +
            'SignedHeaders=accept;content-type;header-1;header-2;host;x-amz-date, ' +
            'Signature=6fe6cf9ba017c591fc404eb9883442355bde3c61233e5f1f7ea8ea38a80070df'));
  });
  test('new SigV4Request generates signed headers and url', () {
    const endpoint = 'https://api.inspire.my/dev';
    final awsSigV4Client = new AwsSigV4Client('AXXXXXXXXXXXXXXXXXXX',
        '000000000000000000000000/000000000000000', endpoint,
        sessionToken: 'session-token', region: 'ap-southeast-1');
    final signedRequest = new SigV4Request(awsSigV4Client,
        method: 'POST',
        path: '/projects/123',
        datetime: '20180515T011950Z',
        headers: new Map<String, String>.from(
            {'header-1': 'one', 'header-2': 'two'}),
        queryParams: new Map<String, String>.from({'color': 'orange red'}),
        body: new Map<String, dynamic>.from({'color': 'blue'}));
    expect(signedRequest.url,
        equals('${endpoint}/projects/123?color=orange%20red'));
    expect(
        signedRequest.headers['Authorization'],
        equals('AWS4-HMAC-SHA256 ' +
            'Credential=AXXXXXXXXXXXXXXXXXXX/20180515/ap-southeast-1/execute-api/aws4_request, ' +
            'SignedHeaders=accept;content-type;header-1;header-2;host;x-amz-date, ' +
            'Signature=a51f0890d0bbbbc1fede3511c0f6448bdeb75623767859b73730ec728f104253'));
  });
}
