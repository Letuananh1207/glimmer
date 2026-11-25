import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/skill/skill_repository_local.dart';
import 'package:glimmer_app/domain/models/app_error.dart';
import 'package:glimmer_app/domain/models/device_state.dart';
import 'package:glimmer_app/domain/rules/skill_rules.dart';
import 'package:glimmer_app/domain/use_cases/toggle_skill_use_case.dart';
import 'package:glimmer_app/utils/result.dart';

import '../../testing/fakes/fake_repositories.dart';
import '../../testing/fakes/fake_services.dart';

const _url = 'http://192.168.1.50';
const _all = ['agent', 'weather', 'clock'];

DeviceState _dev({List<String>? on, List<String>? skills}) => DeviceState.fromJson({
      'fw': '1.0',
      'skills': ?skills,
      'skills_on': ?on,
    });

Map<String, dynamic> _state(List<String> on) =>
    {'fw': '0.23.0', 'skill': on.first, 'skills': _all, 'skills_on': on};

void main() {
  group('rules', () {
    test('R-SK-1 default Agent + Thời tiết + Đồng hồ; stored ids kept in dock order, unknown dropped', () {
      expect(resolveStoredSkills(null), _all);
      expect(resolveStoredSkills(const []), _all, reason: 'at least one → empty is the default');
      expect(resolveStoredSkills(const ['gone']), _all);
      expect(resolveStoredSkills(const ['clock', 'gone', 'agent', 'clock']), ['agent', 'clock']);
    });

    test('R-SK-1 the last skill on cannot be turned off; turning on keeps dock order', () {
      expect(toggledSkills(const ['agent'], 'agent', enable: false), isNull);
      expect(toggledSkills(const ['agent', 'clock'], 'agent', enable: false), ['clock']);
      expect(toggledSkills(const ['clock'], 'agent', enable: true), ['agent', 'clock']);
      expect(toggledSkills(const ['agent'], 'weather', enable: true), ['agent', 'weather']);
    });

    test('R-SK-4 firmware without skills_on → nothing to toggle', () {
      final old = _dev();
      expect(old.skillsOn, isEmpty);
      expect(canToggleSkills(old), isFalse);
      expect(canToggleSkills(null), isFalse);
      expect(availableSkills(old), isEmpty);
      // The 2026-11-25.2 firmware reported one `skill` and `skills` but no list of skills on.
      expect(canToggleSkills(_dev(skills: ['agent'])), isFalse);
      final fresh = _dev(on: ['agent'], skills: ['agent', 'weather', 'clock', 'music']);
      expect(canToggleSkills(fresh), isTrue);
      expect(availableSkills(fresh), _all, reason: 'music has no pack in the app yet');
    });

    test('R-SK-5 the device list wins when it reports skills the app has', () {
      expect(effectiveSkillsOn(stored: _all, device: _dev(on: ['clock', 'agent'])), ['agent', 'clock']);
      expect(effectiveSkillsOn(stored: const ['agent'], device: _dev(on: ['music'])), ['agent'],
          reason: 'nothing the app knows → keep what is stored');
      expect(effectiveSkillsOn(stored: const ['weather']), ['weather']);
    });
  });

  test('R-SK-1 the repository stores the list, falls back to the default, drops the old single key', () async {
    final store = await fakeStore({'active_skill': 'agent'});
    final repo = SkillRepositoryLocal(store: store);
    expect(repo.enabled, _all, reason: 'upgrade keeps what the device was rotating');
    var notified = 0;
    repo.addListener(() => notified++);
    repo.setEnabled(const ['clock', 'agent']);
    expect(store.skillsOn, ['agent', 'clock']);
    expect(repo.enabled, ['agent', 'clock']);
    expect(notified, 1);
    final again = await fakeStore({'skills_on': <String>['gone']});
    expect(SkillRepositoryLocal(store: again).enabled, _all);
  });

  group('ToggleSkillUseCase', () {
    late DeviceRig rig;
    late SkillRepositoryLocal skills;
    late ToggleSkillUseCase toggle;
    setUp(() async {
      rig = await DeviceRig.create();
      skills = SkillRepositoryLocal(store: await fakeStore());
      toggle = ToggleSkillUseCase(skills: skills, device: rig.repo);
    });
    tearDown(() => rig.repo.dispose());

    test('R-SK-2 turning a skill off sends the new list {skillsOn}, then stores it', () async {
      await rig.connect(_url, _state(_all));
      rig.api.on(_url, 'POST', '/api/settings', <String, dynamic>{});
      expect(await toggle('weather', enable: false), isA<Ok<void>>());
      expect(rig.posts('/api/settings').single.body, {
        'skillsOn': ['agent', 'clock'],
      });
      expect(skills.enabled, ['agent', 'clock']);
    });

    test('R-SK-2 the device refusing → nothing stored', () async {
      await rig.connect(_url, _state(_all));
      expect(await toggle('weather', enable: false), isA<Error<void>>());
      expect(skills.enabled, _all);
    });

    test('R-SK-1 turning off the last skill on → skillLastOne, nothing sent', () async {
      await rig.connect(_url, _state(const ['agent']));
      final r = await toggle('agent', enable: false);
      expect(((r as Error).error as AppError).kind, AppErrorKind.skillLastOne);
      expect(rig.posts(), isEmpty);
    });

    test('R-SK-4 old firmware → only Agent, skillUnsupported, nothing sent', () async {
      await rig.connect(_url, {'fw': '0.22.0'});
      final r = await toggle('weather', enable: false);
      expect(((r as Error).error as AppError).kind, AppErrorKind.skillUnsupported);
      expect(rig.posts(), isEmpty);
      expect(toggle.legacy, isTrue);
      expect(toggle.enabled, ['agent']);
      expect(toggle.available, isEmpty);
    });

    test('R-SK-4 a skill the device does not have → skillUnsupported', () async {
      await rig.connect(_url, {'fw': '1.0', 'skills': ['agent'], 'skills_on': ['agent']});
      final r = await toggle('clock', enable: true);
      expect(((r as Error).error as AppError).detail, 'clock');
      expect(rig.posts(), isEmpty);
    });

    test('R-SK-5 syncFromDevice follows the device list and stores it', () async {
      await rig.connect(_url, _state(_all));
      var notified = 0;
      skills.addListener(() => notified++);
      toggle.syncFromDevice();
      expect(skills.enabled, _all);
      expect(toggle.enabled, _all);
      expect(notified, 0, reason: 'already in sync → no change');
      await rig.connect(_url, _state(const ['agent', 'weather']));
      toggle.syncFromDevice();
      expect(skills.enabled, ['agent', 'weather']);
      expect(notified, 1);
    });
  });
}
