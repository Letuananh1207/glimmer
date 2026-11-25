// Skill Ảnh (design 2026-11-25.4, screen_specs §7 PhotoCropScreen).
import 'dart:isolate';
import 'dart:typed_data';

import '../../data/repositories/device/device_repository.dart';
import '../../data/repositories/photo/photo_repository.dart';
import '../../utils/cancel_token.dart';
import '../../utils/result.dart';
import '../models/app_error.dart';
import '../models/device_photo.dart';
import '../rules/photo_rules.dart';

typedef PhotoEncoder = Future<Uint8List?> Function(PhotoPixels pixels, int side, int maxBytes);

Future<Uint8List?> _encodeOffThread(PhotoPixels p, int side, int maxBytes) =>
    Isolate.run(() => encodeDevicePhoto(p, side: side, maxBytes: maxBytes));

/// PhotoCropScreen "Gửi": crop → [side]² baseline JPEG ≤ max bytes (quality 85 → 70 → 55 → 40) → POST /api/photos
/// → keep a copy under the name the device gave it.
class SendPhotoUseCase {
  SendPhotoUseCase({required DeviceRepository device, required PhotoRepository photos, PhotoEncoder? encode})
      : _device = device,
        _photos = photos,
        _encode = encode ?? _encodeOffThread;

  final DeviceRepository _device;
  final PhotoRepository _photos;
  final PhotoEncoder _encode;

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
    final r = await _device.uploadPhoto(jpeg,
        cancel: cancel, onProgress: (p) => onProgress?.call(encodeShare + (1 - encodeShare) * p));
    if (r is Ok<SentPhoto> && r.value.name.isNotEmpty) await _photos.saveCopy(r.value.name, jpeg);
    return r;
  }
}
