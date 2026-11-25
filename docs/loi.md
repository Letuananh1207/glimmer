# Sổ lỗi — firmware (màn thiết bị)

Lỗi của firmware / màn 240×240. Lỗi của app Android ở `app/docs/loi.md`. Cùng mẫu với `/loi`
(`.claude/skills/loi/SKILL.md`); với firmware: test là host test `test/` (`pio test -e native`), code là `src/`, thử máy
là nạp OTA rồi nhìn màn.

Trạng thái: `mới` → `đang sửa` → `chờ thử máy` → `xong` · `không sửa (<lý do>)`.
Mức độ: `chặn dùng` · `khó chịu` · `nhỏ` (chữ, giao diện).

## Đang mở

### L-1 · Home: chữ số phút và cột thời tiết xoá mất chữ của nhau

- Trạng thái: mới · Mức độ: khó chịu (chữ thời tiết / phút bị cắt mất cho tới lần vẽ lại cả màn) · Phần: kênh Home · Quy tắc: PARTIAL REDRAW DISCIPLINE (`CLAUDE.md`)
- Báo: 2026-11-25 — tìm thấy khi `/panel-apply` kiểm bản đầu `P-2026-11-25.1`
- Các bước: 1. Kênh Home đang hiện, có thời tiết. 2. Chờ sang phút mới, hoặc nhiệt độ đổi.
- Mong đợi / thực tế: mỗi vùng chỉ xoá dải của nó / `paintMM` xoá x 110–178, y 6–92 (`src/channels/ch_home.cpp:85`) → mất đầu trái `c.giác`, mô tả thời tiết; `paintWeatherTemp` / `Feels` xoá từ x 154 (`ch_home.cpp:98,113`) → cắt phần phải chữ số phút.
- Bằng chứng: đọc code; chưa có ảnh máy thật.
- Chờ: phiếu `docs/phieu_panel/2026-11-25-ve-lai-dung-luat-khung.md` (bố cục Home mới) — sửa cùng lúc khi áp.

### L-2 · Home: chân trang xoá mất đầu địa chỉ IP

- Trạng thái: mới · Mức độ: nhỏ (mất ~6 px đầu IP dài tới lần vẽ lại cả màn) · Phần: kênh Home · Quy tắc: PARTIAL REDRAW DISCIPLINE
- Báo: 2026-11-25 — tìm thấy khi kiểm bản đầu
- Các bước: 1. Home, IP dài (vd `192.168.100.40`). 2. Chân trang trái đổi chữ.
- Mong đợi / thực tế: IP còn nguyên / `paintFooterLeft` xoá tới x 138 (`ch_home.cpp:258`), IP bắt đầu x 132, `tick()` không vẽ lại IP.
- Bằng chứng: đọc code.
- Chờ: cùng phiếu vẽ lại Home.

### L-3 · Thời tiết: mã lạ in `—` nhưng font không có ký tự này

- Trạng thái: mới · Mức độ: nhỏ (mô tả thời tiết trống) · Phần: thời tiết (Home, Weather, Forecast)
- Báo: 2026-11-25 — tìm thấy khi kiểm bản đầu
- Các bước: 1. Open-Meteo trả `weather_code` không có trong bảng.
- Mong đợi / thực tế: hiện `--` (hoặc chữ tiếng Việt) / `src/data/weather.cpp:197` trả `—` (U+2014), không có trong bộ glyph VLW → trống.
- Bằng chứng: đọc code + danh sách glyph (`CLAUDE.md` mục VLW).

## Đã xong

_(chưa có)_
