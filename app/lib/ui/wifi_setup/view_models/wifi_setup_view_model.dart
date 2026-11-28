import 'package:flutter/foundation.dart';

import '../../../data/repositories/device/device_repository.dart';
import '../../../data/repositories/wifi/wifi_password_repository.dart';
import '../../../domain/models/app_error.dart';
import '../../../domain/rules/setup_qr_rules.dart';
import '../../../utils/result.dart';
import '../../../utils/safe_notifier.dart';

/// [password] = after a QR scan: the network is known (the phone's), only its password is asked (R-WF-5).
/// [formScanned] = after a QR scan while the phone is on no Wi-Fi: the full form, under a "code read" banner
/// (design 2026-11-28.12).
enum WifiStep { form, formScanned, password, working, done, failed }

/// What the working / done screen says.
enum WifiStatus { direct, joinAp, send, wait, done, failed }

/// Put the display on a Wi-Fi network (R-WF-1..3).
///
/// If the display is reachable (it's online here, or the phone is on its setup AP) the new network is
/// sent directly. Otherwise the phone joins "glimmer-setup" just for this app (Android asks to confirm
/// once), sends the network, lets go, and looks for the display on the normal Wi-Fi.
///
/// Scanning the QR on the display's setup screen ([scanned], R-WF-4) names the AP and takes the phone's network;
/// a remembered password is sent without asking (R-WF-5). A password is remembered once the display shows up
/// on that network.
class WifiSetupViewModel extends ChangeNotifier with SafeNotifier {
  WifiSetupViewModel({
    required DeviceRepository device,
    required WifiPasswordRepository passwords,
    this.findAttempts = 10,
    this.findGap = const Duration(seconds: 8),
  })  : _device = device,
        _passwords = passwords;

  final DeviceRepository _device;
  final WifiPasswordRepository _passwords;

  /// Looking for the display on the new network: tries × gap (+ the search itself) ≈ 4 min.
  final int findAttempts;
  final Duration findGap;

  WifiStep _step = WifiStep.form;
  WifiStatus _status = WifiStatus.direct;
  String _ssid = '';
  AppError? _error;
  String? _suggestedSsid;

  /// Setup AP read from the QR (null = not scanned: "glimmer-setup").
  String? _scannedAp;

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

  /// The password remembered for [ssid] (R-WF-5), to prefill the form; null if none.
  String? rememberedPassword(String ssid) => _passwords.passwordFor(ssid);

  /// Networks whose password the app remembers (R-WF-5).
  List<String> get rememberedNetworks => _passwords.networks;

  /// When the display last joined [ssid] with its remembered password ("dùng lần cuối …"); null = unknown.
  DateTime? lastUsed(String ssid) => _passwords.lastUsed(ssid);

  /// Forget the remembered password of [ssid] (R-WF-5).
  void forgetPassword(String ssid) {
    _passwords.forget(ssid);
    notifyListeners();
  }

  /// R-WF-4/5: the QR on the display's setup screen was scanned ([raw] = its text). Not glimmer's → failed
  /// with `notGlimmerQr`, nothing joined. The phone's Wi-Fi is the network to send; its password remembered →
  /// sent at once, else [WifiStep.password] asks only the password ([WifiStep.formScanned] when the phone's Wi-Fi is
  /// unknown).
  Future<void> scanned(String raw) async {
    if (busy) return;
    final ap = setupApFromQr(raw);
    if (ap == null) {
      _error = const AppError(AppErrorKind.notGlimmerQr);
      _step = WifiStep.failed;
      _say(WifiStatus.failed);
      return;
    }
    _scannedAp = ap;
    _error = null;
    await _device.ensureWifiPermissions();
    final phone = await _device.phoneSsid();
    final network = phone == null || phone.startsWith(setupApPrefix) ? null : phone;
    if (network == null) {
      _step = WifiStep.formScanned;
      notifyListeners();
      return;
    }
    _ssid = network;
    _suggestedSsid = network;
    final saved = _passwords.passwordFor(network);
    if (saved != null) {
      await send(network, saved, remembered: true);
    } else {
      _step = WifiStep.password;
      notifyListeners();
    }
  }

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

  /// [WifiStep.password] "Đổi mạng": the full form, the phone's network already in the name field.
  void changeNetwork() {
    if (_step != WifiStep.password) return;
    _step = WifiStep.form;
    notifyListeners();
  }

  /// [remembered] = the password came from memory: if the display doesn't show up with it, it is forgotten
  /// and the next try asks for it (R-WF-5).
  Future<void> send(String ssid, String password, {bool remembered = false}) async {
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
        if (!await _device.joinSetupAp(ssid: _scannedAp ?? DeviceRepository.setupApSsid)) {
          throw const AppError(AppErrorKind.setupAp);
        }
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
        if (remembered) _passwords.forget(name);
        throw AppError(AppErrorKind.notOnNetwork, detail: name);
      }
      _passwords.remember(name, password);
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
