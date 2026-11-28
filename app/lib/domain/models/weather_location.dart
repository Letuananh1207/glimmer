// The device's weather location (design 2026-11-26.9, R-VT-*): `weatherLat`, `weatherLon`, `weatherPlace` of
// `/api/settings` — read from and written to the device, never kept on the phone.

/// Where the device takes its weather from; [place] = the name it shows ("" = none).
class WeatherLocation {
  const WeatherLocation({this.lat = 0, this.lon = 0, this.place = ''});

  static const unset = WeatherLocation();

  final double lat, lon;
  final String place;

  /// The device treats 0, 0 as "not set" (no weather is fetched).
  bool get isSet => lat != 0 || lon != 0;

  @override
  bool operator ==(Object other) =>
      other is WeatherLocation && other.lat == lat && other.lon == lon && other.place == place;

  @override
  int get hashCode => Object.hash(lat, lon, place);

  @override
  String toString() => 'WeatherLocation($lat, $lon, "$place")';
}

/// A city found by the Open-Meteo geocoding search, or the phone's own position.
class PlaceResult {
  const PlaceResult({required this.name, required this.lat, required this.lon, this.region = '', this.country = ''});

  final String name, region, country;
  final double lat, lon;

  /// "Đà Nẵng, Việt Nam" — region and country that are known and not the name itself.
  String get area => [region, country].where((s) => s.isNotEmpty && s != name).join(', ');

  @override
  bool operator ==(Object other) =>
      other is PlaceResult && other.name == name && other.lat == lat && other.lon == lon && other.region == region;

  @override
  int get hashCode => Object.hash(name, lat, lon, region);
}

/// Why the phone's position could not be had (R-VT-1).
enum GpsFailure {
  /// The user said no; asking again shows the system dialog again.
  denied,

  /// Denied for good: only the phone's settings can allow it now.
  deniedForever,

  /// Location services are off.
  off,

  /// No fix (indoors, weak signal, timed out).
  failed,
}

/// The phone's position: [fix] (with the name the phone's geocoder gives, "" = none) or [failure].
class GpsOutcome {
  const GpsOutcome.fix(PlaceResult this.fix) : failure = null;
  const GpsOutcome.failed(GpsFailure this.failure) : fix = null;

  final PlaceResult? fix;
  final GpsFailure? failure;
}
