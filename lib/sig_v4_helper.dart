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
  String region;
  String accessKey;
  String secretKey;
  String sessionToken;
  String serviceName;
  String defaultContentType;
  String defaultAcceptType;
  AwsSigV4Client(this.accessKey, this.secretKey, this.endpoint,
      {this.serviceName = 'execute-api',
      this.region = 'us-east-1',
      this.sessionToken,
      this.defaultContentType = _default_content_type,
      this.defaultAcceptType = _default_accept_type});
}

class SigV4Request {
  String method;
  String path;
  Map<String, String> queryParams;
  Map<String, String> headers;
  String url;
  String body;
  AwsSigV4Client awsSigV4Client;
  SigV4Request(
    this.awsSigV4Client, {
    String method,
    this.path,
    this.queryParams,
    this.headers,
    dynamic body,
  }) {
    this.method = method.toUpperCase();
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
    final datetime = _generateDatetime();
    headers[_x_amz_date] = datetime;
    final endpointUri = Uri.parse(awsSigV4Client.endpoint);
    headers[_host] = endpointUri.host;

    final sigV4 = new SigV4();
    headers[_authorization] = _generateAuthorization(sigV4, datetime);
    if (awsSigV4Client.sessionToken != null) {
      headers[_x_amz_security_token] = awsSigV4Client.sessionToken;
    }
    headers.remove(_host);

    url = _generateUrl(sigV4);

    if (headers['Content-Type'] == null) {
      headers['Content-Type'] = awsSigV4Client.defaultContentType;
    }
  }

  String _generateUrl(SigV4 sigV4) {
    var url = '${awsSigV4Client.endpoint}${path}';
    if (queryParams != null) {
      final queryString = sigV4.buildCanonicalQueryString(queryParams);
      if (queryString != '') {
        url += '?${queryString}';
      }
    }
    return url;
  }

  String _generateAuthorization(SigV4 sigV4, String datetime) {
    final canonicalRequest =
        sigV4.buildCanonicalRequest(method, path, queryParams, headers, body);
    final hashedCanonicalRequest = sigV4.hashCanonicalRequest(canonicalRequest);
    final credentialScope = sigV4.buildCredentialScope(
        datetime, awsSigV4Client.region, awsSigV4Client.serviceName);
    final stringToSign = sigV4.buildStringToSign(
        datetime, credentialScope, hashedCanonicalRequest);
    final signingKey = sigV4.calculateSigningKey(awsSigV4Client.secretKey,
        datetime, awsSigV4Client.region, awsSigV4Client.serviceName);
    final signature = sigV4.calculateSignature(signingKey, stringToSign);
    return sigV4.buildAuthorizationHeader(
        awsSigV4Client.accessKey, credentialScope, headers, signature);
  }

  String _generateDatetime() {
    return new DateTime.now()
        .toUtc()
        .toString()
        .replaceAll(new RegExp(r'\.\d{3}Z$'), 'Z')
        .replaceAll(new RegExp(r'[:-]|\.\d{3}'), '')
        .split(' ')
        .join('T');
  }
}

class SigV4 {
  List<int> _hash(List<int> value) {
    return sha256.convert(value).bytes;
  }

  String _hexEncode(List<int> value) {
    return hex.encode(value);
  }

  List<int> _hmac(List<int> secret, List<int> value) {
    Hmac hmac = new Hmac(sha256, secret);
    Digest dig = hmac.convert(value);
    return dig.bytes;
  }

  String hashCanonicalRequest(request) {
    return _hexEncode(utf8.encode(request));
  }

  String buildCanonicalUri(String uri) {
    return Uri.encodeFull(uri);
  }

  String buildCanonicalQueryString(Map<String, String> queryParams) {
    if (queryParams == null) {
      return '';
    }

    final List<String> sortedQueryParams = [];
    queryParams.forEach((key, value) {
      sortedQueryParams.add(key);
    });
    sortedQueryParams.sort();

    var canonicalQueryString = '';
    sortedQueryParams.forEach((key) {
      canonicalQueryString +=
          '${key}=${Uri.encodeComponent(queryParams[key])}&';
    });

    return canonicalQueryString.substring(0, canonicalQueryString.length - 1);
  }

  String buildCanonicalHeaders(Map<String, String> headers) {
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

  buildCanonicalSignedHeaders(Map<String, String> headers) {
    final List<String> sortedKeys = [];
    headers.forEach((property, _) {
      sortedKeys.add(property.toLowerCase());
    });
    sortedKeys.sort();

    return sortedKeys.join(';');
  }

  String buildStringToSign(
      String datetime, String credentialScope, String hashedCanonicalRequest) {
    return '${_aws_sha_256}\n${datetime}\n${credentialScope}\n${hashedCanonicalRequest}';
  }

  String buildCredentialScope(String datetime, String region, String service) {
    return '${datetime.substring(0, 8)}/${region}/${service}/${_aws4_request}';
  }

  String buildCanonicalRequest(
      String method,
      String path,
      Map<String, String> queryParams,
      Map<String, String> headers,
      String payload) {
    List<String> canonicalRequet = [
      method,
      buildCanonicalUri(path),
      buildCanonicalQueryString(queryParams),
      buildCanonicalHeaders(headers),
      buildCanonicalSignedHeaders(headers),
      _hexEncode(_hash(utf8.encode(payload))),
    ];
    return canonicalRequet.join('\n');
  }

  String buildAuthorizationHeader(String accessKey, String credentialScope,
      Map<String, String> headers, String signature) {
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

  List<int> calculateSigningKey(
      String secretKey, String datetime, String region, String service) {
    return _hmac(
        _hmac(
            _hmac(
                _hmac(utf8.encode('${_aws4}${secretKey}'),
                    utf8.encode(datetime.substring(0, 8))),
                utf8.encode(region)),
            utf8.encode(service)),
        utf8.encode(_aws4_request));
  }

  String calculateSignature(List<int> signingKey, String stringToSign) {
    return _hexEncode(_hmac(signingKey, utf8.encode(stringToSign)));
  }
}
