# Hợp đồng dữ liệu với backend

Mô tả dữ liệu người dùng app lưu trên máy (tên trường, kiểu, ý nghĩa) để backend làm theo. Cập nhật **cùng commit**
với mọi thay đổi ở `lib/data/repositories/` hoặc `lib/domain/models/` (`tool/check.dart` nhắc bằng W-backend).

App chưa có backend. Dữ liệu người dùng chỉ gồm vài giá trị trên máy; mọi thứ khác (trạng thái, cài đặt, thẻ) đọc
thẳng từ thiết bị qua HTTP (`/api/*`, `/push` — hợp đồng do firmware quyết định, `../src/core/web.cpp`) và không lưu.

## Lưu trên máy — `shared_preferences` (`lib/data/services/local_store_service.dart`)

| Khoá | Kiểu | Mặc định | Ý nghĩa |
| --- | --- | --- | --- |
| `device_url` | string | `''` | Địa chỉ thiết bị trả lời lần trước, vd `http://192.168.100.40`. Không lưu AP cài đặt `192.168.4.1` (R-KN-1). |
| `token` | string | `''` | API token của thiết bị (gửi `Authorization: Bearer …`); rỗng khi thiết bị không đặt token. Bí mật. |
| `skills_on` | string list | _(không có)_ | Id skill đang bật, theo thứ tự dock (`agent`, `weather`, `clock`, R-SK-1). Thiếu / rỗng / toàn id lạ → `[agent, weather, clock]`. Thiết bị báo danh sách khác (`skills_on` trong `/api/state`) → ghi theo thiết bị (R-SK-5). |
| `repo` | string | `Letuananh1207/glimmer` | Repo GitHub có bản phát hành `latest` chứa `firmware.bin` / `littlefs.bin`. |

## Tệp sao lưu cấu hình

`glimmer-config-<YYYY-MM-DDTHHmm>.json` trong thư mục tài liệu của app: nguyên văn `GET /api/export` (config.json của
thiết bị, khoá snake_case, **có mật khẩu Wi-Fi và khoá Claude**). Hợp lệ khi có `wifi_ssid` (R-TB-2).

## Ghi chú lần chuyển MVVM (2026-11-25)

Model chuyển sang `lib/domain/models/` (`DeviceState`, `Usage`, `Project`, `AttentionCard` — trước là `Card`,
`Release`, `ConfigBackup`, `AppError`), repository ở `lib/data/repositories/{device,release,backup}/`. Khoá lưu và
định dạng tệp không đổi — không cần di trú.

## Danh mục skill (2026-11-25.2)

`active_skill` chỉ nhận id có gói trong app (`skillCatalog` ở `lib/domain/rules/skill_rules.dart`, hiện chỉ `agent`).
Id `music` / `social` / `fun` là ô "Sắp có" — không bao giờ được lưu. Khoá và kiểu không đổi.

## Skill bật / tắt theo dock (2026-11-25.3)

`active_skill` (string, một skill) **thay bằng** `skills_on` (string list). Không di trú giá trị: khoá cũ bị bỏ qua (mặc
định mới gồm cả ba skill — đúng thứ thiết bị đang xoay trước khi nâng cấp) và bị xoá ở lần ghi đầu. Chỉ id có gói
(`skillCatalog` ở `lib/domain/rules/skill_rules.dart`: `agent`, `weather`, `clock`) được lưu; `chat` / `music` /
`social` / `fun` là chip "Sắp có". Model mới đọc từ thiết bị (không lưu): `DeviceState.skillsOn`,
`DeviceState.weather` (`DeviceWeather` + `WeatherDay`, `lib/domain/models/device_weather.dart`).

`AttentionCard.showsInS` (2026-11-25.3, đọc từ `shows_in_s` của `GET /push`, không lưu): thẻ còn ẩn trên thiết bị
(Codex "tới lượt bạn" chờ 60 s) — không đếm vào huy hiệu agent chờ.

## Skill Ảnh (2026-11-25.4)

`skills_on` nhận thêm id `photo` (thứ tự dock `agent`, `photo`, `weather`, `clock`; mặc định vẫn không có `photo`,
R-SK-1). Không di trú.

**Bản sao ảnh đã gửi** — `<thư mục tài liệu của app>/photos/<tên tệp trên thiết bị>` (`PhotoStoreService`,
`PhotoRepositoryLocal`): đúng tệp JPEG baseline 188 × 188 ≤ 40 KB app đã gửi `POST /api/photos`, đặt theo tên thiết bị
trả về (`p3.jpg`; ký tự ngoài `A-Za-z0-9._-` đổi thành `_`). Chỉ dùng làm hình thu nhỏ ở tab Ảnh: khớp khi thiết bị còn
ảnh **cùng tên và cùng kích thước** (thiết bị khác / ảnh gửi từ nơi khác có thể trùng tên); tải danh sách thì xoá bản
sao của ảnh thiết bị không còn; xoá ảnh trên app xoá luôn bản sao. Không phải dữ liệu gốc — mất thì chỉ thiếu hình
thu nhỏ. Backend (nếu có) không cần đồng bộ.

Model đọc từ thiết bị (không lưu): `DeviceState.photos` (`photos` của `/api/state`, null = firmware chưa có ảnh),
`PhotoInfo` / `DevicePhoto` (`GET /api/photos`), `SentPhoto` (`POST /api/photos`), `PhotoGallery` / `GalleryPhoto`
(danh sách + bản sao), `PhotoPixels` (vùng cắt RGBA đưa vào `SendPhotoUseCase`) — `lib/domain/models/device_photo.dart`.

## Điều khiển thiết bị (2026-11-26.5)

Không lưu gì mới trên máy. Model đọc từ thiết bị (không lưu): `DeviceState.paused` / `screenOn` / `slideLeftMs` /
`wallpaper` (null = firmware chưa có → nút khoá, R-DK-3), `slideMs`, `nightFace`; `ChannelAnswer` (`POST /api/channel`
→ `{active, paused}`), `ControlOutcome`, `ControlCaps` (`lib/domain/models/control.dart`). Lệnh: `DeviceRepository.channel`
/ `setScreen` (vá `state` ngay theo câu trả lời), `clearCard` (`/push/clear {id}`), `saveSettings` (`brightness`,
`nightMode`), `refreshNow`.

**2026-11-26.6** (màn thiết bị chạm được, thiết bị không tự xoay): vẫn không lưu gì trên máy. Trong RAM của
`ControlViewModel`: `WindowStack` (`lib/domain/models/windows.dart` — cửa sổ đang mở theo thứ tự mở, cửa sổ trên cùng,
cửa sổ thu nhỏ; R-DK-7/8), `TouchTarget` / `ProgramGroup` (`lib/domain/models/touch.dart`). `ControlCaps` còn `touch`
(có `paused` → firmware nhận chạm), `screen`, `dismissCard`. Lệnh: `ControlDeviceUseCase.open(name)` (`/api/channel
{name}`; `Home` = desktop), `stopRotation` (`saveSettings {autoRotate: false}` khi còn bật), `restart` (`/api/reboot`).

**2026-11-26.7 / .8**: `TaskbarModel` của ô màn = cửa sổ đang mở (`programs`, `buttons`, `active` = chỉ số nút lõm;
bỏ `progress` / `accent`); `DesktopView.icons` (`DeskIcon`: chương trình, tâm cột, đỉnh ô — theo skill bật, panel
P-2026-11-26.14). Mở app lần đầu: thiết bị đang hiện chương trình → `/api/channel {name: Home}` một lần.
`WindowStack` thêm `z` (thứ tự kích hoạt, để `×` biết cửa sổ trước đó) và `sel` (biểu tượng desktop đang chọn), gửi
xuống bằng `POST /api/windows` (`toJson`); `MenuView` / `MenuItem` (`touch.dart`) = menu chuột phải, gửi `POST /api/menu`.
`DeviceState.windowsApi` (có `windows` trong `/api/state`) → `ControlCaps.windows`.

## Cửa sổ XP thật (panel P-2026-11-26.17, R-DK-14)

Model đọc từ thiết bị (không lưu): `WeatherDay.uv` (`uv` trong `weather.days[]` của `/api/state`, chỉ số UV cao nhất
trong ngày; < 0 hoặc thiếu = null, firmware cũ); `weatherPlace` trong `/api/settings` (tên nơi, rỗng = chưa có) — có
khoá này nghĩa là firmware cửa sổ XP thật (`xpReal`). Model ô màn: `MirrorWeather.code` / `uv` / `place`,
`MirrorDay.code`, `MirrorClock.place` (`lib/domain/models/mirror_ambient.dart`); chạm mới `TouchKind.trayClock` /
`balloonBody` / `tab` (`lib/domain/models/touch.dart`). Không di trú, backend (nếu có) không cần đồng bộ.

## Chuột, bàn phím, nguồn (R-DK-17…21, kế hoạch 2026-11-27)

Không lưu gì trên điện thoại. Model đọc từ thiết bị: `DeviceState.cursorPort` (`cursor.port` của `/api/state`, null =
firmware chưa có chuột → `ControlCaps.mouse` false), `DeviceState.power` (`power`: `on` / `shutting` / `off` /
`booting`, `PowerState` trong `lib/domain/models/cursor.dart`). Trong RAM: `Cursor` (vị trí px thiết bị + hình,
`CursorShape`), `ControlKey`. Lệnh: con trỏ qua **UDP** (`CursorService`, gói 8 byte do `cursorPacket` dựng, không
chờ trả lời), `POST /api/power {on}` (`setPower`, vá `state.power`), `POST /api/menu {…, hover}` (mục đang sáng).
Thiết kế 2026-11-27.10: bỏ ô màn — `MirrorFrame` / `UsageMirror` còn giữ làm dữ liệu cho luật trúng đích, app không vẽ
chúng nữa; `StartPick` / `AppScreen` (`lib/domain/models/start_pick.dart`) = mục Start trên thiết bị được click (R-DK-22).
Không di trú, backend (nếu có) không cần đồng bộ.

**Dò mìn, Start đủ chương trình (panel P-2026-11-27.25, R-DK-22 / R-DK-23):** không lưu gì trên máy. Trong RAM của
`ControlViewModel`: `MinesGame` (`lib/domain/models/mines_game.dart` — mìn, ô đã mở, cờ, trạng thái, giờ bắt đầu /
kết thúc; luật `lib/domain/rules/mines_rules.dart`), gửi cả bảng `POST /api/mines {board, face, left, secs, run}`
(`setMines`). Đọc từ thiết bị: `DeviceState.startRecent` (`start_recent`, 3 chương trình mở gần nhất),
`DeviceState.minesApi` (`mines` có trong `/api/state` → `ControlCaps.mines`). Skill `fun` (Giải trí) thành gói.
Không di trú.
## Vị trí thời tiết (2026-11-26.9, R-VT-1…5)

Không lưu gì trên điện thoại: vị trí chỉ nằm trên thiết bị, đọc / ghi qua `/api/settings` — `weatherLat`,
`weatherLon` (0, 0 = chưa đặt), `weatherPlace` (tên ≤ 16 ký tự; firmware không có khoá này → chỉ gửi toạ độ). Model
`WeatherLocation`, `PlaceResult`, `GpsOutcome` (`lib/domain/models/weather_location.dart`); `LocationRepository`
(`lib/data/repositories/location/`) gọi `PositionService` (geolocator + geocoding, chỉ khi bấm "Dùng vị trí hiện tại")
và `GeoSearchService` (Open-Meteo geocoding, `language=vi`, ≤ 10 kết quả; tên gõ được gửi tới Open-Meteo).

## Kho ảnh (2026-11-27, R-AK-1…5)

App là bộ nhớ, thiết bị trỏ vào lấy (kế hoạch `docs/tasks/2026-11-27-kho-anh-tren-app.md`). Lưu trên máy:
`<app documents>/library/<mã>.jpg` (JPEG 188×188 ≤ 40 KB, đã cắt) + `library.json`
`[{id, added (ms), size, cachedAs?}]` — `id` tăng dần không dùng lại, `cachedAs` = tên ảnh trên thiết bị khi ảnh đang
trong bộ đệm (8 ảnh mới nhất). Ghi qua file tạm rồi đổi tên. `PhotoLibraryService` (file), `PhotoLibraryRepository`
(`lib/data/repositories/photo/`), `PhotoServerService` (HTTP thường cổng 8787, `GET /p/<khoá>/next?after=<id>`),
`PhotoSourceUseCase` (gửi `POST /api/photos/source {host, port, key}`, đồng bộ bộ đệm). Bản sao cũ
(`<app documents>/photos/`, hình xem trước của tab Ảnh) giữ nguyên.
