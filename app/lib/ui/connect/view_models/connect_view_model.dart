import 'package:flutter/foundation.dart';

import '../../../data/repositories/device/device_repository.dart';
import '../../../domain/models/app_error.dart';

/// Màn Kết nối: tìm thiết bị, nhập IP / token.
class ConnectViewModel extends ChangeNotifier {
  ConnectViewModel({required DeviceRepository device}) : _device = device {
    _device.addListener(notifyListeners);
  }

  final DeviceRepository _device;

  bool get searching => _device.searching;

  /// Why the last search failed (null: none yet).
  AppError? get error => _device.error;

  /// Last address that worked, without "http://" — prefills the IP field.
  String get savedAddress => _device.savedUrl.replaceFirst('http://', '');
  String get savedToken => _device.token;

  Future<void> retry() => _device.discover();

  Future<void> connect(String address, String token) => _device.connectTo(address, token: token);

  @override
  void dispose() {
    _device.removeListener(notifyListeners);
    super.dispose();
  }
}
