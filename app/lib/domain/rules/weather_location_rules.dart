// The device's weather location set from the phone (design 2026-11-26.9, R-VT-*). Pure, unit-tested.
import '../models/weather_location.dart';

/// R-VT-3: the name the device shows is at most 16 characters (its slot; the device trims more if still too wide).
const locationNameMax = 16;

/// The device's location from `/api/settings` (missing keys → unset).
WeatherLocation locationOf(Map<String, dynamic>? s) => WeatherLocation(
  lat: (s?['weatherLat'] as num?)?.toDouble() ?? 0,
  lon: (s?['weatherLon'] as num?)?.toDouble() ?? 0,
  place: s?['weatherPlace'] is String ? s!['weatherPlace'] as String : '',
);

/// R-VT-4: the firmware shows a place name when its settings carry `weatherPlace`; older firmware only takes
/// coordinates.
bool placeSupported(Map<String, dynamic>? s) => s != null && s.containsKey('weatherPlace');

/// R-VT-3: [name] trimmed and cut to [locationNameMax] characters (letters, not bytes).
String deviceName(String name) {
  final t = name.trim();
  final r = t.runes.toList();
  return r.length <= locationNameMax ? t : String.fromCharCodes(r.take(locationNameMax)).trimRight();
}

/// Characters of [name] as the counter shows them ("7/16").
int nameLength(String name) => name.trim().runes.length;

/// "16.07" — 2 decimals, as the design shows coordinates (what is sent keeps full precision).
String coord(double v) => v.toStringAsFixed(2);

/// R-VT-2: search only from 2 characters.
bool shouldSearch(String q) => q.trim().runes.length >= 2;

/// How long the search waits after the last key (R-VT-2).
const searchDelay = Duration(milliseconds: 400);

/// R-VT-3 / R-VT-4: `POST /api/settings` body to set [p] named [name] (old firmware: coordinates only).
Map<String, Object> applyBody(PlaceResult p, String name, {required bool place}) => {
  'weatherLat': p.lat,
  'weatherLon': p.lon,
  if (place) 'weatherPlace': deviceName(name),
};

/// Rename only (the coordinates stay).
Map<String, Object> renameBody(String name) => {'weatherPlace': deviceName(name)};

/// R-VT-5: clearing = 0, 0, "" — the device treats it as not set (old firmware: no name to clear).
Map<String, Object> clearBody({required bool place}) => {
  'weatherLat': 0,
  'weatherLon': 0,
  if (place) 'weatherPlace': '',
};

/// "+7", "-3", "+5:30" of an offset in minutes (the preview of the device's clock line).
String gmtOffset(int tzMin) {
  final a = tzMin.abs(), h = a ~/ 60, m = a % 60;
  return '${tzMin < 0 ? '-' : '+'}$h${m == 0 ? '' : ':${m.toString().padLeft(2, '0')}'}';
}
