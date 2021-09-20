import 'dart:convert';
import 'package:amazon_cognito_identity_dart/cognito.dart';

Map<String, String> testStorage = {};

class TestCustomStorage extends CognitoStorage {
  String prefix;
  TestCustomStorage(this.prefix);
  setItem(String key, value) async {
    testStorage[prefix + key] = json.encode(value);
    return testStorage[prefix + key];
  }

  getItem(String key) async {
    if (testStorage[prefix + key] != null) {
      return json.decode(testStorage[prefix + key]!);
    }
    return null;
  }

  removeItem(String key) async {
    return testStorage.remove(prefix + key);
  }

  clear() async {
    testStorage = {};
  }
}
