# Phiếu màn thiết bị: Menu chuột phải thanh tác vụ, menu chuột phải trên tệp, hàng Start cho Máy tính bỏ túi

- Trạng thái: chờ thiết kế
- Ngày: 2026-11-28 · Nguồn: áp P-2026-11-28.28 / .31 / .32 — chỗ CHANGELOG có nhắc nhưng chưa có bản vẽ; kế hoạch app
  `app/docs/tasks/2026-11-28-app-cho-chuong-trinh-xp.md` (người dùng 2026-11-28: tính năng mới phải dùng trọn, giống hệt XP)

## Dán vào canvas

**Kênh / màn:** (1) lớp vẽ đè mới: menu chuột phải **thanh tác vụ** (như menu desktop / cửa sổ, `xp_menu`);
(2) Start › **Tất cả chương trình** và cột trái "hay dùng": hàng **Máy tính bỏ túi**; (3) lớp vẽ đè mới: menu chuột
phải **trên một tệp** trong Explorer (Ảnh của tôi, Thùng rác).

**Cần:**
1. P-.28 ghi "Menu chuột phải thanh tác vụ: thêm mục `Trình quản lý tác vụ` (như XP)", nhưng thiết bị chưa có menu thanh
   tác vụ nào. XP thật: chuột phải vùng trống thanh tác vụ → Toolbars ▸, Cascade / Tile (mờ ở đây: cửa sổ không đổi cỡ),
   Show the Desktop, **Task Manager**, Lock the Taskbar, Properties. Người nhìn mở được Trình quản lý tác vụ bằng chuột.
2. P-.31 cho Máy tính bỏ túi vào skill Giải trí "có mục Start › Tất cả chương trình", nhưng bản Start (P-.25) chưa có
   hàng này, và chữ `Máy tính bỏ túi` đo 105 px — rộng hơn cột chữ menu con (x 166–235, 70 px). XP thật: Start › All
   Programs › Accessories ▸ Calculator (thư mục Phụ kiện), Games ▸ Minesweeper. Cần quyết: thư mục `Phụ kiện ▸` /
   `Trò chơi ▸`, menu con rộng hơn, hay chữ ngắn (`Máy tính`, trùng với My Computer).
3. P-.32 vẽ hộp "Xác nhận xoá tệp" nhưng không có lối nào tới nó: XP thật xoá tệp bằng **chuột phải trên tệp › Delete**
   (hoặc phím Delete — phiếu app `app/docs/phieu_thiet_ke/2026-11-28-phim-xp-con-thieu.md`). Menu tệp XP (ảnh): **Open**
   (đậm, = nhấp đúp), Preview, Set as Desktop Background, Print (mờ), Send To ▸, Cut / Copy (mờ), **Delete**, Rename,
   **Properties**. Thùng rác: **Restore**, Cut (mờ), **Delete**, Properties. Tối thiểu: Mở (đậm) · Đặt làm hình nền
   (nếu được) · Xoá · Thuộc tính (mờ nếu chưa có); Thùng rác: Khôi phục · Xoá. Click phải lên tệp cũng chọn nó (XP).

**Trạng thái phải vẽ:** menu thanh tác vụ mở (vị trí theo chỗ chạm, sát mép dưới y ≤ 213), có mục đang sáng (hover);
Start › Tất cả chương trình khi skill Giải trí bật (có Dò mìn + Máy tính bỏ túi) và tắt; cột trái khi Máy tính bỏ túi
vừa mở; menu tệp mở trên một ảnh của Ảnh của tôi (sát mép phải / dưới) và trên một dòng Thùng rác, có mục sáng.

**Luật phải theo:** menu do app chọn mục và gửi lệnh, thiết bị chỉ vẽ (`CLAUDE.md` Context menus); không vẽ ngoài y
0–213 (thanh tác vụ của `main.cpp`); hover chỉ vẽ lại 2 hàng; Start: đỉnh y 62 hoặc dời lên cho đáy ≤ 213.

**Dữ liệu từ firmware:** đã có `POST /api/menu {kind, x, y, hover}`; cần thêm `kind:"taskbar"` và `kind:"file"`
(+ chỗ: ảnh / thùng rác). Xoá = `POST /api/explorer {confirm: delete}` → Có → `{do: delete}` (đã có). Danh sách chương trình đã
cài + `PROG_CALC` (`xp_core.h`); icon 16 Máy tính bỏ túi có sẵn (`src/ui/xp_icons.h` `Calc`).

**Chữ:** `Trình quản lý tác vụ` 140 px (JBMono-11); `Hiện màn nền`, `Khoá thanh tác vụ`, `Thuộc tính`; `Máy tính bỏ túi`
105 px.

**Dùng lại:** khung menu XP-Menu (viền xpMenuBorder, mục 17 px, mờ = xpMenuBorder), menu con Tất cả chương trình P-.25.

**Máy đang có:** chưa có menu thanh tác vụ; Máy tính bỏ túi mở được từ app (`/api/channel Calc`) nhưng không có hàng
Start, và không vào danh sách "hay dùng" (`XPCore::noteRecent` bỏ qua) cho tới khi có bản vẽ.
