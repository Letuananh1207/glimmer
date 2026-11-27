# Phiếu thiết kế: Màn Điều khiển — app là chuột, bàn phím, nút nguồn

- Trạng thái: chờ thiết kế
- Đã vẽ: 2026-11-27.10
- Ngày: 2026-11-27 · Nguồn: kế hoạch `docs/tasks/2026-11-27-app-la-chuot-ban-phim-nguon.md` (bạn duyệt 2026-11-27)

## Dán vào canvas

**Màn / widget:** `ControlScreen` (screen_specs §8) — thay `TouchMirror`; widget mới (gợi ý tên): `Trackpad`,
`MouseButtons`, `KeyPad`, `PowerButton`.

**Cần:** App thành **phần cứng của máy tính**, thiết bị glimmer là **màn hình** — người dùng nhìn màn thật, không còn
ô màn trên app. Trên app: rê bàn rê để di con trỏ (con trỏ vẽ trên thiết bị), click trái / phải, bấm phím điều khiển
(Windows, Alt+Tab, Alt+F4, mũi tên, Enter, Esc, Tab), bấm nút nguồn để tắt / bật máy. Một tay cầm điện thoại dọc vẫn
dùng thoải mái, mắt nhìn thiết bị chứ không nhìn điện thoại — vùng bấm lớn, dễ tìm bằng cảm giác.

**Trạng thái phải vẽ:**
- `normal` — đang bật, bàn rê + nút chuột + phím + nguồn sẵn sàng.
- `dragging` — đang rê (phản hồi nhẹ trên bàn rê; app không biết con trỏ trông thế nào trên màn thật — không cần vẽ lại con trỏ trên app).
- `keyAlt` — đang giữ / chọn tổ hợp (Alt+Tab, Alt+F4): cách bấm tổ hợp trên màn cảm ứng (phím dính? phím tổ hợp sẵn?).
- `poweringOff` / `off` — đang tắt (thiết bị hiện "đang tắt máy") / đã tắt: bàn rê, phím mờ, chỉ nút nguồn bấm được.
- `poweringOn` — đang khởi động (thiết bị chạy màn khởi động XP).
- `card` — thẻ agent đang chiếm màn (giữ `HoldCardPanel` "Bỏ thẻ khỏi màn").
- `night` — chế độ đêm, `brightness` — đang kéo độ sáng (giữ thẻ độ sáng như cũ).
- `oldFw` — firmware chưa có chuột (R-DK-21): bàn rê, phím, nguồn khoá + thanh báo cập nhật firmware.
- `offline` — mất kết nối thiết bị, `setup` — chưa cài (như cũ).
- `failed` — một lệnh không được thiết bị nhận (`CommandSnackbar` như cũ).

**Luật phải theo:**
- R-DK-17: con trỏ do app giữ, kẹp trong màn 240 × 240, rê nhanh đi xa hơn (gia tốc); hình con trỏ (mũi tên / bàn tay / đồng hồ cát) vẽ trên **thiết bị**.
- R-DK-18: chạm nhẹ trên bàn rê hoặc nút trái = click trái; nút phải = click phải (menu chuột phải trên thiết bị); không kéo thả.
- R-DK-19: Windows mở / đóng Start; Alt+Tab cửa sổ kế; Alt+F4 đóng cửa sổ trên cùng; mũi tên / Tab đổi mục; Enter mở; Esc đóng menu. **Gõ chữ làm sau** — chừa chỗ (vd. nút mở bàn phím chữ, mờ / ẩn đợt này).
- R-DK-20: nút nguồn tắt → thiết bị "đang tắt máy" rồi tắt đèn; bật → khởi động rồi về desktop trống.
- R-DK-21: firmware cũ → khoá cả bàn rê, phím, nguồn + thanh báo.
- R-DK-2 (Bỏ thẻ khỏi màn), R-DK-5 (độ sáng gửi khi thả tay) giữ nguyên.

**Dữ liệu từ thiết bị:** `/api/state` thêm `cursor` (cổng UDP, có chuột) và `power` (`on` / `off` / `booting` /
`shutting`) — firmware đang làm. Mọi trường cũ giữ.

**Chuỗi:** dùng lại `controlScreenA11y`?, khoá độ sáng, `HoldCardPanel`, thanh báo firmware cũ, `CommandSnackbar`.
Mới cần đặt khoá: nhãn nút chuột trái / phải, tên các phím, nút nguồn (Tắt máy / Bật máy), trạng thái đang tắt / đã tắt /
đang khởi động, a11y của bàn rê, thanh báo "firmware chưa có chuột".

**Dùng lại:** vỏ thiết bị (`deviceShell` gradient) có thể làm khung "bàn phím / vỏ máy"; token màu XP (`xp*`) cho phím
kiểu XP; thẻ độ sáng; ba nút tròn hiện có (Tắt màn · Chế độ đêm · Số liệu) — xem lại: "Tắt màn" có trùng nút nguồn không.

**Bỏ:** `TouchMirror` và mọi phần vẽ màn XP trên app; `StartMenuSheet` / `AllProgramsSheet` của app **có thể bỏ** (Start
nay mở trên thiết bị bằng phím Windows hoặc click nút start trên màn thật — R-DK-15 đã vẽ Start trên thiết bị) —
thiết kế quyết định giữ làm lối tắt hay bỏ.

**Gợi ý (không bắt buộc):** bàn rê chiếm nửa trên (như touchpad laptop, hai nút chuột dưới nó); hàng phím XP (Windows có
lá cờ, Alt, Tab, Esc, Enter, cụm mũi tên); nút nguồn tròn biểu tượng ⏻ góc trên, đổi màu khi tắt. Rung nhẹ khi click.

**App đang có (dựng tạm):** chưa có — app hiện là ô màn chạm được (`TouchMirror`, §8).

## Ghi chú phía code
- Chặn việc: nhiệm vụ 9 (màn Điều khiển mới) và 10 (xoá ô màn) của `docs/tasks/2026-11-27-app-la-chuot-ban-phim-nguon.md`.
- Phần không dính giao diện (luật con trỏ / phím, UDP, repository, firmware) làm trước.
- Phiếu màn thiết bị đi kèm (con trỏ, mục menu sáng, màn đang tắt máy): `../docs/phieu_panel/2026-11-27-con-tro-va-tat-may.md`.
