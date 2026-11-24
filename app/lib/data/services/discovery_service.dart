import 'dart:async';
import 'dart:io';

import 'package:nsd/nsd.dart' as nsd;

/// Android NSD (mDNS): the firmware advertises "_http._tcp" as "glimmer".
class DiscoveryService {
  /// IPv4 addresses of "_http._tcp" services named glimmer*, ~4 s scan.
  Future<List<String>> nsdAddresses() async {
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
