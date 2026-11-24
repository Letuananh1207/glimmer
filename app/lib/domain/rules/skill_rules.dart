// Skill (gói chức năng): một skill chiếm màn thiết bị tại một thời điểm (docs/testing/quy_tac.md §7).
import '../models/device_state.dart';

/// Id gửi / nhận với firmware (`skill` trong /api/settings, /api/state) — giữ tiếng Anh.
abstract final class SkillIds {
  static const agent = 'agent';
}

/// Skill mặc định (R-SK-1).
const defaultSkill = SkillIds.agent;

/// Các skill app có gói (màn) — thêm gói mới thì thêm id ở đây.
const appSkills = [SkillIds.agent];

/// R-SK-1: skill đã lưu còn trong danh mục thì dùng, không thì về mặc định.
String resolveStoredSkill(String? stored) =>
    stored != null && appSkills.contains(stored) ? stored : defaultSkill;

/// R-SK-4: đổi skill được khi thiết bị báo danh sách skill (firmware có skill).
bool canSwitchSkill(DeviceState? device) => device != null && device.skills.isNotEmpty;

/// Skill chọn được: app có gói và thiết bị có kênh; firmware cũ → chỉ mặc định (R-SK-4).
List<String> availableSkills(DeviceState? device) => canSwitchSkill(device)
    ? List.unmodifiable(appSkills.where(device!.skills.contains))
    : const [defaultSkill];

/// R-SK-5: skill đang dùng — theo thiết bị khi thiết bị báo một skill app có gói; còn lại theo máy.
String effectiveSkill({required String stored, DeviceState? device}) {
  final d = device?.skill ?? '';
  return appSkills.contains(d) ? d : resolveStoredSkill(stored);
}
