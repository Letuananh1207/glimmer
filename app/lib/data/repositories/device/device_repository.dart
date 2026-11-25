import 'package:flutter/foundation.dart';

import '../../../domain/models/app_error.dart';
import '../../../domain/models/attention_card.dart';
import '../../../domain/models/device_photo.dart';
import '../../../domain/models/device_state.dart';
import '../../../utils/cancel_token.dart';
import '../../../utils/result.dart';

/// The display the app talks to: which one, its latest state and cards, polling, and every call to it.
/// Failures come back as [Error] holding an [AppError].
abstract class DeviceRepository extends ChangeNotifier {
  static const setupApUrl = 'http://192.168.4.1';
  static const setupApSsid = 'glimmer-setup';

  bool get connected;

  /// Base URL of the connected display ('' when none).
  String get url;
  DeviceState? get state;
  List<AttentionCard> get cards;

  /// Last discover / refresh failure (null when the last one worked).
  AppError? get error;

  /// Cards could not be read because the device wants an API token (R-KN-4).
  bool get cardsNeedToken;
  bool get searching;

  /// The address that worked last time and the stored API token.
  String get savedUrl;
  String get token;

  /// GitHub repo whose `latest` release holds the firmware builds.
  String get repo;

  /// Find the display: saved address, NSD, glimmer.local, setup AP (R-KN-1).
  Future<bool> discover();

  /// Connect to an address the user typed ("192.168.1.50" or a URL).
  Future<bool> connectTo(String address, {String? token});

  /// After a reboot / network change: wait [first], then up to [attempts] × [discover], [gap] apart.
  /// [keep] keeps the current connection on screen meanwhile (polling paused) and restores it on failure.
  Future<bool> rediscover({
    Duration first = const Duration(seconds: 15),
    required int attempts,
    required Duration gap,
    bool keep = false,
  });

  void forget();
  void setToken(String token);

  Future<void> refresh();
  void startPolling();
  void stopPolling();

  /// The display answers at [url] right now (one quick try).
  Future<bool> reachable();

  Future<Result<Map<String, dynamic>>> settings();

  /// Partial settings update (camelCase keys) to the display, or to [at] (e.g. the setup AP).
  /// With [restart] the device reboots; no answer then counts as success (R-WF-2).
  Future<Result<void>> saveSettings(Map<String, dynamic> changes, {bool restart = false, String? at});

  /// Raw config.json with secrets.
  Future<Result<Map<String, dynamic>>> exportConfig();

  /// Replace config.json; the device restarts (no answer counts as success, R-WF-2).
  Future<Result<void>> importConfig(Map<String, dynamic> config, {String? at});

  Future<Result<void>> reboot();
  Future<Result<void>> refreshNow();
  Future<Result<void>> showChannel(String name);
  Future<Result<void>> clearCard(String id);
  Future<Result<void>> clearAllCards();
  Future<Result<void>> clearProjects();

  /// OTA upload ("firmware" / "filesystem"); the device reboots after it.
  Future<Result<void>> upload(String field, Uint8List image, {void Function(double)? onProgress});

  // ── photos (skill `photo`, GET / POST / DELETE /api/photos) ──

  /// Photos on the device + its limits.
  Future<Result<PhotoInfo>> photos();

  /// Send one baseline JPEG (multipart field `photo`). Errors: `photoFull`, `photoTooBig`, `photoNoSpace`,
  /// `photoRejected` (detail = device code), `unreachable` (offline), `unauthorized`, `cancelled`, `http`.
  /// [onProgress] = share of bytes sent, 0…1. Refreshes the state (`photos`) after success.
  Future<Result<SentPhoto>> uploadPhoto(Uint8List jpeg, {void Function(double)? onProgress, CancelToken? cancel});

  /// Delete photo [name]; returns the photos left. 404 → `photoNotFound`.
  Future<Result<int>> deletePhoto(String name);

  /// Wait until the display answers again (after a reboot); null after [max].
  Future<DeviceState?> waitOnline({Duration max = const Duration(minutes: 3)});

  // ── the phone's Wi-Fi, for the setup AP ──
  Future<bool> ensureWifiPermissions();
  Future<String?> phoneSsid();

  /// Join "glimmer-setup" for this app only and check the display answers there.
  Future<bool> joinSetupAp({int attempts = 3});
  Future<void> leaveSetupAp();
}
