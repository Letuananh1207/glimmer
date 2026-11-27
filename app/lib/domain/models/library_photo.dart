// The photo library on the phone (app plan docs/tasks/2026-11-27-kho-anh-tren-app.md, R-AK-*): the app is the memory,
// the device points at it (firmware src/data/photo_source_core.h).
import 'dart:typed_data';

/// One photo of the library: a [id]-numbered baseline JPEG 188×188 ≤ 40 KB, already cropped for the device.
class LibraryPhoto {
  const LibraryPhoto({required this.id, required this.added, required this.size, this.cachedAs});

  factory LibraryPhoto.fromJson(Map<String, dynamic> j) => LibraryPhoto(
    id: (j['id'] as num?)?.toInt() ?? 0,
    added: DateTime.fromMillisecondsSinceEpoch((j['added'] as num?)?.toInt() ?? 0),
    size: (j['size'] as num?)?.toInt() ?? 0,
    cachedAs: j['cachedAs'] is String ? j['cachedAs'] as String : null,
  );

  /// ≥ 1, never reused; the device asks "the photo after id".
  final int id;
  final DateTime added;

  /// Bytes of the JPEG.
  final int size;

  /// Its file name on the device while it is in the device's cache ("p3.jpg"), else null.
  final String? cachedAs;

  LibraryPhoto withCache(String? name) => LibraryPhoto(id: id, added: added, size: size, cachedAs: name);

  Map<String, Object?> toJson() => {
    'id': id,
    'added': added.millisecondsSinceEpoch,
    'size': size,
    if (cachedAs != null) 'cachedAs': cachedAs,
  };

  @override
  bool operator ==(Object other) =>
      other is LibraryPhoto &&
      other.id == id &&
      other.added == added &&
      other.size == size &&
      other.cachedAs == cachedAs;

  @override
  int get hashCode => Object.hash(id, added, size, cachedAs);

  @override
  String toString() => 'LibraryPhoto($id, ${cachedAs ?? '-'})';
}

/// What the device gets for "the photo after X" (R-AK-2): the photo, its 1-based place and the library size.
class NextPhoto {
  const NextPhoto(this.photo, this.index, this.count);

  final LibraryPhoto photo;
  final int index, count;
}

/// "The photo after X" as the device gets it (R-AK-2): its id, place, library size and JPEG.
class ServedPhoto {
  const ServedPhoto({required this.id, required this.index, required this.count, required this.jpeg});

  final int id, index, count;
  final Uint8List jpeg;
}
