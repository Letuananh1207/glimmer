import '../../../domain/rules/skill_rules.dart';
import '../../services/local_store_service.dart';
import 'skill_repository.dart';

class SkillRepositoryLocal extends SkillRepository {
  SkillRepositoryLocal({required LocalStoreService store}) : _store = store;

  final LocalStoreService _store;

  @override
  String get active => resolveStoredSkill(_store.activeSkill);

  @override
  void setActive(String id) {
    final next = resolveStoredSkill(id);
    if (next == active && _store.activeSkill == next) return;
    _store.activeSkill = next;
    notifyListeners();
  }
}
