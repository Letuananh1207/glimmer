import 'dart:async';
import 'dart:io';

import 'package:nsd/nsd.dart' as nsd;

import '../api/device_api.dart';
import '../api/models.dart';

/// A display that answered, and where.
class Found {
  final String url;
  final DeviceState state;
  const Found(this.url, this.state);
}

/// Finds the display on the current network, cheapest first:
///   1. the address that worked last time,
///   2. Android NSD (mDNS) — the firmware advertises "_http._tcp" as "glimmer",
///   3. the name glimmer.local through the system resolver,
///   4. the setup AP (192.168.4.1), when the phone is joined to it.
class Discovery {
  static Future<Found?> find({String saved = '', String token = ''}) async {
    final tried = <String>{};

    Future<Found?> tryUrl(String url) async {
      if (url.isEmpty || !tried.add(url)) return null;
      final api = DeviceApi(url, token: token);
      try {
        final s = await api.probe();
        return s == null ? null : Found(url, s);
      } finally {
        api.close();
      }
    }

    var hit = await tryUrl(saved);
    if (hit != null) return hit;

    for (final ip in await _nsdAddresses()) {
      hit = await tryUrl('http://$ip');
      if (hit != null) return hit;
    }

    hit = await tryUrl('http://glimmer.local');
    if (hit != null) return hit;

    return tryUrl(DeviceApi.setupApUrl);
  }

  /// IPv4 addresses of "_http._tcp" services named glimmer*, ~4 s scan.
  static Future<List<String>> _nsdAddresses() async {
    if (!Platform.isAndroid) return const [];
    nsd.Discovery? d;
    try {
      d = await nsd.startDiscovery('_http._tcp', ipLookupType: nsd.IpLookupType.v4);
      final done = Completer<void>();
      d.addServiceListener((s, status) {
        if (status == nsd.ServiceStatus.found &&
            (s.name ?? '').toLowerCase().startsWith('glimmer') &&
            (s.addresses?.isNotEmpty ?? false) &&
            !done.isCompleted) {
          done.complete();
        }
      });
      await done.future.timeout(const Duration(seconds: 4), onTimeout: () {});
      return d.services
          .where((s) => (s.name ?? '').toLowerCase().startsWith('glimmer'))
          .expand((s) => s.addresses ?? const <InternetAddress>[])
          .where((a) => a.type == InternetAddressType.IPv4)
          .map((a) => a.address)
          .toList();
    } catch (_) {
      return const [];
    } finally {
      if (d != null) {
        try {
          await nsd.stopDiscovery(d);
        } catch (_) {}
      }
    }
  }
}
