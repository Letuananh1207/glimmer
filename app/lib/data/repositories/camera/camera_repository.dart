import '../../../domain/models/camera_access.dart';

/// The phone's camera permission (WifiScanScreen reads the display's QR with it).
abstract class CameraRepository {
  /// Ask (the system dialog when it may still ask); the answer.
  Future<CameraAccess> request();

  /// What the phone allows now (no dialog) — after coming back from its settings.
  Future<CameraAccess> status();

  /// The app's page in the phone's settings (after "don't ask again").
  Future<void> openSettings();
}
