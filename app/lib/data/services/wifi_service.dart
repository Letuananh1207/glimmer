import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';

/// The phone's Wi-Fi, for talking to the display's setup AP "glimmer-setup".
///
/// On Android 10+ joining it goes through WifiNetworkSpecifier: the system asks the user once to
/// confirm, the phone keeps its normal Wi-Fi as the default network, and this app's traffic is bound
/// to the AP until [leave] — so nothing else on the phone loses Internet.
class WifiService {
  /// Location (and on Android 13+ "nearby Wi-Fi devices") is needed to read the current SSID and to
  /// request a network.
  Future<bool> ensurePermissions() async {
    if (!Platform.isAndroid) return false;
    final statuses = await [Permission.locationWhenInUse, Permission.nearbyWifiDevices].request();
    return statuses[Permission.locationWhenInUse]?.isGranted ?? false;
  }

  /// The Wi-Fi the phone is on now (null if unknown / not allowed).
  Future<String?> currentSsid() async {
    if (!Platform.isAndroid) return null;
    try {
      final s = await WiFiForIoTPlugin.getSSID();
      if (s == null || s.isEmpty || s == '<unknown ssid>') return null;
      return s.replaceAll('"', '');
    } catch (_) {
      return null;
    }
  }

  /// Join the open network [ssid] (once, no Internet) and route this app's traffic through it.
  Future<bool> joinOpen(String ssid) async {
    if (!Platform.isAndroid) return false;
    final ok = await WiFiForIoTPlugin.connect(ssid,
        security: NetworkSecurity.NONE, joinOnce: true, withInternet: false, timeoutInSeconds: 30);
    if (ok) await WiFiForIoTPlugin.forceWifiUsage(true);
    return ok;
  }

  /// Release the joined network; the phone falls back to its normal one.
  Future<void> leave() async {
    if (!Platform.isAndroid) return;
    try {
      await WiFiForIoTPlugin.forceWifiUsage(false);
      await WiFiForIoTPlugin.disconnect();
    } catch (_) {}
  }
}
