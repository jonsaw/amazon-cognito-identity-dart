import 'package:http/http.dart' as http;

export './exceptions.dart'
    show
        codeDeliveryFailureException,
        internalErrorException,
        invalidEmailRoleAccessPolicyException,
        invalidLambdaResponseException,
        invalidPasswordException,
        invalidSmsRoleAccessPolicyException,
        invalidSmsRoleTrustRelationshipException,
        notAuthorizedException,
        resourceNotFoundException,
        tooManyRequestsException,
        unexpectedLambdaException,
        userLambdaValidationException,
        usernameExistsException;

/// A response from the server indicating that a user registration
/// has been confirmed.
final successfulConfirmedSignUp = http.Response(
  '''{
    "CodeDeliveryDetails": {
      "AttributeName": "string",
      "DeliveryMedium": "SMS",
      "Destination": "string"
    },
    "UserConfirmed": true,
    "UserSub": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
  }''',
  200,
  headers: Map<String, String>.from({
    'Content-Type': 'application/json',
  }),
);

/// A response from the server indicating that a user registration
/// has not been confirmed.
final successfulUnconfirmedSignUp = http.Response(
  '''{
    "CodeDeliveryDetails": {
      "AttributeName": "string",
      "DeliveryMedium": "SMS",
      "Destination": "string"
    },
    "UserConfirmed": false,
    "UserSub": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
  }''',
  200,
  headers: Map<String, String>.from({
    'Content-Type': 'application/json',
  }),
);
