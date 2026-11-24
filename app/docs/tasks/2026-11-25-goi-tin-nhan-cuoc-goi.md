# Gói Tin nhắn & cuộc gọi

- Yêu cầu: "gói Tin nhắn & cuộc gọi: app Android đọc thông báo (quyền Truy cập thông báo) của các app chat (Zalo,
  Messenger, SMS, WhatsApp, Telegram…) và cuộc gọi đến, gửi lên glimmer qua /push. Đã chốt: (1) cuộc gọi đến chen
  ngang mọi skill như thẻ duyệt; (2) tin nhắn chỉ hiện trong skill Tin nhắn, không chen ngang; (3) mặc định bắt danh
  sách app chat phổ biến, người dùng bật/tắt từng app. Có tuỳ chọn chỉ hiện tên người gửi."
- Loại: thêm · Cỡ: lớn
- Trạng thái: chờ duyệt

## Cách làm (tóm tắt)

```
Android: thông báo mới ─► GlimmerNotificationListener (Kotlin, chạy nền do hệ thống giữ)
            lọc app đã bật · cuộc gọi hay tin nhắn · bỏ trùng
            ├─ tin nhắn  ─► POST /msg        → thiết bị giữ 6 tin gần nhất → kênh "Messages" (skill chat)
            └─ cuộc gọi  ─► POST /push kind=call  → thẻ chen ngang mọi skill; hết đổ chuông → POST /push/clear
App Flutter: bật/tắt từng app, "chỉ tên người gửi", xin quyền — lưu shared_preferences, Kotlin đọc cùng chỗ.
```

Listener viết bằng **Kotlin** (không chạy Flutter nền): `NotificationListenerService` được Android giữ sống khi có
quyền, tự gửi HTTP lên thiết bị bằng địa chỉ + token app đã lưu. Không cần dịch vụ nền có thông báo thường trực.

## Phạm vi

**Sẽ sửa — firmware**
- `src/data/attention_core.h`: kind mới `K_CALL` (ưu tiên cao nhất, giữ màn tới khi xoá, hạn tối đa 90 s),
  `attention_json.h` (`"call"`), `ch_attention.cpp` (thẻ cuộc gọi: tên người gọi lớn, app, "ĐANG GỌI"), MCP schema trong
  `web.cpp`, `docs/AGENTS-GLIMMER.md` (giữ đồng bộ — `../CLAUDE.md`).
- `src/data/messages_core.h` (mới, thuần, host test): vòng 6 tin `{app, sender, text, at}`, cắt UTF-8 an toàn.
- `src/core/web.cpp`: `POST /msg`, `POST /msg/clear`; `/api/state` thêm `messages` (số tin) — auth như `/push`.
- `src/channels/ch_messages.cpp` (mới): kênh "Messages" skill `chat` — danh sách tin, phần vẽ lại từng vùng.
- `src/data/skill_core.h`: `kAll += "chat"`; `main.cpp` đăng ký kênh. `data/web/index.html`: nhãn skill.
- `test/test_logic/test_main.cpp`: vòng tin, kind call.

**Sẽ sửa — app**
- `android/app/src/main/kotlin/…/GlimmerNotificationListener.kt` (mới) + `AndroidManifest.xml` (service
  `BIND_NOTIFICATION_LISTENER_SERVICE`) + MethodChannel (`hasAccess`, `openSettings`, danh sách app đã cài).
- `lib/domain/models/chat_app.dart`, `lib/domain/rules/chat_rules.dart` (mới): danh sách app mặc định, phân loại
  cuộc gọi / tin nhắn, rút gọn nội dung khi "chỉ tên người gửi" — **bản Dart là nguồn sự thật cho test**, Kotlin làm
  theo đúng bảng đó.
- `lib/data/services/notification_access_service.dart` (mới, MethodChannel), `local_store_service.dart` (khoá
  `chat_apps`, `chat_sender_only`, `chat_enabled`).
- `lib/data/repositories/chat/chat_repository.dart` (+ `_local`) (mới).
- `skill_rules.dart`: danh mục thêm `chat` (có gói). `routes.dart`: `skillHomes['chat']`.
- Màn chính skill Tin nhắn (bật/tắt app, chỉ tên người gửi, trạng thái quyền) — **chờ thiết kế** (phiếu).
- `docs/testing/quy_tac.md` vùng `R-TN-…`; `docs/backend/README.md` khoá mới.

**Cần kiểm tra** — `skills_test.dart` (danh mục đổi), `ch_attention.cpp` thứ tự kind (thẻ duyệt vẫn đúng),
`pinApprovals` / ban đêm.

**Không đụng** — dữ liệu đã lưu; skill Agent; luồng thẻ của Claude Code / Codex (chỉ thêm một kind).

## Giả định / cần quyết định
- **Id skill `chat`, tên "Tin nhắn"**. Ô "Mạng xã hội" (`social`, "Sắp có") giữ nguyên cho thông báo / số liệu mạng xã
  hội sau này. → cần duyệt.
- **Ban đêm:** cuộc gọi theo luật ban đêm hiện có — đêm "đồng hồ/tắt màn" chỉ sáng dải chỉ báo, không đánh thức màn
  (giống thẻ duyệt khi chưa bật "hiện ban đêm"). → cần duyệt.
- Cuộc gọi: thẻ giữ màn trong lúc đổ chuông; app gỡ thẻ khi thông báo cuộc gọi biến mất (nghe / từ chối / nhỡ). Cuộc
  gọi nhỡ **không** thành tin nhắn ở đợt này.
- App mặc định bật: Zalo, Messenger, Tin nhắn (Google, Samsung), WhatsApp, Telegram, Viber, Điện thoại (Google,
  Samsung). App khác thêm sau.
- Chỉ gửi khi điện thoại cùng mạng với thiết bị (dùng địa chỉ đã lưu); không lưu hàng đợi chờ gửi lại.
- Nội dung tin chỉ đi tới thiết bị trong mạng nhà, không qua máy chủ nào; không lưu trên điện thoại.
- Màn thiết bị (240×240) theo phong cách kênh hiện có (thẻ `ch_attention`, danh sách `ch_agents`) — thiết kế màn
  thiết bị không đi qua canvas app (`../CLAUDE.md`).

## Quy tắc mới (ghi `quy_tac.md` trước, App `sửa`)
- R-TN-1: Chỉ chuyển thông báo của app đang bật; mặc định bật danh sách app chat + điện thoại phổ biến.
- R-TN-2: Tin nhắn không chen ngang; chỉ hiện ở kênh Tin nhắn khi skill `chat` đang dùng; thiết bị giữ 6 tin gần nhất.
- R-TN-3: Cuộc gọi đến chen ngang mọi skill, giữ màn tới khi hết đổ chuông (tối đa 90 s); ban đêm theo luật thẻ duyệt.
- R-TN-4: "Chỉ tên người gửi" bật → không gửi nội dung tin, chỉ app + người gửi.
- R-TN-5: Một tin chỉ gửi một lần (thông báo cập nhật / nhóm tóm tắt không gửi lại).
- R-TN-6: Chưa có quyền Truy cập thông báo, hoặc tắt cả gói → không gửi gì; app chỉ cách bật quyền.

## Nhiệm vụ
- [ ] 1. Quy tắc R-TN-1..6 — `docs/testing/quy_tac.md`.
- [ ] 2. Phiếu thiết kế: màn chính skill Tin nhắn + ô skill trong lưới — `docs/phieu_thiet_ke/`.
- [ ] 3. Firmware: `messages_core.h` + host test; `K_CALL` + host test.
- [ ] 4. Firmware: `/msg`, `/msg/clear`, `/api/state`; kênh `ch_messages.cpp`; thẻ cuộc gọi trong `ch_attention.cpp`;
  `skill_core` `chat`; MCP schema + `AGENTS-GLIMMER.md` · xong khi: `pio test`, `pio run` SUCCESS, đo nhãn tiếng Việt vừa
  ô (`tools/vlwpreview.py`).
- [ ] 5. App domain: `chat_app.dart`, `chat_rules.dart` · test R-TN-1/4/5.
- [ ] 6. App data: `notification_access_service`, khoá lưu, `ChatRepository` · test · `docs/backend`.
- [ ] 7. Android: `GlimmerNotificationListener.kt` + manifest + MethodChannel — theo đúng `chat_rules` · xong khi:
  build APK được; thử máy thật: tin Zalo hiện trên kênh, cuộc gọi chen ngang.
- [ ] 8. Danh mục skill `chat` + route màn chính · *chờ thiết kế (phiếu nhiệm vụ 2)*.
- [ ] 9. Bản đồ tính năng `/lead`.

## Kiểm tra cuối
dart tool/check.dart --changed · flutter analyze · flutter test -r failures-only · dart tool/rule_trace.dart ·
flutter build apk --debug · python -m platformio test -e native · python -m platformio run -e nodemcuv2 ·
thử máy thật (tin nhắn + cuộc gọi).
