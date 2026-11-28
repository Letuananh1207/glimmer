# Phiếu thiết kế: Đặt vị trí thời tiết từ app (tên nơi cho thiết bị)

- Trạng thái: đã áp (2026-11-26.9)
- Đã vẽ: 2026-11-26.9
- Ngày: 2026-11-26 · Nguồn: áp panel P-2026-11-26.17 — người dùng chốt "những cái liên quan địa điểm thì nên dùng vị
  trí trên app để dùng"

## Dán vào canvas

**Màn / widget:** chưa có — app hiện **không có chỗ nào** đặt vị trí thời tiết; vị trí chỉ đặt được ở trang web của
thiết bị (`http://glimmer.local`, ô tìm thành phố). Thiết kế quyết đặt ở đâu (Cài đặt, skill Thời tiết, hay ngay trên
cửa sổ Thời tiết của màn điều khiển) và ra sao.

**Cần:** Người dùng đặt vị trí thời tiết của thiết bị **từ điện thoại**: lấy vị trí hiện tại của điện thoại (GPS, xin
quyền), hoặc gõ tìm một thành phố. App gửi cho thiết bị toạ độ **và tên nơi**; thiết bị hiện tên nơi trên cửa sổ Thời tiết
("Hà Nội" dưới chữ "Ít mây") và trên Đồng hồ ("Múi giờ: GMT+7 · Hà Nội"). Người dùng biết thiết bị đang dùng vị trí nào
và đổi / xoá được.

**Trạng thái phải vẽ:**
- Chưa đặt vị trí (thiết bị không có thời tiết; skill Thời tiết bật nhưng trống).
- Đang lấy vị trí điện thoại · chưa cho quyền vị trí / bị từ chối · tắt định vị · không lấy được.
- Tìm thành phố: đang tìm, có kết quả (tên + vùng / nước), không có kết quả, lỗi mạng.
- Đã đặt: tên nơi + (tuỳ) toạ độ; đổi; xoá.
- Đang gửi cho thiết bị / thiết bị không nhận (thử lại) / firmware cũ không có tên nơi (chỉ gửi toạ độ, gợi ý cập nhật).

**Luật phải theo:**
- Vị trí là cài đặt của thiết bị (`/api/settings`), không lưu riêng trên app; nhiều điện thoại cùng thấy một vị trí.
- Không gửi vị trí ra dịch vụ ngoài khi người dùng chưa đồng ý (tìm thành phố: Open-Meteo geocoding như trang web thiết
  bị đang dùng; GPS: chỉ khi người dùng bấm).
- Tên nơi ngắn: thiết bị cắt cho vừa khe (≈ 112 px ở Thời tiết, 216 px ở dòng múi giờ).

**Dữ liệu từ thiết bị (có sẵn):** `GET /api/settings` → `weatherLat`, `weatherLon`, `weatherPlace` (tên nơi, rỗng =
chưa có; có khoá này = firmware P-2026-11-26.17); `POST /api/settings {weatherLat, weatherLon, weatherPlace}` áp ngay;
`/api/state` → `weather_configured`, `weather`. Trang web thiết bị dùng `https://geocoding-api.open-meteo.com/v1/search`.

**Chữ:** tên mục (vd "Vị trí thời tiết"), "Dùng vị trí hiện tại", ô tìm thành phố, xin quyền vị trí, lỗi.

**Dùng lại:** hàng cài đặt, sheet, ô tìm kiếm của app; ô màn thiết bị (cửa sổ Thời tiết hiện tên nơi ngay khi đặt).

**App đang có:** chưa có. Ô màn đã vẽ tên nơi khi thiết bị có `weatherPlace` (R-DK-14).
