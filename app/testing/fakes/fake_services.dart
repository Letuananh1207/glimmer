import 'dart:async';
import 'dart:typed_data';

import 'package:glimmer_app/data/services/device_api_service.dart';
import 'package:glimmer_app/data/services/discovery_service.dart';
import 'package:glimmer_app/data/services/local_store_service.dart';
import 'package:glimmer_app/data/services/photo_picker_service.dart';
import 'package:glimmer_app/data/services/photo_store_service.dart';
import 'package:glimmer_app/data/services/wifi_service.dart';
import 'package:glimmer_app/utils/cancel_token.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One recorded call to the device.
class ApiCall {
  const ApiCall(this.url, this.method, this.path, this.body, this.token);
  final String url, method, path, token;
  final Object? body;
}

/// Answers by "`url` `METHOD` `path`" key: a Map, or an exception to throw. Missing key → no answer (status 0).
class FakeDeviceApiService implements DeviceApiService {
  final answers = <String, Object>{};
  final calls = <ApiCall>[];
  Object? uploadAnswer;

  /// Runs after each call is recorded, before it is answered (e.g. make the device vanish).
  void Function(ApiCall call)? onCall;

  /// While set, POSTs wait for it (to see a "sending…" state).
  Completer<void>? holdPosts;

  /// While set, DELETEs wait for it (to see a "deleting…" state).
  Completer<void>? holdDeletes;

  /// While set, [uploadFile] waits for it after reporting half the bytes (to see a "sending…" state).
  Completer<void>? holdUpload;

  void on(String url, String method, String path, Object answer) => answers['$url $method $path'] = answer;

  /// A device at [url] answering /api/state with [state] and /push with no cards.
  void device(String url, [Map<String, dynamic> state = const {'fw': '1.0', 'wifi': 'connected'}]) {
    on(url, 'GET', '/api/state', state);
    on(url, 'GET', '/push', {'cards': <Object>[]});
  }

  void gone(String url) => answers.removeWhere((k, _) => k.startsWith('$url '));

  @override
  Future<Map<String, dynamic>> json(String baseUrl, String method, String path,
      {String token = '', Object? body, Duration timeout = const Duration(seconds: 6), int tries = 2}) async {
    final call = ApiCall(baseUrl, method, path, body, token);
    calls.add(call);
    onCall?.call(call);
    if (method == 'POST' && holdPosts != null) await holdPosts!.future;
    if (method == 'DELETE' && holdDeletes != null) await holdDeletes!.future;
    final a = answers['$baseUrl $method $path'];
    if (a == null) throw const DeviceHttpException(0, 'TimeoutException');
    if (a is Exception) throw a;
    return Map<String, dynamic>.from(a as Map);
  }

  @override
  Future<void> upload(String baseUrl, String field, Uint8List image, {void Function(double)? onProgress}) async {
    calls.add(ApiCall(baseUrl, 'UPLOAD', field, null, ''));
    onProgress?.call(1);
    final a = uploadAnswer;
    if (a is Exception) throw a;
  }

  /// Answer of [uploadFile]: a Map, or an exception to throw (null → `{ok, name: p1.jpg, count: 1}`).
  Object? uploadFileAnswer;
  Uint8List? uploadedFile;

  @override
  Future<Map<String, dynamic>> uploadFile(String baseUrl, String path,
      {required String field,
      required String filename,
      required String contentType,
      required Uint8List bytes,
      String token = '',
      void Function(double)? onProgress,
      CancelToken? cancel,
      Duration timeout = const Duration(seconds: 30)}) async {
    calls.add(ApiCall(baseUrl, 'UPLOAD', path, field, token));
    uploadedFile = bytes;
    if (cancel?.cancelled ?? false) throw const DeviceHttpException(-1, 'cancelled');
    onProgress?.call(0.5);
    if (holdUpload != null) await holdUpload!.future;
    if (cancel?.cancelled ?? false) throw const DeviceHttpException(-1, 'cancelled');
    onProgress?.call(1);
    final a = uploadFileAnswer ?? {'ok': true, 'name': 'p1.jpg', 'count': 1};
    if (a is Exception) throw a;
    return Map<String, dynamic>.from(a as Map);
  }

  @override
  void close() {}
}

/// Photo copies in memory.
class FakePhotoStoreService implements PhotoStoreService {
  final files = <String, Uint8List>{};

  @override
  Future<List<String>> list() async => files.keys.toList();

  @override
  Future<Uint8List?> read(String name) async => files[name];

  @override
  Future<void> write(String name, Uint8List bytes) async => files[name] = bytes;

  @override
  Future<void> delete(String name) async => files.remove(name);
}

/// Picker that hands back [next] (null = the user backed out).
class FakePhotoPickerService implements PhotoPickerService {
  Uint8List? next;
  final asked = <bool>[];

  @override
  Future<Uint8List?> pick({required bool camera}) async {
    asked.add(camera);
    return next;
  }

  @override
  Future<Uint8List?> retrieveLost() async => null;
}

class FakeDiscoveryService implements DiscoveryService {
  List<String> addresses = const [];

  @override
  Future<List<String>> nsdAddresses() async => addresses;
}

class FakeWifiService implements WifiService {
  bool permissions = true;
  String? ssid;
  bool joins = true;
  final joined = <String>[];
  int left = 0;

  @override
  Future<bool> ensurePermissions() async => permissions;

  @override
  Future<String?> currentSsid() async => ssid;

  @override
  Future<bool> joinOpen(String ssid) async {
    joined.add(ssid);
    return joins;
  }

  @override
  Future<void> leave() async => left++;
}

/// A [LocalStoreService] over in-memory shared_preferences.
Future<LocalStoreService> fakeStore([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return LocalStoreService(await SharedPreferences.getInstance());
}

/// Delay that returns at once (records what was asked).
class FakeDelay {
  final asked = <Duration>[];
  Future<void> call(Duration d) async => asked.add(d);
}
