import 'dart:async';

Map<String, dynamic> _dataMemory = {};

abstract class CognitoStorage {
  Future<dynamic> setItem(String key, value);
  Future<dynamic> getItem(String key);
  Future<dynamic> removeItem(String key);
  Future<void> clear();
}

class CognitoMemoryStorage extends CognitoStorage {
  setItem(String key, value) async {
    _dataMemory[key] = value;
    return _dataMemory[key];
  }

  getItem(String key) async {
    if (_dataMemory[key] != null) {
      return _dataMemory[key];
    }
    return null;
  }

  removeItem(String key) async {
    return _dataMemory.remove(key);
  }

  clear() async {
    _dataMemory = {};
  }
}

class CognitoStorageHelper<S extends CognitoStorage> {
  S storage;
  CognitoStorageHelper(this.storage);

  S getStorage() {
    return this.storage;
  }
}
