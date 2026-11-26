// Numbers of the DeviceMirror's Weather / Forecast / Clock / Info windows (design 2026-11-26.5), worked out like the
// firmware (src/channels/ch_weather.cpp, ch_forecast.cpp, ch_clock.cpp, ch_info.cpp, src/ui/clockfmt.h).
import 'dart:math' as math;

import '../models/device_state.dart';
import '../models/mirror_ambient.dart';
import 'control_rules.dart';
import 'time_rules.dart';

/// Everything the four windows need from [state] + [settings] at device epoch [nowEpoch] (0 = clock not set),
/// [deviceNow] = the device's wall clock (read through the UTC fields).
MirrorAmbient ambientOf(DeviceState state, Map<String, dynamic>? settings, int nowEpoch, DateTime deviceNow) {
  final tz = (settings?['tzMinutes'] as num?)?.toInt() ?? 0;
  return MirrorAmbient(
    weather: weatherOf(state.weather, settings, nowEpoch),
    clock: MirrorClock(
      week: isoWeek(deviceNow),
      gmt: gmtLabel(tz),
      greet: greetSlot(deviceNow.hour),
      userName: (settings?['userName'] as String? ?? '').trim(),
    ),
    info: infoOf(state, settings, nowEpoch),
  );
}

/// Age rounded like `TimeUtil::shortDuration` (negative → 0).
MirrorSpan spanOf(int seconds) {
  final s = seconds < 0 ? 0 : seconds;
  if (s < 3600) return MirrorSpan(s ~/ 60, SpanUnit.minutes);
  if (s < 172800) return MirrorSpan((s + 1800) ~/ 3600, SpanUnit.hours);
  return MirrorSpan((s + 43200) ~/ 86400, SpanUnit.days);
}

/// "GMT+7", "GMT-3", "GMT+5:30" (`ClockFmt::gmtLabel`).
String gmtLabel(int tzMinutes) {
  final sign = tzMinutes < 0 ? '-' : '+';
  final a = tzMinutes.abs();
  return a % 60 == 0 ? 'GMT$sign${a ~/ 60}' : 'GMT$sign${a ~/ 60}:${(a % 60).toString().padLeft(2, '0')}';
}

GreetSlot greetSlot(int hour) => hour < 5
    ? GreetSlot.night
    : hour < 12
    ? GreetSlot.morning
    : hour < 17
    ? GreetSlot.afternoon
    : hour < 21
    ? GreetSlot.evening
    : GreetSlot.late;

/// Wording of a fetch error string (`errorDetail`): "HTTP 500" → http, "HTTP -1" → connect, "http begin", "JSON…",
/// "no current", anything else unknown.
(WeatherErr, int) weatherErrOf(String err) {
  final m = RegExp(r'^HTTP (-?\d+)').firstMatch(err);
  if (m != null) {
    final code = int.parse(m.group(1)!);
    return code >= 100 ? (WeatherErr.http, code) : (WeatherErr.connect, 0);
  }
  if (err == 'http begin') return (WeatherErr.begin, 0);
  if (err.startsWith('JSON')) return (WeatherErr.json, 0);
  if (err == 'no current') return (WeatherErr.noCurrent, 0);
  return (WeatherErr.unknown, 0);
}

int? _shown(double? c, bool f) => c == null ? null : (f ? c * 9 / 5 + 32 : c).round();

/// The Weather / Forecast data of [w] (`/api/state.weather`; null = not loaded yet).
MirrorWeather weatherOf(DeviceWeather? w, Map<String, dynamic>? settings, int nowEpoch) {
  if (w == null || !w.valid) {
    final err = w?.err ?? '';
    if (err.isEmpty) return const MirrorWeather();
    final (kind, code) = weatherErrOf(err);
    return MirrorWeather(phase: WeatherPhase.error, err: kind, errCode: code);
  }
  final f = settings?['useFahrenheit'] == true;
  final days = [for (var i = 0; i < 3; i++) i < w.days.length ? w.days[i] : const WeatherDay()];
  final (gMin, range) = forecastRange(days);
  final synced = nowEpoch > 1000000000;
  final sun = synced ? nextSunEvent(settings, nowEpoch) : null;
  final tz = (settings?['tzMinutes'] as num?)?.toInt() ?? 0;
  return MirrorWeather(
    phase: WeatherPhase.ready,
    stale: w.stale,
    age: synced && w.lastOk > 0 ? spanOf(nowEpoch - w.lastOk) : null,
    temp: _shown(w.tempC, f),
    feels: _shown(w.feelsC, f),
    humidity: w.humidity,
    wind: w.windKmh?.round(),
    desc: w.desc,
    days: [
      for (final d in days)
        () {
          final (x0, x1) = forecastSpan(d.tmin, d.tmax, gMin, range);
          return MirrorDay(hi: _shown(d.tmax, f), lo: _shown(d.tmin, f), desc: d.desc, spanX0: x0, spanX1: x1);
        }(),
    ],
    sunEvent: sun?.$1,
    sunAt: sun == null ? null : deviceLocal(sun.$2, tz),
  );
}

/// Shared low and range (°C) of the three Forecast bars (`computeRange`): no data or flat → 0…30.
(double, double) forecastRange(List<WeatherDay> days) {
  var gMin = 999.0, gMax = -999.0;
  for (final d in days.take(3)) {
    if (d.tmin != null && d.tmin! < gMin) gMin = d.tmin!;
    if (d.tmax != null && d.tmax! > gMax) gMax = d.tmax!;
  }
  if (gMin >= gMax) (gMin, gMax) = (0, 30);
  final range = gMax - gMin;
  return (gMin, range < 1 ? 1.0 : range);
}

/// Forecast bar of one day in device x (`paintRow`): [gMin, gMin + range] onto x 125…184 inside the 118…191 track,
/// at least 4 px; (0, 0) = unknown day.
(int, int) forecastSpan(double? tmin, double? tmax, double gMin, double range) {
  const trackX = 118, trackW = 74, spanX = 125, spanW = 59;
  if (tmin == null || tmax == null) return (0, 0);
  var x0 = spanX + ((tmin - gMin) / range * spanW + 0.5).floor();
  var x1 = spanX + ((tmax - gMin) / range * spanW + 0.5).floor();
  if (x1 < x0 + 4) x1 = x0 + 4;
  if (x1 > trackX + trackW) {
    x1 = trackX + trackW;
    if (x0 > x1 - 4) x0 = x1 - 4;
  }
  if (x0 < trackX) x0 = trackX;
  return (x0, x1);
}

/// The status-bar sun event at [nowEpoch] (`statusFor`): today's sunrise if not yet, else today's sunset if not yet,
/// else tomorrow's sunrise — computed from `weatherLat` / `weatherLon` (the device reads them from Open-Meteo;
/// `/api/state` does not send them). Null when there is no location or no event (polar day / night).
(SunEvent, int)? nextSunEvent(Map<String, dynamic>? settings, int nowEpoch) {
  final lat = (settings?['weatherLat'] as num?)?.toDouble() ?? 0;
  final lon = (settings?['weatherLon'] as num?)?.toDouble() ?? 0;
  if (lat == 0 && lon == 0) return null;
  final tz = (settings?['tzMinutes'] as num?)?.toInt() ?? 0;
  final local = deviceLocal(nowEpoch, tz);
  final today = DateTime.utc(local.year, local.month, local.day);
  final rise = sunEpoch(today, lat, lon, tz, rising: true);
  if (rise != null && nowEpoch < rise) return (SunEvent.rise, rise);
  final set = sunEpoch(today, lat, lon, tz, rising: false);
  if (set != null && nowEpoch < set) return (SunEvent.set, set);
  final next = sunEpoch(today.add(const Duration(days: 1)), lat, lon, tz, rising: true);
  return next == null ? null : (SunEvent.rise, next);
}

/// Epoch of sunrise / sunset on the device-local [date] (its UTC fields) at [lat] / [lon], time zone [tzMinutes]
/// (US Naval Observatory almanac method, zenith 90.833°, about a minute off); null when the sun does not cross.
int? sunEpoch(DateTime date, double lat, double lon, int tzMinutes, {required bool rising}) {
  double rad(double d) => d * math.pi / 180;
  double deg(double r) => r * 180 / math.pi;
  double norm(double v, double m) => (v % m + m) % m;

  final n = date.difference(DateTime.utc(date.year)).inDays + 1;
  final lngHour = lon / 15;
  final t = n + ((rising ? 6 : 18) - lngHour) / 24;
  final m = 0.9856 * t - 3.289;
  final l = norm(m + 1.916 * math.sin(rad(m)) + 0.020 * math.sin(rad(2 * m)) + 282.634, 360);
  var ra = norm(deg(math.atan(0.91764 * math.tan(rad(l)))), 360);
  ra = (ra + (l / 90).floor() * 90 - (ra / 90).floor() * 90) / 15;
  final sinDec = 0.39782 * math.sin(rad(l));
  final cosDec = math.cos(math.asin(sinDec));
  final cosH = (math.cos(rad(90.833)) - sinDec * math.sin(rad(lat))) / (cosDec * math.cos(rad(lat)));
  if (cosH > 1 || cosH < -1) return null;
  final h = (rising ? 360 - deg(math.acos(cosH)) : deg(math.acos(cosH))) / 15;
  final ut = h + ra - 0.06571 * t - 6.622 - lngHour;
  final localHours = norm(ut + tzMinutes / 60, 24);
  final midnight = date.millisecondsSinceEpoch ~/ 1000 - tzMinutes * 60;
  return midnight + (localHours * 3600).round();
}

/// The Info rows of [state] (`chInfoDraw`).
MirrorInfo infoOf(DeviceState state, Map<String, dynamic>? settings, int nowEpoch) {
  final lastOk = math.max(state.usage.lastOk, state.weather?.lastOk ?? 0);
  return MirrorInfo(
    ip: state.ip,
    ssid: state.ssid,
    rssi: state.rssi,
    upMin: state.uptimeS ~/ 60,
    heapK: state.heap ~/ 1024,
    blockK: state.maxBlock ~/ 1024,
    fw: state.fw,
    channelsOn: rotationGuess(state, settings).length,
    channelsTotal: deviceChannels.length,
    updatedMin: lastOk > 0 && nowEpoch > 1000000000 ? math.max(0, nowEpoch - lastOk) ~/ 60 : null,
    nextMin: state.nextFetchS ~/ 60,
  );
}
