/// Màu của một giá trị % USED (R-DUNG-1).
enum UsageLevel { unknown, ok, low, critical }

/// Dòng phụ ở góc thẻ mức dùng (R-DUNG-2).
enum UsageMetaKind { noKey, keyBad, blocked, stale, fresh, none }

class UsageMeta {
  const UsageMeta(this.kind, [this.ageS = 0]);
  final UsageMetaKind kind;

  /// Giây kể từ lần tải được gần nhất (cho [UsageMetaKind.stale] / [UsageMetaKind.fresh]).
  final int ageS;
}
