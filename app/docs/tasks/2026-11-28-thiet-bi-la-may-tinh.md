# Thiết bị là máy tính XP, app chỉ là chuột + bàn phím + kho lưu trữ

- Yêu cầu (2026-11-28): "các chức năng này sẽ được mở giống window xp, app chỉ là điều khiển chuột và là bộ nhớ lưu
  trữ" → bạn chọn **hướng 1**: thiết bị tự hiểu cú nhấp / phím và tự mở như máy XP thật.
- Loại: sửa hành vi (đảo kiến trúc điều khiển) · Cỡ: lớn · firmware + app
- Trạng thái: đang làm (bạn duyệt 2026-11-28)
- **Thay** kế hoạch `2026-11-28-app-cho-chuong-trinh-xp.md` (app tính click cho 5 chương trình mới) — kế hoạch đó đi
  ngược hướng này, sẽ ghi `bỏ (thay bằng 2026-11-28-thiet-bi-la-may-tinh)` khi bạn duyệt.

## Ý tưởng cốt lõi

```
hôm nay:  app ─ tính trúng gì (touch_rules, start_rules, clock_rules, mines_rules, keyboard_rules)
              ─ giữ cửa sổ, menu, Start, đồng hồ, ván Dò mìn ─► /api/channel, /api/windows, /api/menu … ─► thiết bị vẽ
sau:      app ─ UDP: vị trí chuột + nút (nhấn / nhả) + phím ─► thiết bị: tìm trúng gì, giữ mọi trạng thái, tự mở / đóng,
                                                                  tự chọn hình con trỏ (mũi tên / bàn tay / chờ)
          app ◄─ /api/state: chỉ những việc phải làm trên điện thoại (mở màn Cài đặt, Số liệu…)
```

Thiết bị đã có sẵn nửa việc: tính Start / Tắt máy tính sáng dòng nào, nút nóng thanh tác vụ / tiêu đề, nút trong 4 cửa
sổ mới (`pointerTick`, `pointer_core.h`, `ch_*Pointer`). Thiếu: **hành động** khi bấm.

## Giao thức nhập (mới)

Mở rộng gói UDP :4210 hiện có (`'G' 'C' 1 shape seq x y`, 8 byte):
- Gói **chuột**: `'G' 'C' 2 buttons seq16 x y` — `buttons` = bit trái / phải đang giữ. Thiết bị tự suy ra nhấn, nhả,
  **nhấp đúp** (2 lần nhấn ≤ 500 ms, lệch ≤ 4 px — như XP), **kéo** (giữ trái + di).
- Gói **phím**: `'G' 'K' 1 seq16 mods key` — mods Ctrl / Alt / Shift / Win; key: Tab, Enter, Esc, mũi tên, F4, Del,
  chữ / số (để sau). Ctrl+Alt+Del, Alt+Tab (giữ Alt), Alt+F4 do **thiết bị** hiểu.
- Mất gói: gói nút / phím gửi lặp 3 lần cùng `seq`, thiết bị bỏ trùng. Không JSON, không heap.
- `/api/state` `input` = thiết bị hiểu gói mới (app dùng đường cũ với firmware cũ).

## Phạm vi

**Firmware (phần lớn việc)**
- `src/data/input_core.h` (mới, thuần, test native): nhận sự kiện + ảnh chụp trạng thái → **một hành động**
  (mở chương trình, thu nhỏ, đóng, Start bật / tắt, mở menu ở (x, y), chọn mục menu i, chọn biểu tượng, sự kiện trong
  cửa sổ …). Dùng lại `PointerCore`, `XPCore` (deskIcons, taskbar, startLayout, menuClamp, altTab*).
- `src/data/control_core.h`: thứ tự chồng cửa sổ (z-order), menu nhớ chương trình của nó, mục menu bật / mờ
  (chuyển từ `MenuView.rows/enabled` của app), lựa chọn biểu tượng.
- `src/main.cpp`: áp hành động bằng các hàm có sẵn (`mainShowChannel`, `mainSetWindows`, `mainSetMenu`, `mainSetPower`…);
  hình con trỏ do thiết bị chọn.
- Vùng trúng còn thiếu: mục menu chuột phải (`xp_menu`), nút Start / khay / đồng hồ khay, tab Thời tiết, cửa sổ Đồng hồ
  (`ch_clock.cpp` mới có số vẽ), mặt cười Dò mìn.
- **Dò mìn chuyển lên thiết bị** (ván, loang, thắng / thua, ô đầu không bao giờ là mìn) — ~100 B RAM.
- 4 cửa sổ mới + Alt+Tab + Tắt máy tính: nối sẵn `TaskMgr/Display/Calc/Explorer` (đã có vùng trúng) với hành động;
  máy tính bỏ túi tính trên thiết bị.
- Cài đặt do cửa sổ đổi (múi giờ ở Đồng hồ, hình nền ở Thuộc tính màn hình) thiết bị tự lưu (`Storage::save`).
- `src/core/web.cpp`: `/api/state` `input`, `app_request {seq, screen}`. Các `POST /api/channel|windows|menu|…` **giữ**
  (app cũ, trang web, MCP) nhưng app mới không dùng.
- `test/test_logic`: input_core (mỗi vùng trúng, nhấp đúp, phím tắt), z-order, Dò mìn.
- RAM: bảng mới để PROGMEM / constexpr; so dòng `RAM:` mỗi đợt.

**App (phần nhỏ đi)**
- `ui/control/widgets/trackpad.dart`: gửi nhấn / nhả thay vì "đã chạm" (giữ nút trái để kéo); `key_pad.dart` gửi phím.
- `domain/use_cases/control_device_use_case.dart` + `cursor_service.dart`: gói chuột / phím mới.
- `ui/control/view_models/control_*`: bỏ tính trúng, bỏ giữ cửa sổ / menu / Start / đồng hồ / ván Dò mìn; chỉ còn
  con trỏ + nguồn + đọc `app_request` để mở màn điện thoại.
- Xoá (khi firmware mới là tối thiểu): `touch_rules`, `start_rules`, `clock_rules`, `mines_rules`, `keyboard_rules`
  phần hành động, `mines_game`, `windows.dart` phần giữ chồng — cùng test của chúng. Giữ đường cũ cho firmware ≤ 0.23
  (theo `caps.input`) tới khi bạn bảo bỏ.
- Kho lưu trữ giữ nguyên: thư viện ảnh, cài đặt, khoá Wi-Fi, sao lưu.
- `docs/testing/quy_tac.md`: R-DK-1…23 viết lại ("thiết bị quyết", app chỉ gửi nhập); `../CLAUDE.md` mục "App remote",
  "Context menus", "Mouse, keyboard, power" đổi luật "app chọn mục, thiết bị chỉ vẽ".

**Không đụng** — giao diện màn Điều khiển của app (trừ phím Ctrl+Alt+Del, xem dưới), màn thiết bị đã vẽ, kho ảnh.

## Cần bạn chốt — đã chốt 2026-11-28

- Q1 → **bỏ, chờ vẽ cửa sổ trên thiết bị**: Số liệu / Cài đặt / Thêm / gỡ của cột phải Start không mở màn điện thoại nữa;
  chờ bản vẽ cửa sổ trên thiết bị (như Control Panel của XP) — phiếu panel đi cùng đợt 1. Thiết bị → cửa sổ Máy tính.
- Q2 → **hộp Tắt máy tính trên thiết bị** (Chờ / Tắt / Khởi động lại / Hủy), như XP.
- Q3 → phím Ctrl+Alt+Del: phiếu app `docs/phieu_thiet_ke/2026-11-28-phim-xp-con-thieu.md` (đã soạn, đã đẩy).
- Q4 → **chưa làm kéo**: chỉ nhấn / nhả / nhấp đúp; gói chuột vẫn mang trạng thái nút để thêm kéo sau.

Đề xuất gốc:

1. **Cột phải Start** (Số liệu, Cài đặt, Thêm / gỡ, Thiết bị) hôm nay mở **màn trên điện thoại**. Đề xuất: giữ — thiết bị
   báo `app_request`, app mở màn đó. (`Thiết bị` → cửa sổ Máy tính trên thiết bị, như XP "My Computer".)
2. **Khởi động lại / Tắt máy** từ Start: đề xuất mở hộp **Tắt máy tính** trên thiết bị (đã vẽ, P-.24) thay hộp hỏi trên
   điện thoại — như XP.
3. **Phím Ctrl+Alt+Del** chưa có trên bàn phím app → cần phiếu thiết kế app (`/ui-apply phieu`). Trong lúc chờ: Trình quản
   lý tác vụ mở bằng chuột phải thanh tác vụ (cũng chờ bản vẽ menu, phiếu `docs/phieu_panel/2026-11-28-menu-thanh-tac-vu-
   va-start-may-tinh.md`).
4. **Kéo** (kéo cửa sổ, kéo chọn): XP có, nhưng cửa sổ trên thiết bị không di chuyển / đổi cỡ được → đề xuất chỉ nhận
   nhấn / nhả / nhấp đúp, chưa làm kéo.

## Nhiệm vụ (mỗi đợt nạp máy thử được, app cũ vẫn chạy)

1. [x] (2026-11-28; đã nạp, thử bằng gói UDP: start mở / đóng, con trỏ bàn tay) Firmware: giao thức nhập + `input_core` cho màn nền, thanh tác vụ, nút tiêu đề, Start, Tắt máy tính (bằng việc app
   làm hôm nay) + hình con trỏ. Test native. — `src/data/input_core.h` (gói chuột v2, nhấp đúp, cảnh → hành động,
   hình con trỏ), z-order trong `control_core.h`, `cursor.cpp` (hàng đợi nhấn), `main.cpp` (`inputTick`, `applyClick`),
   `/api/state` `input {mouse: 2, stage: 1}`. Desktop như XP: click = chọn, nhấp đúp = mở. 92/92 native, RAM +96 B.
2. [x] (2026-11-28, đã cài lên điện thoại) App: gửi gói mới khi `caps.input`; bỏ tính trúng ở các chỗ trên. Thử máy: mở / thu nhỏ / đóng / Start như cũ.
   — R-DK-30; `mousePacket`, `ControlDeviceUseCase.mouse/click`, `_clickV2`, `_adoptDevice` (cửa sổ / Start / chọn từ
   `/api/state`, đọc lại 250 ms sau click), mở lại app giữ cửa sổ thiết bị. Code tính trúng cũ giữ cho firmware cũ
   (dọn ở đợt 6).
3. [x] (2026-11-28; đã nạp + cài app; thử UDP: chuột phải → menu desktop, ↓ bỏ mục mờ, Esc đóng) Firmware: menu chuột phải (desktop, cửa sổ), bàn phím (Win, Esc, Alt+F4, Alt+Tab, mũi tên, Enter), z-order.
   — + app: chuột phải / phím gửi lên thiết bị khi `input.stage` ≥ 3 (R-DK-31). 94/94 native, 449 app, RAM +64 B.
4. [x] (2026-11-28; đã nạp + cài app) Firmware: cửa sổ Thời tiết (tab), Đồng hồ (tab, lịch, múi giờ, cập nhật ngay), Dò mìn (ván trên thiết bị).
   — + app: R-DK-32 (thôi gửi `/api/clock`, `/api/mines` khi `stage` ≥ 4). 98/98 native, 450 app, RAM +76 B.
5. Firmware: Trình quản lý tác vụ, Thuộc tính màn hình, Máy tính bỏ túi, Explorer / Thùng rác, Ctrl+Alt+Del.
6. App: `app_request` → màn điện thoại; dọn code tính trúng cũ (sau khi bạn thử máy đạt).
7. Tài liệu: `CLAUDE.md`, `quy_tac.md`, `docs/AGENTS-GLIMMER.md` nếu đổi API.

## Rủi ro

- RAM firmware (~46,5 KB tĩnh, heap ~20 KB): logic mới thuần, bảng PROGMEM; Dò mìn + z-order ~150 B.
- Độ trễ: gói UDP ~30 / s đã chạy; hành động trên thiết bị nhanh hơn hôm nay (bỏ 2 lượt HTTP `/api/channel` +
  `/api/windows`).
- Hai phiên khác đang sửa `app/` (kho ảnh, chương trình XP) — đợt app làm sau khi họ commit, chỉ stage file của mình.
