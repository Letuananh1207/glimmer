import 'package:flutter_test/flutter_test.dart';
import 'package:glimmer_app/data/repositories/skill/skill_repository_local.dart';
import 'package:glimmer_app/domain/use_cases/toggle_skill_use_case.dart';
import 'package:glimmer_app/ui/home/view_models/home_view_model.dart';

import '../../../../testing/fakes/fake_repositories.dart';
import '../../../../testing/fakes/fake_services.dart';

const _url = 'http://192.168.1.50';

void main() {
  test('badge = agents waiting; notifies only when the count changes', () async {
    final rig = await DeviceRig.create();
    await rig.connect(_url);
    final skills = SkillRepositoryLocal(store: await fakeStore());
    final vm = HomeViewModel(toggleSkill: ToggleSkillUseCase(skills: skills, device: rig.repo), device: rig.repo);
    var notified = 0;
    vm.addListener(() => notified++);
    expect(vm.waiting, 0);
    rig.api.on(_url, 'GET', '/push', {
      'cards': [
        {'id': 'a', 'kind': 'approval'},
        {'id': 'b', 'kind': 'input'},
      ],
    });
    await rig.repo.refresh();
    expect((vm.waiting, notified), (2, 1));
    await rig.repo.refresh();
    expect(notified, 1);
    vm.dispose();
    rig.repo.dispose();
  });
}
