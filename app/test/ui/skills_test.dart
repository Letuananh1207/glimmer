import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/skill/skill_repository_local.dart';
import 'package:glimmer_app/domain/rules/skill_rules.dart';
import 'package:glimmer_app/domain/use_cases/switch_skill_use_case.dart';
import 'package:glimmer_app/l10n/app_localizations.dart';
import 'package:glimmer_app/ui/core/themes/app_theme.dart';
import 'package:glimmer_app/ui/home/widgets/home_shell.dart';
import 'package:glimmer_app/ui/skills/view_models/skills_view_model.dart';
import 'package:glimmer_app/ui/skills/widgets/skills_screen.dart';

import '../../testing/fakes/fake_repositories.dart';
import '../../testing/fakes/fake_services.dart';

const _url = 'http://192.168.1.50';
final _vi = lookupAppLocalizations(const Locale('vi'));

/// Catalogue as if Nhạc already had a pack (the canvas illustrates switching with it).
const _withMusic = [
  SkillInfo(SkillIds.agent, hasPack: true),
  SkillInfo(SkillIds.music, hasPack: true),
  SkillInfo(SkillIds.social, hasPack: false),
  SkillInfo(SkillIds.fun, hasPack: false),
];
final _packs = packsOf(_withMusic);

Map<String, dynamic> _state(String skill, [List<String> skills = const ['agent', 'music']]) =>
    {'fw': '1.0', 'skill': skill, 'skills': skills};

class _Rig {
  _Rig(this.device, this.vm);
  final DeviceRig device;
  final SkillsViewModel vm;
}

Future<_Rig> _rig({Map<String, dynamic>? state, bool deviceTakes = true}) async {
  final d = await DeviceRig.create();
  await d.connect(_url, state ?? _state('agent'));
  if (deviceTakes) {
    d.api.on(_url, 'POST', '/api/settings', <String, dynamic>{});
    // The device switches when it gets {skill}.
    d.api.onCall = (c) {
      final body = c.body;
      if (c.method == 'POST' && body is Map && body['skill'] is String) {
        d.api.on(_url, 'GET', '/api/state', _state(body['skill'] as String));
      }
    };
  }
  final skills = SkillRepositoryLocal(store: await fakeStore(), packs: _packs);
  final sw = SwitchSkillUseCase(skills: skills, device: d.repo, packs: _packs);
  return _Rig(d, SkillsViewModel(switchSkill: sw, device: d.repo, catalog: _withMusic));
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
    test('R-SK-1 tiles in catalogue order: current, available, soon', () async {
      final r = await _rig();
      expect(r.vm.tiles.map((t) => (t.id, t.state)), [
        ('agent', SkillTileState.current),
        ('music', SkillTileState.available),
        ('social', SkillTileState.soon),
        ('fun', SkillTileState.soon),
      ]);
      expect(r.vm.tiles.where((t) => t.enabled).map((t) => t.id), ['agent', 'music']);
      expect(r.vm.banner, isNull);
      r.vm.dispose();
      r.device.repo.dispose();
    });

    test('R-SK-2 switching: banner + dashed target, current kept until the device takes it', () async {
      final r = await _rig();
      final seen = <(String, SkillsBanner?)>[];
      r.vm.addListener(() => seen.add((r.vm.active, r.vm.banner)));
      final run = r.vm.select('music');
      expect(r.vm.banner, SkillsBanner.switching);
      expect(r.vm.tiles.firstWhere((t) => t.id == 'music').state, SkillTileState.switching);
      expect(r.vm.active, 'agent');
      expect(r.vm.tiles.every((t) => !t.enabled), isTrue, reason: 'nothing tappable while switching');
      await run;
      expect(r.device.posts('/api/settings').single.body, {'skill': 'music'});
      expect((r.vm.active, r.vm.banner), ('music', null));
      r.vm.dispose();
      r.device.repo.dispose();
    });

    test('device does not answer → error banner, skill unchanged; retry sends it again', () async {
      final r = await _rig(deviceTakes: false);
      await r.vm.select('music');
      expect((r.vm.banner, r.vm.active), (SkillsBanner.error, 'agent'));
      await r.vm.retry();
      expect(r.device.posts('/api/settings').length, 2);
      expect(r.vm.banner, SkillsBanner.error);
      r.vm.dispose();
      r.device.repo.dispose();
    });

    test('R-SK-4 old firmware → legacy banner, only Agent, nothing to switch to', () async {
      final r = await _rig(state: {'fw': '0.22.0'});
      expect((r.vm.banner, r.vm.firmware), (SkillsBanner.legacy, '0.22.0'));
      expect(r.vm.tiles.firstWhere((t) => t.id == 'music').state, SkillTileState.soon);
      r.vm.dispose();
      r.device.repo.dispose();
    });

    test('R-SK-5 a skill changed on the device web page shows up as current', () async {
      final r = await _rig();
      r.device.api.on(_url, 'GET', '/api/state', _state('music'));
      await r.device.repo.refresh();
      expect(r.vm.active, 'music');
      expect(r.vm.tiles.first.state, SkillTileState.available);
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
      await t.pumpWidget(_app(SkillsScreen(viewModel: r.vm, onOpenHome: (_) {}, onOpenDevice: () {})));
      await _frames(t);
      return r;
    }

    testWidgets('normal: title, tiles, current label, soon label, channels card', (t) async {
      await pump(t);
      expect(find.text(_vi.skillsTitle), findsOneWidget);
      expect(find.text(_vi.skillAgentName), findsOneWidget);
      expect(find.text(_vi.skillsCurrent), findsOneWidget);
      expect(find.text(_vi.skillsUse), findsOneWidget);
      expect(find.text(_vi.skillsSoon), findsNWidgets(2));
      await t.scrollUntilVisible(find.text(_vi.skillsAttentionNote), 200);
      expect(find.text(_vi.skillAgentChannels), findsOneWidget);
    });

    testWidgets('switching then error: banner texts and retry', (t) async {
      final r = await pump(t, deviceTakes: false);
      r.device.api.holdPosts = Completer<void>();
      final run = r.vm.select('music');
      await _frames(t);
      expect(find.text(_vi.skillsSwitchingBanner(_vi.skillMusicName)), findsOneWidget);
      expect(find.text(_vi.skillsSwitching), findsOneWidget);
      r.device.api.holdPosts!.complete();
      r.device.api.holdPosts = null;
      await t.runAsync(() => run);
      await _frames(t);
      expect(find.text(_vi.skillsErrorTitle), findsOneWidget);
      expect(find.text(_vi.skillsErrorBody(_vi.skillAgentName)), findsOneWidget);
      expect(find.text(_vi.commonRetry), findsOneWidget);
    });

    testWidgets('legacy: amber banner with the firmware and the update button', (t) async {
      await pump(t, state: {'fw': '0.22.0'});
      expect(find.text(_vi.skillsLegacyTitle), findsOneWidget);
      expect(find.text(_vi.skillsLegacyBody('0.22.0')), findsOneWidget);
      expect(find.text(_vi.deviceUpdateFw), findsOneWidget);
    });
  });

  testWidgets('4 tabs: tab 1 is named after the skill in use', (t) async {
    await t.pumpWidget(_app(HomeShell(skill: 'agent', index: 1, onSelect: (_) {}, child: const SizedBox())));
    await _frames(t);
    for (final label in [_vi.skillAgentName, _vi.navSkills, _vi.navSettings, _vi.navDevice]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text(_vi.navDashboard), findsNothing);
  });
}
