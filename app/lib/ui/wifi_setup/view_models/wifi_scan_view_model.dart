import 'package:flutter/foundation.dart';

import '../../../data/repositories/camera/camera_repository.dart';
import '../../../domain/models/camera_access.dart';
import '../../../domain/rules/setup_qr_rules.dart';
import '../../../utils/safe_notifier.dart';

/// What WifiScanScreen shows (screen_specs §10 `state`, plus [starting] while the permission is asked).
enum ScanState { starting, scanning, found, wrongCode, noCamera }

/// Quét mã (screen_specs §10, design 2026-11-28.12; R-WF-4): the camera reads the QR on the display's setup screen.
/// glimmer's code → [ScanState.found] for [foundPause], then the screen closes with it; any other code →
/// [ScanState.wrongCode], nothing done; no camera permission → [ScanState.noCamera].
class WifiScanViewModel extends ChangeNotifier with SafeNotifier {
  WifiScanViewModel({required CameraRepository camera, this.foundPause = const Duration(milliseconds: 600)})
      : _camera = camera;

  final CameraRepository _camera;

  /// How long "Đã đọc mã" shows before the screen closes (~0.6 s).
  final Duration foundPause;

  ScanState _state = ScanState.starting;
  CameraAccess? _access;

  ScanState get state => _state;

  /// The camera preview runs (scanning, and behind found / wrongCode).
  bool get cameraOn => _state != ScanState.starting && _state != ScanState.noCamera;

  /// Refused for good: only the phone's settings can allow it ("Mở cài đặt điện thoại").
  bool get blocked => _access == CameraAccess.blocked;

  /// Ask for the camera (the system dialog the first time).
  Future<void> start() async {
    _access = await _camera.request();
    _state = _access == CameraAccess.granted ? ScanState.scanning : ScanState.noCamera;
    notifyListeners();
  }

  /// "Cho phép camera": ask again (opens the settings when the phone will not ask any more).
  Future<void> allow() async {
    if (blocked) return openSettings();
    await start();
  }

  Future<void> openSettings() => _camera.openSettings();

  /// Back from the phone's settings: allowed there → scan.
  Future<void> resumed() async {
    if (_state != ScanState.noCamera) return;
    final a = await _camera.status();
    if (a == CameraAccess.granted) {
      _access = a;
      _state = ScanState.scanning;
      notifyListeners();
    }
  }

  /// A code the camera read. R-WF-4: glimmer's setup code → found, and after [foundPause] its text (close with it);
  /// another code → wrongCode, null. Ignored unless scanning.
  Future<String?> detected(String? raw) async {
    if (_state != ScanState.scanning || raw == null || raw.isEmpty) return null;
    if (setupApFromQr(raw) == null) {
      _state = ScanState.wrongCode;
      notifyListeners();
      return null;
    }
    _state = ScanState.found;
    notifyListeners();
    await Future<void>.delayed(foundPause);
    return disposed ? null : raw;
  }

  /// "Quét lại".
  void scanAgain() {
    if (_state != ScanState.wrongCode) return;
    _state = ScanState.scanning;
    notifyListeners();
  }
}
