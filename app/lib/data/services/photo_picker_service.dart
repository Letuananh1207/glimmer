import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// The system photo picker / camera app (image_picker; no extra Android permission — the camera runs in the
/// system camera app through MediaStore.ACTION_IMAGE_CAPTURE).
class PhotoPickerService {
  PhotoPickerService() : _picker = ImagePicker();

  final ImagePicker _picker;

  /// Largest side the picker hands back (it scales down bigger photos) — the crop screen needs no more.
  static const maxSide = 2048.0;

  /// Bytes of the picked / taken photo (JPEG, PNG… as the system gives it); null when the user backed out.
  Future<Uint8List?> pick({required bool camera}) async {
    final f = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: maxSide,
      maxHeight: maxSide,
      requestFullMetadata: false,
    );
    return f?.readAsBytes();
  }

  /// Android may kill the app while the camera / picker is open: the photo comes back on the next start.
  Future<Uint8List?> retrieveLost() async {
    final r = await _picker.retrieveLostData();
    final f = r.isEmpty ? null : r.file;
    return f?.readAsBytes();
  }
}
