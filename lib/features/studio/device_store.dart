/// Small key/value store for necessary client state (theme, device wrapping).
/// Implementations may use SharedPreferences; tests use the memory store.
abstract class DeviceStore {
  String? read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class MemoryDeviceStore implements DeviceStore {
  MemoryDeviceStore([Map<String, String>? seed]) : _data = {...?seed};

  final Map<String, String> _data;

  @override
  String? read(String key) => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);
}
