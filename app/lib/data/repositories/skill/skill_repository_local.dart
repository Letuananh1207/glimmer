import 'package:flutter/foundation.dart';

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
  List<String> get enabled => resolveStoredSkills(_store.skillsOn, packs: _packs);

  @override
  void setEnabled(List<String> ids) {
    final next = resolveStoredSkills(ids, packs: _packs);
    final changed = !listEquals(next, enabled);
    if (!changed && _store.skillsOn != null) return;
    _store.skillsOn = next;
    if (changed) notifyListeners();
  }
}
