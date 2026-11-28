# Phiếu màn thiết bị: Mã QR trên màn log-on (cài Wi-Fi)

- Trạng thái: đã vẽ (P-2026-11-28.26) — chờ áp
- Đã vẽ: P-2026-11-28.26 (PA B: QR giữa màn)
- Ngày: 2026-11-28 · Nguồn: yêu cầu người dùng — "mỗi lần vào mạng mới thì trên màn hình hiện mã QR và app chỉ cần
  quét là xong"; kế hoạch `app/docs/tasks/2026-11-28-qr-cai-wifi.md` (R-WF-4). Phiếu app đi cùng:
  `app/docs/phieu_thiet_ke/2026-11-28-quet-qr-cai-wifi.md`.

## Dán vào canvas

**Kênh / màn:** màn hệ thống **Đăng nhập** (`XP-SetupMode`, `Display::drawSetupMode`) — hiện khi thiết bị không vào
được Wi-Fi và bật AP mở `glimmer-setup` (máy mới, chuyển nhà / đổi router).
**Cần:** Người đứng trước máy thấy **một mã QR** để quét bằng app glimmer (hoặc camera điện thoại) và hiểu là phải quét
nó — không phải tự tìm Wi-Fi `glimmer-setup` trong Cài đặt. Vẫn biết đây là bước "kết nối Wi-Fi".
**Trạng thái phải vẽ:** một trạng thái (log-on có QR). Màn vẽ một lần, không đổi khi đang ở AP (thiết bị tự thử lại
mạng cũ mỗi 180 s ngầm, không cần hiện).
**Luật phải theo:** màn hệ thống = nền đen / welcome XP, không thanh tác vụ (CLAUDE.md "System screens"); không hoạt ảnh;
QR phải **đen trên trắng**, đủ viền trắng 4 ô quanh mã, ô vuông nguyên px (không co giãn).
**Dữ liệu từ firmware:** đã có — `Display::drawSetupQr(x, y, module, ssid)`: QR phiên bản 3 = **29 × 29 ô**, ô = `module`
px nguyên. Cỡ cả ô trắng (kể viền) = `37 × module`: module 4 → **148 px** (khuyên dùng, camera đọc chắc ở 20–40 cm),
module 5 → 185 px, module 3 → 111 px (khó quét hơn). Nội dung: `WIFI:T:nopass;S:glimmer-setup;;`. Tên AP
`glimmer-setup`, IP `192.168.4.1` vẫn có để in.
**Chữ:** 1–2 dòng hướng dẫn ngắn, ví dụ "Quét mã bằng app glimmer" — đo theo JBMono-11 (tiếng Việt dài hơn tiếng Anh);
có thể giữ "Để bắt đầu, kết nối Wi-Fi". Có cần in tên `glimmer-setup` nữa không: thiết kế quyết (dự phòng khi
không có app).
**Dùng lại:** nền welcome + dải trên/dưới, cờ / chữ xp, nút nguồn đỏ + "Cài đặt Wi-Fi" ở đáy, ô người dùng (khung ảnh
Clawd) — bố cục hiện chia trái/phải ở vạch x 116, ô QR 148 px **không vừa** nửa phải (112 px): cần bố cục lại.
**Gợi ý (không bắt buộc):** theo XP thật — QR đặt chỗ "ô người dùng" (thay ảnh tài khoản), tên AP làm "tên người dùng"
dưới nó; hoặc QR giữa màn, cờ + chữ thu nhỏ ở trên.
**Máy đang có:** log-on không có QR (ảnh `design/panel/screens/@2x/XP-SetupMode.png`).
