// Đếm ngược tới lúc đặt lại (R-DUNG-3); chữ hiển thị: utils/durations.dart.

/// Giây tới lúc đặt lại: null = chưa biết (chưa có mốc / đồng hồ thiết bị chưa đồng bộ), 0 = đã tới.
int? secondsUntil(int resetEpoch, int nowEpoch) {
  if (resetEpoch <= 0 || nowEpoch < 1000000000) return null;
  final s = resetEpoch - nowEpoch;
  return s <= 0 ? 0 : s;
}

/// Wall-clock time on the device: [epoch] shifted by its time zone ([tzMinutes]), read through the UTC fields.
DateTime deviceLocal(int epoch, int tzMinutes) =>
    DateTime.fromMillisecondsSinceEpoch((epoch + tzMinutes * 60) * 1000, isUtc: true);

/// ISO-8601 week number (Monday first; week 1 holds the year's first Thursday).
int isoWeek(DateTime d) {
  final day = DateTime.utc(d.year, d.month, d.day);
  final thursday = day.add(Duration(days: DateTime.thursday - day.weekday));
  final jan1 = DateTime.utc(thursday.year);
  return thursday.difference(jan1).inDays ~/ 7 + 1;
}
