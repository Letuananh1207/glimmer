import '../../../domain/models/camera_access.dart';
import '../../services/camera_permission_service.dart';
import 'camera_repository.dart';

class CameraRepositoryLocal implements CameraRepository {
  CameraRepositoryLocal(this._service);

  final CameraPermissionService _service;

  @override
  Future<CameraAccess> request() async => _of(await _service.request());

  @override
  Future<CameraAccess> status() async => _of(await _service.status());

  static CameraAccess _of(CameraPermission p) => switch (p) {
        CameraPermission.granted => CameraAccess.granted,
        CameraPermission.denied => CameraAccess.denied,
        CameraPermission.blocked => CameraAccess.blocked,
      };

  @override
  Future<void> openSettings() async {
    await _service.openSettings();
  }
}
