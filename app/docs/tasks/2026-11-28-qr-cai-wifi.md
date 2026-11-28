# Quét QR trên màn thiết bị để cài Wi-Fi

- Yêu cầu: "Mỗi lần vào mạng mới thì trên màn hình hiện mã QR và app chỉ cần quét là xong." Đã chốt với người
  dùng: gõ mật khẩu một lần, app nhớ theo tên mạng; thiết kế trước (soạn phiếu panel + app).
- Loại: thêm · Cỡ: lớn (firmware + app, thêm 2 thư viện, dữ liệu lưu mới trong app)
- Trạng thái: chờ thiết kế (nhiệm vụ 1–6 xong 2026-11-28; 7–9 đợi bản chốt panel + app)

## Luồng mong muốn
1. Thiết bị không vào được Wi-Fi → AP `glimmer-setup` → màn log-on (`XP-SetupMode`) có mã QR.
2. App: nút "Quét mã trên màn" (màn Kết nối + màn Wi-Fi) → camera → đọc QR → tự vào `glimmer-setup`.
3. Tên Wi-Fi = mạng điện thoại đang dùng. App **đã nhớ** mật khẩu mạng đó → gửi luôn, không hỏi gì.
   Chưa nhớ → chỉ hỏi mật khẩu (một ô) → gửi → lưu mật khẩu khi thiết bị hiện lại trên mạng mới.
4. Phần sau (gửi, rời AP, tìm lại thiết bị) dùng nguyên luồng R-WF-1..3 hiện có.

## Phạm vi
**Sẽ sửa — firmware**
- `platformio.ini`: thêm `ricmoo/QRCode` (C thuần, ~3 KB flash, buffer QR v3 ≈ 106 B trên stack, không thêm RAM tĩnh).
- `src/data/qr_payload.h` (mới, thuần): dựng chuỗi QR từ `SETUP_AP_SSID`.
- `src/core/display.{h,cpp}`: `Display::drawQr(x, y, module, text)` — vẽ theo hàng bằng `fillRect`, không framebuffer;
  `drawSetupMode` gọi nó ở vị trí thiết kế chốt (**chờ thiết kế**).
- `test/test_qr/` (native): payload + mã hoá ra đúng cỡ/finder pattern.
- `tools/screens.py`: vẽ QR trên màn log-on (**chờ thiết kế**).

**Sẽ sửa — app**
- `pubspec.yaml`: thêm `mobile_scanner` (camera + ML Kit) và `flutter_secure_storage` (mật khẩu Wi-Fi là bí mật,
  không để `shared_preferences`).
- `lib/domain/rules/setup_qr_rules.dart` (mới): nhận dạng QR của glimmer → SSID AP; QR lạ → null.
- `lib/data/services/wifi_secrets_service.dart` (mới) + `lib/data/repositories/wifi/wifi_password_repository.dart` (mới):
  nhớ / lấy / quên mật khẩu theo SSID.
- ~~`qr_scanner_service.dart`~~: bỏ — `mobile_scanner` là widget camera, thuộc lớp view; thêm ở nhiệm vụ 8 cùng
  dòng `'package:mobile_scanner/': {'view'}` trong `_packageOwners` (`tool/check.dart`). ViewModel nhận chuỗi QR.
- `lib/ui/wifi_setup/view_models/wifi_setup_view_model.dart`: `scanned(qr)` → điền SSID, có mật khẩu nhớ thì `send` luôn;
  `send` thành công thì lưu mật khẩu; truyền `joinSetupAp` SSID lấy từ QR.
- `lib/ui/wifi_setup/widgets/…` + màn quét mới + `lib/ui/connect/widgets/connect_screen.dart` (nút quét) — **chờ thiết kế**.
- `lib/routing/{routes,router,screens}.dart`, `lib/config/dependencies.dart`: route quét, nối repository mới.
- `lib/l10n/app_vi.arb`: chuỗi quét / quyền camera / chỉ hỏi mật khẩu (lấy từ thiết kế khi chốt).
- `docs/testing/quy_tac.md`: thêm R-WF-4 (QR), R-WF-5 (nhớ mật khẩu); `docs/backend/`: ghi kho mật khẩu Wi-Fi.
- `android/app/src/main/AndroidManifest.xml`: quyền `CAMERA`.

**Cần kiểm tra** — `device_repository_local.dart` (`joinSetupAp` hiện cứng `setupApSsid`), `testing/fakes/fake_services.dart`,
`test/ui/view_models_test.dart`, `test/ui/screens_test.dart`.

**Không đụng** — API thiết bị (`/api/settings` giữ nguyên, AP vẫn mở không mật khẩu), cấu hình đã lưu trên thiết bị,
luồng gửi Wi-Fi gõ tay (vẫn còn, chỉ thêm việc nhớ mật khẩu).

## Giả định / cần quyết định
- **Nội dung QR** = chuẩn Wi-Fi `WIFI:T:nopass;S:glimmer-setup;;` (32 byte, QR v3 29×29). Lợi: camera Android thường
  cũng vào được AP; app nhận khi SSID bắt đầu bằng `glimmer-setup`. Không cần IP (luôn 192.168.4.1).
- Kích thước: 29 module × 4 px = 116 px + viền trắng 4 module → ô 148 px; bố cục log-on cần vẽ lại → phiếu panel.
- Mật khẩu chỉ lưu sau khi thiết bị **hiện lại** trên mạng mới (gửi sai mật khẩu thì không nhớ cái sai). Có nút
  "Quên mật khẩu đã lưu" trong màn Wi-Fi (thiết kế quyết định chỗ).
- Android không cho đọc mật khẩu Wi-Fi đã lưu của hệ thống → lần đầu với mỗi mạng vẫn phải gõ một lần.
- Thiết bị đang chạy firmware cũ (không có QR): nút quét vẫn có, người dùng dùng luồng gõ tay như cũ.

## Nhiệm vụ
Không dính giao diện (làm trước):
- [x] 1. Quy tắc R-WF-4 (quét QR → vào AP, điền SSID) và R-WF-5 (nhớ mật khẩu theo SSID, chỉ lưu khi thành công,
  có mật khẩu → gửi không hỏi) — `docs/testing/quy_tac.md` · xong khi: có 2 dòng mã mới.
- [x] 2. Firmware: `qr_payload.h` + `Display::drawQr` + lib — test native `test/test_qr` · xong khi: `pio test -e native`
  xanh, `pio run` báo RAM không tăng (> 50 B là phải xem lại).
- [x] 3. App rules `setup_qr_rules.dart` (domain) · test: `test/domain/rules/setup_qr_rules_test.dart` · xong khi: nhận đúng
  QR glimmer, từ chối QR khác / Wi-Fi khác.
- [x] 4. Kho mật khẩu: service + repository (data) · test: `test/data/repositories/wifi_password_repository_test.dart` +
  fake trong `testing/fakes/` · xong khi: lưu / đọc / quên theo SSID; cập nhật `docs/backend/`.
- [x] 5. `WifiSetupViewModel.scanned()` + lưu mật khẩu khi xong (ui/view_model) · test: `test/ui/view_models_test.dart`
  · xong khi: có mật khẩu nhớ → gửi không hỏi; chưa có → bước hỏi mật khẩu; gửi thất bại không lưu.
- [x] 6. Phiếu thiết kế: `docs/phieu_panel/2026-11-28-qr-man-log-on.md` (qua `/panel-apply phieu`) và
  `app/docs/phieu_thiet_ke/2026-11-28-quet-qr-cai-wifi.md` (qua `/ui-apply phieu`).

Chờ thiết kế:
- [x] 7. Vẽ QR trên log-on (`display.cpp` `drawSetupMode`, `tools/screens.py`) — áp P-2026-11-28.26 (2026-11-28).
- [ ] 8. Màn quét + bước chỉ hỏi mật khẩu + nút quét ở Kết nối / Wi-Fi, route, l10n, quyền camera — chờ thiết kế:
  phiếu app quét QR.
- [ ] 9. Thử máy thật: nạp firmware, xoá Wi-Fi để vào AP, quét bằng app, lần hai quét không hỏi.

## Kiểm tra cuối
pio test -e native · pio run -e nodemcuv2 (so RAM:) · dart tool/check.dart --changed · flutter analyze ·
flutter test -r failures-only test/domain/rules/setup_qr_rules_test.dart test/data/repositories/wifi_password_repository_test.dart test/ui/view_models_test.dart test/ui/screens_test.dart

## Ghi chú khi làm (2026-11-28)
- Firmware: `src/data/qr_payload.h` + `Display::drawSetupQr` (chưa gọi — chờ vị trí trong thiết kế). Thư viện
  `ricmoo/QRCode` với `-D LOCK_VERSION=3`; native cần `lib_compat_mode = off` + `tools/pio_native_cflags.py`
  (`-std=gnu11` cho C, gcc máy mặc định C23). Đo RAM: gốc 44 564 B; có gọi `drawSetupQr` 44 612 B (+48 B: bảng
  tĩnh của thư viện; chuỗi đầu đã để flash). Bản hiện tại (chưa gọi) = 44 564 B.
- App: `WifiStep.password` đã có trong ViewModel nhưng `wifi_setup_screen.dart` chưa vẽ bước này (rơi vào nhánh
  trạng thái) — không gọi được từ UI cho tới nhiệm vụ 8. R-WF-4/5 để `sửa` tới khi có màn.
- Mật khẩu nhớ mà gửi xong thiết bị không hiện lại → quên (thêm vào R-WF-5).
