// Photos of the `photo` skill on the device (GET /api/photos, src/core/web.cpp in the firmware).
import 'dart:typed_data';

import '../../utils/json.dart';

/// Where a new photo comes from (`PhotoSourceSheet`).
enum PhotoSource { gallery, camera }

/// One photo stored on the device ("p3.jpg", bytes).
class DevicePhoto {
  const DevicePhoto(this.name, this.size);

  factory DevicePhoto.fromJson(Map<String, dynamic> j) => DevicePhoto(jsonStr(j['name']), jsonInt(j['size']));

  /// File name on the device — the id for delete and for the app's local copy.
  final String name;
  final int size;

  @override
  bool operator ==(Object other) => other is DevicePhoto && other.name == name && other.size == size;

  @override
  int get hashCode => Object.hash(name, size);

  @override
  String toString() => 'DevicePhoto($name, $size)';
}

/// GET /api/photos: the photos in device order + the limits.
class PhotoInfo {
  const PhotoInfo({
    this.photos = const [],
    this.free = 0,
    this.maxCount = defaultMaxCount,
    this.maxBytes = defaultMaxBytes,
    this.side = defaultSide,
  });

  factory PhotoInfo.fromJson(Map<String, dynamic> j) => PhotoInfo(
        photos: List.unmodifiable((j['photos'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(DevicePhoto.fromJson)
            .where((p) => p.name.isNotEmpty)),
        free: jsonInt(j['free']),
        maxCount: jsonInt(j['max_count'], defaultMaxCount),
        maxBytes: jsonInt(j['max_bytes'], defaultMaxBytes),
        side: jsonInt(j['side'], defaultSide),
      );

  /// Firmware limits (`Photos::kMax`, `kMaxBytes`, `kSide`) — used when the device does not say.
  static const defaultMaxCount = 8;
  static const defaultMaxBytes = 40960;
  static const defaultSide = 188;

  /// Device order (= order of the Photo channel's slides).
  final List<DevicePhoto> photos;

  /// Free bytes on the device filesystem (after its reserve).
  final int free;
  final int maxCount;

  /// Largest JPEG the device takes.
  final int maxBytes;

  /// The device shows photos at exactly side × side px.
  final int side;

  int get count => photos.length;

  /// Places left ("còn 3 chỗ"), never negative.
  int get left => count >= maxCount ? 0 : maxCount - count;
  bool get full => count >= maxCount;
}

/// A device photo plus the app's copy of it (sent from this phone); [preview] null = "không có bản xem".
class GalleryPhoto {
  const GalleryPhoto(this.photo, this.preview);

  final DevicePhoto photo;

  /// The JPEG the app sent (same name and size as on the device), for the thumbnail.
  final Uint8List? preview;

  String get name => photo.name;
}

/// What the Ảnh tab shows: the device list with previews, and its limits.
class PhotoGallery {
  const PhotoGallery(this.info, this.items);

  final PhotoInfo info;

  /// Device order.
  final List<GalleryPhoto> items;
}

/// A cropped square, as raw RGBA pixels (width × height × 4 bytes, row-major). Any size: it is scaled to the
/// device side; a non-square image is centre-cropped.
class PhotoPixels {
  const PhotoPixels(this.rgba, this.width, this.height);

  final Uint8List rgba;
  final int width, height;
}

/// A photo the device took (POST /api/photos).
class SentPhoto {
  const SentPhoto(this.name, this.count, this.bytes);

  /// File name the device gave it.
  final String name;

  /// Photos on the device now.
  final int count;

  /// The JPEG that was sent.
  final int bytes;
}
