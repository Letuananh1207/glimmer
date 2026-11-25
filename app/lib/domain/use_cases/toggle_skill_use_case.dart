import '../../data/repositories/device/device_repository.dart';
import '../../data/repositories/skill/skill_repository.dart';
import '../../utils/result.dart';
import '../models/app_error.dart';
import '../rules/skill_rules.dart';

/// Bật / tắt skill trên app và thiết bị cùng lúc (R-SK-1, R-SK-2), giữ hai bên khớp nhau (R-SK-5).
class ToggleSkillUseCase {
  ToggleSkillUseCase({required SkillRepository skills, required DeviceRepository device, List<String>? packs})
      : _skills = skills,
        _device = device,
        _packs = packs ?? appSkills;

  final SkillRepository _skills;
  final DeviceRepository _device;

  /// Skill app có gói, thứ tự dock (test đổi được danh mục).
  final List<String> _packs;

  /// Skill đang bật, thứ tự dock (theo thiết bị nếu thiết bị báo, R-SK-5). Firmware cũ → chỉ Agent (R-SK-4).
  List<String> get enabled => legacy
      ? const [SkillIds.agent]
      : effectiveSkillsOn(stored: _skills.enabled, device: _device.state, packs: _packs);

  /// Skill bật / tắt được bây giờ (R-SK-4).
  List<String> get available => availableSkills(_device.state, packs: _packs);

  /// R-SK-4: thiết bị đã kết nối nhưng firmware chưa có dock.
  bool get legacy => _device.state != null && !canToggleSkills(_device.state);

  /// Phiên bản firmware (cho thanh báo firmware cũ).
  String get firmware => _device.state?.fw ?? '';

  /// Gửi thiết bị danh sách mới trước; chỉ lưu máy khi thiết bị nhận, để hai bên không lệch (R-SK-2).
  /// Firmware cũ / skill thiết bị không có → `skillUnsupported`; tắt skill bật cuối → `skillLastOne`; không gửi gì.
  Future<Result<void>> call(String id, {required bool enable}) async {
    if (!canToggleSkills(_device.state) || !available.contains(id)) {
      return Result.error(AppError(AppErrorKind.skillUnsupported, detail: id));
    }
    final next = toggledSkills(enabled, id, enable: enable, packs: _packs);
    if (next == null) return Result.error(AppError(AppErrorKind.skillLastOne, detail: id));
    // Skill thiết bị đang bật mà app chưa có gói (vd `photo` từ trang web thiết bị) giữ nguyên (R-SK-2).
    final keep = [for (final s in _device.state?.skillsOn ?? const <String>[]) if (!_packs.contains(s)) s];
    final r = await _device.saveSettings({'skillsOn': [...next, ...keep]});
    if (r is Ok) {
      _skills.setEnabled(next);
      await _device.refresh();
    }
    return r;
  }

  /// R-SK-5: thiết bị đang bật danh sách khác (đổi từ trang web thiết bị) → app theo và lưu lại.
  void syncFromDevice() {
    final s = _device.state;
    if (s == null || !canToggleSkills(s)) return;
    final fromDevice = orderSkills(s.skillsOn, packs: _packs);
    if (fromDevice.isNotEmpty) _skills.setEnabled(fromDevice);
  }
}
