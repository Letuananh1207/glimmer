import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/skill/skill_repository_local.dart';
import 'package:glimmer_app/domain/models/attention_card.dart';
import 'package:glimmer_app/domain/models/device_state.dart';
import 'package:glimmer_app/domain/rules/board_rules.dart';
import 'package:glimmer_app/domain/use_cases/toggle_skill_use_case.dart';
import 'package:glimmer_app/ui/dashboard/view_models/dashboard_view_model.dart';
import 'package:glimmer_app/utils/result.dart';

import '../../../../testing/fakes/fake_repositories.dart';
import '../../../../testing/fakes/fake_services.dart';

const _url = 'http://192.168.1.50';

/// 2026-11-24 13:00:00 at UTC+7 (a Tuesday, ISO week 48).
const _now = 1795500000;

Map<String, dynamic> _state({List<String> on = const ['agent', 'weather', 'clock'], Map<String, dynamic>? weather}) => {
      'fw': '1.0',
      'wifi': 'connected',
      'time': _now,
      'skills': ['agent', 'weather', 'clock'],
      'skills_on': on,
      'weather_configured': weather != null,
      'weather': ?weather,
    };

AttentionCard _card(String kind, {int showsIn = 0}) =>
    AttentionCard('id', kind, 'claude', '', '', '', '', -1, 0, showsInS: showsIn);

void main() {
  late DeviceRig rig;
  setUp(() async => rig = await DeviceRig.create());
  tearDown(() => rig.repo.dispose());

  Future<DashboardViewModel> vmFor(Map<String, dynamic> state, {Map<String, dynamic>? settings}) async {
    if (settings != null) rig.api.on(_url, 'GET', '/api/settings', settings);
    await rig.connect(_url, state);
    final skills = SkillRepositoryLocal(store: await fakeStore());
    final vm = DashboardViewModel(
      device: rig.repo,
      toggleSkill: ToggleSkillUseCase(skills: skills, device: rig.repo),
      now: () => DateTime.fromMillisecondsSinceEpoch(_now * 1000),
    );
    await Future<void>.delayed(Duration.zero); // settings load
    return vm;
  }

  group('tabs', () {
    test('tabs follow the enabled skills in dock order; starts on the first', () async {
      final vm = await vmFor(_state(on: ['clock', 'agent']));
      expect(vm.tabs, ['agent', 'clock']);
      expect((vm.showTabs, vm.selected), (true, 'agent'));
      vm.dispose();
    });

    test('one skill → no tab bar', () async {
      final vm = await vmFor(_state(on: ['weather']));
      expect((vm.showTabs, vm.selected), (false, 'weather'));
      vm.dispose();
    });

    test('selected skill turned off on the device → back to the first tab', () async {
      final vm = await vmFor(_state());
      vm.select('weather');
      expect(vm.selected, 'weather');
      vm.select('music');
      expect(vm.selected, 'weather', reason: 'not a tab');
      rig.api.device(_url, _state(on: ['agent', 'clock']));
      await rig.repo.refresh();
      expect(vm.selected, 'agent');
      vm.dispose();
    });

    test('legacy firmware (no skills_on) → Agent only', () async {
      final vm = await vmFor({'fw': '0.22.0', 'wifi': 'connected', 'time': _now});
      expect((vm.tabs.join(','), vm.showTabs), ('agent', false));
      vm.dispose();
    });

    test('show on device posts the channel of the selected tab', () async {
      final vm = await vmFor(_state());
      rig.api.on(_url, 'POST', '/api/channel', <String, dynamic>{});
      vm.select('clock');
      expect(await vm.showOnDevice(), isA<Ok<void>>());
      expect(rig.posts('/api/channel').last.body, {'name': 'Clock'});
      vm.select('weather');
      await vm.showOnDevice();
      expect(rig.posts('/api/channel').last.body, {'name': 'Weather'});
      vm.select('agent');
      await vm.showOnDevice();
      expect(rig.posts('/api/channel').last.body, {'name': 'Claude'});
      vm.dispose();
    });
  });

  group('agents waiting', () {
    test('approval + input showing count; hidden cards and other kinds do not', () {
      final n = agentsWaiting([
        _card('approval'),
        _card('input'),
        _card('input', showsIn: 40),
        _card('success'),
        _card('error'),
      ]);
      expect(n, 2);
    });

    test('badge: hidden at 0, "9+" above 9', () {
      expect((badgeText(0), badgeText(3), badgeText(9), badgeText(10)), (null, '3', '9', '9+'));
    });

    test('the view model counts the device cards', () async {
      final vm = await vmFor(_state());
      rig.api.on(_url, 'GET', '/push', {
        'cards': [
          {'id': 'a', 'kind': 'approval'},
          {'id': 'b', 'kind': 'input', 'shows_in_s': 30},
        ],
      });
      await rig.repo.refresh();
      expect(vm.waiting, 1);
      vm.dispose();
    });
  });

  group('clock', () {
    test('24 h in the device zone, ISO week, night window', () async {
      final vm = await vmFor(_state(), settings: {
        'tzMinutes': 420,
        'clock24h': true,
        'nightMode': 1,
        'nightStartMin': 1380,
        'nightEndMin': 420,
      });
      final c = vm.clock;
      expect((c.hour, c.minute, c.pm, c.weekday, c.date, c.week, c.tz), ('13', '00', null, 2, '24/11', 48, 'UTC+7'));
      expect((c.night!.start, c.night!.end, c.night!.mode), ('23:00', '07:00', 1));
      vm.dispose();
    });

    test('12 h → 1 CH; night off when mode 0', () async {
      final vm = await vmFor(_state(), settings: {'tzMinutes': 420, 'clock24h': false, 'nightMode': 0});
      final c = vm.clock;
      expect((c.hour, c.minute, c.pm, c.h24), ('1', '00', true, false));
      expect(c.night, isNull);
      vm.dispose();
    });

    test('device clock not set → "--:--"', () {
      final c = ClockView.from(epoch: 0, synced: false, tzMinutes: 0);
      expect((c.hour, c.minute), ('--', '--'));
    });

    test('UTC label with minutes and negative zones', () {
      expect((ClockView.utcLabel(330), ClockView.utcLabel(-300), ClockView.utcLabel(0)),
          ('UTC+5:30', 'UTC-5', 'UTC+0'));
    });
  });

  group('weather', () {
    final good = <String, dynamic>{
      'valid': true,
      'temp_c': 29.4,
      'feels_c': 33,
      'desc': 'Ít mây',
      'last_ok': _now - 600,
      'days': [
        {'tmin': 24, 'tmax': 31, 'desc': 'Ít mây'},
        {'tmin': 25, 'tmax': 30, 'desc': 'Mưa rào'},
        {'tmin': 25, 'tmax': 32, 'desc': 'Nắng'},
        {'tmin': -999, 'tmax': -999, 'desc': 'Nhiều mây'},
      ],
    };

    test('now, hi/lo of today, three forecast rows with weekdays, age', () async {
      final vm = await vmFor(_state(weather: good), settings: {'tzMinutes': 420});
      final w = vm.weather;
      expect((w.status, w.temp, w.hi, w.lo, w.feels, w.ageS), (WeatherStatus.ok, 29, 31, 24, 33, 600));
      expect(w.forecast.map((r) => (r.offset, r.weekday, r.hi, r.lo)).toList(), [
        (1, DateTime.wednesday, 30, 25),
        (2, DateTime.thursday, 32, 25),
        (3, DateTime.friday, null, null),
      ]);
      vm.dispose();
    });

    test('useFahrenheit → °F', () async {
      final vm = await vmFor(_state(weather: good), settings: {'tzMinutes': 420, 'useFahrenheit': true});
      expect((vm.weather.temp, vm.weather.hi), (85, 88));
      vm.dispose();
    });

    test('no location → noLocation; located but never fetched → waiting', () {
      final day = DateTime.utc(2026, 11, 24);
      WeatherStatus status(Map<String, dynamic> j) =>
          WeatherView.from(DeviceState.fromJson(j), now: _now, today: day, fahrenheit: false).status;
      expect(status(_state()), WeatherStatus.noLocation);
      expect(status({..._state(), 'weather_configured': true, 'weather': <String, dynamic>{'valid': false, 'last_ok': 0}}),
          WeatherStatus.waiting);
      expect(status({..._state(), 'weather_configured': true}), WeatherStatus.waiting);
    });
  });
}
