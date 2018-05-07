import 'package:test/test.dart';
import 'package:amazon_cognito_identity_dart/client.dart';

void main() {
  test('initiating Client should set default endpoint based on region', () {
    Client client = new Client(
      region: 'ap-southeast-1',
    );
    expect(client.endpoint,
        equals('https://cognito-idp.ap-southeast-1.amazonaws.com/'));
  });

  test('intiating Client with endpoint should use endpoint', () {
    Client client = new Client(
      endpoint: 'https://cognito-idp.custom-region.aws.com',
      region: 'ap-southeaset-10',
    );
    expect(
        client.endpoint, equals('https://cognito-idp.custom-region.aws.com'));
  });
}
