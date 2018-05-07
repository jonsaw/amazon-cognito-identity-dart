
Map<String, dynamic> _dataMemory = {};

abstract class Storage {
  setItem(String key, value);
  getItem(String key);
  removeItem(String key);
  void clear();
}

class MemoryStorage extends Storage {
  setItem(String key, value) {
    _dataMemory[key] = value;
    return _dataMemory[key];
  }

  getItem(String key) {
    if (_dataMemory[key] != null) {
      return _dataMemory[key];
    }
    return null;
  }

  removeItem(String key) {
    return _dataMemory.remove(key);
  }

  clear() {
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
