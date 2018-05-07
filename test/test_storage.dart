import 'dart:convert';
import 'package:amazon_cognito_identity_dart/storage_helper.dart';

Map<String, String> testStorage = {};

class TestCustomStorage extends Storage {
  String prefix;
  TestCustomStorage(this.prefix);
  setItem(String key, value) {
    testStorage[prefix+key] = json.encode(value);
    return testStorage[prefix+key];
  }
  getItem(String key) {
    if (testStorage[prefix+key] != null) {
      return json.decode(testStorage[prefix+key]);
    }
    return null;
  }
  removeItem(String key) {
    return testStorage.remove(prefix+key);
  }
  clear() {
    testStorage = {};
  }
}
