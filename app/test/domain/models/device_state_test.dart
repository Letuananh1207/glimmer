import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/domain/models/attention_card.dart';
import 'package:glimmer_app/domain/models/device_state.dart';

void main() {
  test('state JSON from the firmware parses, including usage and the board', () {
    final s = DeviceState.fromJson({
      'fw': '0.22.0-glimmer',
      'build': 'Nov 25 2026 10:21:07',
      'wifi': 'connected',
      'ip': '192.168.100.40',
      'ssid': 'Anh Viet',
      'rssi': -48,
      'uptime_s': 120,
      'heap': 26000,
      'maxblk': 24000,
      'heap_refusals': 0,
      'time': 1795500000,
      'claude_configured': true,
      'claude_usage': {
        'session_used': -1,
        'weekly_used': 66,
        'session_reset': 0,
        'weekly_reset': 1795579199,
        'last_ok': 1795499900,
        'stale': false,
        'cred': 'ok',
      },
      'projects': [
        {'project': 'glimmer', 'agent': 'claude', 'state': 'approval', 'detail': 'Bash', 'age_s': 30, 'idle_s': 5, 'shown': true},
      ],
    });
    expect(s.usage.weeklyUsed, 66);
    expect(s.usage.sessionUsed, -1);
    expect(s.projects.single.detail, 'Bash');
    expect(s.inSetupMode, isFalse);
    expect(s.buildTime, DateTime(2026, 11, 25, 10, 21, 7));
  });

  test('missing fields fall back instead of throwing (older firmware)', () {
    final s = DeviceState.fromJson({'fw': 'x', 'wifi': 'ap'});
    expect(s.inSetupMode, isTrue);
    expect(s.usage.weeklyUsed, -1);
    expect(s.projects, isEmpty);
    expect(s.clockSynced, isFalse);
    expect(s.buildTime, isNull);
  });

  test('card JSON parses; progress defaults to -1', () {
    final c = AttentionCard.fromJson({'id': 'k1', 'kind': 'approval', 'title': 'APPROVAL NEEDED'});
    expect((c.id, c.kind, c.progress, c.body), ('k1', 'approval', -1, ''));
  });

  test('skills_on and weather (firmware 2026-11-25.3); -999 / -1 → unknown', () {
    final s = DeviceState.fromJson({
      'skills': ['agent', 'weather', 'clock'],
      'skills_on': ['agent', 'clock'],
      'weather_configured': true,
      'weather': {
        'valid': true,
        'temp_c': 24.5,
        'feels_c': -999,
        'code': 3,
        'desc': 'Nhiều mây',
        'is_day': false,
        'humidity': -1,
        'wind_kmh': 7.2,
        'last_ok': 1795500000,
        'stale': true,
        'err': '',
        'days': [
          {'tmin': 20, 'tmax': 27.5, 'code': 61, 'desc': 'Mưa nhẹ'},
          {'tmin': -999, 'tmax': -999, 'code': 0, 'desc': 'Quang'},
        ],
      },
    });
    expect(s.skillsOn, ['agent', 'clock']);
    final w = s.weather!;
    expect((w.valid, w.tempC, w.feelsC, w.code, w.desc, w.isDay), (true, 24.5, null, 3, 'Nhiều mây', false));
    expect((w.humidity, w.windKmh, w.lastOk, w.stale), (null, 7.2, 1795500000, true));
    expect(w.days.map((d) => (d.tmin, d.tmax, d.code, d.desc)), [(20.0, 27.5, 61, 'Mưa nhẹ'), (null, null, 0, 'Quang')]);
    final none = DeviceState.fromJson({'fw': '0.22.0'});
    expect((none.weather, none.weatherConfigured, none.skillsOn.length), (null, false, 0));
  });
}
