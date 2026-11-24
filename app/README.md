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

`GET /api/state` (có `claude_usage`, `projects`, `time`), `GET/POST
/api/settings`, `GET /api/export`, `POST /api/import`, `POST /api/reboot`,
`POST /api/refresh`, `POST /api/channel`, `GET /push`, `POST /push/clear`,
`POST /update` (multipart `firmware` / `filesystem`). Token (nếu đặt) gửi qua
`Authorization: Bearer …`.
