import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/skill/skill_repository_local.dart';
import 'package:glimmer_app/domain/models/app_error.dart';
import 'package:glimmer_app/domain/models/device_state.dart';
import 'package:glimmer_app/domain/rules/skill_rules.dart';
import 'package:glimmer_app/domain/use_cases/switch_skill_use_case.dart';
import 'package:glimmer_app/utils/result.dart';

import '../../testing/fakes/fake_repositories.dart';
import '../../testing/fakes/fake_services.dart';

const _url = 'http://192.168.1.50';

DeviceState _dev({String? skill, List<String>? skills}) => DeviceState.fromJson({
      'fw': '1.0',
      'skill': ?skill,
      'skills': ?skills,
    });

void main() {
  group('rules', () {
    test('R-SK-1 default agent; a stored id no longer in the catalogue falls back', () {
      expect(resolveStoredSkill(null), SkillIds.agent);
      expect(resolveStoredSkill('agent'), SkillIds.agent);
      expect(resolveStoredSkill('gone'), SkillIds.agent);
    });

    test('R-SK-4 firmware without skills → only the default, no switching', () {
      final old = _dev();
      expect(old.skill, '');
      expect(old.skills, isEmpty);
      expect(canSwitchSkill(old), isFalse);
      expect(canSwitchSkill(null), isFalse);
      expect(availableSkills(old), [SkillIds.agent]);
      final fresh = _dev(skill: 'agent', skills: ['agent', 'music']);
      expect(canSwitchSkill(fresh), isTrue);
      expect(availableSkills(fresh), [SkillIds.agent], reason: 'music has no pack in the app yet');
    });

    test('R-SK-5 the device wins when it reports a skill the app has', () {
      expect(effectiveSkill(stored: 'gone', device: _dev(skill: 'agent', skills: ['agent'])), 'agent');
      expect(effectiveSkill(stored: 'agent', device: _dev(skill: 'music', skills: ['music'])), 'agent',
          reason: 'unknown to the app → keep what is stored');
      expect(effectiveSkill(stored: 'agent'), 'agent');
    });
  });

  test('R-SK-1 the repository stores the id and falls back to the default', () async {
    final store = await fakeStore({'active_skill': 'gone'});
    final repo = SkillRepositoryLocal(store: store);
    expect(repo.active, SkillIds.agent);
    repo.setActive('agent');
    expect(store.activeSkill, 'agent');
  });

  group('SwitchSkillUseCase', () {
    late DeviceRig rig;
    late SkillRepositoryLocal skills;
    late SwitchSkillUseCase sw;
    setUp(() async {
      rig = await DeviceRig.create();
      skills = SkillRepositoryLocal(store: await fakeStore());
      sw = SwitchSkillUseCase(skills: skills, device: rig.repo);
    });
    tearDown(() => rig.repo.dispose());

    test('R-SK-2 switching sends {skill} to the device, then stores it', () async {
      await rig.connect(_url, {'fw': '1.0', 'skill': 'agent', 'skills': ['agent']});
      rig.api.on(_url, 'POST', '/api/settings', <String, dynamic>{});
      expect(await sw('agent'), isA<Ok<void>>());
      expect(rig.posts('/api/settings').single.body, {'skill': 'agent'});
      expect(skills.active, 'agent');
    });

    test('R-SK-2 the device refusing → nothing stored', () async {
      await rig.connect(_url, {'fw': '1.0', 'skill': 'agent', 'skills': ['agent']});
      final before = skills.active;
      expect(await sw('agent'), isA<Error<void>>());
      expect(skills.active, before);
    });

    test('R-SK-4 old firmware → skillUnsupported, nothing sent', () async {
      await rig.connect(_url, {'fw': '0.22.0'});
      final r = await sw('agent');
      expect(((r as Error).error as AppError).kind, AppErrorKind.skillUnsupported);
      expect(rig.posts(), isEmpty);
      expect(sw.available, [SkillIds.agent]);
    });

    test('R-SK-4 a skill the device does not have → skillUnsupported', () async {
      await rig.connect(_url, {'fw': '1.0', 'skill': 'agent', 'skills': ['agent']});
      final r = await sw('music');
      expect(((r as Error).error as AppError).detail, 'music');
      expect(rig.posts(), isEmpty);
    });

    test('R-SK-5 syncFromDevice follows the device and stores it', () async {
      await rig.connect(_url, {'fw': '1.0', 'skill': 'agent', 'skills': ['agent']});
      var notified = 0;
      skills.addListener(() => notified++);
      sw.syncFromDevice();
      expect((skills.active, sw.active), ('agent', 'agent'));
      expect(notified, 0, reason: 'already in sync (default = device) → no write');
      // A device skill the app has no pack for is not followed.
      await rig.connect(_url, {'fw': '1.0', 'skill': 'music', 'skills': ['agent', 'music']});
      sw.syncFromDevice();
      expect((skills.active, notified), ('agent', 0));
    });
  });
}
