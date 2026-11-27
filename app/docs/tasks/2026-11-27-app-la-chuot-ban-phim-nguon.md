# App là phần cứng máy tính (chuột, bàn phím, nút nguồn), thiết bị là màn hình

- Yêu cầu: "ở app điện thoại đang nhấn thẳng vào màn nhưng tôi muốn chuyển qua ở app đóng vai trò mô phỏng như màn di
  chuột, bàn phím, cây để khởi động nguồn,... và là bộ xử lý, còn thiết bị phần cứng là màn hình"
- Loại: sửa hành vi (+ giao diện mới, app và màn thiết bị) · Cỡ: lớn
- Trạng thái: đang làm

## Bạn đã chốt (2026-11-27)

- **Bỏ hẳn ô màn trên app**: người dùng nhìn màn thật; app chỉ còn bàn rê + nút chuột, bàn phím, nút nguồn.
- **Bàn phím: phím điều khiển trước, gõ chữ sau** (đợt này không có ô nhập chữ trên thiết bị; chừa chỗ cho sau).

## Ý tưởng cốt lõi

App đã là "bộ xử lý": giữ danh sách cửa sổ, tự tính chạm trúng gì (`lib/domain/rules/touch_rules.dart`,
toạ độ px thiết bị trên `MirrorFrame`), gửi lệnh; thiết bị chỉ vẽ. Đổi **cách nhập**:

```
trước:  ngón tay trên ô màn (÷1.5) ─► touchTargetAt(x, y) ─► lệnh /api/*
sau:    bàn rê ─► con trỏ (x, y) của app ─► UDP ─► thiết bị vẽ con trỏ
        nút trái / phải ─► touchTargetAt / holdMenuAt(con trỏ) ─► lệnh /api/*  (giữ nguyên)
        phím ─► keyboard_rules ─► cùng các lệnh
        nút nguồn ─► tắt máy (màn "đang tắt" → tắt đèn) / bật (màn khởi động → desktop)
```

`MirrorFrame` (mô hình thứ đang trên màn) **giữ** — vẫn cần để tính trúng; chỉ bỏ phần **vẽ** nó.

## Phạm vi

**Sẽ sửa — firmware**
- `src/core/cursor.{h,cpp}` (mới): con trỏ vẽ đè có lưu nền (save-under ≤ 32×32 px ≈ 2 KB), nhận vị trí qua UDP
  (`WiFiUDP`, có sẵn trong core — không thêm thư viện), ẩn khi kênh vẽ lại rồi hiện lại.
- `src/main.cpp`: gọi `Cursor::hide()` / `show()` quanh mọi `draw()` / `tick()` / taskbar / menu; vòng UDP.
- `src/data/control_core.h`: trạng thái nguồn (bật / đang tắt / tắt / đang khởi động), mục menu đang sáng (`hover`).
- `src/core/web.cpp`: `POST /api/power {on}`, `/api/menu` thêm `hover`, `/api/state` thêm `cursor` (cổng UDP +
  hình đang vẽ) và `power`; hợp đồng ghi ở `../CLAUDE.md`.
- `src/core/display.cpp`: màn "đang tắt máy" kiểu XP (chờ thiết kế màn thiết bị).
- `test/test_logic`: luật con trỏ (kẹp toạ độ, gói UDP), máy trạng thái nguồn.

**Sẽ sửa — app**
- `lib/domain/models/cursor.dart`, `lib/domain/rules/cursor_rules.dart` (mới): vị trí, gia tốc bàn rê, kẹp 0…239,
  hình con trỏ theo thứ dưới nó (mũi tên / bàn tay / đồng hồ cát).
- `lib/domain/rules/keyboard_rules.dart` (mới): phím → lệnh (mũi tên, Enter, Esc, Tab, Windows, Alt+Tab, Alt+F4).
- `lib/data/services/cursor_service.dart` (mới): gửi UDP (`RawDatagramSocket`, không thêm package).
- `lib/data/repositories/device/*`: `power(on)`, `menu(hover)`, đọc `cursor` / `power` từ `/api/state`.
- `lib/domain/use_cases/control_device_use_case.dart`: nhận click tại con trỏ, phím, nguồn.
- `lib/ui/control/view_models/control_view_model.dart`: con trỏ, nút chuột, bàn phím, nguồn thay cho onTap/onHold.
- `lib/ui/control/widgets/control_screen.dart` + widget mới bàn rê / bàn phím / nút nguồn (**chờ thiết kế app**).
- `docs/testing/quy_tac.md`: luật mới R-DK-17…20, sửa R-DK-10/11 (chạm → chuột), trước khi code.

**Xoá (thành rác khi bỏ ô màn)** — `lib/ui/control/widgets/device_mirror/` phần vẽ: `touch_mirror.dart`,
`xp_canvas.dart`, `xp_paint.dart`, `xp_bits.dart`, `xp_taskbar.dart`, `xp_menu.dart`, `xp_weather_art.dart`,
`desk_icons_xp.dart`, `mirror_channel.dart`, `channels/`; test `test/ui/control/widgets/device_mirror/**`; asset /
chuỗi l10n chỉ ô màn dùng (liệt kê lúc xoá); `usage_mirror` nếu chỉ phục vụ vẽ. Kiểm `lib/ui/device/widgets/device_screen.dart`
(tab Thiết bị) có dùng chung không trước khi xoá.

**Cần kiểm tra** — `lib/routing/screens.dart`, `lib/config/dependencies.dart`, `all_programs_sheet.dart`,
`start_menu_sheet.dart` (Start giờ mở bằng phím Windows / click nút start trên màn thật — sheet trên app có thể bỏ,
theo thiết kế), `test/ui/control/widgets/control_screen_test.dart`, `test/domain/rules/touch_rules_test.dart`
(giữ nguyên — luật trúng không đổi).

**Không đụng** — luật trúng đích (`touch_rules.dart`), danh sách cửa sổ (`windows.dart`), mọi `/api/*` đang có,
thẻ agent / bảng dự án, Cài đặt, Wi-Fi, ảnh. Dữ liệu người dùng đã lưu không đổi.

## Giả định (tự chọn, sửa được)

- **Con trỏ do app giữ** (toạ độ tuyệt đối 0…239 × 0…239), app gửi vị trí ~30 lần/giây qua **UDP** (HTTP mỗi lệnh
  ~50–100 ms trên ESP8266, quá chậm cho chuột). Click / phím vẫn qua HTTP như các lệnh hiện có. Mất gói UDP thì gói
  sau sửa — không cần chắc chắn.
- **Bàn rê** kiểu laptop: rê = di (có gia tốc), chạm nhẹ = click trái, nút trái / phải riêng bên dưới; giữ nút trái
  không kéo thả (cửa sổ không di chuyển được — đã đầy màn).
- **Hình con trỏ** app chọn theo thứ dưới nó: mũi tên; bàn tay trên link / nút; đồng hồ cát khi chờ (đã có
  `XP::emptyFrame` + wait cursor). Đứng yên trên mục menu → mục sáng (như XP) qua `hover`.
- **Phím**: mũi tên đổi biểu tượng chọn trên desktop / mục menu đang sáng; Enter mở; Esc đóng menu; Windows mở /
  đóng Start; Alt+Tab cửa sổ kế; Alt+F4 đóng cửa sổ trên cùng (hết cửa sổ → hộp "Tắt máy" như XP? — hỏi thiết kế).
- **Nút nguồn**: tắt = màn "Đang tắt máy..." ~2 s rồi tắt đèn (thiết bị vẫn chạy để nhận lệnh, như `screen_on`);
  bật = màn khởi động (đã có) → desktop. Khi tắt: thẻ agent khẩn vẫn đánh thức như hiện nay (`chAttentionWakesScreen`).
- **Firmware cũ** (không có `cursor` trong `/api/state`) → màn Điều khiển báo cần cập nhật firmware (theo mẫu
  R-DK-3), không có chế độ chạm cũ để lùi về (ô màn đã bỏ).

## Phiếu thiết kế (thiết kế trước, code sau)

- **App** (`/ui-apply phieu`): màn Điều khiển mới — bàn rê + 2 nút chuột, bàn phím điều khiển, nút nguồn, trạng thái
  tắt / đang khởi động / mất kết nối / firmware cũ.
- **Màn thiết bị** (`/panel-apply phieu`): hình con trỏ XP (mũi tên, bàn tay, đồng hồ cát) cỡ px thật, mục menu /
  Start đang sáng, màn "Đang tắt máy...", (tuỳ) hộp "Tắt máy tính" khi Alt+F4 trên desktop.

## Nhiệm vụ

- [x] 1. Luật nghiệp vụ R-DK-17 (con trỏ), R-DK-18 (click / chuột phải tại con trỏ), R-DK-19 (phím), R-DK-20
  (nguồn); sửa R-DK-10/11, ghi R-DK-7…16 vẫn đúng với nguồn nhập mới — `docs/testing/quy_tac.md` · xong khi: bạn chốt.
- [x] 2. Soạn 2 phiếu thiết kế (app + màn thiết bị), đẩy GitHub · xong khi: phiếu có trong `docs/phieu_thiet_ke/`
  và `../docs/phieu_panel/`. → `docs/phieu_thiet_ke/2026-11-27-dieu-khien-chuot-ban-phim-nguon.md`,
  `../docs/phieu_panel/2026-11-27-con-tro-va-tat-may.md`.
- [ ] 3. Firmware: `cursor_core.h` (gói UDP, kẹp, save-under rect) + test host — `src/data/` · test: `test_logic` ·
  xong khi: `pio test` xanh.
- [ ] 4. Firmware: `Cursor` vẽ / ẩn / hiện + UDP + móc vào `main.cpp`; `/api/state` `cursor` — vẽ hình con trỏ tạm
  theo XP thật đến khi có thiết kế · xong khi: `pio run` OK, RAM tăng ≤ 3 KB, gửi UDP thử bằng tay thấy con trỏ chạy,
  kênh vẽ lại không để vệt.
- [ ] 5. Firmware: nguồn (`/api/power`, máy trạng thái, màn tắt máy — chờ thiết kế panel) + `hover` của menu.
- [ ] 6. App: `cursor.dart`, `cursor_rules.dart`, `keyboard_rules.dart` (domain) · test: `test/domain/rules/cursor_rules_test.dart`,
  `keyboard_rules_test.dart` ghi mã R-DK-17…19.
- [ ] 7. App: `cursor_service.dart` (UDP) + repository `power` / `hover` / đọc `cursor` · test gương ở `test/data/`.
- [ ] 8. App: use case + ViewModel — click / chuột phải tại con trỏ dùng `touchTargetAt` / `holdMenuAt` có sẵn; phím;
  nguồn · test: `test/ui/control/view_models/…`, `control_device_use_case_test.dart`.
- [ ] 9. App: màn Điều khiển mới theo thiết kế — **chờ thiết kế: phiếu nhiệm vụ 2**.
- [ ] 10. App: xoá ô màn + test + chuỗi / asset thành rác (sau nhiệm vụ 9).
- [ ] 11. Cập nhật Bản đồ tính năng của `/lead` (dòng "Điều khiển: chuột, bàn phím, nguồn"), `../CLAUDE.md` (UDP con
  trỏ, nguồn), `docs/AGENTS-GLIMMER.md` nếu đổi API.

## Kiểm tra cuối

`pio test -e native` · `pio run -e nodemcuv2` (RAM) · `dart tool/check.dart --changed` · `flutter analyze` ·
`flutter test -r failures-only test/domain test/ui/control` · `dart tool/rule_trace.dart` · thử máy thật (con trỏ
mượt, không vệt, nguồn tắt / bật).
