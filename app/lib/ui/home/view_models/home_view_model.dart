import 'package:flutter/foundation.dart';

import '../../../data/repositories/device/device_repository.dart';
import '../../../data/repositories/skill/skill_repository.dart';
import '../../../domain/use_cases/switch_skill_use_case.dart';

/// Khung 4 tab: tab 1 theo skill đang dùng; app theo skill thiết bị báo (R-SK-5).
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required SwitchSkillUseCase switchSkill, required DeviceRepository device, required SkillRepository skills})
      : _switch = switchSkill,
        _device = device,
        _skills = skills {
    _device.addListener(_onDevice);
    _skills.addListener(_onSkill);
    _switch.syncFromDevice();
    _last = _switch.active;
  }

  final SwitchSkillUseCase _switch;
  final DeviceRepository _device;
  final SkillRepository _skills;
  late String _last;

  /// Skill whose home is tab 1.
  String get active => _switch.active;

  void _onDevice() {
    _switch.syncFromDevice();
    _onSkill();
  }

  // Rebuild only when the skill on tab 1 changes, not on every poll.
  void _onSkill() {
    if (_switch.active == _last) return;
    _last = _switch.active;
    notifyListeners();
  }

  @override
  void dispose() {
    _device.removeListener(_onDevice);
    _skills.removeListener(_onSkill);
    super.dispose();
  }
}
