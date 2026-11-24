import 'package:flutter/foundation.dart';

import '../../../data/repositories/device/device_repository.dart';
import '../../../domain/models/app_error.dart';
import '../../../utils/result.dart';
import '../../../utils/safe_notifier.dart';

/// How a secret (key / token) row reads (R-CD-2).
enum SecretState { set, unset, pending }

/// Device settings (GET/POST /api/settings, camelCase keys). Only changed keys are sent (R-CD-1);
/// secrets come back masked as "***" and are sent only when the user types a new value (R-CD-2).
class SettingsViewModel extends ChangeNotifier with SafeNotifier {
  SettingsViewModel({required DeviceRepository device}) : _device = device;

  final DeviceRepository _device;

  Map<String, dynamic>? _orig;
  final Map<String, dynamic> _edit = {};
  AppError? _loadError;
  bool _saving = false;

  /// Loaded from the device (false: loading, or [loadError]).
  bool get loaded => _orig != null;
  AppError? get loadError => _loadError;
  bool get saving => _saving;

  /// Number of changed keys (the save button shows it).
  int get changeCount => _edit.length;
  bool get hasChanges => _edit.isNotEmpty;

  /// Night mode: 0 none, 1 dim, 2 clock, 3 dark (R-CD-3).
  int get nightMode => value<int>('nightMode', 0);

  /// The app has an API token stored for this device.
  bool get appTokenSaved => _device.token.isNotEmpty;
  String get appToken => _device.token;

  Future<void> load() async {
    final r = await _device.settings();
    switch (r) {
      case Ok(:final value):
        _orig = value;
        _edit.clear();
        _loadError = null;
      case Error(:final error):
        _loadError = AppError.from(error);
    }
    notifyListeners();
  }

  /// Current value of [key] (edited, else from the device), or [d] when missing / another type.
  V value<V>(String key, V d) {
    final v = _edit.containsKey(key) ? _edit[key] : _orig?[key];
    if (v is V) return v;
    if (d is int && v is num) return v.toInt() as V;
    if (d is double && v is num) return v.toDouble() as V;
    return d;
  }

  /// R-CD-1: setting a key back to the device's value drops the change.
  void set(String key, Object v) {
    if (_orig?[key] == v) {
      _edit.remove(key);
    } else {
      _edit[key] = v;
    }
    notifyListeners();
  }

  void discard() {
    _edit.clear();
    notifyListeners();
  }

  /// R-CD-2.
  SecretState secret(String key) {
    if (_edit.containsKey(key)) return SecretState.pending;
    final o = _orig?[key];
    return o is String && o.isNotEmpty ? SecretState.set : SecretState.unset;
  }

  /// Send the changed keys, then reload.
  Future<Result<void>> save() async {
    _saving = true;
    notifyListeners();
    final r = await _device.saveSettings(Map.of(_edit));
    if (r is Ok) await load();
    _saving = false;
    notifyListeners();
    return r;
  }

  /// The token the app sends to the device (not a device setting).
  void setAppToken(String token) {
    _device.setToken(token);
    notifyListeners();
  }
}
