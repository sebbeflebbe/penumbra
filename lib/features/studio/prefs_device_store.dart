import 'package:shared_preferences/shared_preferences.dart';

import 'device_store.dart';

class PrefsDeviceStore implements DeviceStore {
  PrefsDeviceStore(this._prefs);

  final SharedPreferences _prefs;

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<void> delete(String key) async {
    await _prefs.remove(key);
  }
}
