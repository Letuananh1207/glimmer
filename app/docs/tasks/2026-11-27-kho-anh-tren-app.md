# Kho ảnh trên app, thiết bị trỏ vào lấy

- Yêu cầu: "coi app điện thoại như 1 bộ nhớ bộ xử lý… còn phần cứng là hiển thị… phía app phải có 1 cơ chế gì đó để
  quản lý bộ nhớ và bên màn hình sẽ chỉ chỏ vào lấy" (2026-11-27). Bạn chốt cùng ngày: **thiết bị xin, app trả** (app
  chạy máy chủ ảnh nhỏ trong mạng nhà, thiết bị biết danh sách mã ảnh, tự xin khi cần hiện); **giữ bản đệm nhỏ** trên
  thiết bị (app quyết định ảnh nào) để vẫn hiện được khi app vắng.
- Loại: thêm (đổi cách lưu ảnh) · Cỡ: lớn (firmware + app + 2 phiếu thiết kế)
- Trạng thái: chờ thử máy thật (nhiệm vụ 1–10 xong 2026-11-28)

## Hiện trạng (đọc nhanh)

- Thiết bị: ảnh nằm hẳn trong LittleFS `/photos/p<N>.jpg` (≤ 8, ≤ 40 KB, đúng 188×188, chừa ≥ 64 KB trống),
  `GET/POST/DELETE /api/photos`; cửa sổ Ảnh chuyển ảnh mỗi `channelSec`; hình nền `/wallpaper.jpg` 240×214
  (`/api/wallpaper`). Giải mã TJpgDec từ file, ~3,7 KB đỉnh.
- App: tab Ảnh (lưới ảnh đang có trên thiết bị), cắt ảnh → gửi; giữ **bản sao** mỗi ảnh đã gửi trong
  `<app documents>/photos/<tên>` (`PhotoStoreService`), chỉ để làm hình xem trước, xoá khi thiết bị không còn ảnh đó.

## Mô hình mới

```
App (bộ nhớ)                                Thiết bị (màn hình)
 Kho ảnh: mọi ảnh đã cắt 188×188             RAM: nguồn {ip điện thoại, cổng, khoá, danh sách mã, rev}
 Máy chủ ảnh HTTP :8787 (khi app chạy)  <--  GET /p/<khoá>/<mã>.jpg  (xin khi cần hiện)
 Chọn ảnh "giữ trên máy" ----------------->  Bộ đệm flash (≤ 8, như hiện nay) — dùng khi app vắng
 POST /api/photos/source {…} (mỗi khi mở app / kho đổi)
```

- Cửa sổ Ảnh: có nguồn & xin được → trình chiếu qua **cả kho** (thứ tự kho); xin hỏng (app vắng) → chỉ chiếu
  **bộ đệm**, thử lại nguồn sau (mỗi 60 s, hoặc khi app gửi nguồn mới).
- Ảnh xin về được ghi vào một file tạm `/photos/cur.jpg` rồi vẽ từ file (để vẽ lại dưới con trỏ, sau thẻ agent,
  không phải xin lại) — xem quyết định Q1.
- Hình nền: vẫn **luôn nằm trên thiết bị** (desktop vẽ lại liên tục: con trỏ, menu, cửa sổ đóng mở — xin qua mạng mỗi
  lần là không được); app giữ kho hình nền và đẩy cái được chọn xuống, như "giữ trên máy" — xem Q3.

## Phạm vi

**Firmware — sẽ sửa**
- `src/data/photos_core.h`: luật nguồn (danh sách mã, rev, thứ tự chiếu kho ↔ bộ đệm, khi nào thử lại) — thuần, test host.
- `src/data/photos.{h,cpp}`: xin ảnh qua HTTP thường (WiFiClient, có hạn giờ), soi đầu JPEG khi chảy về (`JpegSniffer`),
  ghi `/photos/cur.jpg`, vẽ; bộ đệm = các `p<N>.jpg` như cũ.
- `src/channels/ch_photo.cpp`: trình chiếu qua kho / bộ đệm, trạng thái "đang tải từ điện thoại", meta `3/40`.
- `src/core/web.cpp`: `POST /api/photos/source {host, port, key, ids, rev}` (RAM), `/api/state` `photos`
  `{source: online|offline|none, lib, cache}`; `/api/photos` giữ nguyên (= bộ đệm).
- `src/main.cpp`: chuyển ảnh không chặn vòng lặp quá lâu (xin có hạn giờ ~3 s), không xin khi cổng heap từ chối.
- `CLAUDE.md` (mục Photos), `docs/AGENTS-GLIMMER.md` nếu liệt kê API.

**App — sẽ sửa / thêm**
- `lib/data/services/photo_store_service.dart`: kho = mọi ảnh (không còn xoá theo thiết bị); thêm siêu dữ liệu nhỏ
  (`library.json`: mã, ngày thêm).
- `lib/data/services/photo_server_service.dart` (mới): `HttpServer` trên cổng cố định, chỉ trả `/p/<khoá>/<mã>.jpg`
  từ kho, khoá ngẫu nhiên mỗi lần chạy app.
- `lib/data/repositories/photo/photo_repository{,_local}.dart`: kho ảnh (thêm, xoá), không phụ thuộc thiết bị.
- `lib/domain/models/device_photo.dart` → mô hình ảnh trong kho; `lib/domain/rules/photo_rules.dart`: bộ đệm = 8 ảnh
  mới nhất vừa chỗ trống thiết bị, thứ tự chiếu.
- `lib/domain/use_cases/` (mới) `sync_photo_source_use_case.dart`: gửi nguồn khi kết nối / mở app / kho đổi;
  đồng bộ bộ đệm (tải lên ảnh giữ trên máy còn thiếu, xoá ảnh thừa trên thiết bị).
- `send_photo_use_case.dart`, `delete_photo_use_case.dart`, `load_photos_use_case.dart`: thêm vào kho thay vì gửi thẳng.
- `lib/ui/dashboard/…photo_tab…`, `photo_grid.dart`: lưới kho, dấu "trên máy" — **chờ thiết kế** (phiếu app).
- `lib/domain/models/device_state.dart`: đọc `photos.source` (firmware có nguồn hay chưa — R-SK-4 kiểu cũ: firmware
  cũ → giữ cách gửi thẳng như hiện nay).
- `docs/testing/quy_tac.md`: mục Ảnh — luật mới (R-AK-…); `docs/backend/README.md`: kho ảnh, `library.json`.

**Cần kiểm tra** — `lib/config/dependencies.dart` (dịch vụ mới), `lib/routing/screens.dart`, `mirror_rules.dart` /
`mirror_agent_rules.dart` (gương màn Ảnh nếu còn dùng), `test/ui/screens_test.dart`, fake `testing/fakes/*`.

**Không đụng** — cách cắt ảnh (`photo_crop`), giới hạn ảnh 188×188 / 40 KB, hình nền phía thiết bị (chỉ đổi phía app
nếu chốt Q3), dữ liệu cấu hình thiết bị (`/config.json`).

## Cần thiết kế (phiếu) — giao diện chưa có trong `design/`

- **App** (`/ui-apply phieu`): tab Ảnh thành **Kho ảnh** — lưới mọi ảnh (không còn giới hạn 8), dấu "trên máy" (8 ảnh
  mới nhất đang ở bộ đệm thiết bị, chỉ để biết, không bấm được), trạng thái máy chủ ảnh (thiết bị đang lấy được /
  không), xoá khỏi kho.
- **Màn thiết bị** (`/panel-apply phieu`): cửa sổ Ảnh khi **đang tải từ điện thoại** (XP: hộp tải về đã có?), khi
  **app vắng** (chỉ chiếu bộ đệm — có ghi chú nhỏ không), meta `3/40` vs `3/8`.

Phần không dính giao diện (firmware nguồn ảnh + API, máy chủ ảnh, đồng bộ) làm trước được.

## Giả định / cần quyết định

- **Q1 — chốt: có** (bạn chốt 2026-11-27). Ảnh đang hiện lưu tạm trên flash: một file `/photos/cur.jpg` (≤ 40 KB) ghi đè mỗi lần đổi
  ảnh, để vẽ lại dưới con trỏ / sau thẻ agent mà không xin lại. Giá: một lần ghi flash mỗi bước trình chiếu (chiếu mỗi
  30 s ≈ 2 900 lần/ngày, LittleFS rải đều — tuổi thọ vẫn nhiều năm; có thể đặt bước chiếu tối thiểu 30 s). Cách kia:
  không lưu, vẽ lại phải xin lại qua mạng (con trỏ trên cửa sổ Ảnh giật, 0,3–1 s mỗi lần).
- **Q2 — chốt: app tự chọn** (bạn chốt 2026-11-27): bộ đệm luôn là 8 ảnh mới nhất của kho (ít hơn nếu thiết bị
  không đủ chỗ); không có nút ghim.
- **Q3 — chốt: gọn** (bạn chốt 2026-11-27): hình nền vẫn luôn nằm trên thiết bị (vẽ lại quá thường); app thêm kho hình nền để chọn lại nhanh
  — có thể để sau, không làm trong đợt này.
- **Q4 — chốt: gọn** (bạn chốt 2026-11-27): máy chủ ảnh chạy khi app mở (và ~2 phút sau khi ra nền); không dùng dịch vụ
  chạy nền có thông báo thường trực. App vắng → thiết bị chiếu bộ đệm. Muốn kho luôn sẵn thì đợt sau thêm dịch vụ nền.
- Bảo mật: chỉ trong mạng nhà, đường dẫn có khoá ngẫu nhiên mỗi lần chạy app (không đoán được tên ảnh); HTTP thường
  (thiết bị không đủ RAM cho TLS hai chiều).
- Firmware cũ (không có `photos.source`) → app giữ cách gửi thẳng như hiện nay.

## Nhiệm vụ

- [x] 1. Luật nguồn ảnh (firmware, thuần): danh sách mã, rev, chiếu kho ↔ bộ đệm, thử lại 60 s — `photos_core.h`
  · test: `test/test_logic` · xong khi: `pio test -e native` xanh.
- [x] 2. (thử trên thiết bị 2026-11-27 bằng máy chủ tạm trên máy tính: đi 1→2→3, tắt máy chủ → offline, chiếu bộ đệm) Thiết bị xin ảnh HTTP + soi JPEG + `cur.jpg` + vẽ; `POST /api/photos/source`, `/api/state photos` —
  `photos.{h,cpp}`, `web.cpp`, `main.cpp`, `ch_photo.cpp` (chưa đổi giao diện) · xong khi: build, RAM tĩnh không tăng
  bất thường, thử bằng `curl` + một máy chủ ảnh trên máy tính.
- [x] 3. Luật app (R-AK-…): kho, chọn bộ đệm, nguồn — `quy_tac.md`, `photo_rules.dart` · test: `photo_rules_test.dart`.
- [x] 4. Kho ảnh app: `PhotoStoreService` + `library.json`, `PhotoRepository` (dữ liệu người dùng → `docs/backend/`)
  · test: `photo_store_service_test.dart`, repository test.
- [x] 5. Máy chủ ảnh `PhotoServerService` · test: `test/data/services/photo_server_service_test.dart` (HttpClient thật
  trên localhost).
- [x] 6. `SyncPhotoSourceUseCase` + sửa send / delete / load use case · test: `photo_use_cases_test.dart` (DeviceRig).
- [x] 7. `DeviceState` đọc `photos.source` · test: model test.
- [x] 8. (áp thiết kế 2026-11-28.11) Giao diện Kho ảnh (app) — **chờ thiết kế: `docs/phieu_thiet_ke/2026-11-27-kho-anh.md`** · test: widget test.
- [x] 9. (áp P-2026-11-28.27) Giao diện cửa sổ Ảnh (thiết bị) — **chờ thiết kế: `../docs/phieu_panel/2026-11-27-anh-tu-dien-thoai.md`**.
- [x] 10. `CLAUDE.md` (Photos), `docs/backend/README.md`, bản đồ tính năng `/lead`.

## Kiểm tra cuối

pio run -e nodemcuv2 · pio test -e native · dart tool/check.dart --changed · flutter analyze ·
flutter test -r failures-only test/domain test/data test/ui/dashboard · dart tool/rule_trace.dart
