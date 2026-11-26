# glimmer — ứng dụng Android

Ứng dụng đi kèm màn hình glimmer (GeekMagic SmallTV-Ultra chạy firmware này):
cài Wi-Fi cho thiết bị, xem mức dùng Claude và bảng project, chỉnh cài đặt,
cập nhật firmware và sao lưu cấu hình. Giao diện tiếng Việt, cùng bảng màu và
linh vật Clawd như trên màn hình.

## Chức năng

| Màn | Làm gì |
|---|---|
| **Kết nối** | Tự tìm thiết bị: địa chỉ lần trước → NSD/mDNS (`_http._tcp` "glimmer") → `glimmer.local` → `192.168.4.1` (khi điện thoại đang ở glimmer-setup). Hoặc nhập IP + API token. |
| **Tổng quan** | Clawd đổi biểu cảm theo bảng project; % đã dùng của tuần và phiên 5 giờ + thời gian đặt lại; bảng project; thẻ đang hiện (xóa từng thẻ / tất cả); tải số liệu ngay; chuyển màn hình sang Claude. Tự làm mới mỗi 5 s khi app đang mở. |
| **Cài đặt** | Độ sáng, tự giảm sáng, số lớn (tuần/phiên), ban đêm, khóa Claude, tần suất tải, tên, các tùy chọn agent, API token. Chỉ gửi những mục đã đổi. |
| **Thiết bị** | Thông tin; **đổi Wi-Fi**; khởi động lại; **cập nhật firmware** (giữ cấu hình); **cập nhật đầy đủ** (firmware + font/giao diện web: tự sao lưu → nạp → khôi phục qua glimmer-setup); **sao lưu / khôi phục cấu hình**. |

Cài Wi-Fi khi thiết bị đang hiện **KẾT NỐI WI-FI · glimmer-setup**: app vào
mạng đó *chỉ cho riêng app* (Android hỏi xác nhận một lần, các app khác vẫn
dùng Wi-Fi bình thường), gửi tên + mật khẩu Wi-Fi, rồi tìm lại thiết bị trên
mạng mới. Thiết bị chỉ dùng Wi-Fi 2,4 GHz và không vào được mạng phải đăng
nhập qua trang web.

Bản cập nhật lấy từ bản phát hành `latest` mà CI đăng lên repo
`Letuananh1207/glimmer` (đổi được trong mã: `Store.repo`).

## Build

```bash
cd app
flutter pub get
flutter build apk --release     # → build/app/outputs/flutter-apk/app-release.apk
flutter test                    # test logic
GLIMMER_LIVE=http://<ip> flutter test test/device_live_test.dart   # với thiết bị thật
```

APK được ký bằng khóa debug (đủ để cài thẳng lên điện thoại). Muốn đưa lên
Play Store thì cần tạo khóa ký riêng.

## API thiết bị dùng tới

`GET /api/state` (có `claude_usage`, `projects`, `time`, `skill`, `skills`, `skills_on`, `weather`, `photos` = số
ảnh, `wallpaper` = có hình nền riêng, `paused`, `screen_on`, `slide_ms`, `slide_left_ms`), `GET/POST
/api/settings`, `GET /api/export`, `POST /api/import`, `POST /api/reboot`,
`POST /api/refresh`, `POST /api/channel`, `GET /push`, `POST /push/clear`,
`POST /update` (multipart `firmware` / `filesystem`). Token (nếu đặt) gửi qua
`Authorization: Bearer …`.

Ảnh (skill `photo`): `GET /api/photos` → `{photos: [{name, size}], free, total, max_count: 8, max_bytes: 40960,
reserve: 65536, side: 188}`; `POST /api/photos` multipart, trường `photo` = JPEG **baseline** đúng **188×188**,
≤ 40 KB (app cắt vuông + thu nhỏ trước khi gửi) → 200 `{ok, name, count}`; lỗi `{error}` với mã `full` / `too_big`
(413), `no_space` (507), `not_jpeg` / `progressive` / `bad_size` / `truncated` / `empty` / `field` (400), `fs` (500);
`DELETE /api/photos?name=p3.jpg` → `{ok, count}` / 404. Upload và xoá cần token (nếu đặt).

Điều khiển (màn Điều khiển, thiết kế 2026-11-26.5; cần token nếu đặt; firmware cũ thiếu → `400 unknown action` /
404 — R-DK-3 khoá nút khi `/api/state` không có `paused` / `screen_on` / `slide_ms`):
- `POST /api/channel {"name":"Claude"}` | `{"action":"next"}` | `{"action":"prev"}` → `{ok, active, paused}`;
  tên lạ → 404, action lạ → 400.
- `POST /api/channel {"action":"pause"}` / `{"action":"resume"}` → `{ok, active, paused}`: vẫn trả lời nhưng từ panel
  P-2026-11-26.14 thiết bị **không xoay kênh** nữa (app vẫn dùng `paused` có mặt để biết firmware nhận chạm).
- `POST /api/windows {"open":[…],"top":…|null,"min":[…],"sel":…|null}` → `{ok}` (panel P-2026-11-26.14): danh sách cửa sổ
  app đang giữ (R-DK-7), cả danh sách mỗi lần; tên như `/api/channel`, tên lạ bỏ qua; RAM. Thanh tác vụ máy = các cửa sổ
  này (4 nút cuối), `sel` = biểu tượng desktop đang chọn. `/api/channel {name}` của một chương trình chưa có trong danh
  sách → máy tự thêm.
- `POST /api/menu {"kind":"desktop"|"window"|"none","x","y","minimized"}` → `{ok}` (R-DK-11): vẽ / đóng menu chuột phải
  (góc trên trái, máy giữ trong y ≤ 213); `409` khi màn không có menu (đêm, thẻ). Máy không tự làm theo mục: app chọn
  mục rồi gửi lệnh. Mọi `/api/channel` đóng menu.
- `POST /api/balloon {"show": true|false}` → `{ok, balloon}` (R-DK-13, firmware P-2026-11-26.15): bong bóng thời
  tiết của desktop — hiện 10 s / ẩn ngay; 409 khi không ở desktop hoặc skill Thời tiết tắt. `/api/state.balloon`.
- `POST /api/screen {"on":false|true}` → `{ok, screen_on}`. Tắt / bật đèn nền ngay, không theo giờ đêm, RAM. Thẻ urgent /
  cần duyệt / câu hỏi / lỗi của người dùng vẫn làm sáng màn lúc nó giữ màn; `screen_on` vẫn là `false` (lệnh của app).
- `/api/state`: `paused` (bool), `screen_on` (bool), `windows {open, top, min, sel}` + `menu` (`desktop` / `window` /
  `none`) khi firmware có P-2026-11-26.14; `slide_ms` / `slide_left_ms` luôn `0` (không xoay).
- Bỏ một thẻ: `POST /push/clear {"id":"…"}` → `{cleared: 1|0}` (như MCP `clear_card`); id lấy từ `GET /push`.

Hình nền desktop (màn đầu, P-2026-11-26.12): `GET /api/wallpaper` → `{set, size, w: 240, h: 214, max_bytes: 40960, free,
reserve}`; `POST /api/wallpaper` multipart, trường `wallpaper` = JPEG **baseline** đúng **240×214**, ≤ 40 KB → 200
`{ok, size}`; lỗi `{error}`: `too_big` (413), `no_space` (507), `not_jpeg` / `progressive` / `bad_size` / `truncated` /
`empty` / `field` (400), `fs` (500); `DELETE /api/wallpaper` → `{ok}` / 404 (đang dùng nền mặc định). Cần token (nếu đặt).
