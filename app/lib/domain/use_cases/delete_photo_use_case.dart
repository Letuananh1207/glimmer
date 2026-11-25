// Skill Ảnh (design 2026-11-25.4, screen_specs §2 DeletePhotoDialog).
import '../../data/repositories/device/device_repository.dart';
import '../../data/repositories/photo/photo_repository.dart';
import '../../utils/result.dart';
import '../models/app_error.dart';

/// `DeletePhotoDialog` "Xoá": DELETE /api/photos?name= and drop the app's copy. A photo already gone from the
/// device (404) counts as deleted.
class DeletePhotoUseCase {
  DeletePhotoUseCase({required DeviceRepository device, required PhotoRepository photos})
      : _device = device,
        _photos = photos;

  final DeviceRepository _device;
  final PhotoRepository _photos;

  /// Ok = photos left on the device (-1 when it was already gone).
  Future<Result<int>> call(String name) async {
    final r = await _device.deletePhoto(name);
    final gone = r is Error<int> && r.error is AppError && (r.error as AppError).kind == AppErrorKind.photoNotFound;
    if (r is Ok || gone) await _photos.removeCopy(name);
    return gone ? const Result.ok(-1) : r;
  }
}
