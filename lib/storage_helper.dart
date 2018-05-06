
Map<String, dynamic> dataMemory = {};

class MemoryStorage {
  setItem(String key, value) {
    dataMemory[key] = value;
    return dataMemory[key];
  }

  getItem(String key) {
    if (dataMemory[key] != null) {
      return dataMemory[key];
    }
    return null;
  }

  removeItem(String key) {
    return dataMemory.remove(key);
  }

  clear() {
    dataMemory = {};
  }
}

class StorageHelper {
  MemoryStorage storage;
  StorageHelper() {
    this.storage = new MemoryStorage();
  }

  MemoryStorage getStorage() {
    return this.storage;
  }
}
