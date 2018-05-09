import 'package:test/test.dart';
import 'package:amazon_cognito_identity_dart/cognito.dart';

void main() {
  final sampleJwt = '0.eyJzdWIiOiIxYzQyMWYwYy03ZmNlLTQ0MDEtOTVlYy' +
      '1lYzA1YTBjNzc0NDkiLCJldmVudF9pZCI6Ijk5NzQ5ODliLTRjNTAtM' +
      'TFlOC04ZTcwLWQzNTEwZGY2NDY5YiIsInRva2VuX3VzZSI6ImFjY2Vz' +
      'cyIsInNjb3BlIjoiYXdzLmNvZ25pdG8uc2lnbmluLnVzZXIuYWRtaW4' +
      'iLCJhdXRoX3RpbWUiOjE1MjUwNzY5NjksImlzcyI6Imh0dHBzOlwvXC' +
      '9jb2duaXRvLWlkcC5hcC1zb3V0aGVhc3QtMS5hbWF6b25hd3MuY29tX' +
      'C9hcC1zb3V0aGVhc3QtMV9LOGdUTmI2Zk8iLCJleHAiOjE1MjUwODA1' +
      'NjksImlhdCI6MTUyNTA3Njk2OSwianRpIjoiNzIxNzFhYzctMTRiMS0' +
      '0OGQwLWFjM2MtMWY2ZmE1Njg2MzI1IiwiY2xpZW50X2lkIjoiM3N2Yj' +
      'hmcTM4c2NpaWF0cDQ4c20ydjZzN2EiLCJ1c2VybmFtZSI6IjFjNDIxZ' +
      'jBjLTdmY2UtNDQwMS05NWVjLWVjMDVhMGM3NzQ0OSJ9.2';
  test('initiating CognitoIdToken with token should decode payload', () {
    var jwt = new CognitoIdToken(sampleJwt);
    expect(jwt.payload, isNotEmpty);
  });
  test('.getExpiration() returns expiration', () {
    var jwt = new CognitoIdToken(sampleJwt);
    expect(jwt.getExpiration(), greaterThan(0));
  });
  test('.getIssuedAt() returns issued at', () {
    var jwt = new CognitoIdToken(sampleJwt);
    expect(jwt.getIssuedAt(), greaterThan(0));
  });
}
