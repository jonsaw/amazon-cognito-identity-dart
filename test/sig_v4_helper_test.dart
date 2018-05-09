import 'package:test/test.dart';
import 'package:amazon_cognito_identity_dart/sig_v4.dart';

void main() {
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
        'projects/123',
        new Map<String, String>.from({
          'color': 'orange red',
        }),
        new Map<String, String>.from({'header-1': 'one', 'header-2': 'two'}),
        '{"color":"green"}');
    expect(
        canonicalReq,
        equals('POST\n'
            'projects/123\n' +
            'color=orange%20red\n' +
            'header-1:one\n' +
            'header-2:two\n' +
            '\n' +
            'header-1;header-2\n' +
            'b1c0d2a81c6839b36839e8d9b273cb17279370ab430e5e3fc8218e2bcaa6373b'));
  });
  test('.calculateSignature() returns valid signature', () {
    final s = new SigV4();
    final signingKey = s.calculateSigningKey(
        'secret', '20180206 00:00:00', 'ap-southeast-1', 'aws4_request');
    final signature = s.calculateSignature(signingKey, 'stringToSign');
    expect(
        signature,
        equals(
            '0f5de12dde74868c960c5cf249000e05f436ed5e5b28e5deaedbe2dde2f4ab5a'));
  });
  test('new SigV4Request generates signed headers and url', () {
    const endpoint = 'https://api.inspire.my/dev';
    final awsSigV4Client = new AwsSigV4Client('AXXXXXXXXXXXXXXXXXXX',
        '000000000000000000000000/000000000000000', endpoint,
        sessionToken: 'session-token', region: 'ap-southeast-1');
    final signedRequest = new SigV4Request(awsSigV4Client,
        method: 'POST',
        path: '/projects',
        headers: new Map<String, String>.from(
            {'header-1': 'one', 'header-2': 'two'}),
        queryParams: new Map<String, String>.from({'tracking': 'x123'}),
        body: new Map<String, dynamic>.from({'color': 'blue'}));
    expect(signedRequest.url, equals('${endpoint}/projects?tracking=x123'));
    expect(
        signedRequest.headers['Authorization'], startsWith('AWS4-HMAC-SHA256'));
    signedRequest.method;
    signedRequest.body;
  });
}
