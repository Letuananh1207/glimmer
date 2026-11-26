# Sổ lỗi — firmware (màn thiết bị)

Lỗi của firmware / màn 240×240. Lỗi của app Android ở `app/docs/loi.md`. Cùng mẫu với `/loi`
(`.claude/skills/loi/SKILL.md`); với firmware: test là host test `test/` (`pio test -e native`), code là `src/`, thử máy
là nạp OTA rồi nhìn màn.

Trạng thái: `mới` → `đang sửa` → `chờ thử máy` → `xong` · `không sửa (<lý do>)`.
Mức độ: `chặn dùng` · `khó chịu` · `nhỏ` (chữ, giao diện).

## Đang mở

### L-1 · Home: chữ số phút và cột thời tiết xoá mất chữ của nhau

- Trạng thái: chờ thử máy · Mức độ: khó chịu (chữ thời tiết / phút bị cắt mất cho tới lần vẽ lại cả màn) · Phần: kênh Home · Quy tắc: PARTIAL REDRAW DISCIPLINE (`CLAUDE.md`)
- Báo: 2026-11-25 — tìm thấy khi `/panel-apply` kiểm bản đầu `P-2026-11-25.1`
- Các bước: 1. Kênh Home đang hiện, có thời tiết. 2. Chờ sang phút mới, hoặc nhiệt độ đổi.
- Mong đợi / thực tế: mỗi vùng chỉ xoá dải của nó / `paintMM` xoá x 110–178, y 6–92 (`src/channels/ch_home.cpp:85`) → mất đầu trái `c.giác`, mô tả thời tiết; `paintWeatherTemp` / `Feels` xoá từ x 154 (`ch_home.cpp:98,113`) → cắt phần phải chữ số phút.
- Bằng chứng: đọc code; chưa có ảnh máy thật.
- Chờ: phiếu `docs/phieu_panel/2026-11-25-ve-lai-dung-luat-khung.md` (bố cục Home mới) — sửa cùng lúc khi áp.

**Sửa**
- Nguyên nhân: giờ (VT323-86 tới x 178) và cột thời tiết (từ x 154) dùng chung dải ngang, mỗi bên xoá dải của mình đè lên bên kia.
- Code: `src/channels/ch_home.cpp` viết lại theo P-2026-11-25.4 — giờ x 12–181, biểu tượng thời tiết (194, 40), nhiệt độ lên status bar; mỗi vùng một dải xoá riêng không chạm nhau.
- Thử máy: để kênh Home chạy qua một lần đổi phút và một lần thời tiết cập nhật — chữ số phút, biểu tượng, `c.giác` còn nguyên.

### L-2 · Home: chân trang xoá mất đầu địa chỉ IP

- Trạng thái: chờ thử máy · Mức độ: nhỏ (mất ~6 px đầu IP dài tới lần vẽ lại cả màn) · Phần: kênh Home · Quy tắc: PARTIAL REDRAW DISCIPLINE
- Báo: 2026-11-25 — tìm thấy khi kiểm bản đầu
- Các bước: 1. Home, IP dài (vd `192.168.100.40`). 2. Chân trang trái đổi chữ.
- Mong đợi / thực tế: IP còn nguyên / `paintFooterLeft` xoá tới x 138 (`ch_home.cpp:258`), IP bắt đầu x 132, `tick()` không vẽ lại IP.
- Bằng chứng: đọc code.
- Chờ: cùng phiếu vẽ lại Home.

**Sửa**
- Code: `ch_home.cpp` — chân trái xoá x 0–117 (IP dài nhất bắt đầu x 123), chữ viết tắt `CL …` / `CX …` ≤ 91 px.
- Thử máy: khoá Claude lỗi → chân trang `CL BỊ TỪ CHỐI`, IP còn nguyên.

### L-3 · Thời tiết: mã lạ in `—` nhưng font không có ký tự này

- Trạng thái: chờ thử máy · Mức độ: nhỏ (mô tả thời tiết trống) · Phần: thời tiết (Home, Weather, Forecast)
- Báo: 2026-11-25 — tìm thấy khi kiểm bản đầu
- Các bước: 1. Open-Meteo trả `weather_code` không có trong bảng.
- Mong đợi / thực tế: hiện `--` (hoặc chữ tiếng Việt) / `src/data/weather.cpp:197` trả `—` (U+2014), không có trong bộ glyph VLW → trống.
- Bằng chứng: đọc code + danh sách glyph (`CLAUDE.md` mục VLW).

**Sửa**
- Code: `src/data/weather.cpp` `describe()` trả `--`.
- Thử máy: khó tái hiện (cần mã WMO lạ) — đóng khi build sạch là đủ.

### L-4 · Claude: cứ ở màn "Đang tải...", không bao giờ có số liệu

- Trạng thái: chờ thử máy · Mức độ: chặn dùng (màn Claude — chức năng chính — không hiện số liệu) · Phần: kênh Claude, bộ lập lịch tải (cổng heap) · Quy tắc: "Fetch scheduler & heap gate" (`CLAUDE.md`)
- Báo: 2026-11-26 — "bây giờ màn claude đang bị lỗi khi cứ ở trạng thái đang tải"
- Các bước: 1. Nạp firmware P-2026-11-26.16 (build 21:43) qua OTA. 2. Mở cửa sổ Claude.
- Mong đợi / thực tế: sau vài giây có % mức dùng / mãi hộp tải về XP, không lỗi, không số.
- Bằng chứng: `/api/state` lúc uptime 217 s — `claude_valid false`, `claude_http 0` (chưa gửi được lần nào), `cred checking`, `heap_refusals 41`, `maxblk 19096` (< `Api::kTlsFloor` 20 000), `min_maxblk 17248`, `heap 24504`, `reset_reason "Software/System restart"` (chưa rút điện từ lần nạp). Lần trước nạp P-.15 máy chạy với `maxblk 24096`.

**Sửa**
- Nguyên nhân: sau khi nạp OTA máy tự khởi động lại bằng phần mềm (`reset_reason "Software/System restart"`) → khối heap liền lớn nhất chỉ 19 096 (< `Api::kTlsFloor` 20 000), đứng yên ở mọi màn (Claude, Đồng hồ, Thông tin, desktop) → cổng heap từ chối mọi lần tải TLS, không lỗi nào để báo nên màn đứng ở "Đang tải". Không phải màn Claude / hộp tải về P-.16 tốn heap lúc chạy. Rút điện cắm lại → `maxblk` 20 624, tải được ngay.
- Còn lại: khoảng dư rất mỏng — sau khi rút điện chỉ hơn ngưỡng 624 B (bản 0.23 lúc đầu: 24 096; RAM tĩnh đã tăng 44 860 → 46 740 qua các đợt skill / ảnh / XP). Một thay đổi nhỏ nữa, hoặc một lần nạp không rút điện, là lỗi quay lại.
- Thử máy: đã thử — rút điện cắm lại, Claude có số (`claude_http 200`, `cred ok`).
- Hướng sửa (bạn chọn 2026-11-26: lấy lại khoảng dư trước): chuỗi đang nằm RAM (`.rodata`) chuyển sang flash — khoá / giá trị JSON `d[F("…")] = F("…")` (`web.cpp` 289 khoá + 26 giá trị, `storage.cpp` 89, `weather.cpp` 51), câu trả lời `server.send_P(…, PSTR(…), PSTR(…))` (36), header `addHeader(F(…), F(…))` và URL claude.ai / chatgpt.com (`api.cpp`, `vendor_status.cpp`). Không đổi hành vi, không đổi API.
- Code: RAM tĩnh 46 740 → 44 624 B (−2 116). `CLAUDE.md` ghi luật chuỗi trong flash.
- Test: chưa khoá được bằng host test (heap phân mảnh chỉ đo được trên máy); `pio test` 59/59, build OK.
- Thử máy lần 2 (chỉ chuỗi sang flash + bỏ `String` tĩnh của org): **chưa đạt** — không rút điện, `maxblk` 19 304 ngay lúc khởi động, 131 lần từ chối, không tải được lần nào. Gốc không phải thiếu RAM tĩnh.
- Nguyên nhân thật: cổng heap `maxblk ≥ 20 000` quá chặt. TLS dùng bộ đệm 4 K / 1 K, lần cấp phát lớn nhất ~6 KB; khởi động mềm chia heap thành khối 15–19 KB (tổng trống ~23,5 K) → cổng chặn mãi dù tải được. Thử nghiệm ngưỡng 12 000: 3 lần tải liền đều 200, heap tự gom lại (`maxblk` 24–25 K).
- Sửa (bạn chốt 2026-11-26): cổng mới `FetchPolicy::tlsHeapOk` — khối lớn nhất ≥ 12 000 **và** heap trống ≥ 20 000 (`fetch_policy.h`, `main.cpp`, `CLAUDE.md`). Giữ thêm: chuỗi sang flash (−2 116 B RAM tĩnh), mã org trong `char[40]` + băm khoá thay `String` tĩnh (`api.cpp`).
- Test: `test/test_logic` `test_tls_heap_gate` (số đo trên máy) — `pio test` 60/60.
- Thử máy lần 3 (Claude Code thử trên máy thật, không rút điện): khởi động mềm → lần tải đầu 200 ngay, lần sau 5 phút 200, `heap_refusals 0`, cài đặt đủ 42 khoá. Chờ bạn dùng thử: sau lần nạp OTA tới, không rút điện, màn Claude có số trong ~1 phút.

**Lịch sử**
- 2026-11-26: ghi từ báo của người dùng + đọc `/api/state`.
- 2026-11-26: đo `maxblk` ở 4 màn = 19 096 cả 4 (phân mảnh từ lúc khởi động). Người dùng rút điện cắm lại → vào được, `maxblk` 20 624.
- 2026-11-26: thử 2 chưa đạt; thử nghiệm ngưỡng 12 000 đạt; bạn chốt cổng mới; thử 3 đạt trên máy.

## Đã xong

_(chưa có)_
