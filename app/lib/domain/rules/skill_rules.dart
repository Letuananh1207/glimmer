// Skill (gói chức năng): mỗi skill bật là một chương trình trên máy (desktop + Start của thiết bị) (docs/testing/quy_tac.md §7).
import '../models/device_state.dart';
import '../models/skill.dart';

export '../models/skill.dart';

/// Id gửi / nhận với firmware (`skills_on` trong /api/state, `skillsOn` trong /api/settings) — giữ tiếng Anh.
abstract final class SkillIds {
  static const agent = 'agent';
  static const photo = 'photo';
  static const weather = 'weather';
  static const clock = 'clock';
  // Id đặt tạm cho chip "Sắp có" — gói thật đặt id khi làm, và thêm vào firmware Skill::kAll.
  static const chat = 'chat';
  static const music = 'music';
  static const social = 'social';
  static const fun = 'fun';
}

/// Skill bật mặc định, theo thứ tự dock (R-SK-1) — Ảnh mặc định tắt.
const defaultSkillsOn = [SkillIds.agent, SkillIds.weather, SkillIds.clock];

/// Danh mục: skill có gói theo thứ tự dock, rồi các chip "Sắp có". Thêm gói mới: đổi `hasPack` thành true.
const skillCatalog = [
  SkillInfo(SkillIds.agent, hasPack: true),
  SkillInfo(SkillIds.photo, hasPack: true),
  SkillInfo(SkillIds.weather, hasPack: true),
  SkillInfo(SkillIds.clock, hasPack: true),
  SkillInfo(SkillIds.fun, hasPack: true), // Giải trí = Dò mìn (panel P-2026-11-27.25)
  SkillInfo(SkillIds.chat, hasPack: false),
  SkillInfo(SkillIds.music, hasPack: false),
  SkillInfo(SkillIds.social, hasPack: false),
];

/// Các skill app có gói, theo thứ tự dock.
final List<String> appSkills = packsOf(skillCatalog);

List<String> packsOf(List<SkillInfo> catalog) =>
    List.unmodifiable([for (final s in catalog) if (s.hasPack) s.id]);

/// [ids] chỉ giữ skill có gói, bỏ trùng, xếp theo thứ tự dock.
List<String> orderSkills(Iterable<String> ids, {List<String>? packs}) {
  final set = ids.toSet();
  return List.unmodifiable((packs ?? appSkills).where(set.contains));
}

/// R-SK-1: danh sách đã lưu (bỏ id lạ); thiếu hoặc rỗng → mặc định.
List<String> resolveStoredSkills(List<String>? stored, {List<String>? packs}) {
  final p = packs ?? appSkills;
  final kept = stored == null ? const <String>[] : orderSkills(stored, packs: p);
  return kept.isNotEmpty ? kept : orderSkills(defaultSkillsOn, packs: p);
}

/// R-SK-4: bật / tắt được khi thiết bị báo danh sách skill bật (firmware có dock).
bool canToggleSkills(DeviceState? device) => device != null && device.skillsOn.isNotEmpty;

/// Skill bật / tắt được bây giờ: app có gói và thiết bị có kênh; firmware cũ → không skill nào (R-SK-4).
List<String> availableSkills(DeviceState? device, {List<String>? packs}) => canToggleSkills(device)
    ? List.unmodifiable((packs ?? appSkills).where((id) => !skillNeedsFirmware(device, id)))
    : const [];

/// Thiết bị có dock nhưng firmware chưa có skill [id] (Ảnh: `/api/state` không có `photos`) → "Cần firmware mới".
bool skillNeedsFirmware(DeviceState? device, String id) =>
    canToggleSkills(device) &&
    (!device!.skills.contains(id) || (id == SkillIds.photo && device.photos == null));

/// R-SK-6: skill Ảnh tắt mà thiết bị đã có ảnh → số ảnh để gợi ý bật (0 = không gợi ý).
int photoHintCount(DeviceState? device, List<String> on) =>
    on.contains(SkillIds.photo) || skillNeedsFirmware(device, SkillIds.photo) ? 0 : (device?.photos ?? 0);

/// R-SK-5: skill đang bật — theo thiết bị khi thiết bị báo skill app có gói; còn lại theo máy.
List<String> effectiveSkillsOn({required List<String> stored, DeviceState? device, List<String>? packs}) {
  final fromDevice = orderSkills(device?.skillsOn ?? const [], packs: packs);
  return fromDevice.isNotEmpty ? fromDevice : resolveStoredSkills(stored, packs: packs);
}

/// Danh sách sau khi bật / tắt [id]; null khi tắt skill bật cuối cùng (R-SK-1: ít nhất một).
List<String>? toggledSkills(List<String> on, String id, {required bool enable, List<String>? packs}) {
  final next = orderSkills(enable ? [...on, id] : on.where((s) => s != id), packs: packs);
  return next.isEmpty ? null : next;
}
