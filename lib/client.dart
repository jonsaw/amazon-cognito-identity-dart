import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ClientException implements Exception {
  int statusCode;
  String code;
  String name;
  String message;
  ClientException(
    this.message,
    {
      this.code,
      this.statusCode,
      this.name,
    }
  );
}

class Client {
  String region;
  String endpoint;
  String userAgent;
  Client({
    String endpoint,
    String this.region,
  }) {
    this.endpoint = endpoint ?? 'https://cognito-idp.${region}.amazonaws.com/';
    this.userAgent = 'aws-amplify/0.0.x dart';
  }

  request(
    String operation,
    Map<dynamic, dynamic> params,
  ) async {
    Map<String, String> headers = {
      'Content-Type': 'application/x-amz-json-1.1',
      'X-Amz-Target': 'AWSCognitoIdentityProviderService.${operation}',
      'X-Amz-User-Agent': this.userAgent,
    };
    String body = json.encode(params);

    http.Response response;
    try {
      response = await http.post(
        this.endpoint,
        headers: headers,
        body: body,
      );
    } on SocketException catch (e) {
      throw new ClientException(
        e.message,
        code: 'NetworkError',
      );
    } catch (e) {
      throw new ClientException('Unknown Error', code: 'Unknown error');
    }

    final data = json.decode(response.body);
    if (response.statusCode < 200 || response.statusCode > 299) {
      String code = (data['__type'] ?? data['code']).split('#').removeLast();
      throw new ClientException(
        data['message'],
        code: code,
        name: code,
        statusCode: response.statusCode,
      );
    }
    return data;
  }
}
