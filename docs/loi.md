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

### L-5 · Claude: dự án glimmer kẹt mãi ở "Cần duyệt" từ phiên ở máy tính khác

- Trạng thái: chờ thử máy · Mức độ: khó chịu (bảng dự án báo sai, che trạng thái thật của phiên đang chạy) · Phần: bảng dự án màn Claude (`projects_core.h`, `attention.cpp`) · Quy tắc: "Project board" (`CLAUDE.md`)
- Báo: 2026-11-27 — "ở claude khi trạng thái của glimmer vẫn cứ mắc ở cần duyệt cái này là trạng thái ở lượt kết nối wifi với máy khác"
- Các bước: 1. Thiết bị chung Wi-Fi với máy tính A, Claude Code trong glimmer hỏi duyệt (PermissionRequest). 2. Máy A rời mạng / tắt trước khi gửi sự kiện tiếp theo của phiên đó. 3. Chuyển sang máy tính B, dùng Claude Code trong glimmer (hook có gửi). 4. Khởi động lại thiết bị.
- Mong đợi / thực tế: dòng glimmer theo phiên đang chạy ở máy B / mãi "Cần duyệt", qua cả khởi động lại.
- Bằng chứng: chưa có ảnh; người dùng xác nhận đã khởi động lại và đã dùng Claude Code ở máy B mà vẫn kẹt.

**Sửa**
- Nguyên nhân: bảng dự án giữ một mục cho mỗi **phiên** (dự án + agent + session id); mỗi dự án hiện một dòng = phiên khẩn nhất. `Projects::shown()` giữ `P_APPROVAL` / `P_INPUT` **vô hạn** ("tới khi trả lời") — chỉ sự kiện của chính phiên đó mới đổi được. Phiên ở máy A không bao giờ gửi nữa → mục "Cần duyệt" sống mãi, và vì khẩn hơn `P_WORKING` / `P_DONE` của phiên máy B nên che dòng glimmer. Bảng lưu vào `/projects.bin` nên khởi động lại không xoá.
- Hành vi (bạn chốt 2026-11-27): một phiên đang chờ (Cần duyệt / Chờ bạn) **nhường** khi một phiên khác cùng dự án + cùng agent có sự kiện muộn hơn lần cuối của nó ≥ 10 phút (`kSupersedeS`); và **hết hạn** khi ≥ 2 giờ không có sự kiện nào của nó (`kWaitS`). Agent khác (Codex) cùng repo không làm Claude nhường.
- Test: `test/test_logic` `test_projects_stale_wait_released` — `(L-5)`: đỏ trước khi sửa (vẫn `P_APPROVAL`), xanh sau; `pio test` 64/64.
- Code: `src/data/projects_core.h` — `waiting()`, `superseded()`, `visible()`; `shown()` hết hạn chờ sau `kWaitS`; `ordered()` dùng `visible()`. Màn Claude đã vẽ lại bảng mỗi phút nên dòng tự đổi. RAM không đổi (44 828 B).
- Thử máy: nạp firmware (giữ filesystem, `/projects.bin` còn mục cũ) → mở cửa sổ Claude: mục "Cần duyệt" cũ (> 2 giờ không sự kiện) biến mất ngay; hoặc dùng Claude Code trong glimmer ở máy này ~10 phút → dòng glimmer theo phiên này (Đang chạy / Xong). Còn kẹt → gửi `/api/state` (mảng `projects`).
- Commit: `e17fb1f`. Đã nạp lên máy 2026-11-27 (kèm filesystem): dòng glimmer theo phiên máy này ("working").

**Lịch sử**
- 2026-11-27: ghi + tìm nguyên nhân; bạn chốt "phiên mới hơn thắng + hết hạn 2 giờ"; sửa, test xanh, chờ thử máy.

### L-9 · Menu Start mở: di chuột trên thiết bị rất lag

- Trạng thái: chờ thử máy · Mức độ: khó chịu (con trỏ bò, khó chọn mục) · Phần: con trỏ + menu Start (`main.cpp` `repaintRect`, `xp_start.cpp`) · Quy tắc: "Mouse, keyboard, power" (`CLAUDE.md`, repaint-safe `draw()`)
- Báo: 2026-11-28 — "Hiện nay khi mở phần start trên phần cứng và di chuyển con chuột thì rất lag"
- Các bước: 1. Mở menu Start từ app. 2. Rê chuột trên bàn rê.
- Mong đợi / thực tế: con trỏ đi mượt như trên cửa sổ / bò, giật.
- Bằng chứng: chưa có (đo được bằng `/api/state` `cursor.repaint_ms` / `repaint_max`).

**Sửa**
- Nguyên nhân: mỗi lần con trỏ nhích, `repaintRect()` vẽ lại cả cửa sổ dưới menu (dù menu Start che kín y 0–213) rồi `XPStart::draw()` vẽ **toàn bộ** menu, không chặn theo vùng clip (`clipHits`). Font của sprite nạp lại mỗi lần vẽ lại, và menu đổi qua lại JBMono-16B / 12B / 11 khoảng 10 lần, mỗi lần ~30 ms → vài trăm ms mỗi bước chuột.
- Test: không khoá được bằng test native (thời gian vẽ trên panel thật).
- Code: `src/main.cpp` `repaintRect` — menu Start mở và hộp ở trên thanh tác vụ → không vẽ cửa sổ bên dưới; `src/channels/xp_start.cpp` — chặn `clipHits` cho dải người dùng, từng dòng, dải dưới, menu con, từng chữ (`text()`). RAM không đổi (45 688 B).
- Thử máy: nạp firmware → mở Start, rê chuột qua lại hai cột và All Programs: con trỏ đi mượt, dòng sáng đúng. Còn lag → gửi `/api/state` (`cursor.repaint_ms`, `repaint_max`).
- Commit: `ed56e00`. Đã nạp lên máy 2026-11-28.

**Lịch sử**
- 2026-11-28: ghi + sửa, chờ thử máy.

### L-10 · Sau khi nạp firmware, cửa sổ Claude không còn thấy các project đang chạy

- Trạng thái: chờ thử máy · Mức độ: khó chịu (bảng dự án trống, thẻ duyệt không tới) · Phần: hook agent → thiết bị (`tools/agents/`, mDNS firmware) · Quy tắc: "Project board" (`CLAUDE.md`)
- Báo: 2026-11-28 — "sau lần nạp firmware gần nhất thì vào claude lại không thấy các project đang chạy"
- Các bước: 1. Hai thiết bị glimmer cùng một mạng (.40 bản mới, .64 bản 0.22.0). 2. Nạp firmware cho .40 (nó khởi động lại). 3. Dùng Claude Code.
- Mong đợi / thực tế: bảng dự án trên .40 hiện glimmer Đang chạy / `projects` trống; sự kiện hook sang .64.
- Bằng chứng: `/api/state` .40 `projects: []`; `glimmer.local` → 192.168.100.64 (fw 0.22.0); `~/.glimmer/cache.json` `{"glimmer.local":"192.168.100.64"}`.

**Sửa**
- Nguyên nhân: mọi thiết bị đều tự xưng `glimmer.local`. Hai máy cùng mạng → tên trỏ vào máy nào trả lời trước; hook nhớ IP đó (`cache.json`) và gửi mãi sang máy cũ.
- Hành vi (bạn chốt 2026-11-28, "tên riêng tự sinh"): mỗi thiết bị một tên `glimmer-<2 byte cuối MAC>.local`; bộ cài hook tự dò thiết bị trên mạng và ghi tên riêng đó; hook bỏ IP đã nhớ nếu máy trả lời xưng tên khác.
- Test: không khoá bằng test native (mạng thật); đã thử `node tools/agents/discover.mjs` (1,7 s, thấy .40) và gửi sự kiện thẳng tới .40 (bảng hiện glimmer Đang chạy).
- Code: firmware `src/core/host.h` `deviceHost()` (mDNS, hostname Wi-Fi, chữ trên màn), `/api/state` `host`, `/hook` header `X-Glimmer-Host`; `chrome.cpp` dải khoá lỗi dùng IP khi tên không vừa. Máy tính: `tools/agents/discover.mjs` (dò HTTP cả /24 — tường lửa Windows chặn trả lời mDNS cho Node), `install.mjs` ghi tên riêng, `glimmer-hook.mjs` kiểm `X-Glimmer-Host`, `glimmer-setup.mjs` chờ thiết bị theo tên riêng. `tools/screens.py` vẽ `glimmer-1a2b.local`.
- Tạm thời (trước khi nạp): `~/.glimmer/config.json` `url` = `http://192.168.100.40`.
- Thử máy: nạp firmware → `node tools/agents/install.mjs` → `~/.glimmer/config.json` có `http://glimmer-xxxx.local` → dùng Claude Code: cửa sổ Claude hiện glimmer Đang chạy. Bật cả máy .64: vẫn đúng.
- Commit: `49cfb74`. Đã nạp 2026-11-28: máy .40 = `glimmer-5769`, `install.mjs` ghi `http://glimmer-5769.local`, hook tới đúng máy (bảng: glimmer Đang chạy). Còn thử: bật lại máy .64 cùng lúc.

**Lịch sử**
- 2026-11-28: ghi; tạm trỏ hook vào IP; bạn chọn tên riêng tự sinh; sửa.

### L-12 · Di chuột trên thiết bị chậm, lag (mọi màn)

- Trạng thái: chờ thử máy · Mức độ: khó chịu (con trỏ bò) · Phần: firmware `display.cpp` (`beginRepaint` / `endRepaint`, sprite của L-8), `cursor.cpp` · Quy tắc: "Mouse, keyboard, power" (`CLAUDE.md`, repaint-safe `draw()`)
- Báo: 2026-11-28 — "sau bản cập nhật đột nhiên tôi cảm thấy lag hơn khi di chuột thì con chuột rất lag và chậm"
- Các bước: 1. Firmware a421d95 (đợt 4). 2. Rê chuột trên desktop hoặc một cửa sổ (Thời tiết).
- Mong đợi / thực tế: con trỏ đi mượt (đo được trước đây: Home ~8 ms mỗi bước) / `cursor.repaint_ms` **~200 ms mỗi bước ở mọi chỗ** (desktop, thanh tác vụ, cửa sổ Thời tiết) — con trỏ chỉ nhích ~5 lần / giây.
- Bằng chứng: đo bằng gói chuột UDP + `/api/state`: Home 200–205 ms ở 10 điểm, Weather 193–196 ms; heap 20,7 KB, khối lớn 10–18 KB.

**Sửa**
- Nguyên nhân: từ L-8, mỗi bước chuột vẽ lại ô dưới con trỏ vào một sprite **tạo mới rồi xoá** — font VLW nạp vào sprite (font của TFT_eSPI theo từng đối tượng) bị nạp lại từ flash ở **mọi** bước, kể cả chỗ không có chữ (desktop đo nhãn biểu tượng trước khi chặn clip). Nạp một font giờ tốn cỡ trăm ms (231 glyph tiếng Việt, heap phân mảnh).
- Code: `display.cpp` giữ **một** đối tượng sprite cho mọi lần vẽ lại, chỉ bộ đệm điểm ảnh tạo / xoá (`deleteSprite` không gỡ font) → font của sprite nạp một lần, dùng lại; `releaseFont()` (trước mỗi TLS, cổng heap L-4) trả luôn font của sprite.
- Test: không khoá được bằng test native (thời gian trên panel thật); đo lại `cursor.repaint_ms` sau khi nạp.
- Thử máy: rê chuột trên desktop, thanh tác vụ, một cửa sổ có chữ: đi mượt; `/api/state` `cursor.repaint_ms` vài chục ms trở xuống; `heap_refusals` không tăng bất thường.
- Lần 2 (bạn báo 2026-11-29: "các màn start, claude, thiết bị vẫn lag"): đo Start 116–349 ms, Claude 120–176 ms, Máy tính 55–124 ms — các màn này dùng 2–3 font trong cùng một ô (JBMono-11 / 12B / 16B, VT323), sprite giữ được một font nên mỗi lần đổi font lại nạp. Gốc: `loadFont()` của TFT_eSPI đọc bảng số đo glyph **từng byte** (~6 500 lần đọc LittleFS mỗi font). Sửa: `display.cpp` `fastLoadFont()` điền đúng các trường công khai của TFT_eSPI (cùng `malloc`, `unloadFont()` vẫn giải phóng), đọc bảng 8 glyph (224 B) một lần; thư viện gốc làm dự phòng. Không thêm heap, RAM tĩnh không đổi.

**Lịch sử**
- 2026-11-29: lần 2 — font nạp nhanh (đọc theo khối), nạp. Đo lại: Start 116–349 → **3–45 ms**, Claude 120–176 → **3–31 ms**, Máy tính 55–124 → **43–48 ms**; heap như trước (17,1 KB).
- 2026-11-28: ghi, đo, sửa, nạp. Đo lại bằng gói chuột UDP: Home **18–21 ms** mỗi bước (lần đầu 126 ms: nạp font một lần); heap thường trực 20,6 → 17,2 KB (font của sprite, trả lại trước TLS).

## Đã xong

### L-11 · Đóng hộp Tắt máy tính: thanh tác vụ còn vệt đen, chuột đi qua đâu mới sạch đến đấy

- Trạng thái: xong · Mức độ: khó chịu · Phần: firmware `main.cpp` `mainSetMenu` / `mainSetScreenOn`, `xp_turnoff` · Quy tắc: "Tắt máy tính" (`CLAUDE.md` Mouse, keyboard, power)
- Báo: 2026-11-28 — "sau khi vào cửa sổ phần lựa chọn tắt nguồn và tắt ra thì ở thanh công cụ bị ám màu đen, di chuyển chuột qua đến đâu thì các vệt màu hết đến đấy"
- Các bước: 1. Mở hộp Tắt máy tính (Start › Tắt máy, hoặc Alt+F4 ở desktop). 2. Hủy / Esc (hoặc Chờ).
- Mong đợi / thực tế: màn và thanh tác vụ như trước khi mở hộp / thanh tác vụ còn lớp chấm tối của hộp; con trỏ vẽ lại ô dưới nó nên vệt tối mất dần theo đường chuột.

**Sửa**
- Nguyên nhân: lớp chấm tối của hộp phủ cả 240×240, kể cả thanh tác vụ; đóng hộp thì `drawActive()` coi thanh tác vụ vẫn còn nguyên và chỉ vẽ lại nút đổi (`Taskbar::update`). Có từ khi có hộp (P-2026-11-27.24), cả khi app điều khiển.
- Test: `test_turnoff_shade_redraws_taskbar` (`XPCore::shadesTaskbar`) — native.
- Code: `xp_core.h` `shadesTaskbar()`; `main.cpp` `mainSetMenu` vẽ lại cả thanh tác vụ (`Taskbar::draw`) khi hộp đóng / thay bằng menu khác; `mainSetScreenOn` (Chờ) cũng vậy.
- Thử máy: mở hộp Tắt máy tính → Hủy: thanh tác vụ sạch ngay, không cần rê chuột. Thử cả Esc và Chờ (bật màn lại).

**Lịch sử**
- 2026-11-28: ghi, sửa (95/95 native), đã nạp; bạn thử 2026-11-28: ổn.

### L-8 · Di chuột trên cửa sổ Ảnh, Thời tiết...: chỗ con trỏ hiện ô trắng tạm thời

- Trạng thái: xong · Mức độ: khó chịu (không thấy rõ con trỏ ở các cửa sổ đó; vẫn dùng được) · Phần: con trỏ chuột
  (`cursor.cpp`, `repaintRect` của `main.cpp`, `display.cpp`) · Quy tắc: Mouse, keyboard, power (`CLAUDE.md`, R-DK-17)
- Báo: 2026-11-27 — "khi di chuyển con chuột ở 1 số tab như ảnh, thời tiết, ... đang bị hiện ô trắng thay cho con
  chuột"; hỏi thêm: "Nó chỉ là ô trắng tạm thời ở vị trí con trỏ"
- Các bước: 1. Firmware 46a1450 (P-2026-11-27.24), app ở chế độ chuột. 2. Mở cửa sổ Ảnh hoặc Thời tiết. 3. Rê con trỏ.
- Mong đợi / thực tế: con trỏ mũi tên đi theo, nền dưới nó giữ nguyên / chỗ con trỏ chớp ô trắng (nền) trong lúc đi.
- Bằng chứng: `/api/state` `cursor.repaint_ms` 65, `repaint_max` 271 ms; chưa có ảnh.

**Sửa**
- Nguyên nhân: màn không đọc lại được điểm ảnh, nên dời con trỏ = vẽ lại ô cũ (`repaintRect`) thẳng lên màn: tô nền
  trước (trang trắng của Thời tiết, thân cửa sổ của Ảnh) rồi mới nạp font (~30 ms mỗi font) / giải mã JPEG (tới 271 ms)
  để vẽ chữ / ảnh → trong lúc đó ô nền lộ ra ngay chỗ con trỏ.
- Test: chưa khoá được bằng test (kết xuất lên màn thật; host test không có TFT). Build + `pio test -e native` 71/71.
- Code: `src/core/display.{h,cpp}` — vẽ lại dưới con trỏ vào sprite cỡ ô cắt (tạo khi vẽ lại, ~1 KB + đối tượng
  ~0,4 KB, xoá ngay sau), đẩy lên màn một lần; `tft` thành `(*g_tft)` (panel hoặc sprite), font của sprite riêng
  (font của màn giữ nguyên); `Display::pushImage` cho JPEG (`photos.cpp`, `wallpaper.cpp`). Không đủ heap tạo sprite
  → vẽ thẳng như cũ. RAM tĩnh +24 B.
- Thử máy: nạp firmware, rút điện cắm lại; mở Ảnh, rồi Thời tiết, rê con trỏ nhanh / chậm qua chữ và ảnh: không còn
  ô trắng, chỗ cũ trở lại đúng nền / chữ / ảnh. Con trỏ có thể đi hơi trễ ở Ảnh (giải mã JPEG). Còn lỗi → quay video
  màn thiết bị + gửi `/api/state` `cursor`.
- Commit: 3f4ec11

**Lịch sử**
- 2026-11-27: ghi lỗi.
- 2026-11-27: sửa, chờ thử máy.
- 2026-11-27: thử máy (192.168.10.51) đạt → xong.

