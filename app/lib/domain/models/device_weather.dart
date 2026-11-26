// `weather` in GET /api/state (firmware 2026-11-25.3): now + today and 3 days, Celsius. Absent until the device has a
// location. The firmware writes -999 (temperatures) / -1 (humidity, wind) for unknown → null here.
import '../../utils/json.dart';

double? _temp(Object? v) => v is num && v > -998 ? v.toDouble() : null;
double? _nonNeg(Object? v) => v is num && v >= 0 ? v.toDouble() : null;

class DeviceWeather {
  const DeviceWeather({
    required this.valid,
    this.tempC,
    this.feelsC,
    this.code = 0,
    this.desc = '',
    this.isDay = true,
    this.humidity,
    this.windKmh,
    this.lastOk = 0,
    this.stale = false,
    this.err = '',
    this.days = const [],
  });

  factory DeviceWeather.fromJson(Map<String, dynamic> j) => DeviceWeather(
    valid: jsonBool(j['valid']),
    tempC: _temp(j['temp_c']),
    feelsC: _temp(j['feels_c']),
    code: jsonInt(j['code']),
    desc: jsonStr(j['desc']),
    isDay: j['is_day'] != false,
    humidity: _nonNeg(j['humidity'])?.round(),
    windKmh: _nonNeg(j['wind_kmh']),
    lastOk: jsonInt(j['last_ok']),
    stale: jsonBool(j['stale']),
    err: jsonStr(j['err']),
    days: List.unmodifiable(
      (j['days'] as List? ?? const []).whereType<Map<String, dynamic>>().map(WeatherDay.fromJson),
    ),
  );

  /// The device has a good reading (false before the first fetch or after errors).
  final bool valid;

  /// °C now / feels like; null = unknown.
  final double? tempC, feelsC;

  /// WMO weather code (Open-Meteo).
  final int code;

  /// Vietnamese description from the device, e.g. "Quang".
  final String desc;
  final bool isDay;

  /// % / km/h; null = unknown.
  final int? humidity;
  final double? windKmh;

  /// Epoch of the last good fetch (0 = never).
  final int lastOk;

  /// Older than the device's stale limit.
  final bool stale;
  final String err;

  /// Today first, then the next days (firmware sends 4).
  final List<WeatherDay> days;
}

/// One forecast day.
class WeatherDay {
  const WeatherDay({this.tmin, this.tmax, this.code = 0, this.desc = '', this.uv});

  factory WeatherDay.fromJson(Map<String, dynamic> j) => WeatherDay(
    tmin: _temp(j['tmin']),
    tmax: _temp(j['tmax']),
    code: jsonInt(j['code']),
    desc: jsonStr(j['desc']),
    uv: j['uv'] is num && (j['uv'] as num) >= 0 ? (j['uv'] as num).toDouble() : null,
  );

  /// Today's UV index max (firmware with the XP-Real Weather tab, P-2026-11-26.17); null = unknown / older firmware.
  final double? uv;

  /// °C low / high; null = unknown.
  final double? tmin, tmax;
  final int code;
  final String desc;
}
