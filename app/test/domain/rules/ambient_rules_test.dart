import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/device_state.dart';
import 'package:glimmer_app/domain/models/mirror_ambient.dart';
import 'package:glimmer_app/domain/rules/ambient_rules.dart';
import 'package:glimmer_app/domain/rules/time_rules.dart';

/// 2026-11-26 14:15:57 at GMT+7 (device epoch of a real /api/state read).
const _now = 1795676157;
const _vn = {'tzMinutes': 420, 'weatherLat': 20.4737, 'weatherLon': 106.0229, 'userName': 'Tuấn Anh'};

DeviceWeather _weather({bool valid = true, String err = '', bool stale = false, int lastOk = _now - 445}) =>
    DeviceWeather.fromJson({
      'valid': valid,
      'temp_c': 21.6,
      'feels_c': 21.4,
      'code': 3,
      'desc': 'Nhiều mây',
      'humidity': 60,
      'wind_kmh': 7.2,
      'last_ok': lastOk,
      'stale': stale,
      'err': err,
      'days': [
        {'tmin': 15.3, 'tmax': 22, 'desc': 'Nhiều mây'},
        {'tmin': 17.2, 'tmax': 25, 'desc': 'Mưa'},
        {'tmin': 15.9, 'tmax': 26.7, 'desc': 'Mưa rào'},
      ],
    });

void main() {
  test('spanOf làm tròn như shortDuration: phút, giờ (+30 phút), ngày (+12 giờ)', () {
    expect(spanOf(-5), const MirrorSpan(0, SpanUnit.minutes));
    expect(spanOf(14 * 60 + 59), const MirrorSpan(14, SpanUnit.minutes));
    expect(spanOf(3600 + 1800), const MirrorSpan(2, SpanUnit.hours));
    expect(spanOf(172799), const MirrorSpan(48, SpanUnit.hours));
    expect(spanOf(172800 + 43200), const MirrorSpan(3, SpanUnit.days));
  });

  test('gmtLabel: GMT+7, GMT-3, GMT+5:30', () {
    expect((gmtLabel(420), gmtLabel(-180), gmtLabel(330), gmtLabel(0)), ('GMT+7', 'GMT-3', 'GMT+5:30', 'GMT+0'));
  });

  test('greetSlot theo giờ: < 5 đêm, < 12 sáng, < 17 chiều, < 21 tối, còn lại nghỉ', () {
    expect([for (final h in [4, 5, 11, 12, 16, 17, 20, 21, 23]) greetSlot(h)], [
      GreetSlot.night,
      GreetSlot.morning,
      GreetSlot.morning,
      GreetSlot.afternoon,
      GreetSlot.afternoon,
      GreetSlot.evening,
      GreetSlot.evening,
      GreetSlot.late,
      GreetSlot.late,
    ]);
  });

  test('weatherErrOf đọc lỗi như errorDetail', () {
    expect(weatherErrOf('HTTP 500'), (WeatherErr.http, 500));
    expect(weatherErrOf('HTTP -1'), (WeatherErr.connect, 0));
    expect(weatherErrOf('http begin'), (WeatherErr.begin, 0));
    expect(weatherErrOf('JSON IncompleteInput'), (WeatherErr.json, 0));
    expect(weatherErrOf('no current'), (WeatherErr.noCurrent, 0));
    expect(weatherErrOf('???'), (WeatherErr.unknown, 0));
  });

  test('weatherOf: chưa có gì → đang tải; lỗi trước khi có số → lỗi', () {
    expect(weatherOf(null, _vn, _now).phase, WeatherPhase.loading);
    expect(weatherOf(_weather(valid: false), _vn, _now).phase, WeatherPhase.loading);
    final e = weatherOf(_weather(valid: false, err: 'HTTP 503'), _vn, _now);
    expect((e.phase, e.err, e.errCode), (WeatherPhase.error, WeatherErr.http, 503));
  });

  test('weatherOf: số làm tròn, độ F, ba ngày, tuổi số liệu', () {
    final w = weatherOf(_weather(stale: true, lastOk: _now - 7200), _vn, _now);
    expect((w.phase, w.temp, w.feels, w.humidity, w.wind, w.stale), (WeatherPhase.ready, 22, 21, 60, 7, true));
    expect(w.age, const MirrorSpan(2, SpanUnit.hours));
    expect([for (final d in w.days) '${d.hi}/${d.lo}'], ['22/15', '25/17', '27/16']);
    final f = weatherOf(_weather(), {..._vn, 'useFahrenheit': true}, _now);
    expect((f.temp, f.days.first.hi), (71, 72));
  });

  test('forecastSpan: thang chung 125…184, tối thiểu 4 px, ngày thiếu → không vẽ', () {
    final days = [
      const WeatherDay(tmin: 24, tmax: 31),
      const WeatherDay(tmin: 24, tmax: 30),
      const WeatherDay(tmin: 23, tmax: 28),
    ];
    final (gMin, range) = forecastRange(days);
    expect((gMin, range), (23.0, 8.0));
    expect(forecastSpan(24, 31, gMin, range), (132, 184));
    expect(forecastSpan(23, 23, gMin, range), (125, 129));
    expect(forecastSpan(null, 30, gMin, range), (0, 0));
    expect(forecastRange(const [WeatherDay(), WeatherDay(), WeatherDay()]), (0.0, 30.0));
  });

  test('sunEpoch: Hà Nam 26/11 — mọc ~6:13, lặn ~17:14 giờ máy', () {
    final day = DateTime.utc(2026, 11, 26);
    final rise = deviceLocal(sunEpoch(day, 20.4737, 106.0229, 420, rising: true)!, 420);
    final set = deviceLocal(sunEpoch(day, 20.4737, 106.0229, 420, rising: false)!, 420);
    expect(rise.hour * 60 + rise.minute, closeTo(6 * 60 + 13, 4));
    expect(set.hour * 60 + set.minute, closeTo(17 * 60 + 14, 4));
    expect((rise.day, set.day), (26, 26));
  });

  test('nextSunEvent: trước bình minh → mọc, chiều → lặn, tối → mọc ngày mai, không có vị trí → null', () {
    expect(nextSunEvent(_vn, _now)?.$1, SunEvent.set);
    expect(nextSunEvent(_vn, _now - 10 * 3600)?.$1, SunEvent.rise);
    final evening = nextSunEvent(_vn, _now + 6 * 3600)!;
    expect((evening.$1, deviceLocal(evening.$2, 420).day), (SunEvent.rise, 27));
    expect(nextSunEvent(const {'tzMinutes': 420}, _now), isNull);
  });

  test('infoOf: KB, phút, đoán số kênh, cập nhật gần nhất', () {
    final s = DeviceState.fromJson({
      'fw': '0.23.0-glimmer',
      'ip': '192.168.10.51',
      'ssid': 'Ptv',
      'rssi': -60,
      'uptime_s': 1655,
      'heap': 22464,
      'maxblk': 21088,
      'next_fetch_s': 154,
      'skills_on': ['agent', 'weather', 'clock'],
      'claude_usage': {'last_ok': _now - 138},
      'weather': {'valid': true, 'last_ok': _now - 445},
    });
    final i = infoOf(s, const {'showClaude': true, 'showInfo': true}, _now);
    expect((i.upMin, i.heapK, i.blockK, i.nextMin, i.updatedMin), (27, 21, 20, 2, 2));
    expect((i.channelsOn, i.channelsTotal), (5, 14));
    expect(infoOf(s, null, 0).updatedMin, isNull);
  });

  test('ambientOf: tuần ISO, GMT, lời chào, tên người dùng', () {
    final s = DeviceState.fromJson({'time': _now});
    final a = ambientOf(s, _vn, _now, deviceLocal(_now, 420));
    expect((a.clock.week, a.clock.gmt, a.clock.greet, a.clock.userName), (48, 'GMT+7', GreetSlot.afternoon, 'Tuấn Anh'));
  });
}
