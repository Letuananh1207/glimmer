import 'dart:typed_data';

import 'package:glimmer_app/data/repositories/backup/backup_repository.dart';
import 'package:glimmer_app/data/repositories/device/device_repository_local.dart';
import 'package:glimmer_app/data/repositories/location/location_repository.dart';
import 'package:glimmer_app/data/repositories/photo/photo_library_repository.dart';
import 'package:glimmer_app/data/repositories/photo/photo_server_repository.dart';
import 'package:glimmer_app/data/repositories/release/release_repository.dart';
import 'package:glimmer_app/domain/models/app_error.dart';
import 'package:glimmer_app/domain/models/config_backup.dart';
import 'package:glimmer_app/domain/models/library_photo.dart';
import 'package:glimmer_app/domain/models/release.dart';
import 'package:glimmer_app/domain/models/weather_location.dart';
import 'package:glimmer_app/utils/result.dart';

import 'fake_services.dart';

/// A real [DeviceRepositoryLocal] over fake services — the ViewModel tests drive the device through
/// [api] (answers) and [wifi] (phone Wi-Fi), with instant delays.
class DeviceRig {
  DeviceRig._(this.api, this.nsd, this.wifi, this.delay, this.repo, this.cursor);

  final FakeDeviceApiService api;
  final FakeCursorService cursor;
  final FakeDiscoveryService nsd;
  final FakeWifiService wifi;
  final FakeDelay delay;
  final DeviceRepositoryLocal repo;

  static Future<DeviceRig> create({Map<String, Object> saved = const {}}) async {
    final api = FakeDeviceApiService(), nsd = FakeDiscoveryService(), wifi = FakeWifiService();
    final delay = FakeDelay();
    final cursor = FakeCursorService();
    final repo = DeviceRepositoryLocal(
      api: api,
      discovery: nsd,
      store: await fakeStore(saved),
      wifi: wifi,
      cursor: cursor,
      delay: delay.call,
      pollEvery: const Duration(hours: 1),
    );
    return DeviceRig._(api, nsd, wifi, delay, repo, cursor);
  }

  /// Device answering at [url] with [state]; connected.
  Future<void> connect(String url, [Map<String, dynamic> state = const {'fw': '1.0', 'wifi': 'connected'}]) async {
    api.device(url, state);
    await repo.connectTo(url);
    await repo.refresh();
  }

  List<ApiCall> posts([String? path]) =>
      api.calls.where((c) => c.method == 'POST' && (path == null || c.path == path)).toList();
}

class FakeReleaseRepository implements ReleaseRepository {
  Result<Release> latestAnswer = Result.ok(Release(DateTime(2026, 11, 25, 12), 'abc1234', const {
    'firmware.bin': 'https://x/firmware.bin',
    'littlefs.bin': 'https://x/littlefs.bin',
  }));
  final downloaded = <String>[];

  @override
  String get repo => 'owner/glimmer';

  @override
  Future<Result<Release>> latest() async => latestAnswer;

  @override
  Future<Result<Uint8List>> download(Release release, String name, {void Function(double)? onProgress}) async {
    downloaded.add(name);
    onProgress?.call(1);
    return Result.ok(Uint8List(4));
  }
}

class FakeBackupRepository implements BackupRepository {
  final saved = <Map<String, dynamic>>[];
  final shared = <String>[];
  Result<ConfigBackup?> pickAnswer = const Result.ok(null);

  @override
  Future<Result<String>> save(Map<String, dynamic> config) async {
    saved.add(config);
    return const Result.ok('/docs/glimmer-config.json');
  }

  @override
  Future<Result<void>> share(String path, String text) async {
    shared.add(path);
    return const Result.ok(null);
  }

  @override
  Future<Result<ConfigBackup?>> pick() async => pickAnswer;

  static Result<ConfigBackup?> invalid() =>
      const Result.error(AppError(AppErrorKind.invalidBackup, detail: 'no wifi_ssid'));
}

/// [LocationRepository] with scripted answers; [searches] / [gpsCalls] record what was asked.
class FakeLocationRepository implements LocationRepository {
  GpsOutcome gpsAnswer = const GpsOutcome.failed(GpsFailure.failed);
  Result<List<PlaceResult>> searchAnswer = const Result.ok([]);
  final searches = <String>[];
  int gpsCalls = 0, appSettings = 0, locationSettings = 0;

  @override
  Future<GpsOutcome> currentPlace() async {
    gpsCalls++;
    return gpsAnswer;
  }

  @override
  Future<Result<List<PlaceResult>>> search(String query) async {
    searches.add(query);
    return searchAnswer;
  }

  @override
  Future<void> openAppSettings() async => appSettings++;

  @override
  Future<void> openLocationSettings() async => locationSettings++;
}


/// The phone's photo library in memory (R-AK-1).
class FakePhotoLibraryRepository implements PhotoLibraryRepository {
  final photos = <LibraryPhoto>[];
  final jpegs = <int, Uint8List>{};
  var _next = 1;
  var _clock = DateTime(2026, 11, 28, 9);

  @override
  Future<List<LibraryPhoto>> list() async => List.of(photos);

  @override
  Future<Result<LibraryPhoto>> add(Uint8List jpeg, {String? cachedAs}) async {
    _clock = _clock.add(const Duration(minutes: 1));
    final p = LibraryPhoto(id: _next++, added: _clock, size: jpeg.length, cachedAs: cachedAs);
    photos.add(p);
    jpegs[p.id] = jpeg;
    return Result.ok(p);
  }

  @override
  Future<void> remove(int id) async {
    photos.removeWhere((p) => p.id == id);
    jpegs.remove(id);
  }

  @override
  Future<LibraryPhoto?> byDeviceName(String deviceName) async =>
      photos.where((p) => p.cachedAs == deviceName).firstOrNull;

  @override
  Future<Uint8List?> bytes(int id) async => jpegs[id];

  @override
  Future<void> setCached(int id, String? deviceName) async {
    final i = photos.indexWhere((p) => p.id == id);
    if (i >= 0) photos[i] = photos[i].withCache(deviceName);
  }
}

/// R-AK-4 without a socket: "serves" on the port asked.
class FakePhotoServerRepository implements PhotoServerRepository {
  @override
  bool running = false;
  @override
  int port = 0;

  @override
  Future<int> start({required int port, required String key, required Future<ServedPhoto?> Function(int after) next}) async {
    running = true;
    return this.port = port;
  }

  @override
  Future<void> stop() async {
    running = false;
    port = 0;
  }
}
