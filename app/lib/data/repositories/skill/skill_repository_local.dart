import '../../../domain/rules/skill_rules.dart';
import '../../services/local_store_service.dart';
import 'skill_repository.dart';

class SkillRepositoryLocal extends SkillRepository {
  SkillRepositoryLocal({required LocalStoreService store, List<String>? packs})
      : _store = store,
        _packs = packs;

  final LocalStoreService _store;

  /// Skill app có gói (null = danh mục thật; test đổi được).
  final List<String>? _packs;

  @override
  String get active => resolveStoredSkill(_store.activeSkill, packs: _packs);

  @override
  void setActive(String id) {
    final next = resolveStoredSkill(id, packs: _packs);
    if (next == active && _store.activeSkill == next) return;
    _store.activeSkill = next;
    notifyListeners();
  }
}
