# Phiếu thiết kế: Quét mã QR trên màn thiết bị để cài Wi-Fi

- Trạng thái: đã áp (2026-11-28.12)
- Đã vẽ: 2026-11-28.12
- Ngày: 2026-11-28 · Nguồn: yêu cầu người dùng — "mỗi lần vào mạng mới thì trên màn hình hiện mã QR và app chỉ cần
  quét là xong"; kế hoạch `docs/tasks/2026-11-28-qr-cai-wifi.md`. Phiếu màn thiết bị đi cùng:
  `docs/phieu_panel/2026-11-28-qr-man-log-on.md` (gốc repo).

## Dán vào canvas

**Màn / widget:** `WifiSetupScreen` (screen_specs §5) + **màn quét mới** (camera) + một lối vào quét ở `ConnectScreen`
(§1, khi không tìm thấy thiết bị) và ở thanh báo `setup` của Điều khiển (`controlSetupAction`).
**Cần:** Thiết bị đang hiện màn cài Wi-Fi (có mã QR) → người dùng bấm "Quét mã", đưa camera vào màn thiết bị, xong.
App tự vào `glimmer-setup` và gửi mạng điện thoại đang dùng. Mạng app đã nhớ mật khẩu → không hỏi gì; chưa nhớ → chỉ
hỏi **mật khẩu** (tên mạng đã biết). Xem / quên được các mật khẩu app đã nhớ.
**Trạng thái phải vẽ:**
- Màn quét: khung ngắm camera + dòng hướng dẫn; chưa cho quyền camera (xin quyền / mở Cài đặt); mã lạ (lỗi
  `devErrNotGlimmerQr`, quét lại).
- `WifiSetupScreen` bước mới **`password`**: tên mạng đã điền (chỉ đọc, đổi được nếu cần) + một ô mật khẩu + nút gửi.
- Bước `form` cũ: thêm nút "Quét mã trên màn" (lối thay cho gõ tay); điện thoại không biết mạng hiện tại → quét xong về
  `form` đầy đủ.
- Bước working / done / failed: như cũ (WifiSetupWorking/Done/Failed). Mạng có mật khẩu nhớ: quét xong vào thẳng
  working.
- Chỗ quên mật khẩu đã nhớ (danh sách mạng + xoá) — thiết kế chọn chỗ (trong màn Wi-Fi hay Cài đặt / Thiết bị).
**Luật phải theo:**
- R-WF-4: chỉ nhận mã Wi-Fi mở có tên bắt đầu `glimmer-setup`; mã khác → báo, không làm gì. Tên gửi đi = mạng điện
  thoại (R-WF-3).
- R-WF-5: mật khẩu nhớ theo tên mạng, chỉ khi thiết bị hiện lại trên mạng đó; nhớ mà thất bại → quên, lần sau hỏi lại.
- R-WF-1..3 giữ nguyên (gửi thẳng nếu thiết bị trả lời, không thì qua AP; tìm lại ~4 phút).
**Dữ liệu từ thiết bị:** không cần thêm — QR do firmware vẽ (`WIFI:T:nopass;S:glimmer-setup;;`); app có sẵn
`WifiSetupViewModel.scanned()`, `step == WifiStep.password`, `rememberedNetworks`, `forgetPassword()`.
**Chuỗi:** có sẵn `wifiTitle`, `wifiSsid`, `wifiPass`, `wifiSend`, `wifiNote`, `devErrNotGlimmerQr` ("Đây không phải mã
của glimmer. Quét mã trên màn cài đặt Wi-Fi của thiết bị."). Mới cần đặt khoá: nút "Quét mã trên màn", hướng dẫn trên
màn quét, xin quyền camera, câu bước `password` (vd "Mật khẩu Wi-Fi “Nha” — app sẽ nhớ cho lần sau"), mục mật khẩu đã
nhớ + xác nhận quên.
**Dùng lại:** Clawd 120 (form/working/done/failed), `appBarTitle`, nút chính / phụ, thanh báo amber `setup`, icon wifi.
**Gợi ý (không bắt buộc):** màn quét toàn màn hình nền tối, khung vuông giữa có góc bo + ảnh nhỏ màn log-on của thiết bị
để người dùng biết quét cái gì; quét được thì rung nhẹ rồi tự đóng.
**App đang có (dựng tạm):** chưa có giao diện — chỉ logic (`scanned()`, bước `password`, kho mật khẩu). Bước `password`
hiện chưa có widget nên chưa gọi được từ UI.
