import 'dart:convert';
import 'package:http/http.dart' as http;
import 'cognito_client_exceptions.dart';

class Client {
  String _service;
  String _userAgent;
  String _region;
  String endpoint;

  Client({
    String endpoint,
    String region,
    String service = 'AWSCognitoIdentityProviderService',
  }) {
    this._region = region;
    this._service = service;
    this._userAgent = 'aws-amplify/0.0.x dart';
    this.endpoint = endpoint ?? 'https://cognito-idp.${_region}.amazonaws.com/';
  }

  request(String operation, Map<dynamic, dynamic> params,
      {String endpoint, String service}) async {
    final endpointReq = endpoint ?? this.endpoint;
    final targetService = service ?? _service;
    final body = json.encode(params);

    Map<String, String> headersReq = {
      'Content-Type': 'application/x-amz-json-1.1',
      'X-Amz-Target': '${targetService}.${operation}',
      'X-Amz-User-Agent': _userAgent,
    };

    http.Response response;
    try {
      response = await http.post(
        endpointReq,
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
    final data = json.decode(response.body);
    if (response.statusCode < 200 || response.statusCode > 299) {
      String code = (data['__type'] ?? data['code']).split('#').removeLast();
      throw new CognitoClientException(
        data['message'],
        code: code,
        name: code,
        statusCode: response.statusCode,
      );
    }
    return data;
  }
}
