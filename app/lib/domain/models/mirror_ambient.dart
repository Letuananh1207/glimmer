// What the DeviceMirror's Weather, Forecast, Clock and Info painters show (design 2026-11-26.5, panel §17 XP-Weather*,
// XP-Forecast*, XP-Clock, XP-Info) — numbers already worked out by `ambientOf` (domain/rules/ambient_rules.dart) the
// way the firmware does (src/channels/ch_weather.cpp, ch_forecast.cpp, ch_clock.cpp, ch_info.cpp); the painters only
// turn them into words.

/// Unit of a rounded age (`TimeUtil::shortDuration`: "14P" / "2G" / "3NG"; long form "14 phút" / "2 giờ" / "3 ngày").
enum SpanUnit { minutes, hours, days }

/// An age rounded like the firmware: < 1 h whole minutes, < 48 h hours (+30 min), else days (+12 h).
class MirrorSpan {
  const MirrorSpan(this.n, this.unit);

  final int n;
  final SpanUnit unit;

  @override
  bool operator ==(Object other) => other is MirrorSpan && other.n == n && other.unit == unit;

  @override
  int get hashCode => Object.hash(n, unit);

  @override
  String toString() => '$n${unit.name[0]}';
}

/// Weather window state: nothing yet (marquee), error before any data (warning dialog), or values.
enum WeatherPhase { loading, error, ready }

/// Fetch error as worded on the device (`errorDetail` in ch_weather.cpp).
enum WeatherErr { none, http, connect, begin, json, noCurrent, unknown }

/// Next sun event of the Weather status bar ("Mặt trời mọc / lặn 17:24").
enum SunEvent { rise, set }

/// One forecast day, temperatures in the display unit (rounded), the Forecast bar span in device x.
class MirrorDay {
  const MirrorDay({this.hi, this.lo, this.desc = '', this.spanX0 = 0, this.spanX1 = 0});

  /// Rounded high / low in the display unit; null = unknown ("--").
  final int? hi, lo;
  final String desc;

  /// Forecast row bar: x from [spanX0] to [spanX1] (exclusive); equal = no bar (unknown day).
  final int spanX0, spanX1;
}

class MirrorWeather {
  const MirrorWeather({
    this.phase = WeatherPhase.loading,
    this.err = WeatherErr.none,
    this.errCode = 0,
    this.stale = false,
    this.age,
    this.temp,
    this.feels,
    this.humidity,
    this.wind,
    this.desc = '',
    this.days = const [],
    this.sunEvent,
    this.sunAt,
  });

  final WeatherPhase phase;
  final WeatherErr err;

  /// HTTP status of a [WeatherErr.http].
  final int errCode;

  /// Older than the device's limit: every value dimmed, "cũ 2G" in the title, "Cập nhật 2 giờ trước" below.
  final bool stale;

  /// Age of the last good reading (null = unknown clock).
  final MirrorSpan? age;

  /// Now / feels like in the display unit (rounded), % and km/h; null = unknown (row skipped).
  final int? temp, feels, humidity, wind;
  final String desc;

  /// Today, tomorrow, the day after (always 3 when [phase] is ready).
  final List<MirrorDay> days;

  /// Next sunrise / sunset and its device-local wall clock (read through the UTC fields); null = unknown.
  final SunEvent? sunEvent;
  final DateTime? sunAt;
}

/// Clock greeting by hour (`greetingFor`): < 5 night, < 12 morning, < 17 afternoon, < 21 evening, else late.
enum GreetSlot { night, morning, afternoon, evening, late }

class MirrorClock {
  const MirrorClock({this.week = 0, this.gmt = '', this.greet = GreetSlot.morning, this.userName = ''});

  /// ISO week of the device date ("Tuần 48").
  final int week;

  /// "GMT+7" / "GMT-3" / "GMT+5:30".
  final String gmt;
  final GreetSlot greet;

  /// `userName` of the settings; empty = "bạn".
  final String userName;
}

/// Values of the Info rows (`ch_info.cpp`).
class MirrorInfo {
  const MirrorInfo({
    this.ip = '',
    this.ssid = '',
    this.rssi = 0,
    this.upMin = 0,
    this.heapK = 0,
    this.blockK = 0,
    this.fw = '',
    this.channelsOn = 0,
    this.channelsTotal = 0,
    this.updatedMin,
    this.nextMin = 0,
  });

  final String ip, ssid;
  final int rssi, upMin, heapK, blockK;

  /// Firmware version without the "v".
  final String fw;

  /// Channels in rotation (the app's guess: `/api/state` does not send the device's count) / all channels.
  final int channelsOn, channelsTotal;

  /// Minutes since the last completed fetch (newest `last_ok` the state reports); null = none yet.
  final int? updatedMin;
  final int nextMin;
}

/// Weather + Clock + Info data of a `MirrorFrame`.
class MirrorAmbient {
  const MirrorAmbient({
    this.weather = const MirrorWeather(),
    this.clock = const MirrorClock(),
    this.info = const MirrorInfo(),
  });

  final MirrorWeather weather;
  final MirrorClock clock;
  final MirrorInfo info;
}
