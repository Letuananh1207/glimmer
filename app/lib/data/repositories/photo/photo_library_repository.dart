import 'dart:typed_data';

import '../../../domain/models/library_photo.dart';
import '../../../utils/result.dart';

/// The photo library on the phone (R-AK-1): every photo the user added, kept on the phone (the app is the memory);
/// the device points at it and keeps only the newest as its cache.
abstract class PhotoLibraryRepository {
  /// All photos, in slideshow order (oldest first).
  Future<List<LibraryPhoto>> list();

  /// Add [jpeg] (already a device photo: 188×188 baseline ≤ 40 KB); [cachedAs] = its device name when it is already
  /// there.
  Future<Result<LibraryPhoto>> add(Uint8List jpeg, {String? cachedAs});

  /// Remove photo [id] (the JPEG and its entry). Nothing when it is not there.
  Future<void> remove(int id);

  /// The photo whose device copy is [deviceName] ("p3.jpg"), or null.
  Future<LibraryPhoto?> byDeviceName(String deviceName);

  /// The JPEG of [id]; null when it is gone.
  Future<Uint8List?> bytes(int id);

  /// [id] is in the device cache as [deviceName] (null = not any more).
  Future<void> setCached(int id, String? deviceName);
}
