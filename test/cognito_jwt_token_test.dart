import 'package:test/test.dart';
import 'package:amazon_cognito_identity_dart/cognito_jwt_token.dart';

void main() {
  final sampleJwt = 'eyJraWQiOiJ3dzdRQWdvcmhGaXVqK09qcUdtXC9taWhITkFhMHRyR' +
      'ThcL1wvSnNtWU94VG1ZPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOi' +
      'IxYzQyMWYwYy03ZmNlLTQ0MDEtOTVlYy1lYzA1YTBjNzc0NDkiLCJ' +
      'ldmVudF9pZCI6Ijk5NzQ5ODliLTRjNTAtMTFlOC04ZTcwLWQzNTEw' +
      'ZGY2NDY5YiIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoiY' +
      'XdzLmNvZ25pdG8uc2lnbmluLnVzZXIuYWRtaW4iLCJhdXRoX3RpbW' +
      'UiOjE1MjUwNzY5NjksImlzcyI6Imh0dHBzOlwvXC9jb2duaXRvLWl' +
      'kcC5hcC1zb3V0aGVhc3QtMS5hbWF6b25hd3MuY29tXC9hcC1zb3V0' +
      'aGVhc3QtMV9LOGdUTmI2Zk8iLCJleHAiOjE1MjUwODA1NjksImlhd' +
      'CI6MTUyNTA3Njk2OSwianRpIjoiNzIxNzFhYzctMTRiMS00OGQwLW' +
      'FjM2MtMWY2ZmE1Njg2MzI1IiwiY2xpZW50X2lkIjoiM3N2YjhmcTM' +
      '4c2NpaWF0cDQ4c20ydjZzN2EiLCJ1c2VybmFtZSI6IjFjNDIxZjBj' +
      'LTdmY2UtNDQwMS05NWVjLWVjMDVhMGM3NzQ0OSJ9.UWDi4PDVxIkO' +
      'SRW5ZqLnBNKoqhyBPCxIcVKzvuBZqTRKkLw4HxpW92GH-ADYJWD2X' +
      '-KFs2vc0HLK-CtQu9IjFwyHR57JQ0OPf_cq9DL8O610eoF2Kcaa6o' +
      't1Xoc0YmP3ZYPTZ0UcP_ZXUDZ2Qa1lEeRnfEOFAOeq2uT_EhUOfas' +
      'b7ufsxglb_UY2qy6T9ZfsiSX_ZSWp5LhE7wQym-l_R3eiDuX6DHxn' +
      'SmsJyNyw6NCi6JLIF8_rQRCOyqzgLwdwfMfxs7uuIx-ZkpiX1wTBo' +
      'pJpFyGslNkuImYt8O15lGjucGxEoGd3gE_bcbcvRHlqKPETpgJobz' +
      'qUa7eE-Q27Mw';
  test('initiating CognitoJwtToken with token should decode payload', () {
    var jwt = new CognitoJwtToken(sampleJwt);
    expect(jwt.payload, isNotEmpty);
  });
  test('.getExpiration() returns expiration', () {
    var jwt = new CognitoJwtToken(sampleJwt);
    expect(jwt.getExpiration(), greaterThan(0));
  });
  test('.getIssuedAt() returns issued at', () {
    var jwt = new CognitoJwtToken(sampleJwt);
    expect(jwt.getIssuedAt(), greaterThan(0));
  });
}
