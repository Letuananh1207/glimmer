import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/app_error.dart';
import 'package:glimmer_app/domain/models/device_photo.dart';
import 'package:glimmer_app/domain/rules/photo_rules.dart';
import 'package:image/image.dart' as img;

/// [w] × [h] RGBA: smooth gradient, or noise (the worst case for JPEG size).
PhotoPixels _pixels(int w, int h, {bool noise = false}) {
  final rnd = Random(7);
  final b = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      b[i] = noise ? rnd.nextInt(256) : x * 255 ~/ w;
      b[i + 1] = noise ? rnd.nextInt(256) : y * 255 ~/ h;
      b[i + 2] = noise ? rnd.nextInt(256) : 128;
      b[i + 3] = 255;
    }
  }
  return PhotoPixels(b, w, h);
}

/// Markers before the scan: true when a baseline SOF0 (FF C0) comes before any other SOFn.
bool _baseline(Uint8List jpeg) {
  var i = 2;
  while (i + 3 < jpeg.length) {
    if (jpeg[i] != 0xFF) return false;
    final m = jpeg[i + 1];
    if (m == 0xC0) return true;
    if (m >= 0xC1 && m <= 0xCF && m != 0xC4 && m != 0xC8 && m != 0xCC) return false;
    if (m == 0xDA) return false;
    i += 2 + (jpeg[i + 2] << 8 | jpeg[i + 3]);
  }
  return false;
}

void main() {
  group('encodeDevicePhoto', () {
    void expectDeviceJpeg(Uint8List? jpeg) {
      expect(jpeg, isNotNull);
      expect(jpeg!.length, lessThanOrEqualTo(PhotoInfo.defaultMaxBytes));
      expect(jpeg.sublist(0, 2), [0xFF, 0xD8]);
      expect(_baseline(jpeg), isTrue, reason: 'the device decodes baseline (SOF0) only');
      final back = img.decodeJpg(jpeg)!;
      expect((back.width, back.height), (188, 188));
    }

    test('a large square is scaled to 188 × 188 baseline JPEG ≤ 40 KB', () {
      expectDeviceJpeg(encodeDevicePhoto(_pixels(600, 600)));
    });

    test('a non-square image is centre-cropped', () {
      expectDeviceJpeg(encodeDevicePhoto(_pixels(400, 240)));
    });

    test('noise still fits by lowering the quality step by step', () {
      final jpeg = encodeDevicePhoto(_pixels(188, 188, noise: true));
      expectDeviceJpeg(jpeg);
      final first = img.encodeJpg(img.decodeJpg(jpeg!)!, quality: photoQualitySteps.first);
      expect(first.length, greaterThan(jpeg.length), reason: 'a lower step than 85 was used');
    });

    test('nothing fits → null (tooBig)', () {
      expect(encodeDevicePhoto(_pixels(188, 188, noise: true), maxBytes: 2000), isNull);
    });

    test('pixels that do not match their size throw', () {
      expect(() => encodeDevicePhoto(PhotoPixels(Uint8List(10), 188, 188)), throwsA(anything));
    });
  });

  test('device error codes → error kinds', () {
    expect(photoErrorKind('full'), AppErrorKind.photoFull);
    expect(photoErrorKind('too_big'), AppErrorKind.photoTooBig);
    expect(photoErrorKind('no_space'), AppErrorKind.photoNoSpace);
    for (final c in ['not_jpeg', 'progressive', 'bad_size', 'truncated', 'empty', 'field']) {
      expect(photoErrorKind(c), AppErrorKind.photoRejected, reason: c);
    }
    expect(photoErrorKind('fs'), AppErrorKind.http);
    expect(photoErrorCode('{"error":"full","count":8}'), 'full');
    expect(photoErrorCode('<html>'), '');
    expect(photoErrorCode(''), '');
  });

  test('PhotoInfo from GET /api/photos', () {
    final i = PhotoInfo.fromJson({
      'photos': [
        {'name': 'p1.jpg', 'size': 20000},
        {'name': 'p3.jpg', 'size': 18000},
        {'size': 1},
      ],
      'free': 300000,
      'total': 1000000,
      'max_count': 8,
      'max_bytes': 40960,
      'reserve': 65536,
      'side': 188,
    });
    expect(i.photos, const [DevicePhoto('p1.jpg', 20000), DevicePhoto('p3.jpg', 18000)]);
    expect((i.count, i.left, i.full, i.free, i.side), (2, 6, false, 300000, 188));
    expect(PhotoInfo.fromJson(const {}).maxCount, 8);
  });
}
