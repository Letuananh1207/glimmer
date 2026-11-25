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
