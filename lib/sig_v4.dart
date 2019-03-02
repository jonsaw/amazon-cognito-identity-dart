import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

const _aws_sha_256 = 'AWS4-HMAC-SHA256';
const _aws4_request = 'aws4_request';
const _aws4 = 'AWS4';
const _x_amz_date = 'x-amz-date';
const _x_amz_security_token = 'x-amz-security-token';
const _host = 'host';
const _authorization = 'Authorization';
const _default_content_type = 'application/json';
const _default_accept_type = 'application/json';

class AwsSigV4Client {
  String endpoint;
  String pathComponent;
  String region;
  String accessKey;
  String secretKey;
  String sessionToken;
  String serviceName;
  String defaultContentType;
  String defaultAcceptType;
  AwsSigV4Client(this.accessKey, this.secretKey, String endpoint,
      {this.serviceName = 'execute-api',
      this.region = 'us-east-1',
      this.sessionToken,
      this.defaultContentType = _default_content_type,
      this.defaultAcceptType = _default_accept_type}) {
    final parsedUri = Uri.parse(endpoint);
    this.endpoint = '${parsedUri.scheme}://${parsedUri.host}';
    this.pathComponent = parsedUri.path;
  }
}

class SigV4Request {
  String method;
  String path;
  Map<String, String> queryParams;
  Map<String, String> headers;
  String url;
  String body;
  AwsSigV4Client awsSigV4Client;
  String canonicalRequest;
  String hashedCanonicalRequest;
  String credentialScope;
  String stringToSign;
  String datetime;
  List<int> signingKey;
  String signature;
  SigV4Request(
    this.awsSigV4Client, {
    String method,
    String path,
    this.datetime,
    this.queryParams,
    this.headers,
    dynamic body,
  }) {
    this.method = method.toUpperCase();
    this.path = '${awsSigV4Client.pathComponent}$path';
    if (headers == null) {
      headers = {};
    }
    if (headers['Content-Type'] == null) {
      headers['Content-Type'] = awsSigV4Client.defaultContentType;
    }
    if (headers['Accept'] == null) {
      headers['Accept'] = awsSigV4Client.defaultAcceptType;
    }
    if (body == null || this.method == 'GET') {
      this.body = '';
    } else {
      this.body = json.encode(body);
    }
    if (body == '') {
      headers.remove('Content-Type');
    }
    if (datetime == null) {
      datetime = SigV4.generateDatetime();
    }
    headers[_x_amz_date] = datetime;
    final endpointUri = Uri.parse(awsSigV4Client.endpoint);
    headers[_host] = endpointUri.host;

    headers[_authorization] = _generateAuthorization(datetime);
    if (awsSigV4Client.sessionToken != null) {
      headers[_x_amz_security_token] = awsSigV4Client.sessionToken;
    }
    headers.remove(_host);

    url = _generateUrl();

    if (headers['Content-Type'] == null) {
      headers['Content-Type'] = awsSigV4Client.defaultContentType;
    }
  }

  String _generateUrl() {
    var url = '${awsSigV4Client.endpoint}$path';
    if (queryParams != null) {
      final queryString = SigV4.buildCanonicalQueryString(queryParams);
      if (queryString != '') {
        url += '?$queryString';
      }
    }
    return url;
  }

  String _generateAuthorization(String datetime) {
    canonicalRequest =
        SigV4.buildCanonicalRequest(method, path, queryParams, headers, body);
    hashedCanonicalRequest = SigV4.hashCanonicalRequest(canonicalRequest);
    credentialScope = SigV4.buildCredentialScope(
        datetime, awsSigV4Client.region, awsSigV4Client.serviceName);
    stringToSign = SigV4.buildStringToSign(
        datetime, credentialScope, hashedCanonicalRequest);
    signingKey = SigV4.calculateSigningKey(awsSigV4Client.secretKey, datetime,
        awsSigV4Client.region, awsSigV4Client.serviceName);
    signature = SigV4.calculateSignature(signingKey, stringToSign);
    return SigV4.buildAuthorizationHeader(
        awsSigV4Client.accessKey, credentialScope, headers, signature);
  }
}

class SigV4 {
  static String generateDatetime() {
    return new DateTime.now()
        .toUtc()
        .toString()
        .replaceAll(new RegExp(r'\.\d*Z$'), 'Z')
        .replaceAll(new RegExp(r'[:-]|\.\d{3}'), '')
        .split(' ')
        .join('T');
  }

  static List<int> hash(List<int> value) {
    return sha256.convert(value).bytes;
  }

  static String hexEncode(List<int> value) {
    return hex.encode(value);
  }

  static List<int> sign(List<int> key, String message) {
    Hmac hmac = new Hmac(sha256, key);
    Digest dig = hmac.convert(utf8.encode(message));
    return dig.bytes;
  }

  static String hashCanonicalRequest(String request) {
    return hexEncode(hash(utf8.encode(request)));
  }

  static String buildCanonicalUri(String uri) {
    return Uri.encodeFull(uri);
  }

  static String buildCanonicalQueryString(Map<String, String> queryParams) {
    if (queryParams == null) {
      return '';
    }

    final List<String> sortedQueryParams = [];
    queryParams.forEach((key, value) {
      sortedQueryParams.add(key);
    });
    sortedQueryParams.sort();

    final List<String> canonicalQueryStrings = [];
    sortedQueryParams.forEach((key) {
      canonicalQueryStrings
          .add('$key=${Uri.encodeComponent(queryParams[key])}');
    });

    return canonicalQueryStrings.join('&');
  }

  static String buildCanonicalHeaders(Map<String, String> headers) {
    final List<String> sortedKeys = [];
    headers.forEach((property, _) {
      sortedKeys.add(property);
    });

    var canonicalHeaders = '';
    sortedKeys.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    sortedKeys.forEach((property) {
      canonicalHeaders += '${property.toLowerCase()}:${headers[property]}\n';
    });

    return canonicalHeaders;
  }

  static String buildCanonicalSignedHeaders(Map<String, String> headers) {
    final List<String> sortedKeys = [];
    headers.forEach((property, _) {
      sortedKeys.add(property.toLowerCase());
    });
    sortedKeys.sort();

    return sortedKeys.join(';');
  }

  static String buildStringToSign(
      String datetime, String credentialScope, String hashedCanonicalRequest) {
    return '$_aws_sha_256\n$datetime\n$credentialScope\n$hashedCanonicalRequest';
  }

  static String buildCredentialScope(
      String datetime, String region, String service) {
    return '${datetime.substring(0, 8)}/$region/$service/$_aws4_request';
  }

  static String buildCanonicalRequest(
      String method,
      String path,
      Map<String, String> queryParams,
      Map<String, String> headers,
      String payload) {
    List<String> canonicalRequest = [
      method,
      buildCanonicalUri(path),
      buildCanonicalQueryString(queryParams),
      buildCanonicalHeaders(headers),
      buildCanonicalSignedHeaders(headers),
      hexEncode(hash(utf8.encode(payload))),
    ];
    return canonicalRequest.join('\n');
  }

  static String buildAuthorizationHeader(String accessKey,
      String credentialScope, Map<String, String> headers, String signature) {
    return _aws_sha_256 +
        ' Credential=' +
        accessKey +
        '/' +
        credentialScope +
        ', SignedHeaders=' +
        buildCanonicalSignedHeaders(headers) +
        ', Signature=' +
        signature;
  }

  static List<int> calculateSigningKey(
      String secretKey, String datetime, String region, String service) {
    return sign(
        sign(
            sign(
                sign(utf8.encode('$_aws4$secretKey'), datetime.substring(0, 8)),
                region),
            service),
        _aws4_request);
  }

  static String calculateSignature(List<int> signingKey, String stringToSign) {
    return hexEncode(sign(signingKey, stringToSign));
  }
}
