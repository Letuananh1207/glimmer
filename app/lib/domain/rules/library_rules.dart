// The photo library on the phone, the device pointing at it (R-AK-*, app plan
// docs/tasks/2026-11-27-kho-anh-tren-app.md; firmware src/data/photo_source_core.h). Pure, unit-tested.
import 'dart:math';

import '../models/library_photo.dart';

/// R-AK-3: the device keeps this many of the newest photos as its cache (its user photo slots, `Photos::kMax`).
const cacheMax = 8;

/// R-AK-4: the port the app serves the library on (any free port when taken; the device is told which).
const photoServerPort = 8787;

/// R-AK-4: how long the library stays served after the app leaves the screen.
const serveAfterPause = Duration(minutes: 2);

/// Slideshow order: oldest first (as added), ids break ties.
List<LibraryPhoto> libraryOrder(Iterable<LibraryPhoto> photos) =>
    [...photos]..sort((a, b) => a.added == b.added ? a.id.compareTo(b.id) : a.added.compareTo(b.added));

/// R-AK-2: the photo after [after] in [ordered] (wrapping to the first); [after] 0 or gone → the first after it in
/// id order, else the first. Null = the library is empty.
NextPhoto? nextAfter(List<LibraryPhoto> ordered, int after) {
  if (ordered.isEmpty) return null;
  var i = ordered.indexWhere((p) => p.id == after);
  if (i < 0) {
    // Deleted meanwhile: keep going from where it was (the next bigger id), else start over.
    final later = ordered.indexWhere((p) => p.id > after);
    i = (later < 0 ? 0 : later) - 1;
  }
  final n = (i + 1) % ordered.length;
  return NextPhoto(ordered[n], n + 1, ordered.length);
}

/// R-AK-3: the ids the device should keep — the [max] newest.
Set<int> cacheIds(Iterable<LibraryPhoto> photos, {int max = cacheMax}) {
  final newest = [...photos]..sort((a, b) => a.added == b.added ? b.id.compareTo(a.id) : b.added.compareTo(a.added));
  return newest.take(max).map((p) => p.id).toSet();
}

/// What syncing the cache does: device photos to delete (library photos that left the newest), and library photos to
/// upload (newest first, so the newest get the room if it runs out). A device photo the library did not send (the
/// device's web page, another phone) is never deleted.
class CachePlan {
  const CachePlan(this.delete, this.upload);

  final List<String> delete;
  final List<LibraryPhoto> upload;

  bool get isEmpty => delete.isEmpty && upload.isEmpty;
}

/// R-AK-3: [onDevice] = the user photo names the device has now ("p3.jpg"; sample photos are not passed).
CachePlan cachePlan(List<LibraryPhoto> photos, Iterable<String> onDevice, {int max = cacheMax}) {
  final keep = cacheIds(photos, max: max);
  final device = onDevice.toSet();
  final delete = [
    for (final p in photos)
      if (!keep.contains(p.id) && p.cachedAs != null && device.contains(p.cachedAs)) p.cachedAs!,
  ];
  final upload = [
    for (final p in photos)
      if (keep.contains(p.id) && !(p.cachedAs != null && device.contains(p.cachedAs))) p,
  ]..sort((a, b) => b.added.compareTo(a.added));
  return CachePlan(delete, upload);
}

/// R-AK-4: a fresh key for the library's URLs each time the app starts (letters + digits, so it goes into a path).
String newServeKey([Random? random]) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
  final r = random ?? Random.secure();
  return String.fromCharCodes(List.generate(16, (_) => chars.codeUnitAt(r.nextInt(chars.length))));
}

/// R-AK-4: the phone's address the device can reach — the IPv4 on the device's /24 (same home network), else the
/// first private IPv4. Null = none (not on Wi-Fi).
String? phoneHostFor(String deviceIp, Iterable<String> phoneIps) {
  final ips = phoneIps.where(_isIPv4).toList();
  final dev = deviceIp.split('.');
  if (dev.length == 4) {
    final net = dev.take(3).join('.');
    for (final ip in ips) {
      if (ip.startsWith('$net.')) return ip;
    }
  }
  for (final ip in ips) {
    if (ip.startsWith('192.168.') || ip.startsWith('10.') || RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(ip)) {
      return ip;
    }
  }
  return null;
}

bool _isIPv4(String s) {
  final p = s.split('.');
  return p.length == 4 && p.every((x) => int.tryParse(x) != null && int.parse(x) >= 0 && int.parse(x) <= 255);
}

/// R-AK-4: `POST /api/photos/source` body.
Map<String, Object> sourceBody(String host, int port, String key) => {'host': host, 'port': port, 'key': key};
