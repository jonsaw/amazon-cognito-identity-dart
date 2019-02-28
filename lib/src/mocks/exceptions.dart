import 'package:http/http.dart' as http;

/// This exception is thrown when a verification code fails to deliver successfully.
final codeDeliveryFailureException = http.Response(
  '{"message":"Mocked error message"}',
  400,
  headers: Map<String, String>.from({
    'x-amzn-ErrorType': 'CodeDeliveryFailureException',
  }),
);

/// This exception is thrown when Amazon Cognito encounters an internal error.
final internalErrorException = http.Response(
  '{"message":"Mocked error message"}',
  500,
  headers: Map<String, String>.from({
    'x-amzn-ErrorType': 'InternalErrorException',
  }),
);

/// This exception is thrown when Amazon Cognito is not allowed to use your email identity.
final invalidEmailRoleAccessPolicyException = http.Response(
  '{"message":"Mocked error message"}',
  400,
  headers: Map<String, String>.from({
    'x-amzn-ErrorType': 'InvalidEmailRoleAccessPolicyException',
  }),
);

/// This exception is thrown when the Amazon Cognito service encounters an invalid AWS Lambda response.
final invalidLambdaResponseException = http.Response(
  '{"message":"Mocked error message"}',
  400,
  headers: Map<String, String>.from({
    'x-amzn-ErrorType': 'InvalidLambdaResponseException',
  }),
);

/// This exception is thrown when the Amazon Cognito service encounters an invalid AWS Lambda response.
final invalidParameterException = http.Response(
  '{"message":"Mocked error message"}',
  400,
  headers: Map<String, String>.from({
    'x-amzn-ErrorType': 'InvalidParameterException',
  }),
);

/// This exception is thrown when the Amazon Cognito service encounters an invalid password.
final invalidPasswordException = http.Response(
  '{"message":"Mocked error message"}',
  400,
  headers: Map<String, String>.from({
    'x-amzn-ErrorType': 'InvalidPasswordException',
  }),
);

/// This exception is returned when the role provided for SMS configuration does not have permission to
/// publish using Amazon SNS.
final invalidSmsRoleAccessPolicyException = http.Response(
  '{"message":"Mocked error message"}',
  400,
  headers: Map<String, String>.from({
    'x-amzn-ErrorType': 'InvalidSmsRoleAccessPolicyException',
  }),
);

/// This exception is thrown when the trust relationship is invalid for the role provided for
/// SMS configuration. This can happen if you do not trust cognito-idp.amazonaws.com or the
/// external ID provided in the role does not match what is provided in the SMS configuration
/// for the user pool.
final invalidSmsRoleTrustRelationshipException = http.Response(
  '{"message":"Mocked error message"}',
  400,
  headers: Map<String, String>.from({
    'x-amzn-ErrorType': 'InvalidSmsRoleTrustRelationshipException',
  }),
);

/// This exception is thrown when a user is not authorized.
final notAuthorizedException = http.Response(
  '{"message":"Mocked error message"}',
  400,
  headers: Map<String, String>.from({
    'x-amzn-ErrorType': 'NotAuthorizedException',
  }),
);

/// This exception is thrown when the Amazon Cognito service cannot find the requested resource.
final resourceNotFoundException = http.Response(
  '{"message":"Mocked error message"}',
  400,
  headers: Map<String, String>.from({
    'x-amzn-ErrorType': 'ResourceNotFoundException',
  }),
);

/// This exception is thrown when the user has made too many requests for a given operation.
final tooManyRequestsException = http.Response(
  '{"message":"Mocked error message"}',
  400,
  headers: Map<String, String>.from({
    'x-amzn-ErrorType': 'TooManyRequestsException',
  }),
);

/// This exception is thrown when the Amazon Cognito service encounters an unexpected
/// exception with the AWS Lambda service.
final unexpectedLambdaException = http.Response(
  '{"message":"Mocked error message"}',
  400,
  headers: Map<String, String>.from({
    'x-amzn-ErrorType': 'UnexpectedLambdaException',
  }),
);

/// This exception is thrown when the Amazon Cognito service encounters a user validation
/// exception with the AWS Lambda service.
final userLambdaValidationException = http.Response(
  '{"message":"Mocked error message"}',
  400,
  headers: Map<String, String>.from({
    'x-amzn-ErrorType': 'UserLambdaValidationException',
  }),
);

/// This exception is thrown when Amazon Cognito encounters a user name that
/// already exists in the user pool
final usernameExistsException = http.Response(
  '{"message":"Mocked error message"}',
  400,
  headers: Map<String, String>.from({
    'x-amzn-ErrorType': 'UsernameExistsException',
  }),
);
