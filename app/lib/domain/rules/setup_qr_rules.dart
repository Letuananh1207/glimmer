// Mã QR trên màn cài đặt của thiết bị (R-WF-4).
//
// Firmware vẽ mã Wi-Fi chuẩn cho AP mở của nó: `WIFI:T:nopass;S:glimmer-setup;;`
// (`src/data/qr_payload.h`, ký tự `\ ; , : "` trong tên được thoát bằng `\`).

/// Tên AP mở bắt đầu bằng chuỗi này mới là thiết bị glimmer.
const setupApPrefix = 'glimmer-setup';

/// R-WF-4: tên AP cài đặt đọc từ mã QR [raw]; null khi không phải mã Wi-Fi của glimmer
/// (mã khác, Wi-Fi khác, Wi-Fi có mật khẩu, mã hỏng).
String? setupApFromQr(String raw) {
  final text = raw.trim();
  if (!text.toUpperCase().startsWith('WIFI:')) return null;
  final fields = _wifiFields(text.substring(5));
  if (fields == null) return null;
  final ssid = fields['S'];
  final type = (fields['T'] ?? 'nopass').toLowerCase();
  final pass = fields['P'] ?? '';
  if (ssid == null || !ssid.startsWith(setupApPrefix)) return null;
  if ((type != 'nopass' && type.isNotEmpty) || pass.isNotEmpty) return null;
  return ssid;
}

/// `K:v;K:v;;` → {K: v}, bỏ thoát `\x`; null khi một trường không có `:`.
Map<String, String>? _wifiFields(String body) {
  final out = <String, String>{};
  final cur = StringBuffer();
  final parts = <String>[];
  for (var i = 0; i < body.length; i++) {
    final c = body[i];
    if (c == r'\' && i + 1 < body.length) {
      cur.write('\u0000${body[++i]}'); // giữ ký tự đã thoát, đánh dấu để không tách theo nó
    } else if (c == ';') {
      parts.add(cur.toString());
      cur.clear();
    } else {
      cur.write(c);
    }
  }
  if (cur.isNotEmpty) parts.add(cur.toString());
  for (final p in parts) {
    if (p.isEmpty) continue;
    final colon = p.indexOf(':');
    if (colon <= 0) return null;
    out[p.substring(0, colon).toUpperCase()] = p.substring(colon + 1).replaceAll('\u0000', '');
  }
  return out;
}
