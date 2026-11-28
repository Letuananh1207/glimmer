import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../../../data/repositories/photo/photo_repository.dart';
import '../../../domain/models/app_error.dart';
import '../../../domain/models/device_photo.dart';
import '../../../domain/use_cases/send_photo_use_case.dart';
import '../../../utils/cancel_token.dart';
import '../../../utils/result.dart';
import '../../../utils/safe_notifier.dart';

/// What PhotoCrop shows (screen_specs §7 `state`, plus [loading] / [unreadable] before the image is ready).
enum CropStatus { loading, unreadable, crop, sending, done, full, tooBig, noSpace, rejected, offline }

/// A decoded picked image: its size (pixels, already upright), the [image] the View paints (null in tests), and
/// [render] = draw region [src] scaled to a [side]² square of raw RGBA.
abstract class CropImage {
  int get width;
  int get height;
  ui.Image? get image;
  Future<PhotoPixels> render(ui.Rect src, int side);
  void dispose();
}

typedef CropDecoder = Future<CropImage> Function(Uint8List bytes);

/// Flutter's codec (JPEG, PNG, HEIC… whatever the phone decodes), long side capped at [maxSide] so a 12 MP photo does
/// not hold ~48 MB while it is cropped.
Future<CropImage> decodeCropImage(Uint8List bytes, {int maxSide = 2048}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final codec = await ui.instantiateImageCodecWithSize(buffer, getTargetSize: (w, h) {
    final long = math.max(w, h);
    if (long <= maxSide) return ui.TargetImageSize(width: w, height: h);
    return ui.TargetImageSize(width: (w * maxSide / long).round(), height: (h * maxSide / long).round());
  });
  try {
    return _UiCropImage((await codec.getNextFrame()).image);
  } finally {
    codec.dispose();
  }
}

class _UiCropImage implements CropImage {
  _UiCropImage(this.image);

  @override
  final ui.Image image;

  @override
  int get width => image.width;

  @override
  int get height => image.height;

  @override
  Future<PhotoPixels> render(ui.Rect src, int side) async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawImageRect(image, src, ui.Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()),
        ui.Paint()..filterQuality = ui.FilterQuality.high);
    final picture = recorder.endRecording();
    final out = await picture.toImage(side, side);
    picture.dispose();
    try {
      final data = await out.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (data == null) throw const AppError(AppErrorKind.photoRejected, detail: 'render');
      return PhotoPixels(data.buffer.asUint8List(), side, side);
    } finally {
      out.dispose();
    }
  }

  @override
  void dispose() => image.dispose();
}

/// Cắt ảnh (screen_specs §7): square crop by drag / pinch (the image always covers the frame), live device preview,
/// send with progress and cancel, then done or one of five errors (the crop is kept).
class PhotoCropViewModel extends ChangeNotifier with SafeNotifier {
  PhotoCropViewModel({
    required Uint8List image,
    required PhotoInfo info,
    required SendPhotoUseCase send,
    required PhotoRepository photos,
    this.library = false,
    CropDecoder? decode,
  })  : _info = info,
        _count = info.count,
        _send = send,
        _photos = photos,
        _decode = decode ?? decodeCropImage {
    _open(image);
  }

  final PhotoInfo _info;

  /// Kho ảnh (design 2026-11-28.11): "Thêm vào kho" hands the crop to the Ảnh tab ([cropped]) instead of sending.
  final bool library;
  final SendPhotoUseCase _send;
  final PhotoRepository _photos;
  final CropDecoder _decode;

  /// Largest zoom: the crop square down to 1/[maxZoom] of the image's short side.
  static const maxZoom = 8.0;

  CropImage? _img;
  CropStatus _status = CropStatus.loading;
  double _left = 0, _top = 0, _side = 1;
  double _progress = 0;
  SentPhoto? _sent;
  int _count;
  CancelToken? _cancel;

  /// Bumped on cancel / new image: answers of an older send or decode are dropped.
  int _gen = 0;

  CropStatus get status => _status;
  CropImage? get image => _img;

  /// The crop square in image pixels.
  ui.Rect get crop => ui.Rect.fromLTWH(_left, _top, _side, _side);

  /// Sending: 0…1 (compress + upload).
  double get progress => _progress;

  /// Done: what the device said.
  SentPhoto? get sent => _sent;

  int get maxCount => _info.maxCount;

  /// Photos on the device once this one is in — the preview's "6/6" meta (device shows index/count).
  int get previewCount => _status == CropStatus.done ? _count : math.min(_count + 1, _info.maxCount);

  bool get isError => switch (_status) {
        CropStatus.full || CropStatus.tooBig || CropStatus.noSpace || CropStatus.rejected || CropStatus.offline => true,
        _ => false,
      };

  /// The crop can move only while nothing is being sent or shown as sent.
  bool get canEdit => _status == CropStatus.crop || isError;

  Future<void> _open(Uint8List bytes) async {
    final gen = ++_gen;
    _status = CropStatus.loading;
    notifyListeners();
    CropImage? img;
    try {
      img = await _decode(bytes);
    } catch (_) {
      img = null;
    }
    if (gen != _gen || disposed) {
      img?.dispose();
      return;
    }
    _img?.dispose();
    _img = img;
    if (img == null || img.width <= 0 || img.height <= 0) {
      _status = CropStatus.unreadable;
    } else {
      _status = CropStatus.crop;
      _resetCrop();
    }
    notifyListeners();
  }

  /// Centre square of the short side (smallest zoom).
  void _resetCrop() {
    final img = _img!;
    _side = math.min(img.width, img.height).toDouble();
    _left = (img.width - _side) / 2;
    _top = (img.height - _side) / 2;
  }

  double get _shortSide => math.min(_img!.width, _img!.height).toDouble();

  void _clamp() {
    final img = _img!;
    _side = _side.clamp(_shortSide / maxZoom, _shortSide);
    _left = _left.clamp(0, img.width - _side);
    _top = _top.clamp(0, img.height - _side);
  }

  /// Drag by [delta] screen points over a frame [frame] points wide: the image follows the finger.
  void pan(ui.Offset delta, double frame) {
    if (_img == null || !canEdit) return;
    final k = _side / frame;
    _left -= delta.dx * k;
    _top -= delta.dy * k;
    _clamp();
    notifyListeners();
  }

  /// Pinch by [factor] (> 1 = zoom in) around [focal] (points from the frame's top-left), keeping the image point
  /// under the fingers still.
  void zoom(double factor, ui.Offset focal, double frame) {
    if (_img == null || !canEdit || factor <= 0) return;
    final px = _left + focal.dx * _side / frame;
    final py = _top + focal.dy * _side / frame;
    _side = (_side / factor).clamp(_shortSide / maxZoom, _shortSide);
    _left = px - focal.dx * _side / frame;
    _top = py - focal.dy * _side / frame;
    _clamp();
    notifyListeners();
  }

  /// "Gửi ảnh" / "Thử lại".
  Future<void> send() async {
    final img = _img;
    if (img == null || !canEdit) return;
    final gen = ++_gen;
    final cancel = _cancel = CancelToken();
    _status = CropStatus.sending;
    _progress = 0;
    notifyListeners();
    Result<SentPhoto> r;
    try {
      final pixels = await img.render(crop, _info.side);
      if (gen != _gen) return;
      r = await _send(pixels, side: _info.side, maxBytes: _info.maxBytes, cancel: cancel, onProgress: (p) {
        if (gen != _gen) return;
        _progress = p;
        notifyListeners();
      });
    } catch (e) {
      r = Result.error(AppError(AppErrorKind.photoRejected, detail: '$e'));
    }
    if (gen != _gen) return;
    _cancel = null;
    switch (r) {
      case Ok(:final value):
        _sent = value;
        if (value.count > 0) _count = value.count;
        _status = CropStatus.done;
      case Error(:final error):
        _status = statusOf(AppError.from(error));
    }
    notifyListeners();
  }

  /// "Thêm vào kho": the crop as [PhotoInfo.side]² pixels for the Ảnh tab to add; null = not ready / unreadable.
  Future<PhotoPixels?> cropped() async {
    final img = _img;
    if (img == null || !canEdit) return null;
    try {
      return await img.render(crop, _info.side);
    } catch (_) {
      return null;
    }
  }

  /// Error kind → the screen state that explains it (screen_specs §7). Cancelled → back to cropping.
  static CropStatus statusOf(AppError e) => switch (e.kind) {
        AppErrorKind.photoFull => CropStatus.full,
        AppErrorKind.photoTooBig => CropStatus.tooBig,
        AppErrorKind.photoNoSpace => CropStatus.noSpace,
        AppErrorKind.unreachable => CropStatus.offline,
        AppErrorKind.cancelled => CropStatus.crop,
        _ => CropStatus.rejected,
      };

  /// "Huỷ" while sending: stop at once (the upload aborts) and go back to cropping.
  void cancel() {
    _cancel?.cancel();
    _cancel = null;
    _gen++;
    _status = CropStatus.crop;
    _progress = 0;
    notifyListeners();
  }

  /// "Cắt lại" / "Huỷ" on an error: back to cropping, same crop.
  void backToCrop() {
    if (!isError) return;
    _status = CropStatus.crop;
    notifyListeners();
  }

  /// "Chọn ảnh khác" / "Thêm ảnh khác": the system photo picker. Ok(true) = a new image is being opened,
  /// Ok(false) = the user backed out (nothing changes).
  Future<Result<bool>> pickOther() async {
    final r = await _photos.pick(PhotoSource.gallery);
    switch (r) {
      case Error(:final error):
        return Result.error(error);
      case Ok(:final value):
        if (value == null) return const Result.ok(false);
        _sent = null;
        await _open(value);
        return const Result.ok(true);
    }
  }

  @override
  void dispose() {
    _cancel?.cancel();
    _gen++;
    _img?.dispose();
    super.dispose();
  }
}
