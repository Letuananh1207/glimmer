// What the Thời tiết and Đồng hồ tabs of Màn hình show (screen_specs §2, 2026-11-25.3), already worked out from
// `/api/state` + `/api/settings` so the widgets only lay it out.
part of 'dashboard_view_model.dart';

/// Device channel each dock tab's `ShowOnDeviceButton` brings up (`POST /api/channel`).
const showChannelOf = {'agent': 'Claude', 'weather': 'Weather', 'clock': 'Clock'};

enum WeatherStatus {
  /// Device has no `weatherLat/Lon` (`weatherNoLoc`).
  noLocation,

  /// Location set but no good reading yet (first fetch pending, or firmware without `weather`).
  waiting,
  ok,
}

/// One forecast row: [offset] days after today (1 → MAI, 2 → KIA, then the [weekday]).
class ForecastRow {
  const ForecastRow(this.offset, this.weekday, this.desc, this.hi, this.lo);

  final int offset;

  /// DateTime.weekday (1 = Monday).
  final int weekday;
  final String desc;
  final int? hi, lo;
}

class WeatherView {
  const WeatherView(
    this.status, {
    this.ageS,
    this.stale = false,
    this.temp,
    this.desc = '',
    this.hi,
    this.lo,
    this.feels,
    this.forecast = const [],
  });

  final WeatherStatus status;

  /// Seconds since the last good fetch; null = never.
  final int? ageS;
  final bool stale;

  /// Rounded, in the device's unit (°C, or °F with `useFahrenheit`); null = unknown.
  final int? temp, hi, lo, feels;
  final String desc;
  final List<ForecastRow> forecast;

  /// Forecast rows after today (firmware sends today + 3).
  static const forecastDays = 3;

  static int? _deg(double? c, bool f) => c == null ? null : (f ? c * 9 / 5 + 32 : c).round();

  /// [now] = device epoch, [today] = device-local date.
  factory WeatherView.from(DeviceState s, {required int now, required DateTime today, required bool fahrenheit}) {
    final w = s.weather;
    if (!s.weatherConfigured) return const WeatherView(WeatherStatus.noLocation);
    if (w == null || (!w.valid && w.lastOk <= 0)) return const WeatherView(WeatherStatus.waiting);
    final days = w.days;
    final todayRow = days.isNotEmpty ? days.first : null;
    return WeatherView(
      WeatherStatus.ok,
      ageS: w.lastOk > 0 && now >= w.lastOk ? now - w.lastOk : null,
      stale: w.stale,
      temp: _deg(w.tempC, fahrenheit),
      desc: w.desc,
      hi: _deg(todayRow?.tmax, fahrenheit),
      lo: _deg(todayRow?.tmin, fahrenheit),
      feels: _deg(w.feelsC, fahrenheit),
      forecast: [
        for (var i = 1; i < days.length && i <= forecastDays; i++)
          ForecastRow(i, today.add(Duration(days: i)).weekday, days[i].desc, _deg(days[i].tmax, fahrenheit),
              _deg(days[i].tmin, fahrenheit)),
      ],
    );
  }
}

/// Night window of the Đồng hồ tab; null mode 0 / start == end (off).
class NightView {
  const NightView(this.start, this.end, this.mode);

  /// "23:00".
  final String start, end;

  /// 1 dim, 2 clock face, 3 panel off (`nightMode`).
  final int mode;
}

class ClockView {
  const ClockView({
    required this.synced,
    required this.hour,
    required this.minute,
    this.pm,
    required this.weekday,
    required this.date,
    required this.week,
    required this.tz,
    required this.h24,
    this.night,
  });

  /// The device clock is set (NTP); otherwise the hero shows "--:--".
  final bool synced;
  final String hour, minute;

  /// 12-hour mode: SA (false) / CH (true); null in 24-hour mode.
  final bool? pm;
  final int weekday;

  /// "25/11".
  final String date;
  final int week;

  /// "UTC+7", "UTC+5:30".
  final String tz;
  final bool h24;
  final NightView? night;

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String _hm(int minutes) => '${_two(minutes ~/ 60 % 24)}:${_two(minutes % 60)}';

  static String utcLabel(int tzMinutes) {
    final sign = tzMinutes < 0 ? '-' : '+';
    final a = tzMinutes.abs();
    return 'UTC$sign${a ~/ 60}${a % 60 == 0 ? '' : ':${_two(a % 60)}'}';
  }

  /// [epoch] = device time now; [settings] = `/api/settings` (null until loaded).
  factory ClockView.from({required int epoch, required bool synced, required int tzMinutes, Map<String, dynamic>? settings}) {
    final t = deviceLocal(epoch, tzMinutes);
    final h24 = settings?['clock24h'] != false;
    final mode = (settings?['nightMode'] as num?)?.toInt() ?? 0;
    final start = (settings?['nightStartMin'] as num?)?.toInt() ?? 0;
    final end = (settings?['nightEndMin'] as num?)?.toInt() ?? 0;
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return ClockView(
      synced: synced,
      hour: !synced ? '--' : (h24 ? _two(t.hour) : '$h12'),
      minute: !synced ? '--' : _two(t.minute),
      pm: h24 || !synced ? null : t.hour >= 12,
      weekday: t.weekday,
      date: '${_two(t.day)}/${_two(t.month)}',
      week: isoWeek(t),
      tz: utcLabel(tzMinutes),
      h24: h24,
      night: mode == 0 || start == end ? null : NightView(_hm(start), _hm(end), mode),
    );
  }
}
