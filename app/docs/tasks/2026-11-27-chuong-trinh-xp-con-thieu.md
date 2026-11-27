# Chương trình cơ bản của Windows XP còn thiếu — lộ trình

- Yêu cầu: "nghiên cứu xem các chương trình cơ bản của window xp còn thiếu là gì để chuẩn bị phát triển thêm" → bạn
  đồng ý thứ tự đề xuất (2026-11-27).
- Loại: thêm (nhiều chương trình, mỗi cái một đợt) · Cỡ: lớn, chia nhỏ
- Trạng thái: đang làm (mục 0–1 xong; phiếu 2–5 đã soạn, chờ thiết kế)

## Thiết bị đang có

Desktop, thanh tác vụ, Start, menu chuột phải, con trỏ, màn khởi động / Welcome / Log On / Tắt máy tính; Ảnh (≈ Picture
and Fax Viewer), Đồng hồ (= Date and Time Properties), Thông tin (≈ System Properties), mặt đêm (≈ screen saver);
Thùng rác chỉ là biểu tượng. Riêng glimmer: Claude, Codex, AI hôm nay, Xu hướng, Agents, Thời tiết.

## Giới hạn khi chọn

Màn 240×240 · heap ~25 KB · không loa · chưa gõ chữ (phím Chữ "sắp có") · LittleFS trống ~290 KB · mọi `draw()` phải
an toàn khi vẽ lại ô dưới con trỏ (`../CLAUDE.md` mục Mouse) · app là bộ xử lý: click / phím do app tính rồi gửi lệnh.

## Thứ tự (bạn đồng ý)

| # | Chương trình | Vì sao | Phiếu |
|---|---|---|---|
| 0 ✅ | Start đủ chương trình (AI hôm nay, Xu hướng, Agents) — P-2026-11-27.25 | mọi chương trình mới cần chỗ mở | `../docs/phieu_panel/2026-11-27-start-du-chuong-trinh.md` |
| 1 ✅ | **Minesweeper** (skill Giải trí `fun`) — P-2026-11-27.25, R-DK-23 | thể hiện chuột tốt nhất; trạng thái vài chục byte | `../docs/phieu_panel/2026-11-27-minesweeper.md` |
| 2 | Task Manager (Ctrl+Alt+Del) | số liệu thật đã có trong `/api/state` | `../docs/phieu_panel/2026-11-27-task-manager.md` |
| 3 | My Computer / Explorer + mở Thùng rác | quản lý ảnh mẫu / ảnh của bạn trên màn | `../docs/phieu_panel/2026-11-27-my-computer-thung-rac.md` |
| 4 | Display Properties | gom hình nền, screen saver, độ sáng | `../docs/phieu_panel/2026-11-27-display-properties.md` |
| 5 | Calculator; ô chuyển Alt+Tab | nhỏ, dùng chuột / phím sẵn có | `../docs/phieu_panel/2026-11-27-calculator.md`, `../docs/phieu_panel/2026-11-27-alt-tab.md` |
| 6 | Sau: Notepad (khi gõ chữ), Solitaire / FreeCell, Media Player (skill Nhạc), Messenger (skill Mạng xã hội), Command Prompt (nhật ký), Windows Update (OTA) | | |

Không làm: Internet Explorer, Outlook Express, Movie Maker, 3D Pinball, Sound Recorder, WordPad, Character Map.

## Mỗi chương trình gồm

1. Phiếu màn thiết bị (`/panel-apply phieu`) + phiếu app nếu app có màn / cài đặt mới (`/ui-apply phieu`).
2. Luật `R-…` cho cách click / phím (`docs/testing/quy_tac.md`), test trước.
3. Firmware: kênh `ch_<x>.cpp` (repaint-safe), `XPCore::Prog`, biểu tượng desktop, mục Start; skill mới = id trong
   `Skill::kAll` (`../CLAUDE.md` mục Skills).
4. App: luật trúng đích của cửa sổ mới (như `touch_rules` / `start_rules`), chương trình trong `programsOf`.
