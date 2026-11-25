// Skill Ảnh (design 2026-11-25.4, screen_specs §2 tab Ảnh).
import '../../data/repositories/device/device_repository.dart';
import '../../data/repositories/photo/photo_repository.dart';
import '../../utils/result.dart';
import '../models/device_photo.dart';

/// Tab Ảnh: the device's photos in device order, each with the app's copy when it has one; copies of photos the
/// device no longer has are dropped.
class LoadPhotosUseCase {
  LoadPhotosUseCase({required DeviceRepository device, required PhotoRepository photos})
      : _device = device,
        _photos = photos;

  final DeviceRepository _device;
  final PhotoRepository _photos;

  Future<Result<PhotoGallery>> call() async {
    final r = await _device.photos();
    switch (r) {
      case Error(:final error):
        return Result.error(error);
      case Ok(:final value):
        await _photos.prune(value.photos.map((p) => p.name));
        return Result.ok(PhotoGallery(value, [
          for (final p in value.photos) GalleryPhoto(p, await _photos.copyOf(p)),
        ]));
    }
  }
}
