import 'dart:ui' show Locale;

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// The phone's location (geolocator) and its geocoder (place name from coordinates). Used only when the user asks
/// (R-VT-1).
class PositionService {
  Future<bool> serviceEnabled() => Geolocator.isLocationServiceEnabled();

  /// Current permission, asking the system when it has not been decided (or was denied once).
  Future<LocationPermission> askPermission() async {
    final p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) return Geolocator.requestPermission();
    return p;
  }

  /// One coarse fix, ≤ 20 s.
  Future<(double, double)> current() async {
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 20)),
    );
    return (p.latitude, p.longitude);
  }

  /// The town / district of a point by the phone's geocoder, Vietnamese when it can; null = none known.
  Future<({String name, String region, String country})?> placeOf(double lat, double lon) async {
    final marks = await Geocoding(locale: const Locale('vi', 'VN')).placemarkFromCoordinates(lat, lon);
    if (marks.isEmpty) return null;
    final m = marks.first;
    final name = [
      m.locality,
      m.subAdministrativeArea,
      m.administrativeArea,
    ].whereType<String>().firstWhere((s) => s.isNotEmpty, orElse: () => '');
    return (name: name, region: m.administrativeArea ?? '', country: m.country ?? '');
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
