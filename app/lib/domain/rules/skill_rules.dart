// Skill (gói chức năng): một skill chiếm màn thiết bị tại một thời điểm (docs/testing/quy_tac.md §7).
import '../models/device_state.dart';
import '../models/skill.dart';

export '../models/skill.dart';

/// Id gửi / nhận với firmware (`skill` trong /api/settings, /api/state) — giữ tiếng Anh.
abstract final class SkillIds {
  static const agent = 'agent';
  // Id đặt tạm của thiết kế cho ô "Sắp có" — gói thật đặt id khi làm, và thêm vào firmware Skill::kAll.
  static const music = 'music';
  static const social = 'social';
  static const fun = 'fun';
}

/// Skill mặc định (R-SK-1).
const defaultSkill = SkillIds.agent;

/// Danh mục theo thứ tự hiện trên màn Skill. Thêm gói mới: đổi `hasPack` thành true.
const skillCatalog = [
  SkillInfo(SkillIds.agent, hasPack: true),
  SkillInfo(SkillIds.music, hasPack: false),
  SkillInfo(SkillIds.social, hasPack: false),
  SkillInfo(SkillIds.fun, hasPack: false),
];

/// Các skill app có gói (màn).
final List<String> appSkills = packsOf(skillCatalog);

List<String> packsOf(List<SkillInfo> catalog) =>
    List.unmodifiable([for (final s in catalog) if (s.hasPack) s.id]);

/// R-SK-1: skill đã lưu còn trong danh mục thì dùng, không thì về mặc định.
String resolveStoredSkill(String? stored, {List<String>? packs}) =>
    stored != null && (packs ?? appSkills).contains(stored) ? stored : defaultSkill;

/// R-SK-4: đổi skill được khi thiết bị báo danh sách skill (firmware có skill).
bool canSwitchSkill(DeviceState? device) => device != null && device.skills.isNotEmpty;

/// Skill chọn được: app có gói và thiết bị có kênh; firmware cũ → chỉ mặc định (R-SK-4).
List<String> availableSkills(DeviceState? device, {List<String>? packs}) => canSwitchSkill(device)
    ? List.unmodifiable((packs ?? appSkills).where(device!.skills.contains))
    : const [defaultSkill];

/// R-SK-5: skill đang dùng — theo thiết bị khi thiết bị báo một skill app có gói; còn lại theo máy.
String effectiveSkill({required String stored, DeviceState? device, List<String>? packs}) {
  final d = device?.skill ?? '';
  return (packs ?? appSkills).contains(d) ? d : resolveStoredSkill(stored, packs: packs);
}
