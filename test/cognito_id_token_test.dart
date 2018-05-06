import 'package:test/test.dart';
import 'package:amazon_cognito_identity_dart/cognito_id_token.dart';

void main() {
  final sampleJwt = '0.eyJzdWIiOiIxYzQyMWYwYy03ZmNlLTQ0MDEtOTVlYy1lYzA1YTBjNzc0NDkiLCJldmVudF9pZCI6Ijk5NzQ5ODliLTRjNTAtMTFlOC04ZTcwLWQzNTEwZGY2NDY5YiIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoiYXdzLmNvZ25pdG8uc2lnbmluLnVzZXIuYWRtaW4iLCJhdXRoX3RpbWUiOjE1MjUwNzY5NjksImlzcyI6Imh0dHBzOlwvXC9jb2duaXRvLWlkcC5hcC1zb3V0aGVhc3QtMS5hbWF6b25hd3MuY29tXC9hcC1zb3V0aGVhc3QtMV9LOGdUTmI2Zk8iLCJleHAiOjE1MjUwODA1NjksImlhdCI6MTUyNTA3Njk2OSwianRpIjoiNzIxNzFhYzctMTRiMS00OGQwLWFjM2MtMWY2ZmE1Njg2MzI1IiwiY2xpZW50X2lkIjoiM3N2YjhmcTM4c2NpaWF0cDQ4c20ydjZzN2EiLCJ1c2VybmFtZSI6IjFjNDIxZjBjLTdmY2UtNDQwMS05NWVjLWVjMDVhMGM3NzQ0OSJ9.2';
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
