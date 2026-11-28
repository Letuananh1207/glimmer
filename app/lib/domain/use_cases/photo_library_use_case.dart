// Kho ảnh (design 2026-11-28.11, screen_specs §2; R-AK-1…3).
import '../../data/repositories/device/device_repository.dart';
import '../../data/repositories/photo/photo_library_repository.dart';
import '../../data/repositories/photo/photo_repository.dart';
import '../../utils/result.dart';
import '../models/app_error.dart';
import '../models/library_photo.dart';
import '../rules/library_rules.dart';
import 'photo_source_use_case.dart';

/// Tab Ảnh as Kho ảnh: the library newest first with each JPEG, and deleting a photo from it (and from the device's
/// cache when it is there).
class PhotoLibraryUseCase {
  PhotoLibraryUseCase({
    required DeviceRepository device,
    required PhotoLibraryRepository library,
    required PhotoRepository photos,
    required PhotoSourceUseCase source,
  }) : _device = device,
       _library = library,
       _photos = photos,
       _source = source;

  final DeviceRepository _device;
  final PhotoLibraryRepository _library;
  final PhotoRepository _photos;
  final PhotoSourceUseCase _source;

  /// Newest first (ids descending); [LibraryItem.order] = the place in the slideshow order (oldest first, R-AK-2).
  Future<List<LibraryItem>> load() async {
    final ordered = libraryOrder(await _library.list());
    final items = <LibraryItem>[
      for (var i = 0; i < ordered.length; i++)
        LibraryItem(photo: ordered[i], preview: await _library.bytes(ordered[i].id), order: i + 1),
    ];
    items.sort((a, b) => b.id.compareTo(a.id));
    return items;
  }

  /// "Xoá ảnh khỏi kho?" → Xoá: the device's copy first when it has one (refused → the photo stays in the library),
  /// then the library's; the device's cache then gets the next newest (R-AK-3, best effort).
  Future<Result<void>> delete(int id) async {
    final p = (await _library.list()).where((e) => e.id == id).firstOrNull;
    if (p == null) return const Result.ok(null);
    final cached = p.cachedAs;
    if (cached != null) {
      final r = await _device.deletePhoto(cached);
      final gone = r is Error<int> && r.error is AppError && (r.error as AppError).kind == AppErrorKind.photoNotFound;
      if (r is Error<int> && !gone) return Result.error(r.error);
      await _photos.removeCopy(cached);
    }
    await _library.remove(id);
    if (_source.supported) await _source.syncCache();
    return const Result.ok(null);
  }
}
