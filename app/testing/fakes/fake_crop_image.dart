import 'dart:typed_data';
import 'dart:ui';

import 'package:glimmer_app/domain/models/device_photo.dart';
import 'package:glimmer_app/ui/photo_crop/view_models/photo_crop_view_model.dart';

/// A decoded image of [width] × [height] with no pixels (renders zeros); remembers what was rendered.
class FakeCropImage implements CropImage {
  FakeCropImage(this.width, this.height);

  @override
  final int width, height;
  final rendered = <Rect>[];
  bool disposed = false;

  @override
  Image? get image => null;

  @override
  Future<PhotoPixels> render(Rect src, int side) async {
    rendered.add(src);
    return PhotoPixels(Uint8List(side * side * 4), side, side);
  }

  @override
  void dispose() => disposed = true;
}
