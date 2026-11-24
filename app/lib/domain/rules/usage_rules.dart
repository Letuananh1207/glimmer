// Mức dùng Claude: màu theo % còn lại và dòng phụ của thẻ — giống firmware (Display::usageColor, chrome usageMeta).
import '../models/device_state.dart';
import '../models/usage_meta.dart';

export '../models/usage_meta.dart';

/// R-DUNG-1: theo % còn lại — ≤ 20 critical, ≤ 50 low, còn lại ok; chưa biết (< 0) unknown.
UsageLevel usageLevel(int used) {
  if (used < 0) return UsageLevel.unknown;
  final remaining = 100 - used;
  return remaining <= 20
      ? UsageLevel.critical
      : remaining <= 50
          ? UsageLevel.low
          : UsageLevel.ok;
}

/// R-DUNG-2: ưu tiên chưa có khóa > khóa lỗi (expired/rejected) > bị chặn > số liệu cũ > "X trước"
/// (chỉ khi đã có lần tải được và đồng hồ thiết bị đã đồng bộ).
UsageMeta usageMeta(DeviceState s) {
  final u = s.usage;
  if (!s.claudeConfigured) return const UsageMeta(UsageMetaKind.noKey);
  if (u.cred == 'expired' || u.cred == 'rejected') return const UsageMeta(UsageMetaKind.keyBad);
  if (u.cred == 'blocked') return const UsageMeta(UsageMetaKind.blocked);
  if (u.stale) return UsageMeta(UsageMetaKind.stale, s.time - u.lastOk);
  if (u.lastOk > 0 && s.clockSynced) return UsageMeta(UsageMetaKind.fresh, s.time - u.lastOk);
  return const UsageMeta(UsageMetaKind.none);
}
