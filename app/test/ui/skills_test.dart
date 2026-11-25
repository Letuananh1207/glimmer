import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/skill/skill_repository_local.dart';
import 'package:glimmer_app/domain/use_cases/toggle_skill_use_case.dart';
import 'package:glimmer_app/l10n/app_localizations.dart';
import 'package:glimmer_app/ui/core/themes/app_theme.dart';
import 'package:glimmer_app/ui/core/widgets/skill_switch.dart';
import 'package:glimmer_app/ui/core/widgets/count_badge.dart';
import 'package:glimmer_app/ui/home/widgets/home_shell.dart';
import 'package:glimmer_app/ui/skills/view_models/skills_view_model.dart';
import 'package:glimmer_app/ui/skills/widgets/skills_screen.dart';

import '../../testing/fakes/fake_repositories.dart';
import '../../testing/fakes/fake_services.dart';

const _url = 'http://192.168.1.50';
const _all = ['agent', 'weather', 'clock'];
final _vi = lookupAppLocalizations(const Locale('vi'));

Map<String, dynamic> _state(List<String> on) =>
    {'fw': '0.23.0', 'skill': on.first, 'skills': _all, 'skills_on': on};

class _Rig {
  _Rig(this.device, this.vm);
  final DeviceRig device;
  final SkillsViewModel vm;
}

Future<_Rig> _rig({Map<String, dynamic>? state, bool deviceTakes = true}) async {
  final d = await DeviceRig.create();
  await d.connect(_url, state ?? _state(_all));
  if (deviceTakes) {
    d.api.on(_url, 'POST', '/api/settings', <String, dynamic>{});
    // The device takes the list it gets in {skillsOn}.
    d.api.onCall = (c) {
      final body = c.body;
      if (c.method == 'POST' && body is Map && body['skillsOn'] is List) {
        d.api.on(_url, 'GET', '/api/state', _state([...(body['skillsOn'] as List).cast<String>()]));
      }
    };
  }
  final skills = SkillRepositoryLocal(store: await fakeStore());
  final toggle = ToggleSkillUseCase(skills: skills, device: d.repo);
  return _Rig(d, SkillsViewModel(toggleSkill: toggle, device: d.repo));
}

Widget _app(Widget child) => MaterialApp(
      theme: AppTheme.dark(),
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );

Future<void> _frames(WidgetTester t) async {
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('SkillsViewModel', () {
    test('R-SK-1 rows in dock order, all on by default; chips "Sắp có"', () async {
      final r = await _rig();
      expect(r.vm.rows.map((x) => (x.id, x.on, x.mode, x.enabled)), [
        ('agent', true, SkillRowMode.toggle, true),
        ('weather', true, SkillRowMode.toggle, true),
        ('clock', true, SkillRowMode.toggle, true),
      ]);
      expect(r.vm.soon, ['chat', 'music', 'social', 'fun']);
      expect((r.vm.banner, r.vm.showOrderNote), (null, true));
      r.vm.dispose();
      r.device.repo.dispose();
    });

    test('R-SK-1 only one skill on → its switch is locked (lastOne)', () async {
      final r = await _rig(state: _state(const ['agent']));
      final agent = r.vm.rows.first;
      expect((agent.on, agent.mode, agent.enabled), (true, SkillRowMode.lastOne, false));
      expect(r.vm.rows.skip(1).every((x) => !x.on && x.mode == SkillRowMode.toggle && x.enabled), isTrue);
      r.vm.dispose();
      r.device.repo.dispose();
    });

    test('R-SK-2 toggling: the row sends (device state kept), others locked; then follows the device', () async {
      final r = await _rig();
      final run = r.vm.toggle('weather', enable: false);
      final weather = r.vm.rows[1];
      expect((weather.mode, weather.on), (SkillRowMode.sending, true));
      expect(r.vm.rows.every((x) => !x.enabled), isTrue, reason: 'nothing tappable while sending');
      expect(r.vm.banner, isNull, reason: 'no banner while sending');
      await run;
      expect(r.device.posts('/api/settings').single.body, {
        'skillsOn': ['agent', 'clock'],
      });
      expect(r.vm.enabled, ['agent', 'clock']);
      expect(r.vm.rows[1].on, isFalse);
      r.vm.dispose();
      r.device.repo.dispose();
    });

    test('device does not answer → error banner, switches as the device has them; retry sends again', () async {
      final r = await _rig(deviceTakes: false);
      await r.vm.toggle('weather', enable: false);
      expect(r.vm.banner, SkillsBanner.error);
      expect((r.vm.failed?.id, r.vm.failed?.enable), ('weather', false));
      expect(r.vm.rows[1].on, isTrue);
      await r.vm.retry();
      expect(r.device.posts('/api/settings').length, 2);
      expect(r.vm.banner, SkillsBanner.error);
      r.vm.dispose();
      r.device.repo.dispose();
    });

    test('R-SK-4 old firmware → legacy banner, Agent locked, Thời tiết / Đồng hồ always on', () async {
      final r = await _rig(state: {'fw': '0.22.0'});
      expect((r.vm.banner, r.vm.firmware, r.vm.showOrderNote), (SkillsBanner.legacy, '0.22.0', false));
      expect(r.vm.rows.map((x) => (x.id, x.on, x.mode)), [
        ('agent', true, SkillRowMode.legacyLocked),
        ('weather', true, SkillRowMode.alwaysOn),
        ('clock', true, SkillRowMode.alwaysOn),
      ]);
      r.vm.dispose();
      r.device.repo.dispose();
    });

    test('R-SK-5 a list changed on the device web page shows up', () async {
      final r = await _rig();
      r.device.api.on(_url, 'GET', '/api/state', _state(const ['clock']));
      await r.device.repo.refresh();
      expect(r.vm.enabled, ['clock']);
      expect(r.vm.rows.last.mode, SkillRowMode.lastOne);
      r.vm.dispose();
      r.device.repo.dispose();
    });
  });

  group('SkillsScreen', () {
    Future<_Rig> pump(WidgetTester t, {Map<String, dynamic>? state, bool deviceTakes = true}) async {
      final r = (await t.runAsync(() => _rig(state: state, deviceTakes: deviceTakes)))!;
      addTearDown(() {
        r.vm.dispose();
        r.device.repo.dispose();
      });
      await t.pumpWidget(_app(SkillsScreen(viewModel: r.vm, onOpenDevice: () {})));
      await _frames(t);
      return r;
    }

    testWidgets('normal: rows with switches, order note, chips', (t) async {
      await pump(t);
      for (final s in [
        _vi.skillsTitle,
        _vi.skillsSubtitle,
        _vi.skillAgentName,
        _vi.skillWeatherName,
        _vi.skillClockName,
        _vi.skillWeatherDesc,
        _vi.skillsOrderNote,
        _vi.skillsSoonTitle,
        _vi.skillChatName,
        _vi.skillFunName,
      ]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      expect(find.byType(SkillSwitch), findsNWidgets(3));
      expect(find.bySemanticsLabel(_vi.skillsToggleA11y(_vi.skillClockName)), findsOneWidget);
    });

    testWidgets('sending then error: spinner on the row, then banner + retry', (t) async {
      final r = await pump(t, deviceTakes: false);
      r.device.api.holdPosts = Completer<void>();
      await t.tap(find.byType(SkillSwitch).at(1));
      await _frames(t);
      expect(find.text(_vi.skillsSending), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      r.device.api.holdPosts!.complete();
      r.device.api.holdPosts = null;
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await _frames(t);
      expect(find.text(_vi.skillsErrorOffTitle(_vi.skillWeatherName)), findsOneWidget);
      expect(find.text(_vi.skillsErrorOffBody(_vi.skillWeatherName)), findsOneWidget);
      expect(find.text(_vi.commonRetry), findsOneWidget);
    });

    testWidgets('last one: amber note instead of the description', (t) async {
      await pump(t, state: _state(const ['agent']));
      expect(find.text(_vi.skillsLastOne), findsOneWidget);
      expect(find.text(_vi.skillAgentDesc), findsNothing);
    });

    testWidgets('legacy: amber banner, padlock, "Luôn có", no order note', (t) async {
      await pump(t, state: {'fw': '0.22.0'});
      expect(find.text(_vi.skillsLegacyTitle), findsOneWidget);
      expect(find.text(_vi.skillsLegacyBody('0.22.0')), findsOneWidget);
      expect(find.text(_vi.deviceUpdateFw), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text(_vi.skillsAlwaysOn), findsNWidgets(2));
      expect(find.byType(SkillSwitch), findsNothing);
      expect(find.text(_vi.skillsOrderNote), findsNothing);
    });
  });

  testWidgets('4 tabs: tab 1 is Màn hình with the agents-waiting badge', (t) async {
    await t.pumpWidget(_app(HomeShell(waiting: 2, badge: '2', index: 1, onSelect: (_) {}, child: const SizedBox())));
    await _frames(t);
    for (final label in [_vi.navHome, _vi.navSkills, _vi.navSettings, _vi.navDevice]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('2'), findsOneWidget);
    await t.pumpWidget(_app(HomeShell(waiting: 12, badge: '9+', index: 0, onSelect: (_) {}, child: const SizedBox())));
    await _frames(t);
    expect(find.text('9+'), findsOneWidget);
    await t.pumpWidget(_app(HomeShell(waiting: 0, badge: null, index: 0, onSelect: (_) {}, child: const SizedBox())));
    await _frames(t);
    expect(find.byType(CountBadge), findsNothing);
  });
}
