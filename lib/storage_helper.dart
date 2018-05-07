import 'dart:async';

Map<String, dynamic> _dataMemory = {};

abstract class Storage {
  Future<dynamic> setItem(String key, value);
  Future<dynamic> getItem(String key);
  Future<dynamic> removeItem(String key);
  Future<void> clear();
}

class MemoryStorage extends Storage {
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

class StorageHelper<S extends Storage> {
  S storage;
  StorageHelper(this.storage);

  S getStorage() {
    return this.storage;
  }
}
