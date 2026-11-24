// Đếm ngược tới lúc đặt lại (R-DUNG-3); chữ hiển thị: utils/durations.dart.

/// Giây tới lúc đặt lại: null = chưa biết (chưa có mốc / đồng hồ thiết bị chưa đồng bộ), 0 = đã tới.
int? secondsUntil(int resetEpoch, int nowEpoch) {
  if (resetEpoch <= 0 || nowEpoch < 1000000000) return null;
  final s = resetEpoch - nowEpoch;
  return s <= 0 ? 0 : s;
}
