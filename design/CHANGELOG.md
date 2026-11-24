# Nhật ký thay đổi thiết kế — app glimmer

Mỗi mục có mã `YYYY-MM-DD.N` (N tăng liên tục). Mục mới nhất ở trên cùng. "Việc cần làm trong code" chỉ ghi tên màn /
widget và việc cần làm — không ghi đường dẫn file hay cách code. Phía code ghi mục đã áp ở `app/.design_sync.json`.

---

## 2026-11-25.2 — Chọn skill: màn Skill và thanh điều hướng 4 tab

- **Skill · `SkillsScreen`** (màn mới; `source/Skills.dc.html`, `screen_specs.md` §6; ảnh `Skills.png`, `SkillsSwitching.png`,
  `SkillsError.png`, `SkillsLegacy.png`):
  - Lưới 2 cột ô skill (`SkillTile`): Agent (đang dùng, viền `skillAgent`), Nhạc / Mạng xã hội / Giải trí "Sắp có" — hiện mờ,
    không bấm được. Chạm ô chọn được → đổi skill ngay; chạm ô đang dùng → mở màn chính của skill.
  - Đang đổi: thanh báo + ô đích viền nét đứt có vòng xoay; ô đang dùng giữ tới khi thiết bị nhận.
  - Đổi lỗi: thanh báo coral `skillsErrorTitle` / `skillsErrorBody` + `commonRetry`; skill vẫn như cũ.
  - Firmware cũ: thanh báo amber `skillsLegacyTitle` / `skillsLegacyBody` + nút viền `deviceUpdateFw` → tab Thiết bị; chỉ Agent.
  - Thẻ kênh thiết bị của skill đang dùng + kênh hệ thống + dòng nhắc thẻ duyệt (R-SK-3).
  - Trạng thái đang đổi / lỗi trên canvas minh họa bằng Nhạc như đã có gói.
- **Khung điều hướng · thanh dưới** (`components.md` "Thanh điều hướng dưới"; `screen_specs.md` §2–4; ảnh mọi trạng thái
  Tổng quan, Cài đặt, Thiết bị chụp lại):
  - 4 tab: tab 1 = màn chính của skill đang dùng (nhãn = tên skill, icon = icon skill; Agent → Tổng quan, icon Clawd),
    tab 2 Skill, tab 3 Cài đặt, tab 4 Thiết bị. Cài đặt / Thiết bị dùng chung; Kết nối, Cài Wi-Fi ngoài khung tab.
  - Tab đang chọn: icon ink (bỏ icon đen của bản đầu), nhãn 12/700; tab khác nhãn inkDim.
  - Hiện app: 3 tab Tổng quan · Cài đặt · Thiết bị.
- **Token**: màu nhấn `skillAgent/Music/Social/Fun` + nền `…Tint`. **Chuỗi**: `navSkills`, `skill…Name/Desc`, `skills…`
  (26 khoá mới). `navDashboard` không còn trên thanh dưới.
- Phiếu: `app/docs/phieu_thiet_ke/2026-11-25-chon-skill.md`
- Id `music` / `social` / `fun` là id đặt tạm cho ô "sắp có"; firmware và app hiện chỉ có `agent` — không cần đổi firmware.

**Việc cần làm trong code:**
- `SkillsScreen` (mới): lưới ô skill từ danh mục app; trạng thái theo R-SK-1…5 — đang dùng theo thiết bị, đổi gửi thiết bị,
  đang đổi / lỗi (thử lại), firmware cũ → thanh báo + nút sang Thiết bị, không đổi được. Ô "sắp có" hiện nhưng không bấm.
- Thanh điều hướng dưới: 4 tab như trên; tab 1 lấy tên + icon + màn chính từ skill đang dùng; icon tab đang chọn màu ink.
- `SkillTile`, thanh báo trạng thái: widget dùng chung theo `components.md`.

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
