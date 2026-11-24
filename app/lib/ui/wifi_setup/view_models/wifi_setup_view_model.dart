import 'package:flutter/foundation.dart';

import '../../../data/repositories/device/device_repository.dart';
import '../../../domain/models/app_error.dart';
import '../../../utils/result.dart';
import '../../../utils/safe_notifier.dart';

enum WifiStep { form, working, done, failed }

/// What the working / done screen says.
enum WifiStatus { direct, joinAp, send, wait, done, failed }

/// Put the display on a Wi-Fi network (R-WF-1..3).
///
/// If the display is reachable (it's online here, or the phone is on its setup AP) the new network is
/// sent directly. Otherwise the phone joins "glimmer-setup" just for this app (Android asks to confirm
/// once), sends the network, lets go, and looks for the display on the normal Wi-Fi.
class WifiSetupViewModel extends ChangeNotifier with SafeNotifier {
  WifiSetupViewModel({required DeviceRepository device, this.findAttempts = 10, this.findGap = const Duration(seconds: 8)})
      : _device = device;

  final DeviceRepository _device;

  /// Looking for the display on the new network: tries × gap (+ the search itself) ≈ 4 min.
  final int findAttempts;
  final Duration findGap;

  WifiStep _step = WifiStep.form;
  WifiStatus _status = WifiStatus.direct;
  String _ssid = '';
  AppError? _error;
  String? _suggestedSsid;

  WifiStep get step => _step;
  bool get busy => _step == WifiStep.working;
  WifiStatus get status => _status;

  /// The network being sent.
  String get ssid => _ssid;

  /// Why it failed ([WifiStep.failed]).
  AppError? get error => _error;

  /// IP of the display once it is back ([WifiStep.done]).
  String get ip => _device.state?.ip ?? '';

  /// The phone's current Wi-Fi, to prefill the name (R-WF-3); null until known.
  String? get suggestedSsid => _suggestedSsid;

  Future<void> prefill() async {
    await _device.ensureWifiPermissions();
    final s = await _device.phoneSsid();
    if (s != null && s != DeviceRepository.setupApSsid) {
      _suggestedSsid = s;
      notifyListeners();
    }
  }

  void _say(WifiStatus s) {
    _status = s;
    notifyListeners();
  }

  void backToForm() {
    _step = WifiStep.form;
    notifyListeners();
  }

  Future<void> send(String ssid, String password) async {
    final name = ssid.trim();
    if (name.isEmpty || busy) return;
    _ssid = name;
    _error = null;
    _step = WifiStep.working;
    notifyListeners();
    var viaAp = false;
    try {
      // 1. Reachable here? Only when it actually answers now — a display that already left this
      //    network would swallow the request, and its silence would look like the reboot that
      //    follows a successful save.
      final direct = _device.connected && !(_device.state?.inSetupMode ?? false) && await _device.reachable();
      String? at;
      if (direct) {
        _say(WifiStatus.direct);
      } else {
        // 2. Through the display's setup AP.
        _say(WifiStatus.joinAp);
        if (!await _device.ensureWifiPermissions()) throw const AppError(AppErrorKind.wifiPermission);
        if (!await _device.joinSetupAp()) throw const AppError(AppErrorKind.setupAp);
        viaAp = true;
        at = DeviceRepository.setupApUrl;
      }
      _say(WifiStatus.send);
      final r = await _device.saveSettings({'wifiSSID': name, 'wifiPass': password}, restart: true, at: at);
      if (r case Error(:final error)) throw error;
      if (viaAp) {
        viaAp = false;
        await _device.leaveSetupAp();
      }

      // 3. Find it on the new network.
      _say(WifiStatus.wait);
      if (!await _device.rediscover(attempts: findAttempts, gap: findGap)) {
        throw AppError(AppErrorKind.notOnNetwork, detail: name);
      }
      _step = WifiStep.done;
      _say(WifiStatus.done);
    } catch (e) {
      if (viaAp) await _device.leaveSetupAp();
      _error = AppError.from(e);
      _step = WifiStep.failed;
      _say(WifiStatus.failed);
    }
  }
}
