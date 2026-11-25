import 'package:flutter/foundation.dart';

import '../../../data/repositories/device/device_repository.dart';
import '../../../domain/rules/skill_rules.dart';
import '../../../domain/use_cases/toggle_skill_use_case.dart';
import '../../../utils/result.dart';
import '../../../utils/safe_notifier.dart';

/// What sits at the right of a skill row and what its description says (screen_specs §6).
enum SkillRowMode {
  /// Switch, tappable unless another row is sending.
  toggle,

  /// Spinner instead of the switch, description `skillsSending`.
  sending,

  /// The only skill on: switch locked, description `skillsLastOne` (R-SK-1).
  lastOne,

  /// Old firmware, Agent: padlock instead of the switch (R-SK-4).
  legacyLocked,

  /// Old firmware, Thời tiết / Đồng hồ: on, no switch, description `skillsAlwaysOn` (R-SK-4).
  alwaysOn,

  /// The firmware has no channels for this skill (Ảnh: no `photos` in /api/state): muted icon, amber
  /// `skillsNeedFirmware`, button `skillsUpdateFirmware` → tab Thiết bị instead of the switch (`photoFw`).
  needsFirmware,
}

class SkillRowData {
  const SkillRowData(this.id, {required this.on, required this.mode, required this.enabled, this.photoHint = 0});
  final String id;

  /// Ảnh off while the device holds photos: description `skillsPhotoHint` (mint) with this count; 0 = none (R-SK-6).
  final int photoHint;

  /// On on the device (the app shows what the device has until it takes a change, R-SK-5).
  final bool on;
  final SkillRowMode mode;

  /// The switch can be tapped now.
  final bool enabled;
}

/// Banner at the top of the screen (none when null).
enum SkillsBanner { error, legacy }

/// Màn Skill: danh sách công tắc skill theo dock (R-SK-1…5).
class SkillsViewModel extends ChangeNotifier with SafeNotifier {
  SkillsViewModel({
    required ToggleSkillUseCase toggleSkill,
    required DeviceRepository device,
    List<SkillInfo> catalog = skillCatalog,
  })  : _toggle = toggleSkill,
        _device = device,
        _catalog = catalog {
    _device.addListener(_onDevice);
    _toggle.syncFromDevice();
  }

  final ToggleSkillUseCase _toggle;
  final DeviceRepository _device;
  final List<SkillInfo> _catalog;

  String? _sending;
  ({String id, bool enable})? _failed;

  /// Skills on, dock order (follows the device, R-SK-5).
  List<String> get enabled => _toggle.enabled;

  /// Firmware version for the legacy banner.
  String get firmware => _toggle.firmware;

  bool get legacy => _toggle.legacy;

  /// The change that failed (for the error banner), null otherwise.
  ({String id, bool enable})? get failed => _failed;

  SkillsBanner? get banner {
    if (_toggle.legacy) return SkillsBanner.legacy;
    if (_failed != null) return SkillsBanner.error;
    return null;
  }

  /// One caption line under the list (not on old firmware).
  bool get showOrderNote => !_toggle.legacy;

  /// Rows in dock order.
  List<SkillRowData> get rows {
    final on = enabled;
    final available = _toggle.available;
    final legacy = _toggle.legacy;
    final busy = _sending != null;
    final device = _device.state;
    return [
      // Old firmware: only the three channels it always rotates; no Ảnh row (screen_specs §6 `legacy`).
      for (final s in _catalog.where((s) => s.hasPack && (!legacy || defaultSkillsOn.contains(s.id))))
        if (legacy)
          SkillRowData(s.id,
              on: true,
              mode: s.id == SkillIds.agent ? SkillRowMode.legacyLocked : SkillRowMode.alwaysOn,
              enabled: false)
        else if (skillNeedsFirmware(device, s.id))
          SkillRowData(s.id, on: false, mode: SkillRowMode.needsFirmware, enabled: false)
        else if (s.id == _sending)
          SkillRowData(s.id, on: on.contains(s.id), mode: SkillRowMode.sending, enabled: false)
        else if (on.length == 1 && on.contains(s.id))
          SkillRowData(s.id, on: true, mode: SkillRowMode.lastOne, enabled: false)
        else
          SkillRowData(s.id,
              on: on.contains(s.id),
              mode: SkillRowMode.toggle,
              enabled: !busy && available.contains(s.id),
              photoHint: s.id == SkillIds.photo ? photoHintCount(device, on) : 0),
    ];
  }

  /// "Sắp có" chips, catalogue order.
  List<String> get soon => List.unmodifiable([for (final s in _catalog) if (!s.hasPack) s.id]);

  void _onDevice() {
    _toggle.syncFromDevice();
    notifyListeners();
  }

  /// Switch tapped: send the new list to the device at once (no confirm). The row keeps the device's state with
  /// a spinner until the device takes it (R-SK-2, R-SK-5); on failure the switch stays as the device has it.
  Future<void> toggle(String id, {required bool enable}) async {
    if (_sending != null) return;
    _sending = id;
    _failed = null;
    notifyListeners();
    final r = await _toggle(id, enable: enable);
    _sending = null;
    if (r is Error) _failed = (id: id, enable: enable);
    notifyListeners();
  }

  /// Error banner → send the change again.
  Future<void> retry() async {
    final f = _failed;
    if (f != null) await toggle(f.id, enable: f.enable);
  }

  @override
  void dispose() {
    _device.removeListener(_onDevice);
    super.dispose();
  }
}
