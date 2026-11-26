import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/skill/skill_repository_local.dart';
import 'package:glimmer_app/domain/use_cases/toggle_skill_use_case.dart';
import 'package:glimmer_app/ui/dashboard/view_models/dashboard_view_model.dart';

import '../../../../testing/fakes/fake_repositories.dart';
import '../../../../testing/fakes/fake_services.dart';

const _url = 'http://192.168.1.50';

void main() {
  test('Số liệu opens at the tab of the channel on the device (2026-11-26.5), else the first', () async {
    final rig = await DeviceRig.create();
    await rig.connect(_url, {
      'fw': '0.25.0',
      'wifi': 'connected',
      'skills_on': ['agent', 'weather', 'clock'],
    });
    final toggle = ToggleSkillUseCase(skills: SkillRepositoryLocal(store: await fakeStore()), device: rig.repo);
    final weather = DashboardViewModel(device: rig.repo, toggleSkill: toggle, initialTab: 'weather');
    final gone = DashboardViewModel(device: rig.repo, toggleSkill: toggle, initialTab: 'photo');
    expect(weather.selected, 'weather');
    expect(gone.selected, 'agent');
    weather.dispose();
    gone.dispose();
    rig.repo.dispose();
  });
}
