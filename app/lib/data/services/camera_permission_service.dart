import 'package:permission_handler/permission_handler.dart';

/// What the phone answers about the camera.
enum CameraPermission { granted, denied, blocked }

/// The camera permission (permission_handler): ask, and open the app's page in the phone's settings.
class CameraPermissionService {
  Future<CameraPermission> request() async => _of(await Permission.camera.request());

  Future<CameraPermission> status() async => _of(await Permission.camera.status);

  Future<bool> openSettings() => openAppSettings();

  static CameraPermission _of(PermissionStatus s) => switch (s) {
        PermissionStatus.granted || PermissionStatus.limited => CameraPermission.granted,
        PermissionStatus.permanentlyDenied || PermissionStatus.restricted => CameraPermission.blocked,
        _ => CameraPermission.denied,
      };
}
