// The device points at the app's photo library (R-AK-*, app plan docs/tasks/2026-11-27-kho-anh-tren-app.md;
// firmware src/data/photo_source_core.h).
import 'dart:async';

import '../../data/repositories/device/device_repository.dart';
import '../../data/repositories/photo/photo_library_repository.dart';
import '../../data/repositories/photo/photo_server_repository.dart';
import '../../utils/result.dart';
import '../models/app_error.dart';
import '../models/device_photo.dart';
import '../models/library_photo.dart';
import '../rules/library_rules.dart';

/// The phone's IPv4 addresses (NetworkInterface in the app, a list in tests).
typedef PhoneIps = Future<List<String>> Function();

/// Serves the library on the home network and tells the device where it is (R-AK-4); keeps the device's cache = the
/// newest [cacheMax] photos of the library (R-AK-3). Firmware without `photo_source` → nothing (R-AK-5).
class PhotoSourceUseCase {
  PhotoSourceUseCase({
    required DeviceRepository device,
    required PhotoLibraryRepository library,
    required PhotoServerRepository server,
    required PhoneIps phoneIps,
    String? key,
  }) : _device = device,
       _library = library,
       _server = server,
       _phoneIps = phoneIps,
       key = key ?? newServeKey();

  final DeviceRepository _device;
  final PhotoLibraryRepository _library;
  final PhotoServerRepository _server;
  final PhoneIps _phoneIps;

  /// R-AK-4: this run's key in the library's URLs.
  final String key;

  Timer? _stopTimer;

  /// R-AK-5: the connected firmware points at a library.
  bool get supported => _device.connected && (_device.state?.photoSourceApi ?? false);

  /// R-AK-2: "the photo after [after]" for the device.
  Future<ServedPhoto?> next(int after) async {
    final n = nextAfter(await _library.list(), after);
    if (n == null) return null;
    final jpeg = await _library.bytes(n.photo.id);
    if (jpeg == null) return null;
    return ServedPhoto(id: n.photo.id, index: n.index, count: n.count, jpeg: jpeg);
  }

  /// The app is on screen (opened, back from the background, device connected): serve the library, tell the device
  /// where it is, bring its cache up to date.
  Future<Result<void>> sync() async {
    _stopTimer?.cancel();
    _stopTimer = null;
    if (!supported) return const Result.ok(null);
    final int port;
    try {
      port = await _server.start(port: photoServerPort, key: key, next: next);
    } on Exception catch (e) {
      return Result.error(AppError.from(e));
    }
    final host = phoneHostFor(_hostOf(_device.url), await _safeIps());
    if (host == null) return const Result.error(AppError(AppErrorKind.unreachable, detail: 'no phone ip'));
    final r = await _device.setPhotoSource(sourceBody(host, port, key));
    if (r is Error<void>) return r;
    final c = await syncCache();
    return c is Error<SentPhoto?> ? Result.error(c.error) : const Result.ok(null);
  }

  /// R-AK-4: the app left the screen — keep serving [serveAfterPause], then stop (the device shows its cache).
  void paused() {
    _stopTimer?.cancel();
    _stopTimer = Timer(serveAfterPause, () => unawaited(_server.stop()));
  }

  /// R-AK-3: delete library photos that left the newest from the device, upload the newest missing (newest first).
  /// Stops at the first upload the device refuses (full / no space): the newest got the room. Ok = the upload of
  /// [forId] when it was one of them (the photo just added), else null.
  Future<Result<SentPhoto?>> syncCache({int? forId, void Function(double)? onProgress}) async {
    if (!supported) return const Result.ok(null);
    final info = await _device.photos();
    if (info is Error<PhotoInfo>) return Result.error(info.error);
    final plan = cachePlan(await _library.list(), (info as Ok<PhotoInfo>).value.photos.map((p) => p.name));
    for (final name in plan.delete) {
      final d = await _device.deletePhoto(name);
      final gone = d is Error<int> && d.error is AppError && (d.error as AppError).kind == AppErrorKind.photoNotFound;
      if (d is Ok || gone) {
        final p = await _library.byDeviceName(name);
        if (p != null) await _library.setCached(p.id, null);
      }
    }
    SentPhoto? sent;
    for (final p in plan.upload) {
      final jpeg = await _library.bytes(p.id);
      if (jpeg == null) continue;
      final u = await _device.uploadPhoto(jpeg, onProgress: p.id == forId ? onProgress : null);
      if (u is Error<SentPhoto>) {
        if (p.id == forId) return Result.error(u.error);
        break;
      }
      final s = (u as Ok<SentPhoto>).value;
      await _library.setCached(p.id, s.name);
      if (p.id == forId) sent = s;
    }
    return Result.ok(sent);
  }

  Future<List<String>> _safeIps() async {
    try {
      return await _phoneIps();
    } on Exception {
      return const [];
    }
  }

  static String _hostOf(String url) => Uri.tryParse(url)?.host ?? '';
}
