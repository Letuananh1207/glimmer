import 'package:flutter/foundation.dart';

import '../../../data/repositories/device/device_repository.dart';
import '../../../domain/rules/skill_rules.dart';
import '../../../domain/use_cases/switch_skill_use_case.dart';
import '../../../utils/result.dart';
import '../../../utils/safe_notifier.dart';

/// How one tile reads (screen_specs §6).
enum SkillTileState { current, available, switching, soon }

/// Banner at the top of the screen (none when null).
enum SkillsBanner { switching, error, legacy }

class SkillTileData {
  const SkillTileData(this.id, this.state, {required this.enabled});
  final String id;
  final SkillTileState state;

  /// Tappable now (current → open its home; available → switch; never while switching).
  final bool enabled;
}

/// Màn Skill: lưới skill, đổi skill (R-SK-1…5).
class SkillsViewModel extends ChangeNotifier with SafeNotifier {
  SkillsViewModel({
    required SwitchSkillUseCase switchSkill,
    required DeviceRepository device,
    List<SkillInfo> catalog = skillCatalog,
  })  : _switch = switchSkill,
        _device = device,
        _catalog = catalog {
    _device.addListener(_onDevice);
    _switch.syncFromDevice();
  }

  final SwitchSkillUseCase _switch;
  final DeviceRepository _device;
  final List<SkillInfo> _catalog;

  String? _target;
  String? _failed;

  /// Skill owning the device screen (follows the device, R-SK-5).
  String get active => _switch.active;

  /// Skill being switched to, null when idle.
  String? get target => _target;

  /// Firmware version for the legacy banner.
  String get firmware => _switch.firmware;

  SkillsBanner? get banner {
    if (_target != null) return SkillsBanner.switching;
    if (_failed != null) return SkillsBanner.error;
    if (_switch.legacy) return SkillsBanner.legacy;
    return null;
  }

  List<SkillTileData> get tiles {
    final available = _switch.available;
    final busy = _target != null;
    return [
      for (final s in _catalog)
        if (s.id == active)
          SkillTileData(s.id, SkillTileState.current, enabled: !busy)
        else if (s.id == _target)
          SkillTileData(s.id, SkillTileState.switching, enabled: false)
        else if (s.hasPack && available.contains(s.id))
          SkillTileData(s.id, SkillTileState.available, enabled: !busy)
        else
          SkillTileData(s.id, SkillTileState.soon, enabled: false),
    ];
  }

  void _onDevice() {
    _switch.syncFromDevice();
    notifyListeners();
  }

  /// Switch to [id] at once (no confirm). Only for an available tile; the current one stays current
  /// until the device takes it (R-SK-2).
  Future<void> select(String id) async {
    if (_target != null || id == active) return;
    _target = id;
    _failed = null;
    notifyListeners();
    final r = await _switch(id);
    _target = null;
    if (r is Error) _failed = id;
    notifyListeners();
  }

  /// Error banner → send the skill just chosen again.
  Future<void> retry() async {
    final id = _failed;
    if (id != null) await select(id);
  }

  @override
  void dispose() {
    _device.removeListener(_onDevice);
    super.dispose();
  }
}
