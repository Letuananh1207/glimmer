# Nhật ký thay đổi thiết kế — app glimmer

Mỗi mục có mã `YYYY-MM-DD.N` (N tăng liên tục). Mục mới nhất ở trên cùng. "Việc cần làm trong code" chỉ ghi tên màn /
widget và việc cần làm — không ghi đường dẫn file hay cách code. Phía code ghi mục đã áp ở `app/.design_sync.json`.

---

## 2026-11-25.1 — Bản đầu: vẽ lại app hiện có

- **Cả 5 màn** (`source/*.dc.html`, `screen_specs.md` §1–5; ảnh `screens/@3x/*.png`): vẽ lại đúng giao diện app đang có
  để làm nền chung, chưa đổi gì:
  - Kết nối `ConnectScreen` — đang tìm, không thấy thiết bị, hộp thoại nhập IP.
  - Tổng quan `DashboardScreen` — có dữ liệu, chưa có khóa / trống, số liệu cũ, thiết bị ở glimmer-setup, đang tải.
  - Cài đặt `SettingsScreen` — bình thường, có thay đổi chưa lưu, lỗi tải.
  - Thiết bị `DeviceScreen` — bình thường, đang nạp firmware.
  - Cài Wi-Fi `WifiSetupScreen` — nhập mạng, đang gửi, xong, lỗi.
- **Token** (`tokens/design_tokens.json`): bảng màu `G` (trùng `src/core/theme.h`), cỡ chữ, khoảng cách, bo góc đang dùng.
- **Chuỗi** (`l10n/app_vi.arb`): mọi chuỗi đang hiện trong app, đặt khóa theo tiền tố màn.
- Ghi nhận (từ màu mặc định Flutter, chưa xem trên máy thật; chưa sửa trong bản này): icon tab đang chọn ở thanh điều
  hướng có thể màu đen trên `panel2`; hai nút ở Tổng quan nền mint chữ đen; viền nút viền và ô nhập màu trắng; thanh tiến độ
  nạp firmware nền mint.

**Việc cần làm trong code:**
- Không đổi giao diện. Ghi `2026-11-25.1` là đã áp trong bản ghi đồng bộ thiết kế.
- Nếu muốn dùng ngay: sinh `AppColors` từ `color` của token và chuyển chuỗi cứng sang `app_vi.arb` (cùng khóa); màn phải
  trông y như ảnh.
