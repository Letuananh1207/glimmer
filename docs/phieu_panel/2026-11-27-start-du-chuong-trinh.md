# Phiếu màn thiết bị: Start menu có đủ mọi chương trình

- Trạng thái: chờ thiết kế
- Ngày: 2026-11-27 · Nguồn: áp thiết kế app 2026-11-27.10 (`app/docs/tasks/2026-11-27-thiet-ke-2026-11-27.10.md`)
- Đã vẽ: P-2026-11-27.25

## Dán vào canvas

**Kênh / màn:** Start menu XP trên thiết bị (P-2026-11-26.20, `src/channels/xp_start.cpp`) — cột trái và menu con
"Tất cả chương trình".

**Cần:** App không còn sheet Start / Tất cả chương trình (thiết kế app 2026-11-27.10, bạn chốt 2026-11-27): mở chương
trình **chỉ còn** qua Start trên thiết bị (click chuột / phím). Start hiện chỉ có Claude, Codex, Ảnh, Thời tiết, Đồng
hồ — **AI hôm nay, Xu hướng, Agents (và Thông tin)** không còn đường mở (Thông tin còn qua "Thuộc tính" của menu
desktop). Cần chúng trong Start, như XP: chương trình cài đặt nằm trong All Programs.

**Trạng thái phải vẽ:** menu con Tất cả chương trình theo skill Agent bật (Claude, Codex, AI hôm nay, Xu hướng,
Agents — Agents chỉ khi `showAgents`), skill khác như cũ; kiểm khi cả 4 skill + `showAgents` bật menu con có vượt
y 213 không (cần cột thứ hai / dời lên như XP?).

**Luật phải theo:** R-DK-9 (chương trình theo skill bật, cờ `show*`), R-DK-22 (app tính trúng theo bố cục Start —
phiếu đổi bố cục thì luật trúng đích `app/lib/domain/rules/start_rules.dart` đổi theo).

**Dữ liệu từ firmware:** `skills_on`, cài đặt `showAgents` (có sẵn).

**Chữ:** "AI hôm nay", "Xu hướng", "Agents" (đã dùng làm tiêu đề cửa sổ).

**Dùng lại:** dòng 20 px của menu con, icon nhỏ 16 của Start.

**Máy đang có:** menu con có Claude, Codex, Ảnh, Thời tiết, Đồng hồ + Thêm / gỡ.
