# Phiếu màn thiết bị: Task Manager (Trình quản lý tác vụ)

- Trạng thái: đã vẽ (P-2026-11-28.28) — chờ áp
- Đã vẽ: P-2026-11-28.28
- Ngày: 2026-11-27 · Nguồn: lộ trình `app/docs/tasks/2026-11-27-chuong-trinh-xp-con-thieu.md` (bạn đồng ý 2026-11-27), mục 2

## Dán vào canvas

**Kênh / màn:** kênh mới `TaskMgr` — cửa sổ XP "Windows Task Manager" ("Trình quản lý tác vụ"). Mở bằng Ctrl+Alt+Del
(phím của app) hoặc chuột phải thanh tác vụ › Trình quản lý tác vụ (XP có mục này). Chương trình hệ thống, không thuộc
skill (như Thông tin), không có biểu tượng desktop.

**Cần:** Người nhìn biết thiết bị đang chạy gì và khoẻ không: cửa sổ nào đang mở, bộ nhớ còn bao nhiêu, Wi-Fi mạnh
yếu, đã chạy bao lâu. Đóng được một cửa sổ (Kết thúc tác vụ) bằng chuột của app.

**Trạng thái phải vẽ (theo XP thật):**
- Thanh menu XP (Tệp · Tùy chọn · Xem · Trợ giúp — thiết kế quyết giữ hay bỏ vì chật, như Dò mìn đã bỏ).
- Các tab như XP: **Ứng dụng** (Applications), **Hiệu năng** (Performance), **Mạng** (Networking). XP còn Processes,
  Users — đề xuất bỏ (thiết bị không có tiến trình / người dùng thật); thiết kế quyết.
- Tab Ứng dụng: ListView "Tác vụ | Trạng thái" — mỗi cửa sổ đang mở một dòng, biểu tượng 16 px, trạng thái "Đang chạy";
  một dòng được chọn (xpSelect); nút "Kết thúc tác vụ", "Chuyển tới", "Tác vụ mới..." (cái cuối có thể mờ). Danh sách
  rỗng.
- Tab Hiệu năng: như XP — ô "Mức dùng CPU" / "Bộ nhớ" kiểu đồ thị xanh lá trên nền đen có lưới (cuộn theo thời gian),
  group "Bộ nhớ (KB)": Tổng, Còn trống, Khối lớn nhất; "Thời gian chạy". Heap thấp (gần ngưỡng TLS) có cần màu cảnh báo
  không — thiết kế quyết.
- Tab Mạng: đồ thị cường độ Wi-Fi + dòng "Wi-Fi · <ssid> · <rssi> dBm · <ip>".
- Thanh trạng thái XP dưới cùng: "Tiến trình: N · CPU: x% · Bộ nhớ: y KB".
- Nút / dòng đang hover dưới con trỏ (như XP: nút sáng viền cam khi hover).

**Luật phải theo:**
- Theo XP thật (người dùng yêu cầu 2026-11-26).
- Partial redraw: đồ thị cập nhật mỗi 1 s chỉ vẽ lại ô đồ thị + số; không vẽ lại cả cửa sổ.
- An toàn khi vẽ lại ô dưới con trỏ (`CLAUDE.md` mục Mouse): đồ thị giữ lịch sử trong RAM nhỏ (vài chục điểm), không
  reset khi `draw()` vẽ lại.
- App là bộ xử lý: app tính click trúng tab / dòng / nút và gửi lệnh (đóng cửa sổ = danh sách `/api/windows` mới).

**Dữ liệu từ firmware:** đã có trong `/api/state`: `heap`, `maxblk`, `min_maxblk`, `heap_refusals`, `uptime_s`,
`cpu_mhz`, `rssi`, `ssid`, `ip`, `windows` (cửa sổ mở), `reset_reason`, `fw`. CPU % chưa có (ESP8266 không đo sẵn —
firmware có thể tính tỷ lệ thời gian `loop()` bận; thiết kế cứ vẽ, phía code quyết).

**Chữ:** "Trình quản lý tác vụ", "Ứng dụng", "Hiệu năng", "Mạng", "Tác vụ", "Trạng thái", "Đang chạy", "Kết thúc tác
vụ", "Chuyển tới", "Mức dùng CPU", "Bộ nhớ", "Còn trống", "Khối lớn nhất", "Thời gian chạy". Đo theo JBMono đã đóng gói;
tab ≈ 70 px mỗi tab.

**Dùng lại:** `XP::window`, `XP::tabs` (Đồng hồ), ListView Details (Dự báo), `XP::groupBox`, nút XP, biểu tượng 16 px
của Start (`start_icons.h`).

**Máy đang có:** chưa có. Thông tin (kênh Info, ≈ System Properties) có vài số liệu tương tự.
