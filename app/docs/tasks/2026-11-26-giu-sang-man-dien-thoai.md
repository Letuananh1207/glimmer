# Giữ sáng màn điện thoại khi mở app

- Yêu cầu: tôi muốn trong thời gian mở app flutter thì không được tắt màn hình
- Loại: thêm · Cỡ: nhỏ
- Trạng thái: xong

## Phạm vi
**Sẽ sửa** — `android/app/src/main/kotlin/io/github/letuananh1207/glimmer_app/MainActivity.kt`: bật `FLAG_KEEP_SCREEN_ON` cho cửa sổ Activity · `docs/testing/quy_tac.md`: thêm R-DK-12
**Không đụng** — code Dart, `pubspec.yaml` (không thêm gói wakelock), firmware / màn thiết bị glimmer

## Giả định / cần quyết định
- "Màn hình" = màn điện thoại (người dùng xác nhận). Cờ cửa sổ chỉ có hiệu lực khi Activity đang hiện, nên ra nền là tự hết — không cần theo dõi vòng đời bằng Dart.

## Nhiệm vụ
- [x] 1. Quy tắc R-DK-12 — `docs/testing/quy_tac.md` · test: miễn (cờ Android gốc) · xong khi: dòng có trong sổ
- [x] 2. Bật `FLAG_KEEP_SCREEN_ON` trong `onCreate` — `MainActivity.kt` (Android gốc) · xong khi: `flutter build apk --debug` qua

## Kiểm tra cuối
flutter build apk --debug · thử máy thật: mở app để yên quá thời gian tắt màn
