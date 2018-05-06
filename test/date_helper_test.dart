import 'package:test/test.dart';
import 'package:amazon_cognito_identity_dart/date_helper.dart';

void main() {
  test('.getNowString() starts with short day', () {
    final DateHelper dateHelper = new DateHelper();
    expect(dateHelper.getNowString(),
      matches(r'^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)\s')
    );
  });
  test('.getNowString() includes short month', () {
    final DateHelper dateHelper = new DateHelper();
    expect(dateHelper.getNowString(),
      matches(r'\s(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s')
    );
  });
  test('.getNowString() includes day', () {
    final DateHelper dateHelper = new DateHelper();
    expect(dateHelper.getNowString(),
      matches(r'\s([1-9]|[12]\d|3[01])\s')
    );
  });
  test('.getNowString() includes time', () {
    final DateHelper dateHelper = new DateHelper();
    expect(dateHelper.getNowString(),
      matches(r'\s([01]?[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])\s')
    );
  });
  test('.getNowString() includes UTC', () {
    final DateHelper dateHelper = new DateHelper();
    expect(dateHelper.getNowString(),
      matches(r'\sUTC\s')
    );
  });
  test('.getNowString() ends with Year', () {
    final DateHelper dateHelper = new DateHelper();
    expect(dateHelper.getNowString(),
      matches(r'\d{4}$')
    );
  });
  test('.getNowString() generates valid timestamp', () {
    final DateHelper dateHelper = new DateHelper();
    expect(dateHelper.getNowString(),
      matches(r'^[SMTWF][uoehra][neduit]\s[JFMASOND][aepuco][nbrylgptvc]\s([1-9]|[12]\d|3[01])\s([01]?[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9])\sUTC\s\d{4}$')
    );
  });
}
