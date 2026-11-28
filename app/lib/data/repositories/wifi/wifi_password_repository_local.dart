import 'dart:async';

import '../../services/wifi_secrets_service.dart';
import 'wifi_password_repository.dart';

class WifiPasswordRepositoryLocal extends WifiPasswordRepository {
  WifiPasswordRepositoryLocal(this._secrets, Map<String, String> saved) : _byNetwork = {...saved};

  /// Nạp mọi mật khẩu đã nhớ từ kho bảo mật.
  static Future<WifiPasswordRepositoryLocal> load(WifiSecretsService secrets) async =>
      WifiPasswordRepositoryLocal(secrets, await secrets.readAll());

  final WifiSecretsService _secrets;
  final Map<String, String> _byNetwork;

  @override
  String? passwordFor(String ssid) => _byNetwork[ssid.trim()];

  @override
  List<String> get networks => List.unmodifiable(_byNetwork.keys.toList()..sort());

  @override
  void remember(String ssid, String password) {
    final name = ssid.trim();
    if (name.isEmpty || _byNetwork[name] == password) return;
    _byNetwork[name] = password;
    unawaited(_secrets.write(name, password)); // không chờ — bộ nhớ là nguồn sự thật
    notifyListeners();
  }

  @override
  void forget(String ssid) {
    final name = ssid.trim();
    if (_byNetwork.remove(name) == null) return;
    unawaited(_secrets.delete(name));
    notifyListeners();
  }
}
