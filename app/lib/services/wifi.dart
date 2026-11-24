import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';

import '../api/device_api.dart';
import '../api/models.dart';

/// The phone's Wi-Fi, for talking to the display's setup AP "glimmer-setup".
///
/// On Android 10+ joining it goes through WifiNetworkSpecifier: the system
/// asks the user once to confirm, the phone keeps its normal Wi-Fi as the
/// default network, and this app's traffic is bound to glimmer-setup until
/// [leaveSetupAp] — so nothing else on the phone loses Internet.
class PhoneWifi {
  /// Location (and on Android 13+ "nearby Wi-Fi devices") is needed to read
  /// the current SSID and to request a network.
  static Future<bool> ensurePermissions() async {
    if (!Platform.isAndroid) return false;
    final statuses = await [Permission.locationWhenInUse, Permission.nearbyWifiDevices].request();
    return statuses[Permission.locationWhenInUse]?.isGranted ?? false;
  }

  /// The Wi-Fi the phone is on now (null if unknown / not allowed).
  static Future<String?> currentSsid() async {
    if (!Platform.isAndroid) return null;
    try {
      final s = await WiFiForIoTPlugin.getSSID();
      if (s == null || s.isEmpty || s == '<unknown ssid>') return null;
      return s.replaceAll('"', '');
    } catch (_) {
      return null;
    }
  }

  /// Join the open setup AP and route this app's traffic through it.
  /// Returns the device state read over it, or null.
  static Future<DeviceState?> joinSetupAp({int attempts = 3}) async {
    if (!Platform.isAndroid) return null;
    for (var i = 0; i < attempts; i++) {
      final ok = await WiFiForIoTPlugin.connect(DeviceApi.setupApSsid,
          security: NetworkSecurity.NONE, joinOnce: true, withInternet: false, timeoutInSeconds: 30);
      if (ok) {
        await WiFiForIoTPlugin.forceWifiUsage(true);
        final api = DeviceApi(DeviceApi.setupApUrl);
        try {
          for (var j = 0; j < 5; j++) {
            final s = await api.probe();
            if (s != null) return s;
            await Future<void>.delayed(const Duration(seconds: 2));
          }
        } finally {
          api.close();
        }
      }
      await Future<void>.delayed(const Duration(seconds: 5));
    }
    return null;
  }

  /// Release the setup AP; the phone falls back to its normal network.
  static Future<void> leaveSetupAp() async {
    if (!Platform.isAndroid) return;
    try {
      await WiFiForIoTPlugin.forceWifiUsage(false);
      await WiFiForIoTPlugin.disconnect();
    } catch (_) {}
  }
}
