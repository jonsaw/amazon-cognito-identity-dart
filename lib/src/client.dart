import 'dart:convert';

import 'package:http/http.dart' as http;

import 'cognito_client_exceptions.dart';

class Client {
  String _service;
  String _userAgent;
  String _region;
  String endpoint;
  http.Client _client;

  Client({
    String endpoint,
    String region,
    String service = 'AWSCognitoIdentityProviderService',
    http.Client client,
  }) {
    this._region = region;
    this._service = service;
    this._userAgent = 'aws-amplify/0.0.x dart';
    this.endpoint = endpoint ?? 'https://cognito-idp.$_region.amazonaws.com/';
    this._client = client;
    if (this._client == null) {
      this._client = new http.Client();
    }
  }

  /// Makes requests on AWS API service provider
  request(String operation, Map<String, dynamic> params, {String endpoint, String service}) async {
    final endpointReq = endpoint ?? this.endpoint;
    final targetService = service ?? _service;
    final body = json.encode(params);

    Map<String, String> headersReq = {
      'Content-Type': 'application/x-amz-json-1.1',
      'X-Amz-Target': '$targetService.$operation',
      'X-Amz-User-Agent': _userAgent,
    };

    http.Response response;
    try {
      response = await _client.post(
        Uri.parse(endpointReq),
        headers: headersReq,
        body: body,
      );
    } catch (e) {
      if (e.toString().startsWith('SocketException:')) {
        throw new CognitoClientException(
          e.message,
          code: 'NetworkError',
        );
      }
      throw new CognitoClientException('Unknown Error', code: 'Unknown error');
    }
    var data;
    try {
      data = json.decode(response.body);
    } catch (e) {
      // expect json
    }
    if (response.statusCode < 200 || response.statusCode > 299) {
      String errorType = 'UnknownError';
      for (String header in response.headers.keys) {
        if (header.toLowerCase() == 'x-amzn-errortype') {
          errorType = response.headers[header].split(':')[0];
          break;
        }
      }
      if (data == null) {
        throw new CognitoClientException(
          'Cognito client request error with unknown message',
          code: errorType,
          name: errorType,
          statusCode: response.statusCode,
        );
      }
      final String dataType = data['__type'];
      final String dataCode = data['code'];
      final String code = (dataType ?? dataCode ?? errorType).split('#').removeLast();
      throw new CognitoClientException(
        data['message'] ?? 'Cognito client request error with unknown message',
        code: code,
        name: code,
        statusCode: response.statusCode,
      );
    }
    return data;
  }
}
