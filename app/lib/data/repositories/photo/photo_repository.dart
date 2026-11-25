import 'dart:typed_data';

import '../../../domain/models/device_photo.dart';
import '../../../utils/result.dart';

export '../../../domain/models/device_photo.dart' show PhotoSource;

/// The phone side of skill Ảnh: picking a photo, and the copies of the photos this app sent (the device cannot
/// send its photos back, so these are the Ảnh tab's thumbnails). A copy is keyed by the device file name and only
/// counts while the device still has a photo of that name **and** size (another phone may reuse "p3.jpg").
abstract class PhotoRepository {
  /// Pick from the gallery or take one with the camera app; Ok(null) = the user backed out.
  Future<Result<Uint8List?>> pick(PhotoSource source);

  /// A photo picked before Android killed the app (call once at start of the Ảnh flow); null = none.
  Future<Uint8List?> retrieveLost();

  /// The copy of [photo], or null ("không có bản xem").
  Future<Uint8List?> copyOf(DevicePhoto photo);

  /// Keep [jpeg] as the copy of device photo [name] (replaces an older one).
  Future<void> saveCopy(String name, Uint8List jpeg);

  Future<void> removeCopy(String name);

  /// Drop copies of photos the device no longer has.
  Future<void> prune(Iterable<String> onDevice);
}
