# App điều khiển 5 chương trình XP mới (Trình quản lý tác vụ, Alt+Tab, Thuộc tính màn hình, Máy tính bỏ túi, Explorer)

- Yêu cầu: "làm tiếp chương trình XP còn thiếu" — tiếp lộ trình `2026-11-27-chuong-trinh-xp-con-thieu.md` mục 2–5.
  Firmware đã áp (panel P-2026-11-28.28 → .32, commit 3137a68); còn phía app ("app là máy tính": app giữ trạng thái,
  tính click / phím, gửi view; thiết bị chỉ vẽ).
- Loại: thêm · Cỡ: lớn
- Trạng thái: chờ thử máy thật (nhiệm vụ 1–11 xong 2026-11-28; vòng còn hở chờ phiếu app `docs/phieu_thiet_ke/2026-11-28-phim-xp-con-thieu.md` + phiếu panel `../docs/phieu_panel/2026-11-28-menu-thanh-tac-vu-va-start-may-tinh.md`)

## Phạm vi

**Sẽ sửa**
- `lib/domain/rules/` mới: `calc_rules.dart`, `xp_program_rules.dart` (Trình quản lý tác vụ, Alt+Tab, Thuộc tính màn hình,
  Explorer) — vùng trúng (chép đúng số của `src/data/{perf,display,calc,explorer,xp}_core.h` +
  `ch_*.cpp *Pointer`), phép tính XP Standard, thứ tự Alt+Tab.
- `lib/domain/models/` mới: view của từng cửa sổ (tab, sel, …) và `CalcState`.
- `lib/domain/rules/touch_rules.dart` (`programOf` + 4 chương trình, mục `Thuộc tính` của menu desktop mở Display,
  biểu tượng Thùng rác mở Explorer › Thùng rác), `start_rules.dart` (Start › `Thiết bị` → cửa sổ Máy tính),
  `keyboard_rules.dart` (Alt+Tab mới, Enter / mũi tên trong cửa sổ mới nếu XP có).
- `lib/data/repositories/device/*` + `device_api_service`: `POST /api/taskmgr|display|calc|explorer`, `/api/menu`
  kind `alttab` + `sel`; `DeviceState` đọc `taskmgr`, `display`, `calc`, `explorer`, `alttab` (= firmware có).
- `lib/domain/use_cases/control_device_use_case.dart`: lệnh gửi cho từng cửa sổ (theo `caps`).
- `lib/ui/control/view_models/control_pointer.dart` (+ tách `control_programs.dart` vì file đã dài): click trái /
  phải trong từng cửa sổ, giống `_minesClick`.
- `docs/testing/quy_tac.md`: luật mới R-DK-24… (mỗi chương trình một mã), R-DK-19 sửa phần Alt+Tab.
- Test: `test/domain/rules/*_rules_test.dart` (mỗi luật), `test/ui/control/view_models/control_pointer_test.dart`.

**Cần kiểm tra** — `program_style.dart` (biểu tượng chương trình trong app nếu có danh sách cửa sổ), `windows.dart`
(`WindowStack`), `cursor_rules.dart` (hình tay trên nút mới), `ControlScreen` (không đổi giao diện).

**Không đụng** — giao diện màn Điều khiển (không vẽ thêm gì trên điện thoại), firmware, dữ liệu đã lưu.

## Giả định / cần quyết định

- **Q1 — chốt: hộp chuyển, tự nhả** (bạn chốt 2026-11-28). Alt+Tab với một phím trên app (app không có phím Alt giữ được): đề xuất bấm `Alt+Tab` → hộp hiện, chọn sẵn
  cửa sổ thứ hai; mỗi lần bấm nữa trong 1 s → ô kế; 1 s không bấm = "nhả Alt" → cửa sổ đã chọn lên trên, hộp đóng. Esc
  → huỷ. (Sửa R-DK-19.)
- **Q2 — chốt: làm phần trong cửa sổ, chờ vẽ** (bạn chốt 2026-11-28). Chỗ chưa có bản vẽ (thiết kế trước, code sau):
  - Mở **Trình quản lý tác vụ**: thiết kế ghi "Ctrl+Alt+Del / menu thanh tác vụ" — app chưa có phím Ctrl+Alt+Del,
    thiết bị chưa có menu thanh tác vụ (phiếu `../docs/phieu_panel/2026-11-28-menu-thanh-tac-vu-va-start-may-tinh.md`).
  - Mở **Máy tính bỏ túi**: chưa có hàng Start (cùng phiếu).
  - **Xoá ảnh** trong Ảnh của tôi: XP = phím Delete / chuột phải › Xoá — app chưa có phím Delete, thiết bị chưa có menu
    chuột phải trên tệp.
  - Đề xuất: làm hết phần trong cửa sổ ngay; 3 lối mở / xoá trên chờ bản vẽ (soạn phiếu app cho phím Ctrl+Alt+Del và
    Delete; phiếu panel đã có thêm menu tệp).
- Màn xem trước của Thuộc tính màn hình trong app (thiết kế ghi "như Đồng hồ trong màn mô phỏng"): màn mô phỏng đã bỏ
  từ 2026-11-27.10 → không làm.
- Thuộc tính màn hình: app giữ giá trị đang sửa, gửi `/api/display` mỗi lần đổi; `OK` / `Áp dụng` gửi
  `/api/settings` (wallpaperMode, nightMode, idleDim, brightness, invertDisplay); `Hủy` / `×` bỏ.
- Máy tính bỏ túi: như XP Standard — tính trái sang phải, `=` lặp phép cuối, `%` = a × b / 100, `1/x`, `sqrt`, `+/-`,
  bộ nhớ MC MR MS M+, tối đa 16 ký tự, chia 0 → "Không thể chia cho 0." (phải `C` mới tính tiếp).

## Vòng dùng như XP (bạn yêu cầu 2026-11-28: hoàn thiện, dùng giống hệt XP)

| Chương trình | XP thật | Đợt này | Còn hở → phiếu (nhiệm vụ 11) |
|---|---|---|---|
| Trình quản lý tác vụ | Ctrl+Alt+Del / Ctrl+Shift+Esc, chuột phải thanh tác vụ › Task Manager; Kết thúc tác vụ, Chuyển tới; Delete = Kết thúc | bên trong cửa sổ | phím Ctrl+Alt+Del trên app; menu chuột phải thanh tác vụ (phiếu panel đã có) |
| Alt+Tab | giữ Alt, Tab / Shift+Tab, nhả Alt | trọn (hộp tự nhả 1 s) | Shift+Tab lùi: phím trên app |
| Thuộc tính màn hình | chuột phải desktop › Properties; OK / Cancel / Apply; Esc = Cancel, Enter = OK | trọn (+ Esc / Enter) | — |
| Máy tính bỏ túi | Start › All Programs › Accessories › Calculator; gõ số bằng bàn phím | bên trong cửa sổ | hàng Start (phiếu panel đã có); gõ số cần bàn phím chữ (sắp có) |
| Explorer / Thùng rác | My Computer, nhấp đúp mở; Backspace = lên; Delete / chuột phải › Delete → Confirm; Recycle Bin: Restore, Empty | mở, chọn, nhấp đúp, Thùng rác | phím Delete + Backspace trên app; menu chuột phải trên tệp (Mở / Xoá) ở thiết bị |

## Nhiệm vụ

- [x] 1. (bạn duyệt 2026-11-28) Luật R-DK-24…29 + R-DK-19 (Alt+Tab) — `docs/testing/quy_tac.md` · xong khi: bạn duyệt chữ.
- [x] 2. `DeviceState` đọc 5 khối mới + `caps` — model · test: model test.
- [x] 3. API thiết bị: 4 POST mới + `alttab` — service/repository · test: repository test (DeviceRig).
- [x] 4. Máy tính bỏ túi: `calc_rules.dart` (phép tính + vùng nút) — rules · test: `calc_rules_test.dart`.
- [x] 5. Trình quản lý tác vụ: tab, dòng, `Kết thúc tác vụ` (đóng cửa sổ = gửi danh sách mới), `Chuyển tới` — rules ·
      test.
- [x] 6. Thuộc tính màn hình: tab, danh sách hình nền, ô chọn chế độ + danh sách mở, ô tích, thanh trượt, OK / Hủy /
      Áp dụng — rules · test.
- [x] 7. Explorer: chỗ xem, chọn ảnh / dòng, cuộn, nhấp đúp ảnh = mở trong Ảnh, Khôi phục / Dọn sạch (+ hộp xác nhận
      Có / Không) — rules · test.
- [x] 8. Alt+Tab — `alttab_rules.dart` + `keyboard_rules.dart` · test.
- [x] 9. Lối mở: menu desktop › Thuộc tính → Display; Start › Thiết bị → Máy tính; biểu tượng Thùng rác → Thùng rác —
      `touch_rules`, `start_rules` · test.
- [x] 10. Nối vào `ControlViewModel` (click trái / phải, phím, gửi lệnh theo `caps`) · test: `control_pointer_test.dart`.
- [x] 11. Phiếu app (phím Ctrl+Alt+Del, Delete) — `/ui-apply phieu`; phiếu panel thêm menu chuột phải trên tệp.
- [ ] 12. Thử máy thật.

## Kiểm tra cuối
dart tool/check.dart --changed · flutter analyze · flutter test -r failures-only · dart tool/rule_trace.dart
