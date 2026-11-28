// Skill Ảnh (design 2026-11-25.4, screen_specs §7 PhotoCropScreen).
import 'dart:isolate';
import 'dart:typed_data';

import '../../data/repositories/device/device_repository.dart';
import '../../data/repositories/photo/photo_library_repository.dart';
import '../../data/repositories/photo/photo_repository.dart';
import '../../utils/cancel_token.dart';
import '../../utils/result.dart';
import '../models/app_error.dart';
import '../models/device_photo.dart';
import '../models/library_photo.dart';
import '../rules/photo_rules.dart';
import 'photo_source_use_case.dart';

typedef PhotoEncoder = Future<Uint8List?> Function(PhotoPixels pixels, int side, int maxBytes);

Future<Uint8List?> _encodeOffThread(PhotoPixels p, int side, int maxBytes) =>
    Isolate.run(() => encodeDevicePhoto(p, side: side, maxBytes: maxBytes));

/// PhotoCropScreen "Gửi": crop → [side]² baseline JPEG ≤ max bytes (quality 85 → 70 → 55 → 40) → POST /api/photos
/// → keep a copy under the name the device gave it. With the library (R-AK-1): the photo goes into the library first
/// (the app is the memory); a firmware that points at the library gets it as its cache's newest (R-AK-3), the oldest
/// cached one leaving for it.
class SendPhotoUseCase {
  SendPhotoUseCase({
    required DeviceRepository device,
    required PhotoRepository photos,
    PhotoEncoder? encode,
    PhotoLibraryRepository? library,
    PhotoSourceUseCase? source,
  }) : _device = device,
       _photos = photos,
       _encode = encode ?? _encodeOffThread,
       _library = library,
       _source = source;

  final DeviceRepository _device;
  final PhotoRepository _photos;
  final PhotoEncoder _encode;
  final PhotoLibraryRepository? _library;
  final PhotoSourceUseCase? _source;

  /// Share of the progress bar spent compressing (the spec's "sending" includes it).
  static const encodeShare = 0.1;

  /// [onProgress] 0…1 over compress + upload. Errors ([AppError.kind]): `photoTooBig` (nothing fits, not sent),
  /// `photoFull`, `photoNoSpace`, `photoRejected` (device code in detail; also an unreadable image),
  /// `unreachable` (offline), `unauthorized`, `cancelled`, `http`.
  Future<Result<SentPhoto>> call(
    PhotoPixels pixels, {
    int side = PhotoInfo.defaultSide,
    int maxBytes = PhotoInfo.defaultMaxBytes,
    void Function(double)? onProgress,
    CancelToken? cancel,
  }) async {
    onProgress?.call(0);
    Uint8List? jpeg;
    try {
      jpeg = await _encode(pixels, side, maxBytes);
    } catch (e) {
      // Pixels that do not match their size (RangeError / ArgumentError) or an encoder failure.
      return Result.error(AppError(AppErrorKind.photoRejected, detail: '$e'));
    }
    if (jpeg == null) return const Result.error(AppError(AppErrorKind.photoTooBig, detail: 'too_big'));
    if (cancel?.cancelled ?? false) return const Result.error(AppError(AppErrorKind.cancelled));
    onProgress?.call(encodeShare);
    void upload(double p) => onProgress?.call(encodeShare + (1 - encodeShare) * p);
    final library = _library, source = _source;
    if (library != null && source != null && source.supported) {
      final added = await library.add(jpeg);
      if (added is Error<LibraryPhoto>) return Result.error(added.error);
      final id = (added as Ok<LibraryPhoto>).value.id;
      final r = await source.syncCache(forId: id, onProgress: upload);
      final sent = r is Ok<SentPhoto?> ? r.value : null;
      if (sent == null) {
        await library.remove(id); // not on the device: as before, nothing was sent
        return r is Error<SentPhoto?> ? Result.error(r.error) : const Result.error(AppError(AppErrorKind.photoFull));
      }
      await _photos.saveCopy(sent.name, jpeg);
      return Result.ok(sent);
    }
    final r = await _device.uploadPhoto(jpeg, cancel: cancel, onProgress: upload);
    if (r is Ok<SentPhoto> && r.value.name.isNotEmpty) {
      await _photos.saveCopy(r.value.name, jpeg);
      await library?.add(jpeg, cachedAs: r.value.name);
    }
    return r;
  }
}
