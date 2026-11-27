// Skill Ảnh (design 2026-11-25.4, screen_specs §2 DeletePhotoDialog).
import '../../data/repositories/device/device_repository.dart';
import '../../data/repositories/photo/photo_library_repository.dart';
import '../../data/repositories/photo/photo_repository.dart';
import '../../utils/result.dart';
import '../models/app_error.dart';
import 'photo_source_use_case.dart';

/// `DeletePhotoDialog` "Xoá": DELETE /api/photos?name= and drop the app's copy. A photo already gone from the
/// device (404) counts as deleted.
class DeletePhotoUseCase {
  DeletePhotoUseCase({
    required DeviceRepository device,
    required PhotoRepository photos,
    PhotoLibraryRepository? library,
    PhotoSourceUseCase? source,
  }) : _device = device,
       _photos = photos,
       _library = library,
       _source = source;

  final DeviceRepository _device;
  final PhotoRepository _photos;
  final PhotoLibraryRepository? _library;
  final PhotoSourceUseCase? _source;

  /// Ok = photos left on the device (-1 when it was already gone). R-AK-1: the photo also leaves the library; a
  /// firmware pointing at it then gets the next newest into its cache (R-AK-3).
  Future<Result<int>> call(String name) async {
    final r = await _device.deletePhoto(name);
    final gone = r is Error<int> && r.error is AppError && (r.error as AppError).kind == AppErrorKind.photoNotFound;
    if (r is Ok || gone) {
      await _photos.removeCopy(name);
      final library = _library;
      final p = await library?.byDeviceName(name);
      if (library != null && p != null) {
        await library.remove(p.id);
        if (_source?.supported ?? false) await _source!.syncCache();
      }
    }
    return gone ? const Result.ok(-1) : r;
  }
}
