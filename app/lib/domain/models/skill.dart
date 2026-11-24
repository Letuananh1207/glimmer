/// Một mục trong danh mục skill (design/docs/navigation.json `skills.catalog`).
class SkillInfo {
  const SkillInfo(this.id, {required this.hasPack});

  /// Id gửi / nhận với firmware — giữ tiếng Anh.
  final String id;

  /// App có gói (màn) cho skill này; false = "Sắp có", hiện nhưng không chọn được.
  final bool hasPack;
}
