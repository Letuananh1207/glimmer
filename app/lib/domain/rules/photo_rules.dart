// Skill Ảnh: turning a crop into what the device takes, and its answers (docs/testing/quy_tac.md §7, screen_specs §7).
import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../../utils/json.dart';
import '../models/app_error.dart';
import '../models/device_photo.dart';

/// JPEG qualities tried in turn until the file fits the device limit (screen_specs §7: lower step by step,
/// `tooBig` only when every step is still too large).
const photoQualitySteps = [85, 70, 55, 40];

/// Scale [pixels] to [side] × [side] (centre-crop when not square) and encode a **baseline** JPEG (SOF0, which is
/// all the device decodes) at the first quality of [photoQualitySteps] that is ≤ [maxBytes]; null = still too big.
/// Pure and synchronous — run it off the UI thread (`Isolate.run`).
Uint8List? encodeDevicePhoto(
  PhotoPixels pixels, {
  int side = PhotoInfo.defaultSide,
  int maxBytes = PhotoInfo.defaultMaxBytes,
}) {
  var image = img.Image.fromBytes(
    width: pixels.width,
    height: pixels.height,
    bytes: pixels.rgba.buffer,
    bytesOffset: pixels.rgba.offsetInBytes,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  if (image.width != image.height) {
    final s = image.width < image.height ? image.width : image.height;
    image = img.copyCrop(image, x: (image.width - s) ~/ 2, y: (image.height - s) ~/ 2, width: s, height: s);
  }
  if (image.width != side) {
    image = img.copyResize(image, width: side, height: side, interpolation: img.Interpolation.average);
  }
  // The device panel has no alpha: flatten onto black (the Photo channel's background).
  if (image.hasAlpha) image = image.convert(numChannels: 3, alpha: 255);
  for (final q in photoQualitySteps) {
    final jpeg = img.encodeJpg(image, quality: q);
    if (jpeg.length <= maxBytes) return jpeg;
  }
  return null;
}

/// The device's `error` code from POST /api/photos → why it failed.
AppErrorKind photoErrorKind(String code) => switch (code) {
      'full' => AppErrorKind.photoFull,
      'too_big' => AppErrorKind.photoTooBig,
      'no_space' => AppErrorKind.photoNoSpace,
      'not_jpeg' || 'progressive' || 'bad_size' || 'truncated' || 'empty' || 'field' => AppErrorKind.photoRejected,
      _ => AppErrorKind.http,
    };

/// The `error` code in an error answer body (`{"error":"full","count":8}`); '' when there is none.
String photoErrorCode(String body) {
  try {
    final j = jsonDecode(body);
    return j is Map ? jsonStr(j['error']) : '';
  } on FormatException {
    return '';
  }
}
