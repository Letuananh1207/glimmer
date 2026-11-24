import '../../data/repositories/device/device_repository.dart';
import '../../data/repositories/skill/skill_repository.dart';
import '../../utils/result.dart';
import '../models/app_error.dart';
import '../rules/skill_rules.dart';

/// Đổi skill trên app và thiết bị cùng lúc (R-SK-2), giữ hai bên khớp nhau (R-SK-5).
class SwitchSkillUseCase {
  SwitchSkillUseCase({required SkillRepository skills, required DeviceRepository device, List<String>? packs})
      : _skills = skills,
        _device = device,
        _packs = packs ?? appSkills;

  final SkillRepository _skills;
  final DeviceRepository _device;

  /// Skill app có gói (test đổi được danh mục).
  final List<String> _packs;

  /// Skill đang dùng (theo thiết bị nếu thiết bị báo, R-SK-5).
  String get active => effectiveSkill(stored: _skills.active, device: _device.state, packs: _packs);

  /// Skill chọn được bây giờ (R-SK-4).
  List<String> get available => availableSkills(_device.state, packs: _packs);

  /// R-SK-4: thiết bị đã kết nối nhưng firmware chưa có skill.
  bool get legacy => _device.state != null && !canSwitchSkill(_device.state);

  /// Phiên bản firmware (cho thanh báo firmware cũ).
  String get firmware => _device.state?.fw ?? '';

  /// Gửi thiết bị trước; chỉ lưu máy khi thiết bị nhận, để hai bên không lệch.
  /// Firmware cũ / skill thiết bị không có → `skillUnsupported`, không gửi gì (R-SK-4).
  Future<Result<void>> call(String id) async {
    if (!available.contains(id) || !canSwitchSkill(_device.state)) {
      return Result.error(AppError(AppErrorKind.skillUnsupported, detail: id));
    }
    final r = await _device.saveSettings({'skill': id});
    if (r is Ok) {
      _skills.setActive(id);
      await _device.refresh();
    }
    return r;
  }

  /// R-SK-5: thiết bị đang dùng skill khác (đổi từ trang web thiết bị) → app theo và lưu lại.
  void syncFromDevice() {
    final s = _device.state;
    if (s == null || !_packs.contains(s.skill)) return;
    if (s.skill != _skills.active) _skills.setActive(s.skill);
  }
}
