# Sổ lỗi

Ghi và sửa bằng `/loi` (`.claude/skills/loi/SKILL.md`): `/loi <mô tả>` chỉ ghi · `/loi` liệt kê lỗi mở ·
`/loi sua [L-…]` sửa · `/loi xong L-…` sau khi thử máy đạt · `/loi mo L-…` khi thử máy vẫn lỗi.

Trạng thái: `mới` → `đang sửa` → `chờ thử máy` → `xong` · `không sửa (<lý do>)`.
Mức độ: `chặn dùng` (không dùng tiếp được, văng app, mất dữ liệu, không đăng nhập / đồng bộ được) · `khó chịu`
(tính sai, báo sai, phải thao tác lại) · `nhỏ` (chữ, giao diện, âm thanh).

## Đang mở

_(chưa có)_

## Đã xong

### L-7 · Đổi tab trên app rồi quay lại Điều khiển → cửa sổ đang mở trên thiết bị bị đóng

- Trạng thái: xong · Mức độ: khó chịu (mất cửa sổ đang xem, phải mở lại) · Phần: Điều khiển
  (`lib/ui/control/view_models/control_view_model.dart`) · Quy tắc: R-DK-7
- Báo: 2026-11-27 — "ở phần cứng tôi đang mở tab gì đó sau đó ở app mobile tôi chuyển qua tab khác sau đó quay lại tab
  điều khiển thì tab đang ở phần cứng bị thoát"
- Các bước: 1. Tab Điều khiển, mở một chương trình trên thiết bị (vd Thời tiết). 2. Chuyển sang tab khác của app.
  3. Quay lại tab Điều khiển.
- Mong đợi / thực tế: thiết bị vẫn hiện cửa sổ đó, thanh tác vụ giữ các cửa sổ đang mở / cửa sổ đóng, thiết bị về
  desktop, thanh tác vụ trống.
- Bằng chứng: PKG110 (Android); chưa có ảnh.

**Sửa**
- Nguyên nhân: mỗi lần mở lại tab, app tạo `ControlViewModel` mới; nó coi như "mới mở app" (R-DK-7: danh sách cửa sổ
  rỗng, thiết bị đang hiện chương trình → gửi `Home`) nên đóng cửa sổ trên thiết bị.
- Test: `test/ui/control/view_models/control_view_model_test.dart` — `'R-DK-7 (L-7): back on the Điều khiển tab in
  the same run → the windows stay, no Home sent'` (đỏ trước khi sửa: thiết bị nhận thêm một `Home`).
- Code: `lib/domain/use_cases/control_device_use_case.dart` (`session`: cửa sổ của lần chạy app, sống cùng app),
  `lib/ui/control/view_models/control_view_model.dart` (rời tab → cất, quay lại → lấy lại, không gửi `Home`);
  R-DK-7 ghi rõ "mới mở app" = lần chạy app mới.
- Thử máy: tab Điều khiển → mở Thời tiết và Đồng hồ trên thiết bị → sang tab khác → quay lại Điều khiển: thiết bị
  vẫn hiện Đồng hồ, thanh tác vụ còn 2 nút. Tắt hẳn app rồi mở lại → về desktop như cũ (R-DK-7).
- Commit: …

**Lịch sử**
- 2026-11-27: ghi lỗi.
- 2026-11-27: sửa, chờ thử máy.
- 2026-11-27: thử máy PKG110 đạt → xong.

### L-6 · Rê trên bàn rê của màn Điều khiển đôi khi cuộn cả màn app

- Trạng thái: xong · Mức độ: khó chịu (con trỏ đứng lại / nhảy, phải rê lại; vẫn dùng được) · Phần: Điều khiển
  (bàn rê, `lib/ui/control/`) · Quy tắc: R-DK-17, R-DK-18
- Báo: 2026-11-27 — "khi lướt trong khu vực touch thì đôi khi app sẽ scroll nên gây khó khăn"
- Các bước: 1. Mở app, nối thiết bị (firmware P-2026-11-27.24, 46a1450). 2. Tab Điều khiển. 3. Lướt ngón tay trong
  vùng bàn rê (vùng touch) để di con trỏ — đôi khi.
- Mong đợi / thực tế: mọi cú rê trong bàn rê chỉ di con trỏ (R-DK-17), màn app đứng yên / đôi khi cả màn app cuộn
  theo ngón tay, con trỏ không đi hoặc đi ít.
- Bằng chứng: điện thoại PKG110 (Android), bản cài 2026-11-27 từ `app/` (gồm thay đổi chưa commit của phiên làm màn
  Điều khiển 2026-11-27.10); chưa có ảnh / video.

**Sửa**
- Nguyên nhân: bàn rê nằm trong `ListView` của màn. Nhận rê (`onPan…`) chỉ thắng khi ngón đi ≥ 36 px, còn cuộn dọc
  của list thắng ở 18 px → cú rê đi dọc trước bị list giành, con trỏ không đi (và list cuộn nếu còn chỗ cuộn).
- Test: `test/ui/control/widgets/trackpad_test.dart` — `'R-DK-17 (L-6): a mostly vertical stroke on the trackpad
  moves the cursor, the screen does not scroll'` (đỏ trước khi sửa: con trỏ nhận 0 / 60 px), `'R-DK-18 (L-6): a
  light touch is still a left click…'`, `'(L-6): outside the trackpad the screen still scrolls'`.
- Code: `lib/ui/control/widgets/trackpad.dart` — nhận rê thắng ngay khi đặt ngón (`_EagerPan`), chạm nhẹ (đi < 18 px,
  nhấc < 500 ms) = click trái.
- Thử máy: tab Điều khiển → rê dọc, rê chéo, rê nhanh nhiều lần trong bàn rê: màn app không cuộn, con trỏ trên thiết
  bị đi theo; chạm nhẹ vẫn là click; vuốt ngoài bàn rê (phần trên / dưới) vẫn cuộn màn. Còn lỗi → quay video màn app.
- Commit: …

**Lịch sử**
- 2026-11-27: ghi lỗi (đánh số tiếp sổ firmware `docs/loi.md`, đã tới L-5, để mã không trùng).
- 2026-11-27: sửa, chờ thử máy.
- 2026-11-27: thử máy PKG110 đạt → xong.
