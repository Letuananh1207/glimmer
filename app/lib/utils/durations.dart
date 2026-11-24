// Khoảng thời gian dạng ngắn, chữ đơn vị tiếng Anh như trên màn thiết bị (R-DUNG-3).

/// "4d 3h", "2h 14m", "12m" (đếm ngược).
String spanShort(int s) {
  final d = s ~/ 86400, h = (s % 86400) ~/ 3600, m = (s % 3600) ~/ 60;
  if (d > 0) return '${d}d ${h}h';
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

/// "45s", "12m", "3h", "2d" (đã qua bao lâu).
String agoShort(int s) => s < 60
    ? '${s}s'
    : s < 3600
        ? '${s ~/ 60}m'
        : s < 172800
            ? '${(s / 3600).round()}h'
            : '${(s / 86400).round()}d';
