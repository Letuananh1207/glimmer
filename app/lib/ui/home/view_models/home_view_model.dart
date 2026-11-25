import 'package:flutter/foundation.dart';

import '../../../data/repositories/device/device_repository.dart';
import '../../../domain/rules/board_rules.dart';
import '../../../domain/use_cases/toggle_skill_use_case.dart';

/// Khung 4 tab (tab 1 = Màn hình): huy hiệu agent chờ trên tab 1; app theo danh sách skill thiết bị báo (R-SK-5).
class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required ToggleSkillUseCase toggleSkill, required DeviceRepository device})
      : _toggle = toggleSkill,
        _device = device {
    _device.addListener(_onDevice);
    _toggle.syncFromDevice();
    _waiting = agentsWaiting(_device.cards);
  }

  final ToggleSkillUseCase _toggle;
  final DeviceRepository _device;
  int _waiting = 0;

  /// Agents waiting on the user (approval + input) — badge on the Màn hình tab.
  int get waiting => _waiting;

  /// Badge text: null at 0, "9+" above 9.
  String? get badge => badgeText(_waiting);

  // Rebuild only when the count changes, not on every poll.
  void _onDevice() {
    _toggle.syncFromDevice();
    final n = agentsWaiting(_device.cards);
    if (n == _waiting) return;
    _waiting = n;
    notifyListeners();
  }

  @override
  void dispose() {
    _device.removeListener(_onDevice);
    super.dispose();
  }
}
