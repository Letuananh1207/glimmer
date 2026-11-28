import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wi-Fi passwords the app remembers, in the phone's secure storage (Android Keystore) — never in
/// shared_preferences. One entry per network: key `wifi_pw:<ssid>`. Keys: docs/backend/README.md.
class WifiSecretsService {
  WifiSecretsService([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;
  static const _prefix = 'wifi_pw:';

  /// Every remembered network → its password (empty map if the store can't be read).
  Future<Map<String, String>> readAll() async {
    try {
      final all = await _s.readAll();
      return {
        for (final e in all.entries)
          if (e.key.startsWith(_prefix) && e.key.length > _prefix.length) e.key.substring(_prefix.length): e.value,
      };
    } on Exception {
      return {};
    }
  }

  Future<void> write(String ssid, String password) => _s.write(key: '$_prefix$ssid', value: password);

  Future<void> delete(String ssid) => _s.delete(key: '$_prefix$ssid');
}
