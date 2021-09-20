import 'package:amazon_cognito_identity_dart/src/client.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:amazon_cognito_identity_dart/src/cognito_user_pool.dart';
import 'package:amazon_cognito_identity_dart/src/mocks/sign_up.dart'
    as signUpMock;
import 'package:amazon_cognito_identity_dart/src/cognito_client_exceptions.dart';

void main() {
  test('initiating with invalid userPoolId', () {
    try {
      CognitoUserPool('badUserPoolId', 'nnnnnnnnnnnnnnnnnnnnnnnnnn');
    } on ArgumentError catch (e) {
      expect(e.message, equals('Invalid userPoolId format.'));
    }
  });

  test('initiating with invalid userPoolId throws ArgumentError', () {
    try {
      CognitoUserPool('badUserPoolId', 'nnnnnnnnnnnnnnnnnnnnnnnnnn');
    } on ArgumentError catch (e) {
      expect(e.message, equals('Invalid userPoolId format.'));
    }
  });

  test('initiating with valid userPoolId sets up client', () {
    final cup = CognitoUserPool(
        'ap-southeast-1_nnnnnnnnn', 'nnnnnnnnnnnnnnnnnnnnnnnnnn');
    expect(
      cup.client!.endpoint,
      equals('https://cognito-idp.ap-southeast-1.amazonaws.com/'),
    );
  });

  test('initiating with custom client', () async {
    final testClient = MockClient((request) {
      return Future<http.Response>.value(http.Response(
        '{"it":"works"}',
        200,
        headers: Map<String, String>.from({
          'Content-Type': 'application/json',
        }),
      ));
    });

    final c = Client(
      client: testClient,
    );

    final cup = CognitoUserPool(
      'ap-southeast-1_nnnnnnnnn',
      'nnnnnnnnnnnnnnnnnnnnnnnnnn',
      customClient: c,
    );
    final Map<String, dynamic> data =
        await cup.client!.request('TestOperation', {
      'color': 'Green',
    });
    expect(data['it'], equals('works'));
  });

  group('signUp', () {
    test('successful confirmed signup', () async {
      final c = Client(
        client: MockClient((request) =>
            Future<http.Response>.value(signUpMock.successfulConfirmedSignUp)),
      );
      final cup = CognitoUserPool(
        'ap-southeast-1_nnnnnnnnn',
        'nnnnnnnnnnnnnnnnnnnnnnnnnn',
        customClient: c,
      );
      final data = await cup.signUp('username', 'password');
      expect(data.userConfirmed, equals(true));
      expect(data.userSub, equals('XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'));
    });

    test('successful unconfirmed signup', () async {
      final c = Client(
        client: MockClient((request) => Future<http.Response>.value(
            signUpMock.successfulUnconfirmedSignUp)),
      );
      final cup = CognitoUserPool(
        'ap-southeast-1_nnnnnnnnn',
        'nnnnnnnnnnnnnnnnnnnnnnnnnn',
        customClient: c,
      );
      final data = await cup.signUp('username', 'password');
      expect(data.userConfirmed, equals(false));
      expect(data.userSub, equals('XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX'));
    });

    test('unsuccessful', () async {
      final c = Client(
        client: MockClient((request) => Future<http.Response>.value(
              signUpMock.notAuthorizedException,
            )),
      );
      final cup = CognitoUserPool(
        'ap-southeast-1_nnnnnnnnn',
        'nnnnnnnnnnnnnnnnnnnnnnnnnn',
        customClient: c,
      );
      try {
        await cup.signUp('username', 'password');
      } on CognitoClientException catch (e) {
        expect(e.code, equals('NotAuthorizedException'));
        expect(e.message, isNotEmpty);
      }
    });
  });
}
