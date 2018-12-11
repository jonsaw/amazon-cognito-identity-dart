import 'package:test/test.dart';
import 'package:amazon_cognito_identity_dart/cognito.dart';
import 'test_storage.dart';

void main() {
  group('CognitoMemoryStorage', () {
    test('new CognitoStorageHelper() sets up default CognitoMemoryStorage', () {
      final s = new CognitoStorageHelper(new CognitoMemoryStorage());
      expect(s.getStorage(), TypeMatcher<CognitoMemoryStorage>());
    });
    test('.getItem() returns default null', () async {
      final s =
          new CognitoStorageHelper(new CognitoMemoryStorage()).getStorage();
      expect(await s.getItem('some'), equals(null));
    });
    test('.setItem() sets up item in memory & .getItem() retrieves item',
        () async {
      final s =
          new CognitoStorageHelper(new CognitoMemoryStorage()).getStorage();
      s.setItem('some', 'value');
      expect(await s.getItem('some'), equals('value'));
    });
    test('.getItem() retrieves item from previous storage', () async {
      final s =
          new CognitoStorageHelper(new CognitoMemoryStorage()).getStorage();
      expect(await s.getItem('some'), equals('value'));
    });
    test('.removeItem() returns item and removes from storage', () async {
      final s =
          new CognitoStorageHelper(new CognitoMemoryStorage()).getStorage();
      await s.setItem('another', 'awesome value');
      final removedItem = await s.removeItem('another');
      expect(removedItem, equals('awesome value'));
      expect(await s.getItem('another'), equals(null));
    });
    test('.clear() clears storage', () async {
      final s =
          new CognitoStorageHelper(new CognitoMemoryStorage()).getStorage();
      s.clear();
      expect(await s.getItem('some'), equals(null));
    });
  });
  group('custom storage', () {
    test('new CognitoStorageHelper() sets up default TestCustomStorage', () {
      final s = new CognitoStorageHelper(new TestCustomStorage('test:'));
      expect(s.getStorage(), TypeMatcher<TestCustomStorage>());
    });
    test('.setItem() sets up json value with custom prefixed key', () async {
      final s =
          new CognitoStorageHelper(new TestCustomStorage('test:')).getStorage();
      final Map<String, String> params = {
        'username': 'x123',
        'name': 'Michael',
      };
      await s.setItem('user', params);
      expect(testStorage['test:user'],
          equals('{"username":"x123","name":"Michael"}'));
    });
    test('.getItem() gets item with decoded values', () async {
      final s =
          new CognitoStorageHelper(new TestCustomStorage('test:')).getStorage();
      final user = await s.getItem('user');
      expect(user['username'], equals('x123'));
      expect(user['name'], equals('Michael'));
    });
  });
}
