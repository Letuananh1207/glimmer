# Đặc tả màn thiết bị glimmer (240×240)

Tọa độ px panel thật (x, y, w×h); datum căn chữ theo TFT_eSPI (TL / TC / TR / MC / MR — điểm neo là (x, y)).
Font là file VLW trong `data/fonts/`; màu là tên token trong `tokens/panel_tokens.json` (`CLAWD` = #D97757).
Cột **px** = độ rộng chữ đo bằng font VLW thật. Số liệu mẫu (38 %, 14:32, 29°…) chỉ để minh hoạ.
Vùng: status y 0–21 · gạch nhấn y 22 · nội dung y 24–219 · trống y 220–229 · vạch chỉ báo y 230 (2 px).
Chữ trên màn là tiếng Việt: thời lượng `P` phút · `G` giờ · `NG` ngày (`2G 14P`, `3NG`, `CŨ 14P`); 12 giờ `SA` / `CH`; thứ `T2`…`T7`, `CN`.

## 1. Attention — kênh `Attention`

> **P-2026-11-25.4 — Khớp máy, Việt hoá, đúng luật khung:** đơn vị tiếng Việt ở dòng chờ (`chờ bạn · 2P`, dưới 1 phút `45 giây`).

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

> **P-2026-11-25.5 — Clawd vui mới:** thẻ `Attention-Done` dùng mắt `happy` mới: lấp kín lỗ mắt cũ rồi khoét theo **nửa ô** (ô 4 px → lỗ 2×2 px; ô 5 px → lỗ 2×2 px, vị trí `x + hx·ô/2` làm tròn xuống) — mỗi mắt `^` (đỉnh nửa-ô (10, 5) / (25, 5), chân (9, 6) (11, 6) / (24, 6) (26, 6)), miệng cười `‿` (16, 9) (19, 9) (17, 10) (18, 10); lưới nửa ô 36×20. Badge, tia sáng, chữ giữ nguyên.

Thẻ toàn màn cho agent (duyệt / câu hỏi / xong / tiến độ / lỗi).

- Không có status bar: nền đen từ y 0, dòng `AGENT · project` ở y 30.
- Clawd 18×10 ô, ô 5 px → 90×50 tại (75, 62); huy hiệu 7×7 ô 3 px (21×21) tại (165, 56); thẻ Codex tô Clawd LILAC.
- Chuyển động trong `tick()`: chờ bạn → chớp mắt 150 ms mỗi 4 s; tiến độ → bước chân mỗi 400 ms. Chỉ vẽ lại khung 90×50 của Clawd.
- Dòng `chờ bạn · 2P` (MUTED; dưới 1 phút `chờ bạn · 45 giây`) vẽ lại mỗi giây khi đổi; nhiều thẻ giữ màn → chấm hàng đợi 6×6 tại y 204 (thẻ đang hiện màu loại thẻ, còn lại LINE); thẻ kết quả một mình → vạch hết giờ 60 px tại (90, 206).
- Vạch y 230: vàng liền (duyệt) / xanh liền (câu hỏi) trên mọi màn khi agent chờ.

### Attention-Approval — Attention · cần duyệt

Nguồn `source/Attention-Approval.dc.html` · ảnh `screens/@2x/AttentionApproval.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 120, 30 | TC | `JBMono-11` | MUTED | `CLAUDE · glimmer` | 112 |
| 75, 62, 90×50 |  |  | CLAWD | Clawd (ô 5, mắt `wide`, chân `stand`) |  |
| 165, 56, 21×21 |  |  | AMBER | huy hiệu `!` |  |
| 120, 130 | TC | `JBMono-16B` | AMBER | `Cần duyệt` | 90 |
| 120, 156 | TC | `JBMono-11` | INK_DIM | `Bash · pio run -e nodemcuv2` | 189 |
| 120, 180 | TC | `JBMono-11` | MUTED | `chờ bạn · 2P` | 84 |
| 0, 230, 240×2 |  |  | AMBER | vạch chỉ báo (agent chờ) |  |

### Attention-Input — Attention · lượt bạn

Nguồn `source/Attention-Input.dc.html` · ảnh `screens/@2x/AttentionInput.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 120, 30 | TC | `JBMono-11` | MUTED | `CLAUDE · glimmer` | 112 |
| 75, 62, 90×50 |  |  | CLAWD | Clawd (ô 5, mắt `open`, chân `stand`) |  |
| 165, 56, 21×21 |  |  | SKY | huy hiệu `...` |  |
| 120, 130 | TC | `JBMono-16B` | SKY | `Lượt bạn` | 80 |
| 120, 156 | TC | `JBMono-11` | INK_DIM | `Claude đang chờ câu trả lời` | 189 |
| 120, 180 | TC | `JBMono-11` | MUTED | `chờ bạn · 45 giây` | 119 |
| 0, 230, 240×2 |  |  | SKY | vạch chỉ báo (agent chờ) |  |

### Attention-Done — Attention · xong

Nguồn `source/Attention-Done.dc.html` · ảnh `screens/@2x/AttentionDone.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 120, 30 | TC | `JBMono-11` | MUTED | `CLAUDE · glimmer` | 112 |
| 75, 62, 90×50 |  |  | CLAWD | Clawd (ô 5, mắt `happy`, chân `stand`) |  |
| 165, 56, 21×21 |  |  | MINT | huy hiệu `ok` |  |
| 63, 66 |  |  | MINT | lấp lánh `+` 10×10 |  |
| 179, 92 |  |  | MINT | lấp lánh `+` 10×10 |  |
| 120, 130 | TC | `JBMono-16B` | MINT | `Xong rồi!` | 90 |
| 120, 156 | TC | `JBMono-11` | INK_DIM | `Claude đã xong` | 98 |

### Attention-Progress — Attention · tiến độ

Nguồn `source/Attention-Progress.dc.html` · ảnh `screens/@2x/AttentionProgress.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 120, 30 | TC | `JBMono-11` | MUTED | `CLAUDE · api` | 84 |
| 75, 62, 90×50 |  |  | CLAWD | Clawd (ô 5, mắt `open`, chân `walk`) |  |
| 120, 130 | TC | `JBMono-16B` | LILAC | `tests 64%` | 90 |
| 40, 156, 160×6 |  |  | PANEL | khối |  |
| 40, 156, 102×6 |  |  | LILAC | khối |  |
| 120, 172 | TC | `JBMono-11` | INK_DIM | `main · 4 min` | 84 |

### Attention-Error — Attention · lỗi

Nguồn `source/Attention-Error.dc.html` · ảnh `screens/@2x/AttentionError.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 120, 30 | TC | `JBMono-11` | MUTED | `CLAUDE · glimmer` | 112 |
| 75, 62, 90×50 |  |  | CLAWD | Clawd (ô 5, mắt `sad`, chân `stand`) |  |
| 165, 56, 21×21 |  |  | CORAL | huy hiệu `x` |  |
| 120, 130 | TC | `JBMono-16B` | CORAL | `build failed` | 120 |
| 120, 156 | TC | `JBMono-11` | INK_DIM | `3 lỗi · ch_claude.cpp:120` | 175 |

## 2. Night — kênh `Night`

> **P-2026-11-26.17:** kiểu XP thật — xem §17 mục XP-Real.

> **P-2026-11-25.4 — Khớp máy, Việt hoá, đúng luật khung:** 12 giờ dùng `SA` / `CH`.

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Mặt đồng hồ ban đêm (`nightMode` 2) — không xoay vòng.

- Không status bar. Giờ VT323-86 căn giữa: HH INK_DIM, `:` MUTED, MM INK_DIM, y 64.
- `tick()`: phút đổi → vẽ lại MM; giờ đổi → vẽ lại HH và ngày.
- 12 giờ: ngày thêm `  SA` / `  CH` (thay `AM` / `PM`).

### Night — Night · mặt đồng hồ đêm

Nguồn `source/Night.dc.html` · ảnh `screens/@2x/Night.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 35, 64 | TL | `VT323-86` | INK_DIM | `23` | 68 |
| 103, 64 | TL | `VT323-86` | MUTED | `:` | 34 |
| 137, 64 | TL | `VT323-86` | INK_DIM | `47` | 68 |
| 120, 168 | TC | `JBMono-11` | MUTED | `THỨ TƯ 25/11` | 84 |

## 3. Setup — kênh `Setup`

> **P-2026-11-25.4 — Khớp máy, Việt hoá, đúng luật khung:** vạch y 230 MUTED.

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Setup-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Danh sách cài đặt lần đầu — chỉ hiện khi chưa có khóa Claude lẫn token Codex.

- Ô đánh dấu 11×11 (LINE / MINT), xong thì tô ô 5×5 MINT bên trong.
- Màn tĩnh, không có `tick()`.
- Vạch y 230: MUTED.

### Setup — Setup · chưa có khóa

Nguồn `source/Setup.dc.html` · ảnh `screens/@2x/Setup.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn AMBER | Status bar `glimmer` · meta `CÀI ĐẶT` (AMBER, 49 px); gạch nhấn y 22 | 49 |
| 120, 40 | MC | `JBMono-12B` | AMBER | `HOÀN TẤT CÀI ĐẶT` | 112 |
| 24, 63, 11×11 |  |  | LINE | viền 1 px |  |
| 44, 62 | TL | `JBMono-11` | INK | `Khóa Claude` | 77 |
| 224, 62 | TR | `JBMono-11` | MUTED | `Tài khoản` | 63 |
| 24, 85, 11×11 |  |  | LINE | viền 1 px |  |
| 44, 84 | TL | `JBMono-11` | INK | `Token Codex` | 77 |
| 224, 84 | TR | `JBMono-11` | MUTED | `Tài khoản` | 63 |
| 24, 107, 11×11 |  |  | MINT | viền 1 px |  |
| 27, 110, 5×5 |  |  | MINT | khối |  |
| 44, 106 | TL | `JBMono-11` | INK_DIM | `Thời tiết` | 63 |
| 224, 106 | TR | `JBMono-11` | MUTED | `Vị trí & giờ` | 84 |
| 30, 140, w 180 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 120, 158 | MC | `JBMono-11` | MUTED | `mở trong trình duyệt` | 140 |
| 120, 180 | MC | `JBMono-16B` | SKY | `glimmer.local` | 130 |
| 120, 202 | MC | `JBMono-11` | MUTED | `192.168.100.40` | 98 |
| 0, 230, 240×2 |  |  | MUTED / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

## 4. Home — kênh `Home`

> **P-2026-11-25.4 — Khớp máy, Việt hoá, đúng luật khung:** status bar `Trang chủ`; giờ và thời tiết tách vùng; chân trang `CL …` cách IP ≥ 20 px; thêm `Home-NoWeather`; `CÒN 9G`; chấm tải x 206 / 215 / 224.

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Home-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

"dấu hiệu sinh tồn": đồng hồ, thời tiết, hai đồng hồ đo AI, dải 24 giờ.

- Status bar `Trang chủ`, meta = thời tiết `29° Ít mây` (70 px; chưa có số → `--°`).
- Giờ VT323-86 x 12–182, y 30–100: HH INK, `:` CORAL, MM AMBER. Biểu tượng thời tiết ×2 (32×32) SKY tại (194, 40). Vùng giờ và vùng thời tiết không chạm nhau — mỗi vùng xoá riêng.
- Dòng ngày 12B INK_DIM (12, 104); `c.giác 33°` (chưa có: `c.giác --`) MUTED TR (228, 105).
- Đồng hồ đo y 128 / 146: thẻ 12B x 12; pixelBar (40, y+3, 150×7); giá trị TR x 228. Màu thanh theo phần **còn lại**, số là phần **đã dùng**. Khóa lỗi → ghi chú thay thanh; đang tải → 3 chấm 6×6 tại x 206 / 215 / 224, y+4.
- `HÔM NAY` y 170 + `CÒN 9G` TR; dải 24 giờ đáy y 198, x 12–227; giờ hiện tại CORAL cao 6 + ô AMBER 3×3.
- Chân trang y 204 — trái: thông báo theo ưu tiên, viết theo thẻ đồng hồ đo: `CL BỊ TỪ CHỐI` / `CL HẾT HẠN` / `CL BỊ CHẶN` (CORAL / AMBER), `CX CÒN 2NG` (AMBER), gợi ý mưa `MƯA 60% 16:00` / `MƯA 60% 4CH` (SKY); dài nhất 91 px. Phải: IP MUTED TR (228, 204), dài nhất `192.168.100.200` 105 px → khe ≥ 20 px. Không có gì → chỉ IP.
- `tick()`: MM / HH, thời tiết (đổi > 0,4° / đổi mã), đồng hồ đo (> 0,4 %), dải giờ (mỗi giờ), chân trang (mỗi phút).

### Home — Home · bình thường

Nguồn `source/Home.dc.html` · ảnh `screens/@2x/Home.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn AMBER | Status bar `Trang chủ` · meta `29° Ít mây` (MUTED, 70 px); gạch nhấn y 22 | 63 |
| 12, 30 | TL | `VT323-86` | INK | `14` | 68 |
| 80, 30 | TL | `VT323-86` | CORAL | `:` | 34 |
| 114, 30 | TL | `VT323-86` | AMBER | `32` | 68 |
| 194, 40, 32×32 |  |  | SKY | bitmap `PARTCLOUD` |  |
| 12, 104 | TL | `JBMono-12B` | INK_DIM | `THỨ TƯ 25/11` | 84 |
| 228, 105 | TR | `JBMono-11` | MUTED | `c.giác 33°` | 70 |
| 12, 122, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 128 | TL | `JBMono-12B` | CORAL | `CL` | 14 |
| 40, 131, 150×7 |  |  | MINT | `pixelBar` 9 ô, 38 % |  |
| 228, 128 | TR | `JBMono-11` | MINT | `38%` | 21 |
| 12, 146 | TL | `JBMono-12B` | LILAC | `CX` | 14 |
| 40, 149, 150×7 |  |  | AMBER | `pixelBar` 9 ô, 71 % |  |
| 228, 146 | TR | `JBMono-11` | AMBER | `71%` | 21 |
| 12, 166, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 170 | TL | `JBMono-12B` | MUTED | `HÔM NAY` | 49 |
| 228, 170 | TR | `JBMono-11` | INK_DIM | `CÒN 9G` | 42 |
| 12, 198, 216×1 |  |  | LINE | khối |  |
| 12, 195, 1×3 |  |  | INK_DIM | khối |  |
| 21, 196, 1×2 |  |  | LINE | khối |  |
| 30, 196, 1×2 |  |  | LINE | khối |  |
| 39, 196, 1×2 |  |  | LINE | khối |  |
| 48, 196, 1×2 |  |  | LINE | khối |  |
| 57, 196, 1×2 |  |  | LINE | khối |  |
| 66, 195, 1×3 |  |  | INK_DIM | khối |  |
| 75, 196, 1×2 |  |  | LINE | khối |  |
| 84, 196, 1×2 |  |  | LINE | khối |  |
| 93, 196, 1×2 |  |  | LINE | khối |  |
| 102, 196, 1×2 |  |  | LINE | khối |  |
| 111, 196, 1×2 |  |  | LINE | khối |  |
| 120, 195, 1×3 |  |  | INK_DIM | khối |  |
| 129, 196, 1×2 |  |  | LINE | khối |  |
| 138, 192, 1×6 |  |  | CORAL | khối |  |
| 147, 196, 1×2 |  |  | LINE | khối |  |
| 156, 196, 1×2 |  |  | LINE | khối |  |
| 165, 196, 1×2 |  |  | LINE | khối |  |
| 174, 195, 1×3 |  |  | INK_DIM | khối |  |
| 183, 196, 1×2 |  |  | LINE | khối |  |
| 192, 196, 1×2 |  |  | LINE | khối |  |
| 201, 196, 1×2 |  |  | LINE | khối |  |
| 210, 196, 1×2 |  |  | LINE | khối |  |
| 219, 196, 1×2 |  |  | LINE | khối |  |
| 137, 190, 3×3 |  |  | AMBER | khối |  |
| 228, 204 | TR | `JBMono-11` | MUTED | `192.168.100.200` | 105 |
| 0, 230, 240×2 |  |  | AMBER / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Home-KeyBad — Home · khóa Claude lỗi

Nguồn `source/Home-KeyBad.dc.html` · ảnh `screens/@2x/HomeKeyBad.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn AMBER | Status bar `Trang chủ` · meta `29° Ít mây` (MUTED, 70 px); gạch nhấn y 22 | 63 |
| 12, 30 | TL | `VT323-86` | INK | `14` | 68 |
| 80, 30 | TL | `VT323-86` | CORAL | `:` | 34 |
| 114, 30 | TL | `VT323-86` | AMBER | `32` | 68 |
| 194, 40, 32×32 |  |  | SKY | bitmap `PARTCLOUD` |  |
| 12, 104 | TL | `JBMono-12B` | INK_DIM | `THỨ TƯ 25/11` | 84 |
| 228, 105 | TR | `JBMono-11` | MUTED | `c.giác 33°` | 70 |
| 12, 122, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 128 | TL | `JBMono-12B` | CORAL | `CL` | 14 |
| 228, 128 | TR | `JBMono-11` | CORAL | `khóa bị từ chối · cập nhật` | 182 |
| 12, 146 | TL | `JBMono-12B` | LILAC | `CX` | 14 |
| 40, 149, 150×7 |  |  | AMBER | `pixelBar` 9 ô, 71 % |  |
| 228, 146 | TR | `JBMono-11` | AMBER | `71%` | 21 |
| 12, 166, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 170 | TL | `JBMono-12B` | MUTED | `HÔM NAY` | 49 |
| 228, 170 | TR | `JBMono-11` | INK_DIM | `CÒN 9G` | 42 |
| 12, 198, 216×1 |  |  | LINE | khối |  |
| 12, 195, 1×3 |  |  | INK_DIM | khối |  |
| 21, 196, 1×2 |  |  | LINE | khối |  |
| 30, 196, 1×2 |  |  | LINE | khối |  |
| 39, 196, 1×2 |  |  | LINE | khối |  |
| 48, 196, 1×2 |  |  | LINE | khối |  |
| 57, 196, 1×2 |  |  | LINE | khối |  |
| 66, 195, 1×3 |  |  | INK_DIM | khối |  |
| 75, 196, 1×2 |  |  | LINE | khối |  |
| 84, 196, 1×2 |  |  | LINE | khối |  |
| 93, 196, 1×2 |  |  | LINE | khối |  |
| 102, 196, 1×2 |  |  | LINE | khối |  |
| 111, 196, 1×2 |  |  | LINE | khối |  |
| 120, 195, 1×3 |  |  | INK_DIM | khối |  |
| 129, 196, 1×2 |  |  | LINE | khối |  |
| 138, 192, 1×6 |  |  | CORAL | khối |  |
| 147, 196, 1×2 |  |  | LINE | khối |  |
| 156, 196, 1×2 |  |  | LINE | khối |  |
| 165, 196, 1×2 |  |  | LINE | khối |  |
| 174, 195, 1×3 |  |  | INK_DIM | khối |  |
| 183, 196, 1×2 |  |  | LINE | khối |  |
| 192, 196, 1×2 |  |  | LINE | khối |  |
| 201, 196, 1×2 |  |  | LINE | khối |  |
| 210, 196, 1×2 |  |  | LINE | khối |  |
| 219, 196, 1×2 |  |  | LINE | khối |  |
| 137, 190, 3×3 |  |  | AMBER | khối |  |
| 12, 204 | TL | `JBMono-11` | CORAL | `CL BỊ TỪ CHỐI` | 91 |
| 228, 204 | TR | `JBMono-11` | MUTED | `192.168.100.200` | 105 |
| 0, 230, 240×2 |  |  | AMBER / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Home-NoWeather — Home · chưa có thời tiết

Nguồn `source/Home-NoWeather.dc.html` · ảnh `screens/@2x/HomeNoWeather.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn AMBER | Status bar `Trang chủ` · meta `--°` (MUTED, 21 px); gạch nhấn y 22 | 63 |
| 12, 30 | TL | `VT323-86` | INK | `14` | 68 |
| 80, 30 | TL | `VT323-86` | CORAL | `:` | 34 |
| 114, 30 | TL | `VT323-86` | AMBER | `32` | 68 |
| 12, 104 | TL | `JBMono-12B` | INK_DIM | `THỨ TƯ 25/11` | 84 |
| 228, 105 | TR | `JBMono-11` | MUTED | `c.giác --` | 63 |
| 12, 122, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 128 | TL | `JBMono-12B` | CORAL | `CL` | 14 |
| 40, 131, 150×7 |  |  | MINT | `pixelBar` 9 ô, 38 % |  |
| 228, 128 | TR | `JBMono-11` | MINT | `38%` | 21 |
| 12, 146 | TL | `JBMono-12B` | LILAC | `CX` | 14 |
| 40, 149, 150×7 |  |  | AMBER | `pixelBar` 9 ô, 71 % |  |
| 228, 146 | TR | `JBMono-11` | AMBER | `71%` | 21 |
| 12, 166, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 170 | TL | `JBMono-12B` | MUTED | `HÔM NAY` | 49 |
| 228, 170 | TR | `JBMono-11` | INK_DIM | `CÒN 9G` | 42 |
| 12, 198, 216×1 |  |  | LINE | khối |  |
| 12, 195, 1×3 |  |  | INK_DIM | khối |  |
| 21, 196, 1×2 |  |  | LINE | khối |  |
| 30, 196, 1×2 |  |  | LINE | khối |  |
| 39, 196, 1×2 |  |  | LINE | khối |  |
| 48, 196, 1×2 |  |  | LINE | khối |  |
| 57, 196, 1×2 |  |  | LINE | khối |  |
| 66, 195, 1×3 |  |  | INK_DIM | khối |  |
| 75, 196, 1×2 |  |  | LINE | khối |  |
| 84, 196, 1×2 |  |  | LINE | khối |  |
| 93, 196, 1×2 |  |  | LINE | khối |  |
| 102, 196, 1×2 |  |  | LINE | khối |  |
| 111, 196, 1×2 |  |  | LINE | khối |  |
| 120, 195, 1×3 |  |  | INK_DIM | khối |  |
| 129, 196, 1×2 |  |  | LINE | khối |  |
| 138, 192, 1×6 |  |  | CORAL | khối |  |
| 147, 196, 1×2 |  |  | LINE | khối |  |
| 156, 196, 1×2 |  |  | LINE | khối |  |
| 165, 196, 1×2 |  |  | LINE | khối |  |
| 174, 195, 1×3 |  |  | INK_DIM | khối |  |
| 183, 196, 1×2 |  |  | LINE | khối |  |
| 192, 196, 1×2 |  |  | LINE | khối |  |
| 201, 196, 1×2 |  |  | LINE | khối |  |
| 210, 196, 1×2 |  |  | LINE | khối |  |
| 219, 196, 1×2 |  |  | LINE | khối |  |
| 137, 190, 3×3 |  |  | AMBER | khối |  |
| 228, 204 | TR | `JBMono-11` | MUTED | `192.168.100.200` | 105 |
| 0, 230, 240×2 |  |  | AMBER / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

## 5. Agents — kênh `Agents`

> **P-2026-11-25.4 — Khớp máy, Việt hoá, đúng luật khung:** status bar `Tác tử`; vạch MUTED, AMBER liền khi có mục chờ; tuổi `2p`; thêm `Agents-Idle`.

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Agents-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Danh sách hàng đợi agent (≤ 3 dòng; > 3 → 2 dòng + `+ N mục khác`).

- Status bar `Tác tử`, meta `N MỤC` MUTED, gạch nhấn MUTED.
- Mỗi dòng cao 60 px từ y 32: ô màu loại 6×6 tại (20, y+4), dòng chính INK (36, y), dòng phụ MUTED (36, y+15) — tuổi chữ thường `2p`, `1g`, `3ng`; cắt ở 190 px; kẻ LINE 200 px tại y+44. `+ N mục khác` TC (120, 152).
- Vạch y 230: MUTED khi không mục nào chờ; AMBER liền 240 px khi có mục chờ duyệt (SKY liền khi chờ câu hỏi).
- Vẽ lại cả danh sách khi hàng đợi đổi hoặc sang phút mới.

### Agents — Agents · 3 mục (có mục chờ duyệt)

Nguồn `source/Agents.dc.html` · ảnh `screens/@2x/Agents.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn MUTED | Status bar `Tác tử` · meta `3 MỤC` (MUTED, 35 px); gạch nhấn y 22 | 42 |
| 20, 36, 6×6 |  |  | AMBER | khối |  |
| 36, 32 | TL | `JBMono-11` | INK | `Cần bạn · Bash` | 98 |
| 36, 47 | TL | `JBMono-11` | MUTED | `claude · glimmer · 2p` | 147 |
| 20, 76, 200×1 |  |  | LINE | khối |  |
| 20, 96, 6×6 |  |  | LILAC | khối |  |
| 36, 92 | TL | `JBMono-11` | INK | `Tests · 64%` | 77 |
| 36, 107 | TL | `JBMono-11` | MUTED | `codex · api · 5p` | 112 |
| 20, 136, 200×1 |  |  | LINE | khối |  |
| 20, 156, 6×6 |  |  | MINT | khối |  |
| 36, 152 | TL | `JBMono-11` | INK | `Xong` | 28 |
| 36, 167 | TL | `JBMono-11` | MUTED | `claude · TieuMac3d · 12p` | 168 |
| 0, 230, 240×2 |  |  | AMBER | vạch chỉ báo liền (agent chờ) |  |

### Agents-More — Agents · 4 mục (+ N khác)

Nguồn `source/Agents-More.dc.html` · ảnh `screens/@2x/AgentsMore.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn MUTED | Status bar `Tác tử` · meta `4 MỤC` (MUTED, 35 px); gạch nhấn y 22 | 42 |
| 20, 36, 6×6 |  |  | AMBER | khối |  |
| 36, 32 | TL | `JBMono-11` | INK | `Cần bạn · Bash` | 98 |
| 36, 47 | TL | `JBMono-11` | MUTED | `claude · glimmer · 2p` | 147 |
| 20, 76, 200×1 |  |  | LINE | khối |  |
| 20, 96, 6×6 |  |  | LILAC | khối |  |
| 36, 92 | TL | `JBMono-11` | INK | `Tests · 64%` | 77 |
| 36, 107 | TL | `JBMono-11` | MUTED | `codex · api · 5p` | 112 |
| 20, 136, 200×1 |  |  | LINE | khối |  |
| 120, 152 | TC | `JBMono-11` | MUTED | `+ 2 mục khác` | 84 |
| 0, 230, 240×2 |  |  | AMBER | vạch chỉ báo liền (agent chờ) |  |

### Agents-Idle — Agents · không mục nào chờ

Nguồn `source/Agents-Idle.dc.html` · ảnh `screens/@2x/AgentsIdle.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn MUTED | Status bar `Tác tử` · meta `2 MỤC` (MUTED, 35 px); gạch nhấn y 22 | 42 |
| 20, 36, 6×6 |  |  | LILAC | khối |  |
| 36, 32 | TL | `JBMono-11` | INK | `Tests · 64%` | 77 |
| 36, 47 | TL | `JBMono-11` | MUTED | `codex · api · 5p` | 112 |
| 20, 76, 200×1 |  |  | LINE | khối |  |
| 20, 96, 6×6 |  |  | MINT | khối |  |
| 36, 92 | TL | `JBMono-11` | INK | `Xong` | 28 |
| 36, 107 | TL | `JBMono-11` | MUTED | `claude · TieuMac3d · 12p` | 168 |
| 0, 230, 240×2 |  |  | MUTED / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

## 6. Claude — kênh `Claude`

> **P-2026-11-25.6 — Zz động:** chữ "Zz" đứng yên khi Clawd ngủ (`Claude-NoProject`, `Claude-Done`) thay bằng **một chữ z bay lên** chậm, lắc nhẹ, lớn dần; hiện ra / tan đi bằng màu LINE. Bảng khung ở mục "Zz động" dưới đây; ảnh `ClaudeZzFrames.png`.

> **P-2026-11-25.5 — Xong hết thì Clawd ngủ:** mọi project trên bảng đều `Xong` (project gấp nhất là P_DONE) → Clawd mắt `sleep` + "Zz" MUTED như bảng trống, **không** còn mắt `happy`. Xem `Claude-Done`.

> **P-2026-11-25.4 — Khớp máy, Việt hoá, đúng luật khung:** đơn vị `4NG`, `2G 14P`, `18G 5P`, `CŨ 14P`, tuổi `2P` / `1G`; vạch y 230 phần còn lại PANEL.

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Claude-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.2 — Clawd ngủ khi chưa có project:** bảng project trống → Clawd mắt `sleep` (vạch ngang 2 ô ở hàng mắt dưới) thay cho `shut`, kèm chữ "Zz" pixel MUTED ở góc trên phải Clawd. Xem `Claude-NoProject`.

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Hạn mức Claude: số to tuần, phiên 5 giờ, bảng project.

- Số to VT323-86 = phần **đã dùng**; màu theo phần còn lại; dữ liệu cũ / khóa lỗi → MUTED.
- Cột phải: Clawd 72×40 (ô 4) tại (156, 58), biểu cảm theo bảng project (không có project → nhắm mắt); đếm ngược JBMono-12B CORAL TR (228, 112).
- Hàng dưới y 176, mỗi dòng 14 px, ≤ 3 dòng: project (cắt 84 px) + trạng thái màu (`Cần duyệt` AMBER, `Chờ bạn` SKY, `Lỗi` CORAL, `Đang chạy` LILAC, `Xong` MINT) + tuổi TR. Khóa lỗi khi còn số → dải 224×14 màu lỗi chiếm dòng đầu.
- Không có số liệu mà khóa lỗi / mất mạng → thẻ credential (biểu tượng chìa khóa hoặc vòng cấm, tiêu đề JBMono-16B, 2 dòng lý do, `glimmer.local` SKY + IP).
- Meta status bar (≈ 72 px): `CŨ 14P` AMBER khi cũ; `KHÓA LỖI` CORAL khi khóa lỗi; `BỊ CHẶN` AMBER.

### Claude — Claude · bình thường

Nguồn `source/Claude.dc.html` · ảnh `screens/@2x/Claude.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn CORAL | Status bar `Claude`; gạch nhấn y 22 | 42 |
| 12, 32 | TL | `JBMono-11` | MUTED | `TUẦN` | 28 |
| 156, 58, 72×40 |  |  | CLAWD | Clawd (ô 4, mắt `wide`, chân `stand`) |  |
| 228, 112 | TR | `JBMono-12B` | CORAL | `4NG` | 21 |
| 12, 46 | TL | `VT323-86` | MINT | `38` | 68 |
| 82, 76 | TL | `VT323-44` | MINT | `%` | 18 |
| 12, 128, 216×8 |  |  | MINT | `pixelBar` 9 ô, 38 % |  |
| 12, 146, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 150 | TL | `JBMono-11` | MUTED | `PHIÊN 5 GIỜ` | 77 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `12% · 2G 14P` | 84 |
| 12, 164, 216×4 |  |  | MINT | `pixelBar` 9 ô, 12 % |  |
| 12, 170, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 180, 5×5 |  |  | AMBER | khối |  |
| 228, 176 | TR | `JBMono-11` | MUTED | `2P` | 14 |
| 22, 176 | TL | `JBMono-11` | INK_DIM | `glimmer` | 49 |
| 79, 176 | TL | `JBMono-11` | AMBER | `Cần duyệt · Bash` | 112 |
| 12, 194, 5×5 |  |  | LILAC | khối |  |
| 228, 190 | TR | `JBMono-11` | MUTED | `5P` | 14 |
| 22, 190 | TL | `JBMono-11` | INK_DIM | `TieuMac3d` | 63 |
| 93, 190 | TL | `JBMono-11` | LILAC | `Đang chạy · Edit` | 112 |
| 12, 208, 5×5 |  |  | MINT | khối |  |
| 228, 204 | TR | `JBMono-11` | MUTED | `1G` | 14 |
| 22, 204 | TL | `JBMono-11` | INK_DIM | `api` | 21 |
| 51, 204 | TL | `JBMono-11` | MINT | `Xong` | 28 |
| 0, 230, 240×2 |  |  | CORAL / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Claude-NoProject — Claude · chưa có project

Nguồn `source/Claude-NoProject.dc.html` · ảnh `screens/@2x/ClaudeNoProject.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn CORAL | Status bar `Claude`; gạch nhấn y 22 | 42 |
| 12, 32 | TL | `JBMono-11` | MUTED | `TUẦN` | 28 |
| 156, 58, 72×40 |  |  | CLAWD | Clawd (ô 4, mắt `sleep`, chân `stand`) |  |
| 196, 24, 30×34 |  |  | MUTED / LINE | **Zz động** (P-2026-11-25.5→.6): một chữ z bay lên 12 khung × 0,4 s rồi nghỉ 1,2 s (chu kỳ 6,0 s); mỗi khung xoá vùng này về BG rồi vẽ đúng một chữ — bảng khung ở mục Zz động §6; ảnh vẽ khung 6 |  |
| 228, 112 | TR | `JBMono-12B` | CORAL | `4NG` | 21 |
| 12, 46 | TL | `VT323-86` | MINT | `38` | 68 |
| 82, 76 | TL | `VT323-44` | MINT | `%` | 18 |
| 12, 128, 216×8 |  |  | MINT | `pixelBar` 9 ô, 38 % |  |
| 12, 146, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 150 | TL | `JBMono-11` | MUTED | `PHIÊN 5 GIỜ` | 77 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `12% · 2G 14P` | 84 |
| 12, 164, 216×4 |  |  | MINT | `pixelBar` 9 ô, 12 % |  |
| 12, 170, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 176 | TL | `JBMono-11` | MUTED | `Chưa có hoạt động project` | 175 |
| 0, 230, 240×2 |  |  | CORAL / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Claude-Done — Claude · đã xong hết (Clawd ngủ)

Giống `Claude-NoProject` (Clawd ngủ + Zz), chỉ khác bảng project: mọi hàng `Xong` MINT. Clawd ngủ khi project đứng đầu `ordered()` là P_DONE; còn project chờ duyệt / câu hỏi / lỗi / đang chạy thì mặt theo project đó như cũ.

Nguồn `source/Claude-Done.dc.html` · ảnh `screens/@2x/ClaudeDone.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn CORAL | Status bar `Claude`; gạch nhấn y 22 | 42 |
| 12, 32 | TL | `JBMono-11` | MUTED | `TUẦN` | 28 |
| 156, 58, 72×40 |  |  | CLAWD | Clawd (ô 4, mắt `sleep`, chân `stand`) |  |
| 196, 24, 30×34 |  |  | MUTED / LINE | **Zz động** (P-2026-11-25.5→.6): một chữ z bay lên 12 khung × 0,4 s rồi nghỉ 1,2 s (chu kỳ 6,0 s); mỗi khung xoá vùng này về BG rồi vẽ đúng một chữ — bảng khung ở mục Zz động §6; ảnh vẽ khung 6 |  |
| 228, 112 | TR | `JBMono-12B` | CORAL | `4NG` | 21 |
| 12, 46 | TL | `VT323-86` | MINT | `38` | 68 |
| 82, 76 | TL | `VT323-44` | MINT | `%` | 18 |
| 12, 128, 216×8 |  |  | MINT | `pixelBar` 9 ô, 38 % |  |
| 12, 146, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 150 | TL | `JBMono-11` | MUTED | `PHIÊN 5 GIỜ` | 77 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `12% · 2G 14P` | 84 |
| 12, 164, 216×4 |  |  | MINT | `pixelBar` 9 ô, 12 % |  |
| 12, 170, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 180, 5×5 |  |  | MINT | ô trạng thái hàng 1 |  |
| 22, 176 | TL | `JBMono-11` | INK_DIM | `glimmer` | 49 |
| 79, 176 | TL | `JBMono-11` | MINT | `Xong` (x = 22 + tên + 8) | 28 |
| 228, 176 | TR | `JBMono-11` | MUTED | `2P` | 14 |
| 12, 194, 5×5 |  |  | MINT | ô trạng thái hàng 2 |  |
| 22, 190 | TL | `JBMono-11` | INK_DIM | `TieuMac3d` | 63 |
| 93, 190 | TL | `JBMono-11` | MINT | `Xong` | 28 |
| 228, 190 | TR | `JBMono-11` | MUTED | `40P` | 21 |
| 12, 208, 5×5 |  |  | MINT | ô trạng thái hàng 3 |  |
| 22, 204 | TL | `JBMono-11` | INK_DIM | `api` | 21 |
| 51, 204 | TL | `JBMono-11` | MINT | `Xong` | 28 |
| 228, 204 | TR | `JBMono-11` | MUTED | `1G` | 14 |
| 0, 230, 240×2 |  |  | CORAL / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Zz động — khi Clawd ngủ

Dùng ở `Claude-NoProject` và `Claude-Done` (Clawd mắt `sleep`, không chớp). Ảnh dải khung `screens/@2x/ClaudeZzFrames.png` (vùng x 192–227, y 24–59, ×4).

- Chu kỳ 6,0 s: 12 khung × 0,4 s (4,8 s) rồi nghỉ 1,2 s (vùng trống). Đổi khung trong `tick()` 5 Hz.
- Mỗi khung: tô BG vùng **196, 24, 30×34** rồi vẽ một chữ, ô 2 px. Không chạm Clawd (y ≥ 58), không vượt y 24.
- Bitmap: `z3` 3×3 (`###` `.#.` `###`) · `z4` 4×4 (`####` `..#.` `.#..` `####`) · `Z5` 5×5 (`#####` `...#.` `..#..` `.#...` `#####`).
- Màn vào lại (`draw()`) bắt đầu từ khung 0.

| khung | thời điểm | bitmap | x, y (trái-trên) | cỡ | màu |
|---|---|---|---|---|---|
| 0 | 0.0–0.4 s | `z3` | 198, 52 | 6 px | LINE |
| 1 | 0.4–0.8 s | `z3` | 200, 50 | 6 px | MUTED |
| 2 | 0.8–1.2 s | `z3` | 202, 48 | 6 px | MUTED |
| 3 | 1.2–1.6 s | `z3` | 203, 45 | 6 px | MUTED |
| 4 | 1.6–2.0 s | `z4` | 202, 42 | 8 px | MUTED |
| 5 | 2.0–2.4 s | `z4` | 202, 40 | 8 px | MUTED |
| 6 | 2.4–2.8 s | `z4` | 202, 38 | 8 px | MUTED |
| 7 | 2.8–3.2 s | `z4` | 203, 36 | 8 px | MUTED |
| 8 | 3.2–3.6 s | `Z5` | 204, 32 | 10 px | MUTED |
| 9 | 3.6–4.0 s | `Z5` | 206, 30 | 10 px | MUTED |
| 10 | 4.0–4.4 s | `Z5` | 208, 28 | 10 px | LINE |
| 11 | 4.4–4.8 s | `Z5` | 209, 26 | 10 px | LINE |

### Claude-Low — Claude · sắp hết hạn mức

Nguồn `source/Claude-Low.dc.html` · ảnh `screens/@2x/ClaudeLow.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn CORAL | Status bar `Claude`; gạch nhấn y 22 | 42 |
| 12, 32 | TL | `JBMono-11` | MUTED | `TUẦN` | 28 |
| 156, 58, 72×40 |  |  | CLAWD | Clawd (ô 4, mắt `open`, chân `stand`) |  |
| 228, 112 | TR | `JBMono-12B` | CORAL | `18G 5P` | 42 |
| 12, 46 | TL | `VT323-86` | CORAL | `92` | 68 |
| 82, 76 | TL | `VT323-44` | CORAL | `%` | 18 |
| 12, 128, 216×8 |  |  | CORAL | `pixelBar` 9 ô, 92 % |  |
| 12, 146, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 150 | TL | `JBMono-11` | MUTED | `PHIÊN 5 GIỜ` | 77 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `97% · 2G 14P` | 84 |
| 12, 164, 216×4 |  |  | CORAL | `pixelBar` 9 ô, 97 % |  |
| 12, 170, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 180, 5×5 |  |  | LILAC | khối |  |
| 228, 176 | TR | `JBMono-11` | MUTED | `5P` | 14 |
| 22, 176 | TL | `JBMono-11` | INK_DIM | `TieuMac3d` | 63 |
| 93, 176 | TL | `JBMono-11` | LILAC | `Đang chạy · Edit` | 112 |
| 12, 194, 5×5 |  |  | MINT | khối |  |
| 228, 190 | TR | `JBMono-11` | MUTED | `1G` | 14 |
| 22, 190 | TL | `JBMono-11` | INK_DIM | `api` | 21 |
| 51, 190 | TL | `JBMono-11` | MINT | `Xong` | 28 |
| 0, 230, 240×2 |  |  | CORAL / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Claude-Stale — Claude · dữ liệu cũ

Nguồn `source/Claude-Stale.dc.html` · ảnh `screens/@2x/ClaudeStale.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn CORAL | Status bar `Claude` · meta `CŨ 14M` (AMBER, 42 px); gạch nhấn y 22 | 42 |
| 12, 32 | TL | `JBMono-11` | MUTED | `TUẦN` | 28 |
| 156, 58, 72×40 |  |  | CLAWD | Clawd (ô 4, mắt `wide`, chân `stand`) |  |
| 228, 112 | TR | `JBMono-12B` | CORAL | `4NG` | 21 |
| 12, 46 | TL | `VT323-86` | MUTED | `38` | 68 |
| 82, 76 | TL | `VT323-44` | MUTED | `%` | 18 |
| 12, 128, 216×8 |  |  | MUTED | `pixelBar` 9 ô, 38 % |  |
| 12, 146, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 150 | TL | `JBMono-11` | MUTED | `PHIÊN 5 GIỜ` | 77 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `12% · 2G 14P` | 84 |
| 12, 164, 216×4 |  |  | MINT | `pixelBar` 9 ô, 12 % |  |
| 12, 170, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 180, 5×5 |  |  | AMBER | khối |  |
| 228, 176 | TR | `JBMono-11` | MUTED | `2P` | 14 |
| 22, 176 | TL | `JBMono-11` | INK_DIM | `glimmer` | 49 |
| 79, 176 | TL | `JBMono-11` | AMBER | `Cần duyệt · Bash` | 112 |
| 12, 194, 5×5 |  |  | LILAC | khối |  |
| 228, 190 | TR | `JBMono-11` | MUTED | `5P` | 14 |
| 22, 190 | TL | `JBMono-11` | INK_DIM | `TieuMac3d` | 63 |
| 93, 190 | TL | `JBMono-11` | LILAC | `Đang chạy · Edit` | 112 |
| 12, 208, 5×5 |  |  | MINT | khối |  |
| 228, 204 | TR | `JBMono-11` | MUTED | `1G` | 14 |
| 22, 204 | TL | `JBMono-11` | INK_DIM | `api` | 21 |
| 51, 204 | TL | `JBMono-11` | MINT | `Xong` | 28 |
| 0, 230, 240×2 |  |  | CORAL / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Claude-KeyExpired — Claude · khóa hết hạn (còn số cũ)

Nguồn `source/Claude-KeyExpired.dc.html` · ảnh `screens/@2x/ClaudeKeyExpired.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn CORAL | Status bar `Claude` · meta `KHÓA LỖI` (CORAL, 56 px); gạch nhấn y 22 | 42 |
| 12, 32 | TL | `JBMono-11` | MUTED | `TUẦN` | 28 |
| 156, 58, 72×40 |  |  | CLAWD | Clawd (ô 4, mắt `wide`, chân `stand`) |  |
| 228, 112 | TR | `JBMono-12B` | CORAL | `4NG` | 21 |
| 12, 46 | TL | `VT323-86` | MUTED | `38` | 68 |
| 82, 76 | TL | `VT323-44` | MUTED | `%` | 18 |
| 12, 128, 216×8 |  |  | MUTED | `pixelBar` 9 ô, 38 % |  |
| 12, 146, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 150 | TL | `JBMono-11` | MUTED | `PHIÊN 5 GIỜ` | 77 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `12% · 2G 14P` | 84 |
| 12, 164, 216×4 |  |  | MINT | `pixelBar` 9 ô, 12 % |  |
| 12, 170, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 8, 176, 224×14 |  |  | CORAL | khối |  |
| 120, 183 | MC | `JBMono-11` | BG | `KHÓA HẾT HẠN · glimmer.local` | 196 |
| 12, 194, 5×5 |  |  | AMBER | khối |  |
| 228, 190 | TR | `JBMono-11` | MUTED | `2P` | 14 |
| 22, 190 | TL | `JBMono-11` | INK_DIM | `glimmer` | 49 |
| 79, 190 | TL | `JBMono-11` | AMBER | `Cần duyệt · Bash` | 112 |
| 12, 208, 5×5 |  |  | LILAC | khối |  |
| 228, 204 | TR | `JBMono-11` | MUTED | `5P` | 14 |
| 22, 204 | TL | `JBMono-11` | INK_DIM | `TieuMac3d` | 63 |
| 93, 204 | TL | `JBMono-11` | LILAC | `Đang chạy · Edit` | 112 |
| 0, 230, 240×2 |  |  | CORAL / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Claude-Loading — Claude · đang tải

Nguồn `source/Claude-Loading.dc.html` · ảnh `screens/@2x/ClaudeLoading.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn CORAL | Status bar `Claude`; gạch nhấn y 22 | 42 |
| 120, 100 | MC | `JBMono-16B` | MUTED | `Đang tải` | 80 |
| 99, 128 |  |  | CORAL | 5 chấm tải 6×6, bước 9 |  |
| 0, 230, 240×2 |  |  | CORAL / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Claude-Rejected — Claude · khóa bị từ chối

Nguồn `source/Claude-Rejected.dc.html` · ảnh `screens/@2x/ClaudeRejected.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn CORAL | Status bar `Claude` · meta `KHÓA LỖI` (CORAL, 56 px); gạch nhấn y 22 | 42 |
| 104, 34, 32×32 |  |  | CORAL | bitmap `key` |  |
| 120, 92 | MC | `JBMono-16B` | CORAL | `KHÓA BỊ TỪ CHỐI` | 150 |
| 120, 116 | MC | `JBMono-11` | MUTED | `claude.ai từ chối khóa` | 154 |
| 120, 132 | MC | `JBMono-11` | MUTED | `nhập khóa mới tại` | 119 |
| 30, 148, w 180 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 120, 166 | MC | `JBMono-12B` | SKY | `glimmer.local` | 91 |
| 120, 186 | MC | `JBMono-11` | MUTED | `192.168.100.40` | 98 |
| 0, 230, 240×2 |  |  | CORAL / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Claude-Offline — Claude · mất mạng

Nguồn `source/Claude-Offline.dc.html` · ảnh `screens/@2x/ClaudeOffline.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn CORAL | Status bar `Claude`; gạch nhấn y 22 | 42 |
| tâm 120, 54 |  |  | AMBER | vòng cấm Ø 29, nét 2 |  |
| 120, 92 | MC | `JBMono-16B` | AMBER | `Mất mạng` | 80 |
| 120, 116 | MC | `JBMono-11` | MUTED | `không tới được claude.ai` | 168 |
| 120, 132 | MC | `JBMono-11` | MUTED | `kiểm tra Wi-Fi` | 98 |
| 30, 148, w 180 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 120, 166 | MC | `JBMono-11` | INK_DIM | `đang tự động thử lại` | 140 |
| 0, 230, 240×2 |  |  | CORAL / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

## 7. Codex — kênh `Codex`

> **P-2026-11-25.4 — Khớp máy, Việt hoá, đúng luật khung:** đơn vị `3NG`, `2G 14P`, `CŨ 18P`; vạch y 230 phần còn lại PANEL.

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Codex-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Hạn mức Codex — bố cục như Claude, nhấn LILAC, đáy là dải 24 giờ.

- Nhãn cửa sổ (`TUẦN` / `NGÀY` / `5H`) JBMono-12B MUTED (12, 32). Cột phải: tín dụng `$4.20` VT323-32 SKY, nếu không có thì đếm ngược VT323-32 LILAC, TR (228, 26).
- Hàng phụ y 150: nhãn (tag mô hình như `SPARK`, hoặc độ dài cửa sổ) + đếm ngược / %; thanh 216×4 tại y 164.
- Đáy y 174–219: [dải lỗi token] · `24H` + nhịp tuần (`~70% KHI ĐẶT LẠI` INK_DIM, `HẾT SAU 5G` CORAL) · `ĐẶT LẠI` MINT + `CÒN 2 · 3NG` khi có lượt đặt lại · 24 cột rộng 8 (bước 9) cao theo % còn lại mỗi giờ, cột giờ hiện tại LILAC, giờ thiếu số → vạch LINE ở y 219.
- `tick()`: phút đổi → đếm ngược, meta; đổi > 0,4 % → số to / hàng phụ; mỗi giờ → dải 24 giờ.

### Codex — Codex · bình thường

Nguồn `source/Codex.dc.html` · ảnh `screens/@2x/Codex.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn LILAC | Status bar `Codex`; gạch nhấn y 22 | 35 |
| 12, 32 | TL | `JBMono-12B` | MUTED | `TUẦN` | 28 |
| 228, 26 | TR | `VT323-32` | LILAC | `3NG` | 39 |
| 12, 46 | TL | `VT323-86` | MINT | `41` | 68 |
| 82, 76 | TL | `VT323-44` | MINT | `%` | 18 |
| 12, 128, 216×8 |  |  | MINT | `pixelBar` 9 ô, 41 % |  |
| 12, 146, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 150 | TL | `JBMono-11` | MUTED | `SPARK` | 35 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `2G 14P` | 42 |
| 12, 164, 216×4 |  |  | MINT | `pixelBar` 9 ô, 12 % |  |
| 12, 170, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 174 | TL | `JBMono-11` | MUTED | `24H` | 21 |
| 228, 174 | TR | `JBMono-11` | INK_DIM | `~70% KHI ĐẶT LẠI` | 112 |
| 12, 188 | TL | `JBMono-11` | MINT | `ĐẶT LẠI` | 49 |
| 228, 188 | TR | `JBMono-11` | INK_DIM | `CÒN 2 · 3NG` | 77 |
| 12, 219, 8×1 |  |  | LINE | khối |  |
| 21, 219, 8×1 |  |  | LINE | khối |  |
| 30, 219, 8×1 |  |  | LINE | khối |  |
| 39, 219, 8×1 |  |  | LINE | khối |  |
| 48, 219, 8×1 |  |  | LINE | khối |  |
| 57, 208, 8×12 |  |  | INK_DIM | khối |  |
| 66, 208, 8×12 |  |  | INK_DIM | khối |  |
| 75, 209, 8×11 |  |  | INK_DIM | khối |  |
| 84, 209, 8×11 |  |  | INK_DIM | khối |  |
| 93, 209, 8×11 |  |  | INK_DIM | khối |  |
| 102, 209, 8×11 |  |  | INK_DIM | khối |  |
| 111, 209, 8×11 |  |  | INK_DIM | khối |  |
| 120, 209, 8×11 |  |  | INK_DIM | khối |  |
| 129, 209, 8×11 |  |  | INK_DIM | khối |  |
| 138, 209, 8×11 |  |  | INK_DIM | khối |  |
| 147, 209, 8×11 |  |  | INK_DIM | khối |  |
| 156, 210, 8×10 |  |  | INK_DIM | khối |  |
| 165, 210, 8×10 |  |  | INK_DIM | khối |  |
| 174, 210, 8×10 |  |  | INK_DIM | khối |  |
| 183, 210, 8×10 |  |  | INK_DIM | khối |  |
| 192, 210, 8×10 |  |  | INK_DIM | khối |  |
| 201, 210, 8×10 |  |  | INK_DIM | khối |  |
| 210, 210, 8×10 |  |  | INK_DIM | khối |  |
| 219, 210, 8×10 |  |  | LILAC | khối |  |
| 0, 230, 240×2 |  |  | LILAC / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Codex-Stale — Codex · dữ liệu cũ

Nguồn `source/Codex-Stale.dc.html` · ảnh `screens/@2x/CodexStale.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn LILAC | Status bar `Codex` · meta `CŨ 18M` (AMBER, 42 px); gạch nhấn y 22 | 35 |
| 12, 32 | TL | `JBMono-12B` | MUTED | `TUẦN` | 28 |
| 228, 26 | TR | `VT323-32` | LILAC | `3NG` | 39 |
| 12, 46 | TL | `VT323-86` | MUTED | `41` | 68 |
| 82, 76 | TL | `VT323-44` | MUTED | `%` | 18 |
| 12, 128, 216×8 |  |  | MUTED | `pixelBar` 9 ô, 41 % |  |
| 12, 146, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 150 | TL | `JBMono-11` | MUTED | `SPARK` | 35 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `2G 14P` | 42 |
| 12, 164, 216×4 |  |  | MINT | `pixelBar` 9 ô, 12 % |  |
| 12, 170, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 174 | TL | `JBMono-11` | MUTED | `24H` | 21 |
| 228, 174 | TR | `JBMono-11` | INK_DIM | `~70% KHI ĐẶT LẠI` | 112 |
| 12, 188 | TL | `JBMono-11` | MINT | `ĐẶT LẠI` | 49 |
| 228, 188 | TR | `JBMono-11` | INK_DIM | `CÒN 2 · 3NG` | 77 |
| 12, 219, 8×1 |  |  | LINE | khối |  |
| 21, 219, 8×1 |  |  | LINE | khối |  |
| 30, 219, 8×1 |  |  | LINE | khối |  |
| 39, 219, 8×1 |  |  | LINE | khối |  |
| 48, 219, 8×1 |  |  | LINE | khối |  |
| 57, 208, 8×12 |  |  | INK_DIM | khối |  |
| 66, 208, 8×12 |  |  | INK_DIM | khối |  |
| 75, 209, 8×11 |  |  | INK_DIM | khối |  |
| 84, 209, 8×11 |  |  | INK_DIM | khối |  |
| 93, 209, 8×11 |  |  | INK_DIM | khối |  |
| 102, 209, 8×11 |  |  | INK_DIM | khối |  |
| 111, 209, 8×11 |  |  | INK_DIM | khối |  |
| 120, 209, 8×11 |  |  | INK_DIM | khối |  |
| 129, 209, 8×11 |  |  | INK_DIM | khối |  |
| 138, 209, 8×11 |  |  | INK_DIM | khối |  |
| 147, 209, 8×11 |  |  | INK_DIM | khối |  |
| 156, 210, 8×10 |  |  | INK_DIM | khối |  |
| 165, 210, 8×10 |  |  | INK_DIM | khối |  |
| 174, 210, 8×10 |  |  | INK_DIM | khối |  |
| 183, 210, 8×10 |  |  | INK_DIM | khối |  |
| 192, 210, 8×10 |  |  | INK_DIM | khối |  |
| 201, 210, 8×10 |  |  | INK_DIM | khối |  |
| 210, 210, 8×10 |  |  | INK_DIM | khối |  |
| 219, 210, 8×10 |  |  | LILAC | khối |  |
| 0, 230, 240×2 |  |  | LILAC / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Codex-Loading — Codex · đang tải

Nguồn `source/Codex-Loading.dc.html` · ảnh `screens/@2x/CodexLoading.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn LILAC | Status bar `Codex`; gạch nhấn y 22 | 35 |
| 120, 100 | MC | `JBMono-16B` | MUTED | `Đang tải` | 80 |
| 99, 128 |  |  | LILAC | 5 chấm tải 6×6, bước 9 |  |
| 0, 230, 240×2 |  |  | LILAC / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Codex-Expired — Codex · token hết hạn

Nguồn `source/Codex-Expired.dc.html` · ảnh `screens/@2x/CodexExpired.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn LILAC | Status bar `Codex` · meta `KHÓA LỖI` (CORAL, 56 px); gạch nhấn y 22 | 35 |
| 104, 34, 32×32 |  |  | CORAL | bitmap `key` |  |
| 120, 92 | MC | `JBMono-16B` | CORAL | `TOKEN HẾT HẠN` | 130 |
| 120, 116 | MC | `JBMono-11` | MUTED | `hết hạn ngày 20/11` | 126 |
| 120, 132 | MC | `JBMono-11` | MUTED | `nhập token mới tại` | 126 |
| 30, 148, w 180 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 120, 166 | MC | `JBMono-12B` | SKY | `glimmer.local` | 91 |
| 120, 186 | MC | `JBMono-11` | MUTED | `192.168.100.40` | 98 |
| 0, 230, 240×2 |  |  | LILAC / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

## 8. AI — kênh `AI`

> **P-2026-11-25.4 — Khớp máy, Việt hoá, đúng luật khung:** đơn vị `2G 14P`, `3NG`; đang tải: cột đặt lại `--` (đã đồng bộ giờ mà quá hạn: `ngay`).

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `AI-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Claude + Codex cạnh nhau (chỉ khi có cả hai khóa).

- Status bar nhấn INK_DIM, meta = tín dụng Codex `$4.20`.
- Số VT323-32: Claude TL (12, 50), Codex TR (228, 50); khóa lỗi → chữ `KHÓA` màu lỗi, thanh rỗng MUTED; đang tải → 3 chấm.
- Hai thanh 216×10 tại y 92 / 110; đặt lại `CL` / `CX` ở y 158 / 174; lời khuyên căn giữa y 198 (INK; lỗi khóa → màu lỗi), có chấm kẻ y 192.

### AI — AI · bình thường

Nguồn `source/AI.dc.html` · ảnh `screens/@2x/AI.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn INK_DIM | Status bar `AI hôm nay` · meta `$4.20` (MUTED, 35 px); gạch nhấn y 22 | 70 |
| 12, 32 | TL | `JBMono-12B` | CORAL | `CLAUDE` | 42 |
| 228, 32 | TR | `JBMono-12B` | LILAC | `CODEX` | 35 |
| 12, 50 | TL | `VT323-32` | MINT | `38%` | 39 |
| 12, 92, 216×10 |  |  | MINT | `pixelBar` 9 ô, 38 % |  |
| 228, 50 | TR | `VT323-32` | AMBER | `71%` | 39 |
| 12, 110, 216×10 |  |  | AMBER | `pixelBar` 9 ô, 71 % |  |
| 12, 130, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 138 | TL | `JBMono-11` | MUTED | `ĐẶT LẠI` | 49 |
| 12, 158 | TL | `JBMono-12B` | CORAL | `CL` | 14 |
| 228, 158 | TR | `JBMono-11` | INK_DIM | `2G 14P` | 42 |
| 12, 174 | TL | `JBMono-12B` | LILAC | `CX` | 14 |
| 228, 174 | TR | `JBMono-11` | INK_DIM | `3NG` | 21 |
| 12, 192, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 120, 198 | TC | `JBMono-11` | INK | `DÙNG CLAUDE · ĐẶT LẠI 2G` | 168 |
| 0, 230, 240×2 |  |  | INK_DIM / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### AI-Loading — AI · đang tải

Nguồn `source/AI-Loading.dc.html` · ảnh `screens/@2x/AILoading.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn INK_DIM | Status bar `AI hôm nay`; gạch nhấn y 22 | 70 |
| 12, 32 | TL | `JBMono-12B` | CORAL | `CLAUDE` | 42 |
| 228, 32 | TR | `JBMono-12B` | LILAC | `CODEX` | 35 |
| 14, 58 |  |  | CORAL | 3 chấm tải 6×6, bước 9 |  |
| 204, 58 |  |  | LILAC | 3 chấm tải 6×6, bước 9 |  |
| 12, 92, 216×10 |  |  | MINT | `pixelBar` 9 ô, 0 % |  |
| 12, 110, 216×10 |  |  | MINT | `pixelBar` 9 ô, 0 % |  |
| 12, 130, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 138 | TL | `JBMono-11` | MUTED | `ĐẶT LẠI` | 49 |
| 12, 158 | TL | `JBMono-12B` | CORAL | `CL` | 14 |
| 228, 158 | TR | `JBMono-11` | INK_DIM | `--` | 14 |
| 12, 174 | TL | `JBMono-12B` | LILAC | `CX` | 14 |
| 228, 174 | TR | `JBMono-11` | INK_DIM | `--` | 14 |
| 0, 230, 240×2 |  |  | INK_DIM / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### AI-KeyBad — AI · khóa Claude lỗi

Nguồn `source/AI-KeyBad.dc.html` · ảnh `screens/@2x/AIKeyBad.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn INK_DIM | Status bar `AI hôm nay` · meta `$4.20` (MUTED, 35 px); gạch nhấn y 22 | 70 |
| 12, 32 | TL | `JBMono-12B` | CORAL | `CLAUDE` | 42 |
| 228, 32 | TR | `JBMono-12B` | LILAC | `CODEX` | 35 |
| 12, 50 | TL | `VT323-32` | CORAL | `KHÓA` | 52 |
| 12, 92, 216×10 |  |  | MUTED | `pixelBar` 9 ô, 0 % |  |
| 228, 50 | TR | `VT323-32` | AMBER | `71%` | 39 |
| 12, 110, 216×10 |  |  | AMBER | `pixelBar` 9 ô, 71 % |  |
| 12, 130, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 138 | TL | `JBMono-11` | MUTED | `ĐẶT LẠI` | 49 |
| 12, 158 | TL | `JBMono-12B` | CORAL | `CL` | 14 |
| 228, 158 | TR | `JBMono-11` | INK_DIM | `2G 14P` | 42 |
| 12, 174 | TL | `JBMono-12B` | LILAC | `CX` | 14 |
| 228, 174 | TR | `JBMono-11` | INK_DIM | `3NG` | 21 |
| 12, 192, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 120, 198 | TC | `JBMono-11` | CORAL | `KHÓA CLAUDE BỊ TỪ CHỐI` | 154 |
| 0, 230, 240×2 |  |  | INK_DIM / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

## 9. Trend — kênh `Trend`

> **P-2026-11-25.4 — Khớp máy, Việt hoá, đúng luật khung:** nhãn thứ `T2`…`CN`.

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Trend-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Phần trăm hạn mức tuần dùng mỗi ngày, 7 ngày.

- Hai khối (CLAUDE y 30, CODEX y 98; chỉ khối có khóa): cột 27 px, bước 31, cao tối đa 44, đáy y+60; hôm nay tô màu nhà cung cấp, các ngày khác INK_DIM; khóa lỗi → LINE.
- Nhãn thứ y 168: `T2`…`T7`, `CN` (hôm nay INK, ngày khác MUTED).
- Vẽ lại khi sang giờ mới, khóa đổi trạng thái, hoặc số hôm nay đổi > 0,4.

### Trend — Trend · 7 ngày

Nguồn `source/Trend.dc.html` · ảnh `screens/@2x/Trend.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn MINT | Status bar `Xu hướng` · meta `7 NGÀY` (MUTED, 42 px); gạch nhấn y 22 | 56 |
| 12, 30 | TL | `JBMono-12B` | CORAL | `CLAUDE` | 42 |
| 228, 31 | TR | `JBMono-11` | MUTED | `HÔM NAY 9 · ĐỈNH T2` | 133 |
| 12, 90, 27×1 |  |  | LINE | khối |  |
| 12, 68, 27×22 |  |  | INK_DIM | khối |  |
| 43, 90, 27×1 |  |  | LINE | khối |  |
| 43, 57, 27×33 |  |  | INK_DIM | khối |  |
| 74, 90, 27×1 |  |  | LINE | khối |  |
| 74, 79, 27×11 |  |  | INK_DIM | khối |  |
| 105, 90, 27×1 |  |  | LINE | khối |  |
| 136, 90, 27×1 |  |  | LINE | khối |  |
| 136, 46, 27×44 |  |  | INK_DIM | khối |  |
| 167, 90, 27×1 |  |  | LINE | khối |  |
| 167, 61, 27×29 |  |  | INK_DIM | khối |  |
| 198, 90, 27×1 |  |  | LINE | khối |  |
| 198, 57, 27×33 |  |  | CORAL | khối |  |
| 12, 98 | TL | `JBMono-12B` | LILAC | `CODEX` | 35 |
| 228, 99 | TR | `JBMono-11` | MUTED | `HÔM NAY 4 · ĐỈNH CN` | 133 |
| 12, 158, 27×1 |  |  | LINE | khối |  |
| 12, 143, 27×15 |  |  | INK_DIM | khối |  |
| 43, 158, 27×1 |  |  | LINE | khối |  |
| 43, 151, 27×7 |  |  | INK_DIM | khối |  |
| 74, 158, 27×1 |  |  | LINE | khối |  |
| 74, 140, 27×18 |  |  | INK_DIM | khối |  |
| 105, 158, 27×1 |  |  | LINE | khối |  |
| 105, 132, 27×26 |  |  | INK_DIM | khối |  |
| 136, 158, 27×1 |  |  | LINE | khối |  |
| 136, 147, 27×11 |  |  | INK_DIM | khối |  |
| 167, 158, 27×1 |  |  | LINE | khối |  |
| 167, 136, 27×22 |  |  | INK_DIM | khối |  |
| 198, 158, 27×1 |  |  | LINE | khối |  |
| 198, 143, 27×15 |  |  | LILAC | khối |  |
| 25, 168 | TC | `JBMono-11` | MUTED | `T5` | 14 |
| 56, 168 | TC | `JBMono-11` | MUTED | `T6` | 14 |
| 87, 168 | TC | `JBMono-11` | MUTED | `T7` | 14 |
| 118, 168 | TC | `JBMono-11` | MUTED | `CN` | 14 |
| 149, 168 | TC | `JBMono-11` | MUTED | `T2` | 14 |
| 180, 168 | TC | `JBMono-11` | MUTED | `T3` | 14 |
| 211, 168 | TC | `JBMono-11` | INK | `T4` | 14 |
| 120, 194 | TC | `JBMono-11` | MUTED | `% hạn mức tuần dùng mỗi ngày` | 196 |
| 0, 230, 240×2 |  |  | MINT / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Trend-Collecting — Trend · đang thu thập

Nguồn `source/Trend-Collecting.dc.html` · ảnh `screens/@2x/TrendCollecting.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn MINT | Status bar `Xu hướng` · meta `7 NGÀY` (MUTED, 42 px); gạch nhấn y 22 | 56 |
| 12, 30 | TL | `JBMono-12B` | CORAL | `CLAUDE` | 42 |
| 228, 31 | TR | `JBMono-11` | MUTED | `đang thu thập` | 91 |
| 12, 90, 27×1 |  |  | LINE | khối |  |
| 43, 90, 27×1 |  |  | LINE | khối |  |
| 74, 90, 27×1 |  |  | LINE | khối |  |
| 105, 90, 27×1 |  |  | LINE | khối |  |
| 136, 90, 27×1 |  |  | LINE | khối |  |
| 167, 90, 27×1 |  |  | LINE | khối |  |
| 198, 90, 27×1 |  |  | LINE | khối |  |
| 12, 98 | TL | `JBMono-12B` | LILAC | `CODEX` | 35 |
| 228, 99 | TR | `JBMono-11` | MUTED | `đang thu thập` | 91 |
| 12, 158, 27×1 |  |  | LINE | khối |  |
| 43, 158, 27×1 |  |  | LINE | khối |  |
| 74, 158, 27×1 |  |  | LINE | khối |  |
| 105, 158, 27×1 |  |  | LINE | khối |  |
| 136, 158, 27×1 |  |  | LINE | khối |  |
| 167, 158, 27×1 |  |  | LINE | khối |  |
| 198, 158, 27×1 |  |  | LINE | khối |  |
| 25, 168 | TC | `JBMono-11` | MUTED | `T5` | 14 |
| 56, 168 | TC | `JBMono-11` | MUTED | `T6` | 14 |
| 87, 168 | TC | `JBMono-11` | MUTED | `T7` | 14 |
| 118, 168 | TC | `JBMono-11` | MUTED | `CN` | 14 |
| 149, 168 | TC | `JBMono-11` | MUTED | `T2` | 14 |
| 180, 168 | TC | `JBMono-11` | MUTED | `T3` | 14 |
| 211, 168 | TC | `JBMono-11` | INK | `T4` | 14 |
| 120, 194 | TC | `JBMono-11` | MUTED | `% hạn mức tuần dùng mỗi ngày` | 196 |
| 0, 230, 240×2 |  |  | MINT / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

## 10. Weather — kênh `Weather`

> **P-2026-11-26.17:** kiểu XP thật — xem §17 mục XP-Real.

> **P-2026-11-25.4 — Khớp máy, Việt hoá, đúng luật khung:** thêm `Weather-Error` (lỗi bằng tiếng Việt).

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Weather-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Thời tiết hiện tại + 3 ô ngày.

- Meta: `LẶN 17:24` / `MỌC 5:48` MUTED; cũ → `CŨ 2G` AMBER và số to MUTED.
- Ô ngày: 69×64, nền PANEL, viền LINE, bước 73 từ x 12, y 150.
- UV: ≥ 8 CORAL, ≥ 6 AMBER, còn lại MUTED.
- Chưa có dữ liệu → `đang tải...` JBMono-16B MUTED giữa màn.
- Lỗi (chưa từng có số): `Chưa có thời tiết` 16B MUTED MC (120, 100); chi tiết 11 MUTED MC (120, 124); chấm kẻ (30, 140, 180); `đang tự thử lại` INK_DIM MC (120, 158). Chi tiết theo lỗi máy: `HTTP <mã ≥ 100>` → `máy chủ trả lỗi <mã>`; `HTTP <mã âm>` → `không kết nối được`; `http begin` → `không mở được kết nối`; `JSON …` → `dữ liệu lỗi`; `no current` → `thiếu số liệu hiện tại`.

### Weather — Weather · bình thường

Nguồn `source/Weather.dc.html` · ảnh `screens/@2x/Weather.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn SKY | Status bar `Thời tiết` · meta `LẶN 17:24` (MUTED, 63 px); gạch nhấn y 22 | 63 |
| 12, 32 | TL | `VT323-86` | INK | `29` | 68 |
| 82, 42 | TL | `VT323-32` | SKY | `°` | 13 |
| 12, 117, 16×16 |  |  | SKY | bitmap `PARTCLOUD` |  |
| 32, 118 | TL | `JBMono-13` | INK_DIM | `Ít mây` | 48 |
| 228, 36 | TR | `JBMono-11` | MUTED | `cảm giác 33°` | 84 |
| 228, 54 | TR | `JBMono-11` | MUTED | `ẩm 74%` | 42 |
| 228, 72 | TR | `JBMono-11` | MUTED | `gió 12km` | 56 |
| 228, 90 | TR | `JBMono-11` | AMBER | `UV 7` | 28 |
| 12, 140, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 150, 69×64 |  |  | PANEL | khối |  |
| 12, 150, 69×64 |  |  | LINE | viền 1 px |  |
| 46, 160 | MC | `JBMono-12B` | MUTED | `HÔM NAY` | 49 |
| 46, 180 | MC | `VT323-32` | INK | `31/24` | 65 |
| 46, 202 | MC | `JBMono-11` | MUTED | `Ít mây` | 42 |
| 85, 150, 69×64 |  |  | PANEL | khối |  |
| 85, 150, 69×64 |  |  | LINE | viền 1 px |  |
| 119, 160 | MC | `JBMono-12B` | MUTED | `+1` | 14 |
| 119, 180 | MC | `VT323-32` | INK | `30/24` | 65 |
| 119, 202 | MC | `JBMono-11` | MUTED | `Mưa rào` | 49 |
| 158, 150, 69×64 |  |  | PANEL | khối |  |
| 158, 150, 69×64 |  |  | LINE | viền 1 px |  |
| 192, 160 | MC | `JBMono-12B` | MUTED | `+2` | 14 |
| 192, 180 | MC | `VT323-32` | INK | `28/23` | 65 |
| 192, 202 | MC | `JBMono-11` | MUTED | `Mưa` | 21 |
| 0, 230, 240×2 |  |  | SKY / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Weather-Stale — Weather · dữ liệu cũ

Nguồn `source/Weather-Stale.dc.html` · ảnh `screens/@2x/WeatherStale.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn SKY | Status bar `Thời tiết` · meta `CŨ 2G` (AMBER, 35 px); gạch nhấn y 22 | 63 |
| 12, 32 | TL | `VT323-86` | MUTED | `29` | 68 |
| 82, 42 | TL | `VT323-32` | SKY | `°` | 13 |
| 12, 117, 16×16 |  |  | SKY | bitmap `PARTCLOUD` |  |
| 32, 118 | TL | `JBMono-13` | INK_DIM | `Ít mây` | 48 |
| 228, 36 | TR | `JBMono-11` | MUTED | `cảm giác 33°` | 84 |
| 228, 54 | TR | `JBMono-11` | MUTED | `ẩm 74%` | 42 |
| 228, 72 | TR | `JBMono-11` | MUTED | `gió 12km` | 56 |
| 228, 90 | TR | `JBMono-11` | AMBER | `UV 7` | 28 |
| 12, 140, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 150, 69×64 |  |  | PANEL | khối |  |
| 12, 150, 69×64 |  |  | LINE | viền 1 px |  |
| 46, 160 | MC | `JBMono-12B` | MUTED | `HÔM NAY` | 49 |
| 46, 180 | MC | `VT323-32` | INK | `31/24` | 65 |
| 46, 202 | MC | `JBMono-11` | MUTED | `Ít mây` | 42 |
| 85, 150, 69×64 |  |  | PANEL | khối |  |
| 85, 150, 69×64 |  |  | LINE | viền 1 px |  |
| 119, 160 | MC | `JBMono-12B` | MUTED | `+1` | 14 |
| 119, 180 | MC | `VT323-32` | INK | `30/24` | 65 |
| 119, 202 | MC | `JBMono-11` | MUTED | `Mưa rào` | 49 |
| 158, 150, 69×64 |  |  | PANEL | khối |  |
| 158, 150, 69×64 |  |  | LINE | viền 1 px |  |
| 192, 160 | MC | `JBMono-12B` | MUTED | `+2` | 14 |
| 192, 180 | MC | `VT323-32` | INK | `28/23` | 65 |
| 192, 202 | MC | `JBMono-11` | MUTED | `Mưa` | 21 |
| 0, 230, 240×2 |  |  | SKY / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Weather-Loading — Weather · đang tải

Nguồn `source/Weather-Loading.dc.html` · ảnh `screens/@2x/WeatherLoading.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn SKY | Status bar `Thời tiết` · meta `--` (MUTED, 14 px); gạch nhấn y 22 | 63 |
| 120, 110 | MC | `JBMono-16B` | MUTED | `đang tải...` | 110 |
| 0, 230, 240×2 |  |  | SKY / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Weather-Error — Weather · lỗi

Nguồn `source/Weather-Error.dc.html` · ảnh `screens/@2x/WeatherError.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn SKY | Status bar `Thời tiết` · meta `--` (MUTED, 14 px); gạch nhấn y 22 | 63 |
| 120, 100 | MC | `JBMono-16B` | MUTED | `Chưa có thời tiết` | 170 |
| 120, 124 | MC | `JBMono-11` | MUTED | `máy chủ trả lỗi 500` | 133 |
| 30, 140, w 180 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 120, 158 | MC | `JBMono-11` | INK_DIM | `đang tự thử lại` | 105 |
| 0, 230, 240×2 |  |  | SKY / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

## 11. Forecast — kênh `Forecast`

> **P-2026-11-26.17:** kiểu XP thật — xem §17 mục XP-Real.

> **P-2026-11-25.4 — Khớp máy, Việt hoá, đúng luật khung:** đoạn nhiệt màu đặc (SKY / MUTED), không tràn rãnh.

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Forecast-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

3 dòng ngày: NAY / MAI / KIA.

- Dòng cao 52, bước 56 từ y 32; hôm nay nền PANEL toàn chiều ngang + vạch trái 2 px CORAL (ngày khác LINE).
- Thanh nhiệt 130×8 tại (90, y+10) nền PANEL2; đoạn min→max tô **màu đặc** — SKY hôm nay, MUTED ngày khác; điểm cuối ≤ x 219 (trong rãnh).
- Vẽ lại khi min / max / mã thời tiết đổi.

### Forecast — Forecast · 3 ngày

Nguồn `source/Forecast.dc.html` · ảnh `screens/@2x/Forecast.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn SKY | Status bar `Dự báo` · meta `3 NGÀY` (MUTED, 42 px); gạch nhấn y 22 | 42 |
| 0, 32, 240×52 |  |  | PANEL | khối |  |
| 0, 32, 2×52 |  |  | CORAL | khối |  |
| 10, 36 | TL | `JBMono-16B` | INK | `NAY` | 30 |
| 10, 58, 16×16 |  |  | SKY | bitmap `PARTCLOUD` |  |
| 28, 60 | TL | `JBMono-11` | MUTED | `Ít mây` | 42 |
| 90, 42, 130×8 |  |  | PANEL2 | khối |  |
| 106, 42, 114×8 |  |  | SKY | khối |  |
| 204, 60 | TR | `JBMono-11` | MUTED | `24` | 14 |
| 230, 60 | TR | `JBMono-11` | INK | `31` | 14 |
| 0, 88, 2×52 |  |  | LINE | khối |  |
| 10, 92 | TL | `JBMono-16B` | INK_DIM | `MAI` | 30 |
| 10, 114, 16×16 |  |  | MUTED | bitmap `RAIN` |  |
| 28, 116 | TL | `JBMono-11` | MUTED | `Mưa rào` | 49 |
| 90, 98, 130×8 |  |  | PANEL2 | khối |  |
| 106, 98, 98×8 |  |  | MUTED | khối |  |
| 204, 116 | TR | `JBMono-11` | MUTED | `24` | 14 |
| 230, 116 | TR | `JBMono-11` | INK | `30` | 14 |
| 0, 144, 2×52 |  |  | LINE | khối |  |
| 10, 148 | TL | `JBMono-16B` | INK_DIM | `KIA` | 30 |
| 10, 170, 16×16 |  |  | MUTED | bitmap `RAIN` |  |
| 28, 172 | TL | `JBMono-11` | MUTED | `Mưa` | 21 |
| 90, 154, 130×8 |  |  | PANEL2 | khối |  |
| 90, 154, 82×8 |  |  | MUTED | khối |  |
| 204, 172 | TR | `JBMono-11` | MUTED | `23` | 14 |
| 230, 172 | TR | `JBMono-11` | INK | `28` | 14 |
| 0, 230, 240×2 |  |  | SKY / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Forecast-Empty — Forecast · chưa có dự báo

Nguồn `source/Forecast-Empty.dc.html` · ảnh `screens/@2x/ForecastEmpty.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn SKY | Status bar `Dự báo` · meta `3 NGÀY` (MUTED, 42 px); gạch nhấn y 22 | 42 |
| 120, 110 | MC | `JBMono-16B` | MUTED | `chưa có dự báo` | 140 |
| 0, 230, 240×2 |  |  | SKY / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

## 12. Clock — kênh `Clock`

> **P-2026-11-26.17:** kiểu XP thật — xem §17 mục XP-Real.

> **P-2026-11-25.4 — Khớp máy, Việt hoá, đúng luật khung:** status bar `Đồng hồ` (meta `tuần 48`); thêm `Clock-12h` với `SA` / `CH`.

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Clock-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Đồng hồ lớn + lời chào + dải 24 giờ.

- Status bar `Đồng hồ`, meta `tuần 48` MUTED. Ngày `THỨ TƯ · 25/11` MUTED TC (120, 32).
- Giờ VT323-86 căn giữa x 35–205, y 46: HH / MM INK, `:` CORAL. 12 giờ: giờ dạng `%2d` (` 2`), thêm `SA` / `CH` 12B AMBER tại (209, 95).
- Lời chào JBMono-13 INK_DIM MC (120, 148). Dải 24 chấm 4×4 bước 7 từ x 37, y 178: đã qua AMBER, giờ hiện tại INK, còn lại LINE.
- `tick()`: phút → MM; giờ → HH, ngày, lời chào, dải, SA / CH.

### Clock — Clock · đồng hồ 24 giờ

Nguồn `source/Clock.dc.html` · ảnh `screens/@2x/Clock.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn AMBER | Status bar `Đồng hồ` · meta `tuần 48` (MUTED, 49 px); gạch nhấn y 22 | 49 |
| 120, 32 | TC | `JBMono-11` | MUTED | `THỨ TƯ · 25/11` | 98 |
| 35, 46 | TL | `VT323-86` | INK | `14` | 68 |
| 103, 46 | TL | `VT323-86` | CORAL | `:` | 34 |
| 137, 46 | TL | `VT323-86` | INK | `32` | 68 |
| 120, 148 | MC | `JBMono-13` | INK_DIM | `chào buổi chiều, bạn` | 160 |
| 37, 178, 4×4 |  |  | AMBER | khối |  |
| 44, 178, 4×4 |  |  | AMBER | khối |  |
| 51, 178, 4×4 |  |  | AMBER | khối |  |
| 58, 178, 4×4 |  |  | AMBER | khối |  |
| 65, 178, 4×4 |  |  | AMBER | khối |  |
| 72, 178, 4×4 |  |  | AMBER | khối |  |
| 79, 178, 4×4 |  |  | AMBER | khối |  |
| 86, 178, 4×4 |  |  | AMBER | khối |  |
| 93, 178, 4×4 |  |  | AMBER | khối |  |
| 100, 178, 4×4 |  |  | AMBER | khối |  |
| 107, 178, 4×4 |  |  | AMBER | khối |  |
| 114, 178, 4×4 |  |  | AMBER | khối |  |
| 121, 178, 4×4 |  |  | AMBER | khối |  |
| 128, 178, 4×4 |  |  | AMBER | khối |  |
| 135, 178, 4×4 |  |  | INK | khối |  |
| 142, 178, 4×4 |  |  | LINE | khối |  |
| 149, 178, 4×4 |  |  | LINE | khối |  |
| 156, 178, 4×4 |  |  | LINE | khối |  |
| 163, 178, 4×4 |  |  | LINE | khối |  |
| 170, 178, 4×4 |  |  | LINE | khối |  |
| 177, 178, 4×4 |  |  | LINE | khối |  |
| 184, 178, 4×4 |  |  | LINE | khối |  |
| 191, 178, 4×4 |  |  | LINE | khối |  |
| 198, 178, 4×4 |  |  | LINE | khối |  |
| 0, 230, 240×2 |  |  | AMBER / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Clock-12h — Clock · đồng hồ 12 giờ (SA / CH)

Nguồn `source/Clock-12h.dc.html` · ảnh `screens/@2x/Clock12h.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn AMBER | Status bar `Đồng hồ` · meta `tuần 48` (MUTED, 49 px); gạch nhấn y 22 | 49 |
| 120, 32 | TC | `JBMono-11` | MUTED | `THỨ TƯ · 25/11` | 98 |
| 35, 46 | TL | `VT323-86` | INK | ` 2` | 68 |
| 103, 46 | TL | `VT323-86` | CORAL | `:` | 34 |
| 137, 46 | TL | `VT323-86` | INK | `32` | 68 |
| 209, 95 | TL | `JBMono-12B` | AMBER | `CH` | 14 |
| 120, 148 | MC | `JBMono-13` | INK_DIM | `chào buổi chiều, bạn` | 160 |
| 37, 178, 4×4 |  |  | AMBER | khối |  |
| 44, 178, 4×4 |  |  | AMBER | khối |  |
| 51, 178, 4×4 |  |  | AMBER | khối |  |
| 58, 178, 4×4 |  |  | AMBER | khối |  |
| 65, 178, 4×4 |  |  | AMBER | khối |  |
| 72, 178, 4×4 |  |  | AMBER | khối |  |
| 79, 178, 4×4 |  |  | AMBER | khối |  |
| 86, 178, 4×4 |  |  | AMBER | khối |  |
| 93, 178, 4×4 |  |  | AMBER | khối |  |
| 100, 178, 4×4 |  |  | AMBER | khối |  |
| 107, 178, 4×4 |  |  | AMBER | khối |  |
| 114, 178, 4×4 |  |  | AMBER | khối |  |
| 121, 178, 4×4 |  |  | AMBER | khối |  |
| 128, 178, 4×4 |  |  | AMBER | khối |  |
| 135, 178, 4×4 |  |  | INK | khối |  |
| 142, 178, 4×4 |  |  | LINE | khối |  |
| 149, 178, 4×4 |  |  | LINE | khối |  |
| 156, 178, 4×4 |  |  | LINE | khối |  |
| 163, 178, 4×4 |  |  | LINE | khối |  |
| 170, 178, 4×4 |  |  | LINE | khối |  |
| 177, 178, 4×4 |  |  | LINE | khối |  |
| 184, 178, 4×4 |  |  | LINE | khối |  |
| 191, 178, 4×4 |  |  | LINE | khối |  |
| 198, 178, 4×4 |  |  | LINE | khối |  |
| 0, 230, 240×2 |  |  | AMBER / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

## 13. Info — kênh `Info`

> **P-2026-11-25.4 — Khớp máy, Việt hoá, đúng luật khung:** bước 19 px, dòng cuối y 201–214; đơn vị `P`.

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Info-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Chẩn đoán thiết bị.

- 10 dòng bước 19 từ y 30, chấm kẻ y+15 — dòng cuối `Lần tới` y 201–214, trong vùng nội dung.
- Đơn vị phút `P`: `312P`, `1P trước`, `sau 4P`.
- Sóng: > −60 dBm MINT, > −75 AMBER, còn lại CORAL.
- `tick()`: vẽ lại riêng dòng có giá trị đổi.

### Info — Info · chẩn đoán

Nguồn `source/Info.dc.html` · ảnh `screens/@2x/Info.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn MINT | Status bar `Thông tin` · meta `CHẨN ĐOÁN` (MUTED, 63 px); gạch nhấn y 22 | 63 |
| 12, 30 | TL | `JBMono-11` | MUTED | `IP` | 14 |
| 228, 30 | TR | `JBMono-11` | INK | `192.168.100.40` | 98 |
| 12, 45, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 49 | TL | `JBMono-11` | MUTED | `SSID` | 28 |
| 228, 49 | TR | `JBMono-11` | INK | `Anh Viet` | 56 |
| 12, 64, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 68 | TL | `JBMono-11` | MUTED | `Sóng` | 28 |
| 228, 68 | TR | `JBMono-11` | MINT | `-58 dBm` | 49 |
| 12, 83, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 87 | TL | `JBMono-11` | MUTED | `Đã chạy` | 49 |
| 228, 87 | TR | `JBMono-11` | INK_DIM | `312P` | 28 |
| 12, 102, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 106 | TL | `JBMono-11` | MUTED | `Bộ nhớ` | 42 |
| 228, 106 | TR | `JBMono-11` | AMBER | `27K trống` | 63 |
| 12, 121, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 125 | TL | `JBMono-11` | MUTED | `Khối lớn` | 56 |
| 228, 125 | TR | `JBMono-11` | INK_DIM | `21K` | 21 |
| 12, 140, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 144 | TL | `JBMono-11` | MUTED | `Firmware` | 56 |
| 228, 144 | TR | `JBMono-11` | INK_DIM | `v0.23.0-glimmer` | 105 |
| 12, 159, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 163 | TL | `JBMono-11` | MUTED | `Kênh` | 28 |
| 228, 163 | TR | `JBMono-11` | INK_DIM | `9 / 13` | 42 |
| 12, 178, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 182 | TL | `JBMono-11` | MUTED | `Cập nhật` | 56 |
| 228, 182 | TR | `JBMono-11` | INK_DIM | `1P trước` | 56 |
| 12, 197, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 201 | TL | `JBMono-11` | MUTED | `Lần tới` | 49 |
| 228, 201 | TR | `JBMono-11` | MINT | `sau 4P` | 42 |
| 0, 230, 240×2 |  |  | MINT / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

## 14. Màn hệ thống

> **P-2026-11-25.4 — Khớp máy, Việt hoá, đúng luật khung:** chuỗi phiên bản `v0.23.0-glimmer`.

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Khởi động, kết nối Wi-Fi, cài đặt Wi-Fi, cập nhật OTA, chưa có kênh.

- Logo 16×16 AMBER. Chấm tải 6×6, bước 9 (đang sáng CORAL, còn lại LINE).
- Thanh OTA: viền LINE 216×12 tại (12, 148), lõi tô CORAL theo %, phần còn lại PANEL — thanh liền (không phải `pixelBar`).
- Cùng kỷ luật vẽ lại từng phần: khung vẽ một lần mỗi phiên, chỉ phần đổi (chấm, %, lần thử) được vẽ lại.

### Splash — Hệ thống · khởi động

Nguồn `source/Splash.dc.html` · ảnh `screens/@2x/Splash.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 112, 68, 16×16 |  |  | AMBER | bitmap `logo` |  |
| 120, 104 | MC | `JBMono-16B` | INK | `GLIMMER` | 70 |
| 102, 130, 6×6 |  |  | CORAL | khối |  |
| 111, 130, 6×6 |  |  | CORAL | khối |  |
| 120, 130, 6×6 |  |  | CORAL | khối |  |
| 129, 130, 6×6 |  |  | LINE | khối |  |
| 138, 130, 6×6 |  |  | LINE | khối |  |
| 120, 156 | MC | `JBMono-11` | MUTED | `đang khởi động...` | 119 |
| 120, 200 | MC | `JBMono-11` | MUTED | `v0.23.0-glimmer` | 105 |

### Connecting — Hệ thống · đang kết nối Wi-Fi

Nguồn `source/Connecting.dc.html` · ảnh `screens/@2x/Connecting.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 112, 40, 16×16 |  |  | AMBER | bitmap `logo` |  |
| 120, 68 | MC | `JBMono-16B` | INK | `GLIMMER` | 70 |
| 120, 100 | MC | `JBMono-12B` | MUTED | `Đang kết nối Wi-Fi` | 126 |
| 120, 124 | MC | `JBMono-11` | INK | `Anh Viet` | 56 |
| 104, 160 |  |  | CORAL | 5 chấm tải 6×6, bước 9 |  |
| 120, 192 | MC | `JBMono-11` | MUTED | `lần thử 1` | 63 |
| 120, 216 | MC | `JBMono-11` | MUTED | `v0.23.0-glimmer` | 105 |

### SetupMode — Hệ thống · chế độ cài đặt Wi-Fi

Nguồn `source/SetupMode.dc.html` · ảnh `screens/@2x/SetupMode.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn CORAL | Status bar `glimmer` · meta `CÀI ĐẶT` (MUTED, 49 px); gạch nhấn y 22 | 49 |
| 112, 26, 16×16 |  |  | AMBER | bitmap `logo` |  |
| 120, 44 | MC | `JBMono-12B` | MUTED | `KẾT NỐI WI-FI` | 91 |
| 120, 68 | MC | `JBMono-16B` | INK | `glimmer-setup` | 130 |
| 10, 96, w 220 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 120, 116 | MC | `JBMono-12B` | MUTED | `RỒI MỞ` | 42 |
| 120, 140 | MC | `JBMono-16B` | SKY | `http://192.168.4.1` | 180 |
| 102, 176, 6×6 |  |  | CORAL | khối |  |
| 111, 176, 6×6 |  |  | CORAL | khối |  |
| 120, 176, 6×6 |  |  | CORAL | khối |  |
| 129, 176, 6×6 |  |  | LINE | khối |  |
| 138, 176, 6×6 |  |  | LINE | khối |  |
| 120, 204 | MC | `JBMono-11` | MUTED | `v0.23.0-glimmer` | 105 |

### OtaProgress — Hệ thống · đang cập nhật

Nguồn `source/OtaProgress.dc.html` · ảnh `screens/@2x/OtaProgress.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 112, 30, 16×16 |  |  | AMBER | bitmap `logo` |  |
| 120, 58 | MC | `JBMono-16B` | INK | `GLIMMER` | 70 |
| 120, 82 | MC | `JBMono-12B` | CORAL | `ĐANG CẬP NHẬT` | 91 |
| 120, 110 | MC | `VT323-44` | CORAL | `42%` | 54 |
| 12, 148, 216×12 |  |  | LINE | viền 1 px |  |
| 13, 149, 89×10 |  |  | CORAL | khối |  |
| 102, 149, 125×10 |  |  | PANEL | khối |  |
| 120, 178 | MC | `JBMono-11` | MUTED | `đừng rút điện` | 91 |
| 120, 200 | MC | `JBMono-11` | MUTED | `v0.23.0-glimmer` | 105 |

### NoChannels — Hệ thống · chưa có kênh

Nguồn `source/NoChannels.dc.html` · ảnh `screens/@2x/NoChannels.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 120, 90 | MC | `JBMono-16B` | CORAL | `CHƯA CÓ KÊNH` | 120 |
| 120, 135 | MC | `JBMono-11` | MUTED | `bật kênh trên trang web` | 161 |


## 15. Dock dọc — thành phần dùng chung và bố cục có dock

> **P-2026-11-25.7 — Tab Ảnh:** tab thứ 2 của dock là **Ảnh** (skill `photo`) thay cho Tin nhắn (chờ gói chat): icon khung ảnh 16×11 INK_DIM, không huy hiệu. Ảnh 11 màn có dock vẽ lại phần tab 2. Prop `second` (`photo` mặc định / `chat`).

> **P-2026-11-25.4 — Khớp máy, Việt hoá:** vạch y 230 phần còn lại PANEL; Agents vạch AMBER liền khi có mục chờ; Setup MUTED; Forecast màu đặc; đơn vị `P` / `G` / `NG`, thứ `T2`…`CN`.

> **P-2026-11-25.3 — Dock dọc nổi bám lề trái:** thành phần mới `Dock` + 11 kênh xếp lại theo bề ngang mới. **Chờ phía code chốt dòng "Đổi luật" trong CHANGELOG** trước khi áp.

Dock = thanh tab kiểu Slide Over của iPad: báo đang ở tab nào và tab nào có việc. Không có nút bấm — tab đổi theo vòng xoay.

**Thành phần `Dock`** (`source/Dock.dc.html`) — khối 30×150 tại (2, 34), nằm dưới status bar, không chạm vạch y 230:

| phần | tọa độ trong dock (gốc = góc trong viền) | màu |
|---|---|---|
| khung | 30×150, viền 1 px | nền PANEL, viền LINE |
| ô tab k (k = 0…3: Claude, Ảnh, Thời tiết, Đồng hồ) | tâm (14, 19 + 36k) | — |
| icon | Clawd 18×10 (ô 1 px) · khung ảnh 16×11 · mặt trời 16×14 · đồng hồ 16×14, căn giữa tâm ô; nét 2 px | Clawd CLAWD, còn lại INK_DIM |
| tab đang hiện | ô 24×24 tại (2, cy − 12) + vạch 2×10 tại (0, cy − 5) | ô PANEL2, vạch = màu nhấn của kênh |
| huy hiệu số | 9×9 vạt góc 1 px tại (19, cy − 14); chữ số bitmap 3×5 tại (22, cy − 12); > 9 → `+`; 0 → ẩn | Claude AMBER (agent chờ duyệt); Tin nhắn SKY khi gói chat có (tab Ảnh không huy hiệu); chữ số BG |

Bitmap icon và chữ số (lưới `#`) nằm trong `source/Dock.dc.html` (`ICONS`, `DIGITS`) và `tokens/panel_tokens.json` → `component.dock`.

**Bố cục có dock:** nội dung kênh x 40–228 (rộng 188), y 24–219 như cũ; status bar và vạch tiến độ y 230 phủ hết 240 px. Huy hiệu thay cho vạch vàng / xanh liền y 230 khi agent chờ. Tab đang hiện theo kênh: Claude cho kênh skill agent (Home, Agents, Claude, Codex, AI, Trend, Setup); Thời tiết cho Weather, Forecast; Đồng hồ cho Clock; Info không tab nào (`none`). Không dock: Attention, Night, màn hệ thống.

Khác bản không dock: Home, Agents, Clock có status bar (`Trang chủ` meta `29° Ít mây` 70 px; `Tác tử` meta `3 MỤC`; `Đồng hồ` meta `tuần 48`); Home tách giờ (x 40–210, y 30–100) khỏi thời tiết (chuyển lên meta + dòng `c.giác`); Info bước 19 px (dòng cuối y 201–214); Weather 2 ô ngày 92 px (MAI, KIA), nhiệt cao/thấp hôm nay `31°/24°` cạnh mô tả; Trend cột 23 px bước 27, chú thích `% hạn mức tuần mỗi ngày`; Forecast nền dòng hôm nay từ x 36, rãnh nhiệt 92 px tại x 104.


### Claude-Dock — Claude · có dock

Nguồn `source/Claude-Dock.dc.html` · ảnh `screens/@2x/ClaudeDock.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 |  |  | BG | khối |  |
| 120, 11 | MC | `JBMono-12B` | INK | `Claude` | 42 |
| 0, 22, 240×1 |  |  | CORAL | khối |  |
| 40, 32 | TL | `JBMono-11` | MUTED | `TUẦN` | 28 |
| 156, 58, 72×40 |  |  | CLAWD | Clawd (ô 4, mắt `open`, chân `stand`) |  |
| 228, 112 | TR | `JBMono-12B` | CORAL | `4NG` | 21 |
| 40, 46 | TL | `VT323-86` | MINT | `38` | 68 |
| 110, 76 | TL | `VT323-44` | MINT | `%` | 18 |
| 40, 128, 188×8 |  |  | MINT | `pixelBar` 9 ô, 38 % |  |
| 40, 146, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 150 | TL | `JBMono-11` | MUTED | `PHIÊN 5 GIỜ` | 77 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `12% · 2G 14P` | 84 |
| 40, 164, 188×4 |  |  | MINT | `pixelBar` 9 ô, 12 % |  |
| 40, 170, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 180, 5×5 |  |  | AMBER | khối |  |
| 228, 176 | TR | `JBMono-11` | MUTED | `2P` | 14 |
| 50, 176 | TL | `JBMono-11` | INK_DIM | `glimmer` | 49 |
| 107, 176 | TL | `JBMono-11` | AMBER | `Cần duyệt` | 63 |
| 40, 194, 5×5 |  |  | LILAC | khối |  |
| 228, 190 | TR | `JBMono-11` | MUTED | `5P` | 14 |
| 50, 190 | TL | `JBMono-11` | INK_DIM | `TieuMac3d` | 63 |
| 121, 190 | TL | `JBMono-11` | LILAC | `Đang chạy` | 63 |
| 40, 208, 5×5 |  |  | MINT | khối |  |
| 228, 204 | TR | `JBMono-11` | MUTED | `1G` | 14 |
| 50, 204 | TL | `JBMono-11` | INK_DIM | `api` | 21 |
| 79, 204 | TL | `JBMono-11` | MINT | `Xong` | 28 |
| 2, 34, 30×150 |  |  | nhấn CORAL | Dock (`Dock.dc.html`), tab đang hiện `claude`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 96×2 |  |  | CORAL | khối |  |
| 96, 230, 144×2 |  |  | PANEL | khối |  |

### Home-Dock — Home · có dock

Nguồn `source/Home-Dock.dc.html` · ảnh `screens/@2x/HomeDock.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn AMBER | Status bar `Trang chủ` · meta `29° Ít mây` (MUTED, 70 px); gạch nhấn y 22 | 63 |
| 40, 30 | TL | `VT323-86` | INK | `14` | 68 |
| 108, 30 | TL | `VT323-86` | CORAL | `:` | 34 |
| 142, 30 | TL | `VT323-86` | AMBER | `32` | 68 |
| 40, 104 | TL | `JBMono-12B` | INK_DIM | `THỨ TƯ 25/11` | 84 |
| 228, 105 | TR | `JBMono-11` | MUTED | `c.giác 33°` | 70 |
| 40, 122, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 128 | TL | `JBMono-12B` | CORAL | `CL` | 14 |
| 66, 131, 120×7 |  |  | MINT | `pixelBar` 9 ô, 38 % |  |
| 228, 128 | TR | `JBMono-11` | MINT | `38%` | 21 |
| 40, 146 | TL | `JBMono-12B` | LILAC | `CX` | 14 |
| 66, 149, 120×7 |  |  | AMBER | `pixelBar` 9 ô, 71 % |  |
| 228, 146 | TR | `JBMono-11` | AMBER | `71%` | 21 |
| 40, 166, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 170 | TL | `JBMono-12B` | MUTED | `HÔM NAY` | 49 |
| 228, 170 | TR | `JBMono-11` | INK_DIM | `CÒN 9G` | 42 |
| 40, 198, 188×1 |  |  | LINE | khối |  |
| 40, 195, 1×3 |  |  | INK_DIM | khối |  |
| 47, 196, 1×2 |  |  | LINE | khối |  |
| 55, 196, 1×2 |  |  | LINE | khối |  |
| 63, 196, 1×2 |  |  | LINE | khối |  |
| 71, 196, 1×2 |  |  | LINE | khối |  |
| 79, 196, 1×2 |  |  | LINE | khối |  |
| 87, 195, 1×3 |  |  | INK_DIM | khối |  |
| 94, 196, 1×2 |  |  | LINE | khối |  |
| 102, 196, 1×2 |  |  | LINE | khối |  |
| 110, 196, 1×2 |  |  | LINE | khối |  |
| 118, 196, 1×2 |  |  | LINE | khối |  |
| 126, 196, 1×2 |  |  | LINE | khối |  |
| 134, 195, 1×3 |  |  | INK_DIM | khối |  |
| 141, 196, 1×2 |  |  | LINE | khối |  |
| 149, 192, 1×6 |  |  | CORAL | khối |  |
| 157, 196, 1×2 |  |  | LINE | khối |  |
| 165, 196, 1×2 |  |  | LINE | khối |  |
| 173, 196, 1×2 |  |  | LINE | khối |  |
| 181, 195, 1×3 |  |  | INK_DIM | khối |  |
| 188, 196, 1×2 |  |  | LINE | khối |  |
| 196, 196, 1×2 |  |  | LINE | khối |  |
| 204, 196, 1×2 |  |  | LINE | khối |  |
| 212, 196, 1×2 |  |  | LINE | khối |  |
| 220, 196, 1×2 |  |  | LINE | khối |  |
| 148, 190, 3×3 |  |  | AMBER | khối |  |
| 228, 204 | TR | `JBMono-11` | MUTED | `192.168.100.40` | 98 |
| 2, 34, 30×150 |  |  | nhấn AMBER | Dock (`Dock.dc.html`), tab đang hiện `claude`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 96×2 |  |  | AMBER | khối |  |
| 96, 230, 144×2 |  |  | PANEL | khối |  |

### Agents-Dock — Agents · có dock

Nguồn `source/Agents-Dock.dc.html` · ảnh `screens/@2x/AgentsDock.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn AMBER | Status bar `Tác tử` · meta `3 MỤC` (MUTED, 35 px); gạch nhấn y 22 | 42 |
| 40, 36, 6×6 |  |  | AMBER | khối |  |
| 54, 32 | TL | `JBMono-11` | INK | `Cần bạn · Bash` | 98 |
| 54, 47 | TL | `JBMono-11` | MUTED | `claude · glimmer · 2p` | 147 |
| 40, 76, 188×1 |  |  | LINE | khối |  |
| 40, 96, 6×6 |  |  | LILAC | khối |  |
| 54, 92 | TL | `JBMono-11` | INK | `Tests · 64%` | 77 |
| 54, 107 | TL | `JBMono-11` | MUTED | `codex · api · 5p` | 112 |
| 40, 136, 188×1 |  |  | LINE | khối |  |
| 40, 156, 6×6 |  |  | MINT | khối |  |
| 54, 152 | TL | `JBMono-11` | INK | `Xong` | 28 |
| 54, 167 | TL | `JBMono-11` | MUTED | `claude · TieuMac3d · 12p` | 168 |
| 2, 34, 30×150 |  |  | nhấn AMBER | Dock (`Dock.dc.html`), tab đang hiện `claude`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 240×2 |  |  | AMBER | khối |  |

### Codex-Dock — Codex · có dock

Nguồn `source/Codex-Dock.dc.html` · ảnh `screens/@2x/CodexDock.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn LILAC | Status bar `Codex`; gạch nhấn y 22 | 35 |
| 40, 32 | TL | `JBMono-12B` | MUTED | `TUẦN` | 28 |
| 228, 26 | TR | `VT323-32` | LILAC | `3NG` | 39 |
| 40, 46 | TL | `VT323-86` | MINT | `41` | 68 |
| 110, 76 | TL | `VT323-44` | MINT | `%` | 18 |
| 40, 128, 188×8 |  |  | MINT | `pixelBar` 9 ô, 41 % |  |
| 40, 146, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 150 | TL | `JBMono-11` | MUTED | `SPARK` | 35 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `2G 14P` | 42 |
| 40, 164, 188×4 |  |  | MINT | `pixelBar` 9 ô, 12 % |  |
| 40, 170, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 174 | TL | `JBMono-11` | MUTED | `24H` | 21 |
| 228, 174 | TR | `JBMono-11` | INK_DIM | `~70% KHI ĐẶT LẠI` | 112 |
| 40, 188 | TL | `JBMono-11` | MINT | `ĐẶT LẠI` | 49 |
| 228, 188 | TR | `JBMono-11` | INK_DIM | `CÒN 2 · 3NG` | 77 |
| 40, 219, 6×1 |  |  | LINE | khối |  |
| 47, 219, 6×1 |  |  | LINE | khối |  |
| 54, 219, 6×1 |  |  | LINE | khối |  |
| 61, 219, 6×1 |  |  | LINE | khối |  |
| 68, 219, 6×1 |  |  | LINE | khối |  |
| 75, 208, 6×12 |  |  | INK_DIM | khối |  |
| 82, 208, 6×12 |  |  | INK_DIM | khối |  |
| 89, 209, 6×11 |  |  | INK_DIM | khối |  |
| 96, 209, 6×11 |  |  | INK_DIM | khối |  |
| 103, 209, 6×11 |  |  | INK_DIM | khối |  |
| 110, 209, 6×11 |  |  | INK_DIM | khối |  |
| 117, 209, 6×11 |  |  | INK_DIM | khối |  |
| 124, 209, 6×11 |  |  | INK_DIM | khối |  |
| 131, 209, 6×11 |  |  | INK_DIM | khối |  |
| 138, 209, 6×11 |  |  | INK_DIM | khối |  |
| 145, 209, 6×11 |  |  | INK_DIM | khối |  |
| 152, 210, 6×10 |  |  | INK_DIM | khối |  |
| 159, 210, 6×10 |  |  | INK_DIM | khối |  |
| 166, 210, 6×10 |  |  | INK_DIM | khối |  |
| 173, 210, 6×10 |  |  | INK_DIM | khối |  |
| 180, 210, 6×10 |  |  | INK_DIM | khối |  |
| 187, 210, 6×10 |  |  | INK_DIM | khối |  |
| 194, 210, 6×10 |  |  | INK_DIM | khối |  |
| 201, 210, 6×10 |  |  | LILAC | khối |  |
| 2, 34, 30×150 |  |  | nhấn LILAC | Dock (`Dock.dc.html`), tab đang hiện `claude`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 96×2 |  |  | LILAC | khối |  |
| 96, 230, 144×2 |  |  | PANEL | khối |  |

### AI-Dock — AI · có dock

Nguồn `source/AI-Dock.dc.html` · ảnh `screens/@2x/AIDock.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn INK_DIM | Status bar `AI hôm nay` · meta `$4.20` (MUTED, 35 px); gạch nhấn y 22 | 70 |
| 40, 32 | TL | `JBMono-12B` | CORAL | `CLAUDE` | 42 |
| 228, 32 | TR | `JBMono-12B` | LILAC | `CODEX` | 35 |
| 40, 50 | TL | `VT323-32` | MINT | `38%` | 39 |
| 228, 50 | TR | `VT323-32` | AMBER | `71%` | 39 |
| 40, 92, 188×10 |  |  | MINT | `pixelBar` 9 ô, 38 % |  |
| 40, 110, 188×10 |  |  | AMBER | `pixelBar` 9 ô, 71 % |  |
| 40, 130, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 138 | TL | `JBMono-11` | MUTED | `ĐẶT LẠI` | 49 |
| 40, 158 | TL | `JBMono-12B` | CORAL | `CL` | 14 |
| 228, 158 | TR | `JBMono-11` | INK_DIM | `2G 14P` | 42 |
| 40, 174 | TL | `JBMono-12B` | LILAC | `CX` | 14 |
| 228, 174 | TR | `JBMono-11` | INK_DIM | `3NG` | 21 |
| 40, 192, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 134, 198 | TC | `JBMono-11` | INK | `DÙNG CLAUDE · ĐẶT LẠI 2G` | 168 |
| 2, 34, 30×150 |  |  | nhấn INK_DIM | Dock (`Dock.dc.html`), tab đang hiện `claude`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 96×2 |  |  | INK_DIM | khối |  |
| 96, 230, 144×2 |  |  | PANEL | khối |  |

### Trend-Dock — Trend · có dock

Nguồn `source/Trend-Dock.dc.html` · ảnh `screens/@2x/TrendDock.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn MINT | Status bar `Xu hướng` · meta `7 NGÀY` (MUTED, 42 px); gạch nhấn y 22 | 56 |
| 40, 30 | TL | `JBMono-12B` | CORAL | `CLAUDE` | 42 |
| 228, 31 | TR | `JBMono-11` | MUTED | `HÔM NAY 9 · ĐỈNH T2` | 133 |
| 40, 90, 23×1 |  |  | LINE | khối |  |
| 40, 68, 23×22 |  |  | INK_DIM | khối |  |
| 67, 90, 23×1 |  |  | LINE | khối |  |
| 67, 57, 23×33 |  |  | INK_DIM | khối |  |
| 94, 90, 23×1 |  |  | LINE | khối |  |
| 94, 79, 23×11 |  |  | INK_DIM | khối |  |
| 121, 90, 23×1 |  |  | LINE | khối |  |
| 148, 90, 23×1 |  |  | LINE | khối |  |
| 148, 46, 23×44 |  |  | INK_DIM | khối |  |
| 175, 90, 23×1 |  |  | LINE | khối |  |
| 175, 61, 23×29 |  |  | INK_DIM | khối |  |
| 202, 90, 23×1 |  |  | LINE | khối |  |
| 202, 57, 23×33 |  |  | CORAL | khối |  |
| 40, 98 | TL | `JBMono-12B` | LILAC | `CODEX` | 35 |
| 228, 99 | TR | `JBMono-11` | MUTED | `HÔM NAY 4 · ĐỈNH CN` | 133 |
| 40, 158, 23×1 |  |  | LINE | khối |  |
| 40, 143, 23×15 |  |  | INK_DIM | khối |  |
| 67, 158, 23×1 |  |  | LINE | khối |  |
| 67, 151, 23×7 |  |  | INK_DIM | khối |  |
| 94, 158, 23×1 |  |  | LINE | khối |  |
| 94, 140, 23×18 |  |  | INK_DIM | khối |  |
| 121, 158, 23×1 |  |  | LINE | khối |  |
| 121, 132, 23×26 |  |  | INK_DIM | khối |  |
| 148, 158, 23×1 |  |  | LINE | khối |  |
| 148, 147, 23×11 |  |  | INK_DIM | khối |  |
| 175, 158, 23×1 |  |  | LINE | khối |  |
| 175, 136, 23×22 |  |  | INK_DIM | khối |  |
| 202, 158, 23×1 |  |  | LINE | khối |  |
| 202, 143, 23×15 |  |  | LILAC | khối |  |
| 51, 168 | TC | `JBMono-11` | MUTED | `T5` | 14 |
| 78, 168 | TC | `JBMono-11` | MUTED | `T6` | 14 |
| 105, 168 | TC | `JBMono-11` | MUTED | `T7` | 14 |
| 132, 168 | TC | `JBMono-11` | MUTED | `CN` | 14 |
| 159, 168 | TC | `JBMono-11` | MUTED | `T2` | 14 |
| 186, 168 | TC | `JBMono-11` | MUTED | `T3` | 14 |
| 213, 168 | TC | `JBMono-11` | INK | `T4` | 14 |
| 134, 194 | TC | `JBMono-11` | MUTED | `% hạn mức tuần mỗi ngày` | 161 |
| 2, 34, 30×150 |  |  | nhấn MINT | Dock (`Dock.dc.html`), tab đang hiện `claude`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 96×2 |  |  | MINT | khối |  |
| 96, 230, 144×2 |  |  | PANEL | khối |  |

### Weather-Dock — Weather · có dock

Nguồn `source/Weather-Dock.dc.html` · ảnh `screens/@2x/WeatherDock.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn SKY | Status bar `Thời tiết` · meta `LẶN 17:24` (MUTED, 63 px); gạch nhấn y 22 | 63 |
| 40, 32 | TL | `VT323-86` | INK | `29` | 68 |
| 110, 42 | TL | `VT323-32` | SKY | `°` | 13 |
| 228, 36 | TR | `JBMono-11` | MUTED | `cảm giác 33°` | 84 |
| 228, 54 | TR | `JBMono-11` | MUTED | `ẩm 74%` | 42 |
| 228, 72 | TR | `JBMono-11` | MUTED | `gió 12km` | 56 |
| 228, 90 | TR | `JBMono-11` | AMBER | `UV 7` | 28 |
| 40, 117, 16×16 |  |  | SKY | bitmap `PARTCLOUD` |  |
| 60, 118 | TL | `JBMono-13` | INK_DIM | `Ít mây` | 48 |
| 228, 119 | TR | `JBMono-11` | INK_DIM | `31°/24°` | 49 |
| 40, 140, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 150, 92×64 |  |  | PANEL | khối |  |
| 40, 150, 92×64 |  |  | LINE | viền 1 px |  |
| 86, 160 | MC | `JBMono-12B` | MUTED | `MAI` | 21 |
| 86, 180 | MC | `VT323-32` | INK | `30/24` | 65 |
| 86, 202 | MC | `JBMono-11` | MUTED | `Mưa rào` | 49 |
| 136, 150, 92×64 |  |  | PANEL | khối |  |
| 136, 150, 92×64 |  |  | LINE | viền 1 px |  |
| 182, 160 | MC | `JBMono-12B` | MUTED | `KIA` | 21 |
| 182, 180 | MC | `VT323-32` | INK | `28/23` | 65 |
| 182, 202 | MC | `JBMono-11` | MUTED | `Mưa` | 21 |
| 2, 34, 30×150 |  |  | nhấn SKY | Dock (`Dock.dc.html`), tab đang hiện `weather`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 96×2 |  |  | SKY | khối |  |
| 96, 230, 144×2 |  |  | PANEL | khối |  |

### Forecast-Dock — Forecast · có dock

Nguồn `source/Forecast-Dock.dc.html` · ảnh `screens/@2x/ForecastDock.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn SKY | Status bar `Dự báo` · meta `3 NGÀY` (MUTED, 42 px); gạch nhấn y 22 | 42 |
| 36, 32, 204×52 |  |  | PANEL | khối |  |
| 36, 32, 2×52 |  |  | CORAL | khối |  |
| 44, 36 | TL | `JBMono-16B` | INK | `NAY` | 30 |
| 44, 58, 16×16 |  |  | SKY | bitmap `PARTCLOUD` |  |
| 62, 60 | TL | `JBMono-11` | MUTED | `Ít mây` | 42 |
| 104, 42, 92×8 |  |  | PANEL2 | khối |  |
| 115, 42, 81×8 |  |  | SKY | khối |  |
| 206, 60 | TR | `JBMono-11` | MUTED | `24` | 14 |
| 228, 60 | TR | `JBMono-11` | INK | `31` | 14 |
| 36, 88, 2×52 |  |  | LINE | khối |  |
| 44, 92 | TL | `JBMono-16B` | INK_DIM | `MAI` | 30 |
| 44, 114, 16×16 |  |  | MUTED | bitmap `RAIN` |  |
| 62, 116 | TL | `JBMono-11` | MUTED | `Mưa rào` | 49 |
| 104, 98, 92×8 |  |  | PANEL2 | khối |  |
| 115, 98, 70×8 |  |  | MUTED | khối |  |
| 206, 116 | TR | `JBMono-11` | MUTED | `24` | 14 |
| 228, 116 | TR | `JBMono-11` | INK | `30` | 14 |
| 36, 144, 2×52 |  |  | LINE | khối |  |
| 44, 148 | TL | `JBMono-16B` | INK_DIM | `KIA` | 30 |
| 44, 170, 16×16 |  |  | MUTED | bitmap `RAIN` |  |
| 62, 172 | TL | `JBMono-11` | MUTED | `Mưa` | 21 |
| 104, 154, 92×8 |  |  | PANEL2 | khối |  |
| 104, 154, 58×8 |  |  | MUTED | khối |  |
| 206, 172 | TR | `JBMono-11` | MUTED | `23` | 14 |
| 228, 172 | TR | `JBMono-11` | INK | `28` | 14 |
| 2, 34, 30×150 |  |  | nhấn SKY | Dock (`Dock.dc.html`), tab đang hiện `weather`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 96×2 |  |  | SKY | khối |  |
| 96, 230, 144×2 |  |  | PANEL | khối |  |

### Clock-Dock — Clock · có dock

Nguồn `source/Clock-Dock.dc.html` · ảnh `screens/@2x/ClockDock.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn AMBER | Status bar `Đồng hồ` · meta `tuần 48` (MUTED, 49 px); gạch nhấn y 22 | 49 |
| 134, 32 | TC | `JBMono-11` | MUTED | `THỨ TƯ · 25/11` | 98 |
| 49, 50 | TL | `VT323-86` | INK | `14` | 68 |
| 117, 50 | TL | `VT323-86` | CORAL | `:` | 34 |
| 151, 50 | TL | `VT323-86` | INK | `32` | 68 |
| 134, 148 | MC | `JBMono-13` | INK_DIM | `chào buổi chiều, bạn` | 160 |
| 52, 178, 4×4 |  |  | AMBER | khối |  |
| 59, 178, 4×4 |  |  | AMBER | khối |  |
| 66, 178, 4×4 |  |  | AMBER | khối |  |
| 73, 178, 4×4 |  |  | AMBER | khối |  |
| 80, 178, 4×4 |  |  | AMBER | khối |  |
| 87, 178, 4×4 |  |  | AMBER | khối |  |
| 94, 178, 4×4 |  |  | AMBER | khối |  |
| 101, 178, 4×4 |  |  | AMBER | khối |  |
| 108, 178, 4×4 |  |  | AMBER | khối |  |
| 115, 178, 4×4 |  |  | AMBER | khối |  |
| 122, 178, 4×4 |  |  | AMBER | khối |  |
| 129, 178, 4×4 |  |  | AMBER | khối |  |
| 136, 178, 4×4 |  |  | AMBER | khối |  |
| 143, 178, 4×4 |  |  | AMBER | khối |  |
| 150, 178, 4×4 |  |  | INK | khối |  |
| 157, 178, 4×4 |  |  | LINE | khối |  |
| 164, 178, 4×4 |  |  | LINE | khối |  |
| 171, 178, 4×4 |  |  | LINE | khối |  |
| 178, 178, 4×4 |  |  | LINE | khối |  |
| 185, 178, 4×4 |  |  | LINE | khối |  |
| 192, 178, 4×4 |  |  | LINE | khối |  |
| 199, 178, 4×4 |  |  | LINE | khối |  |
| 206, 178, 4×4 |  |  | LINE | khối |  |
| 213, 178, 4×4 |  |  | LINE | khối |  |
| 2, 34, 30×150 |  |  | nhấn AMBER | Dock (`Dock.dc.html`), tab đang hiện `clock`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 96×2 |  |  | AMBER | khối |  |
| 96, 230, 144×2 |  |  | PANEL | khối |  |

### Info-Dock — Info · có dock

Nguồn `source/Info-Dock.dc.html` · ảnh `screens/@2x/InfoDock.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn MINT | Status bar `Thông tin` · meta `CHẨN ĐOÁN` (MUTED, 63 px); gạch nhấn y 22 | 63 |
| 40, 30 | TL | `JBMono-11` | MUTED | `IP` | 14 |
| 228, 30 | TR | `JBMono-11` | INK | `192.168.100.40` | 98 |
| 40, 45, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 49 | TL | `JBMono-11` | MUTED | `SSID` | 28 |
| 228, 49 | TR | `JBMono-11` | INK | `Anh Viet` | 56 |
| 40, 64, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 68 | TL | `JBMono-11` | MUTED | `Sóng` | 28 |
| 228, 68 | TR | `JBMono-11` | MINT | `-58 dBm` | 49 |
| 40, 83, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 87 | TL | `JBMono-11` | MUTED | `Đã chạy` | 49 |
| 228, 87 | TR | `JBMono-11` | INK_DIM | `312P` | 28 |
| 40, 102, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 106 | TL | `JBMono-11` | MUTED | `Bộ nhớ` | 42 |
| 228, 106 | TR | `JBMono-11` | AMBER | `27K trống` | 63 |
| 40, 121, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 125 | TL | `JBMono-11` | MUTED | `Khối lớn` | 56 |
| 228, 125 | TR | `JBMono-11` | INK_DIM | `21K` | 21 |
| 40, 140, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 144 | TL | `JBMono-11` | MUTED | `Firmware` | 56 |
| 228, 144 | TR | `JBMono-11` | INK_DIM | `v0.23.0-glimmer` | 105 |
| 40, 159, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 163 | TL | `JBMono-11` | MUTED | `Kênh` | 28 |
| 228, 163 | TR | `JBMono-11` | INK_DIM | `9 / 13` | 42 |
| 40, 178, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 182 | TL | `JBMono-11` | MUTED | `Cập nhật` | 56 |
| 228, 182 | TR | `JBMono-11` | INK_DIM | `1P trước` | 56 |
| 40, 197, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 201 | TL | `JBMono-11` | MUTED | `Lần tới` | 49 |
| 228, 201 | TR | `JBMono-11` | MINT | `sau 4P` | 42 |
| 2, 34, 30×150 |  |  | nhấn MINT | Dock (`Dock.dc.html`), tab đang hiện `none`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 96×2 |  |  | MINT | khối |  |
| 96, 230, 144×2 |  |  | PANEL | khối |  |

### Setup-Dock — Setup · có dock

Nguồn `source/Setup-Dock.dc.html` · ảnh `screens/@2x/SetupDock.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn AMBER | Status bar `glimmer` · meta `CÀI ĐẶT` (AMBER, 49 px); gạch nhấn y 22 | 49 |
| 134, 40 | MC | `JBMono-12B` | AMBER | `HOÀN TẤT CÀI ĐẶT` | 112 |
| 44, 63, 11×11 |  |  | LINE | viền 1 px |  |
| 62, 62 | TL | `JBMono-11` | INK | `Khóa Claude` | 77 |
| 228, 62 | TR | `JBMono-11` | MUTED | `Tài khoản` | 63 |
| 44, 85, 11×11 |  |  | LINE | viền 1 px |  |
| 62, 84 | TL | `JBMono-11` | INK | `Token Codex` | 77 |
| 228, 84 | TR | `JBMono-11` | MUTED | `Tài khoản` | 63 |
| 44, 107, 11×11 |  |  | MINT | viền 1 px |  |
| 47, 110, 5×5 |  |  | MINT | khối |  |
| 62, 106 | TL | `JBMono-11` | INK_DIM | `Thời tiết` | 63 |
| 228, 106 | TR | `JBMono-11` | MUTED | `Vị trí & giờ` | 84 |
| 52, 140, w 164 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 134, 158 | MC | `JBMono-11` | MUTED | `mở trong trình duyệt` | 140 |
| 134, 180 | MC | `JBMono-16B` | SKY | `glimmer.local` | 130 |
| 134, 202 | MC | `JBMono-11` | MUTED | `192.168.100.40` | 98 |
| 2, 34, 30×150 |  |  | nhấn MUTED | Dock (`Dock.dc.html`), tab đang hiện `claude`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 96×2 |  |  | MUTED | khối |  |
| 96, 230, 144×2 |  |  | PANEL | khối |  |

## 16. Ảnh — kênh `Photo` (skill `photo`)

> **P-2026-11-25.7 — Kênh mới:** skill thứ 2 sau agent: hiện ảnh người dùng gửi lên, mỗi slide một ảnh, lượt sau ảnh kế tiếp. Bố cục có dock (đã chọn B). Màu nhấn MINT.

Ảnh JPEG baseline vuông 188×188 (máy không co giãn — app / trang web cắt và thu nhỏ trước khi gửi), lưu LittleFS. `draw()` giải mã từng khối thẳng ra màn một lần; `tick()` không vẽ gì. Không có ảnh → `Photo-Empty`. Ảnh lỗi / không đọc được → bỏ qua sang ảnh kế tiếp; hết ảnh đọc được → `Photo-Empty`.

### Photo — Ảnh · có dock

Nguồn `source/Photo.dc.html` (ảnh minh hoạ `source/SamplePhoto.dc.html`) · ảnh `screens/@2x/Photo.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / TR | `JBMono-12B` / `JBMono-11` | INK / MUTED; gạch nhấn MINT | Status bar `Ảnh`; meta `2/5` TR (236, 5) = ảnh thứ mấy / tổng; gạch nhấn y 22 | 21 / 21 |
| 40, 28, 188×188 |  |  | ảnh người dùng | ảnh JPEG đúng 188×188, vẽ thẳng (không viền, không bo góc); khoảng trống quanh ảnh BG |  |
| 2, 34, 30×150 |  |  | PANEL / LINE | Dock (§15), tab `photo` đang hiện: ô PANEL2 + vạch MINT; Claude huy hiệu AMBER nếu có agent chờ |  |
| 0, 230, 240×2 |  |  | MINT / PANEL | vạch tiến độ slide (vẽ ở 40 %), phần chưa chạy PANEL |  |

### Photo-Empty — Ảnh · chưa có ảnh

Nguồn `source/Photo-Empty.dc.html` · ảnh `screens/@2x/PhotoEmpty.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC | `JBMono-12B` | INK; gạch nhấn MINT | Status bar `Ảnh`, không meta | 21 |
| 110, 56, 48×33 |  |  | LINE | icon khung ảnh ×3 (lưới 16×11 như icon dock, ô 3 px) |  |
| 134, 104 | TC | `JBMono-16B` | MUTED | `Chưa có ảnh` | 110 |
| 134, 132 | TC | `JBMono-11` | INK_DIM | `Gửi ảnh từ app glimmer` | 154 |
| 134, 148 | TC | `JBMono-11` | MUTED | `hoặc glimmer.local` | 126 |
| 2, 34, 30×150 |  |  | PANEL / LINE | Dock (§15), tab `photo` đang hiện: ô PANEL2 + vạch MINT; Claude huy hiệu AMBER nếu có agent chờ |  |
| 0, 230, 240×2 |  |  | MUTED | vạch liền MUTED (như Setup) — không có gì để xem |  |

## 17. Kiểu XP (Luna) — giao diện toàn máy

> **P-2026-11-28.28 — Trình quản lý tác vụ:** cửa sổ mới kiểu Windows Task Manager (tab Ứng dụng / Hiệu năng / Mạng) — xem mục XP-TaskMgr.

> **P-2026-11-26.23 — dọn thiết kế:** bỏ 76 màn lỗi thời khỏi canvas và `source/` (màn kiểu cũ trước XP, màn XP đã có bản thay); XP-Desk-All = desktop hiện hành (Claude thu nhỏ); Thời tiết lỗi / cũ / Dự báo chưa có vẽ lại theo cửa sổ có tab. Các mục đặc tả của màn đã bỏ giữ làm lịch sử.

> **P-2026-11-26.22 — Ngày và Giờ chạm được:** 3 tab (Ngày và giờ / Múi giờ / Internet), tháng + năm tách, danh sách tháng, chọn múi giờ, đồng bộ lại — xem mục XP-Real.

> **P-2026-11-26.21 — bỏ bong bóng thời tiết:** xem mục XP-Desk-Tray.

> **P-2026-11-26.20 — Start menu kiểu XP:** app chạm start → thiết bị vẽ Start menu 2 cột + menu con Tất cả chương trình — xem mục XP-Start.

> **P-2026-11-26.19 — biểu tượng desktop kiểu XP:** Codex / Ảnh / Thùng rác thành bitmap màu 32×23 — xem mục XP-Real.

> **P-2026-11-26.18 — nhãn desktop không có %:** `Claude` / `Codex` chỉ là tên — xem mục XP-Real.

> **P-2026-11-26.17 — Đồng hồ, Thời tiết, Dự báo, Đêm, desktop theo XP thật:** Đồng hồ = hộp thoại Ngày và Giờ; Thời tiết = trang thuộc tính có tab; Dự báo = tab Dự báo, danh sách Chi tiết; Đêm = trình bảo vệ màn hình; desktop bỏ biểu tượng Thời tiết / Đồng hồ. Xem mục XP-Real. Thay phần tương ứng của XP-Weather, XP-Forecast, XP-Clock, XP-Desk.

> **P-2026-11-26.16 — Mở cửa sổ như XP:** nút lún trước, thanh tiêu đề bay khi khôi phục / thu nhỏ, khung trống trước nội dung, con trỏ chờ, đang tải kiểu hộp tải về. Xem mục XP-Open (thay phần "Đang tải" ở Thành phần cho các cửa sổ chưa có số liệu).

> **P-2026-11-26.15 — Thời tiết thành biểu tượng khay, bong bóng hiện tạm như XP:** bỏ bong bóng luôn mở trên desktop; khay có biểu tượng thời tiết, bong bóng XP thật hiện ~10 s. Xem mục XP-Desk-Tray. Thay phần bong bóng của P-2026-11-26.12 / .14.

> **P-2026-11-26.14 — Desktop theo skill, thanh tác vụ = cửa sổ đang mở:** biểu tượng desktop theo skill bật (2 cột), biểu tượng đang chọn; nút thanh tác vụ là cửa sổ đang mở, bỏ vạch tiến độ; menu chuột phải (desktop, cửa sổ); nút □ mờ. Xem mục XP-Desk / XP-Menu.

> **P-2026-11-26.13 — Clawd làm việc theo GIF:** Đang chạy = lấy laptop ra (một lần) rồi gõ lặp; xong = ngủ ngay. Clawd ngủ nâng lên y 44, `4NG` không còn dời sang trái.

> **P-2026-11-26.12 — Màn đầu kiểu desktop:** `XP-Desktop` thay kênh Trang chủ: nền = ảnh JPEG người dùng (240×214), nền dự phòng vẽ pixel; biểu tượng desktop; bong bóng thời tiết ở khay.

> **P-2026-11-26.11 — Màu theo XP, mắt Clawd đen:** số to (38%, 41%, 71%) màu đen, màu báo mức chỉ ở thanh tiến độ; chữ mờ xpDim = `#ACA899`; link xpLink = `#0066CC`; mắt Clawd (và miệng khi vui) luôn đen trên mọi nền.

> **P-2026-11-26.10 — Góc khởi động:** Clawd trắng ở góc dưới phải màn khởi động đổi thành chữ `Clawdsoft` nghiêng trắng.

> **P-2026-11-26.9 — Nút start + màn hệ thống theo ảnh XP thật + tên Clawdsoft Window xp:** nút start 68 px có cờ 4 ô (14×12) + chữ `start` nghiêng; 4 nút skill 28 px tại x 71 + 30k; màn khởi động / welcome / đăng nhập / cập nhật vẽ lại theo ảnh chụp XP, bỏ dòng thông tin (phiên bản, tên mạng, %, lần thử); logo `Clawdsoft` / `Window` / `xp` / `Professional`.

> **P-2026-11-26.8 — Kiểu XP bản A:** mọi kênh vẽ lại thành cửa sổ kiểu XP (thanh tiêu đề xanh, thân be, thanh tác vụ). Thay §1–16 khi phía code áp; bố cục cũ giữ làm tham chiếu dữ liệu.

Lấy dáng XP; không dùng tên, chữ hay font của Microsoft (logo đọc là **Clawdsoft Window xp**). Font JetBrains Mono / VT323; chữ nghiêng (`start`, `welcome`, `Window`, `đang cập nhật...`) là bitmap 1-bit sinh từ font thật, nghiêng 1 px / 3 hàng. Màu: token `themeXP.color` (RGB565).

**Khung chung (mọi kênh có cửa sổ):**

| phần | tọa độ | màu / font |
|---|---|---|
| thanh tiêu đề | y 0–21, 5 dải: y0 · y1–2 · y3–18 · y19–20 · y21 | xpTitleHi · xpTitleLight · xpTitle · xpTitleDark · xpTitleEdge |
| icon tiêu đề | (4, 6) Clawd 18×10; icon skill căn tâm (13, 11) | CLAWD / white |
| chữ tiêu đề | TL (24, 4), bóng (25, 5); tối đa 156 px | `JBMono-12B` white, bóng xpTitleShadow |
| 3 nút | 16×16 tại x 184 / 202 / 220, y 3; viền 1 px white | thu nhỏ, phóng to xpTitleLight; đóng xpClose |
| khung + thân | khung x 0–1 / 238–239, y 22–213; thân x 2–237, y 22–213 (nội dung x 10–229) | xpFrame; xpBody |
| thanh trạng thái (tuỳ kênh) | đường y 196 xpStatusLine, y 197 white; chữ TL (8, 199), phải TR (231, 199) + vạch ngăn | `JBMono-11` black |
| thanh tác vụ | y 214–239, dải y214 · y215–216 · y217–236 · y237–239 | xpTaskHi · xpTaskLight · xpTask · xpTaskDark |
| nút start | x 0–67, dải xpStartHi / xpStart / xpStartDark, mép phải bo tròn (thụt 5,3,2,1,1 … 1,1,2,3,5) viền xpStartDark; cờ 14×12 tại (7, 221); chữ `start` nghiêng (25, 221) + bóng (26, 222) | cờ xpFlagRed / Green / Blue / Yellow; chữ white, bóng xpStartShadow |
| nút skill | 28×20 tại x 71 + 30k, y 217 (Claude, Ảnh, Thời tiết, Đồng hồ); Clawd (x+5, 222), icon căn tâm (x+14, 227) | thường xpBtnEdge/xpBtn; đang hiện xpBtnPressedEdge/xpBtnPressed; thẻ cần bạn xpFlashEdge/xpFlash |
| tiến độ slide | (x+1, 234) cao 2, dài 26 × tiến độ — thay vạch y 230 | màu nhấn kênh |
| huy hiệu agent chờ | 9×9 vạt góc (x+18, 215), chữ số 3×5 BG (x+21, 217), trên nút Claude | AMBER |
| khay giờ | x 196–239, viền trái xpTrayEdge, đường trên xpTrayHi; `14:32` TC (218, 221) | xpTray; `JBMono-11` white |

**Cờ (14×12, ô 1 px; R/G/B/Y = xpFlagRed/Green/Blue/Yellow):**

```
........GGGGG.
...RRRR.GGGGGG
.RRRRRR.GGGGGG
.RRRRRR.GGGGGG
.RRRRRR.GGGGGG
RRRRRRR.......
.......YYYYYY.
BBBBBB.YYYYYY.
BBBBBB.YYYYYY.
BBBBBB.YYYYYY.
BBBBBB.YYYYY..
.BBBB.........
```

**Thành phần:**

- **Số to**: VT323-86 / VT323-44 màu black (như chữ hộp thoại XP); màu báo mức (xpGreen / xpAmber / xpRed / xpLilac) chỉ ở thanh tiến độ khối.
- **Clawd**: ô mắt — và lỗ nửa ô của mắt / miệng vui — luôn tô `#000000` (không lấy màu nền be / xanh), ở mọi cỡ: tiêu đề, nút thanh tác vụ, màn Claude, thẻ agent, ô người dùng.
- **Thanh tiến độ XP**: viền xpFieldBorder, nền white, 9 khối rời (khe 2 px; cao ≤ 6 px khe 1 px), khối sáng khi `pct > i·11.11`.
- **Groupbox**: viền 1 px xpGroup, nhãn `JBMono-11` xpGroupLabel tại (x+7, y−6) trên nền thân.
- **Ô trắng / danh sách**: viền xpFieldBorder, nền white; dòng chọn xpSelect chữ white; dòng kẻ xpRowLine; dòng hôm nay xpRowHi.
- **Hộp thoại**: icon 24×24 tại (14, 36) — tròn xpIconError dấu X white / tam giác xpIconWarn dấu ! đen / tròn xpIconInfo chữ i white; tiêu đề `JBMono-12B` (48, 38); dòng `JBMono-11` từ (48, 58) bước 16; link `JBMono-12B` xpLink gạch chân. Không nút.
- **Đang tải**: chữ `JBMono-12B` TC (120, 92); ô 140×14 tại (50, 116), 3 khối xpBar sáng chạy qua 9 ô, 1 ô / 0,2 s.
- **Dữ liệu cũ**: tiêu đề thêm ` · cũ 14P`; số liệu xpDim (`#ACA899`). **Dải thông báo**: nền xpInfoBar cao 14, icon ! xpAmber, chữ xpRed.
- **Thẻ agent**: cửa sổ tên theo loại; Clawd ô 6 tại (66, 50); tiêu đề `JBMono-16B` TC (120, 120); chi tiết TC (120, 146); chân TC (120, 176). Cần bạn: nút Claude sáng cam.
- **Clawd ngủ** (chưa có project / xong hết): Clawd mắt `sleep` ô 4 tại (156, 44); Zz động như §6, mỗi khung x − 2, y = 24 + round((y − 26) × 14 / 26) (bay trong y 24–38); `4NG` giữ TR (229, 84).
- **Clawd làm việc** (project đầu bảng Đang chạy): xem mục XP-Claude-Laptop.

**Màn hệ thống (không cửa sổ), theo ảnh chụp XP thật — không dòng thông tin:**

- **Khởi động** (`XP-Splash`): nền đen; cờ ×3 (42×36) trên-phải; `Clawdsoft` 11 white, `Window` 16B white, `xp` 11 xpWelcomeOrange chỉ số trên, `Professional` 11 xpWelcomeOrange — cụm căn giữa (x0 = (240 − (w + 16)) / 2); ô 56×11 tại (92, 152) viền xpBootGrey góc vạt, 3 khối xanh 6×5 bước 8 chạy qua lại; góc dưới phải chữ `Clawdsoft` nghiêng white (bitmap, mép phải x 231, y 226) — chỗ tên hãng của XP.
- **Welcome** (`XP-Connecting`): nền xpWelcome; dải trên y 0–29 + đường y 30, dải dưới y 206–239 xpWelcomeBand; viền y 205–206 cam giữa nhạt dần ra hai bên; chỉ chữ `welcome` nghiêng white + bóng tại (70, 106).
- **Đăng nhập** (`XP-SetupMode`) — **P-2026-11-28.26: mã QR giữa màn, xem mục XP-SetupMode** (dòng dưới là bản cũ): nền welcome; trái cờ ×2 + `Window` nghiêng + `xp` + `Để bắt đầu, kết nối Wi-Fi`; vạch dọc x 116 mờ hai đầu; phải ô chọn (ảnh khung trắng + `glimmer-setup` + `192.168.4.1` nhỏ); dưới-trái nút nguồn đỏ + `Cài đặt Wi-Fi`. Chi tiết: token `themeXP.welcome`.
- **Cập nhật** (`XP-OtaProgress`): nền welcome; `đang cập nhật...` nghiêng (20, 96); `Đừng tắt hay rút điện máy.` 11 TC (120, 130).
- **Đêm** (`XP-Night`): nền đen, chữ #4D4D4D, không cửa sổ.

**Các màn** (nguồn `source/<Màn>.dc.html`, ảnh `screens/@2x/<Màn bỏ gạch>.png`; bảng = chữ vẽ bằng font, đo bằng VLW thật — chữ nghiêng là bitmap, không có trong bảng):

### XP-Claude-A — Kiểu XP · A: thân cửa sổ sáng (be như XP)

Nguồn `source/XP-Claude-A.dc.html` · ảnh `screens/@2x/XPClaudeA.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Claude` | 42 |
| 24, 4 | TL | `JBMono-12B` | `Claude` | 42 |
| 10, 28 | TL | `JBMono-11` | `Hạn mức tuần` | 84 |
| 10, 40 | TL | `VT323-86` | `38` | 68 |
| 80, 70 | TL | `VT323-44` | `%` | 18 |
| 229, 84 | TR | `JBMono-12B` | `4NG` | 21 |
| 17, 122 | TL | `JBMono-11` | `Phiên 5 giờ` | 77 |
| 224, 135 | TR | `JBMono-11` | `12% · 2G 14P` | 84 |
| 225, 168 | TR | `JBMono-11` | `2P` | 14 |
| 23, 168 | TL | `JBMono-11` | `glimmer` | 49 |
| 79, 168 | TL | `JBMono-11` | `Cần duyệt · Bash` | 112 |
| 225, 181 | TR | `JBMono-11` | `5P` | 14 |
| 23, 181 | TL | `JBMono-11` | `TieuMac3d` | 63 |
| 93, 181 | TL | `JBMono-11` | `Đang chạy` | 63 |
| 225, 194 | TR | `JBMono-11` | `1G` | 14 |
| 23, 194 | TL | `JBMono-11` | `api` | 21 |
| 51, 194 | TL | `JBMono-11` | `Xong` | 28 |

### XP-Home — Kiểu XP · Trang chủ

Nguồn `source/XP-Home.dc.html` · ảnh `screens/@2x/XPHome.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Trang chủ` | 63 |
| 24, 4 | TL | `JBMono-12B` | `Trang chủ` | 63 |
| 10, 30 | TL | `VT323-86` | `14:32` | 170 |
| 229, 66 | TR | `JBMono-12B` | `29°` | 21 |
| 10, 100 | TL | `JBMono-11` | `Thứ Tư 25/11` | 84 |
| 229, 100 | TR | `JBMono-11` | `Ít mây` | 42 |
| 17, 118 | TL | `JBMono-11` | `Hạn mức` | 49 |
| 18, 135 | TL | `JBMono-11` | `Claude` | 42 |
| 222, 135 | TR | `JBMono-11` | `38%` | 21 |
| 18, 159 | TL | `JBMono-11` | `Codex` | 35 |
| 222, 159 | TR | `JBMono-11` | `71%` | 21 |
| 8, 199 | TL | `JBMono-11` | `192.168.100.40` | 98 |
| 231, 199 | TR | `JBMono-11` | `Còn 9G hôm nay` | 98 |

### XP-Agents — Kiểu XP · Tác tử

Nguồn `source/XP-Agents.dc.html` · ảnh `screens/@2x/XPAgents.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Tác tử` | 42 |
| 24, 4 | TL | `JBMono-12B` | `Tác tử` | 42 |
| 32, 36 | TL | `JBMono-12B` | `Cần bạn · Bash` | 98 |
| 32, 56 | TL | `JBMono-11` | `claude · glimmer · 2p` | 147 |
| 32, 88 | TL | `JBMono-12B` | `Tests · 64%` | 77 |
| 32, 108 | TL | `JBMono-11` | `codex · api · 5p` | 112 |
| 32, 140 | TL | `JBMono-12B` | `Xong` | 28 |
| 32, 160 | TL | `JBMono-11` | `claude · TieuMac3d · 12p` | 168 |
| 8, 199 | TL | `JBMono-11` | `3 mục` | 35 |
| 231, 199 | TR | `JBMono-11` | `1 cần duyệt` | 77 |

### XP-Codex — Kiểu XP · Codex

Nguồn `source/XP-Codex.dc.html` · ảnh `screens/@2x/XPCodex.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Codex` | 35 |
| 24, 4 | TL | `JBMono-12B` | `Codex` | 35 |
| 10, 28 | TL | `JBMono-11` | `Hạn mức tuần` | 84 |
| 10, 40 | TL | `VT323-86` | `41` | 68 |
| 80, 70 | TL | `VT323-44` | `%` | 18 |
| 229, 84 | TR | `JBMono-12B` | `3NG` | 21 |
| 229, 68 | TR | `JBMono-11` | `đặt lại sau` | 77 |
| 17, 122 | TL | `JBMono-11` | `Phiên 5 giờ` | 77 |
| 18, 137 | TL | `JBMono-11` | `Spark` | 35 |
| 222, 137 | TR | `JBMono-11` | `2G 14P` | 42 |
| 17, 164 | TL | `JBMono-11` | `Đặt lại tuần` | 84 |
| 18, 177 | TL | `JBMono-11` | `còn 2 · 3NG` | 77 |
| 222, 177 | TR | `JBMono-11` | `~70% khi đặt lại` | 112 |

### XP-AI — Kiểu XP · AI hôm nay

Nguồn `source/XP-AI.dc.html` · ảnh `screens/@2x/XPAI.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `AI hôm nay` | 70 |
| 24, 4 | TL | `JBMono-12B` | `AI hôm nay` | 70 |
| 10, 28 | TL | `JBMono-11` | `Chi phí hôm nay` | 105 |
| 10, 40 | TL | `VT323-86` | `$4.20` | 170 |
| 17, 114 | TL | `JBMono-11` | `Claude` | 42 |
| 18, 128 | TL | `VT323-44` | `38%` | 54 |
| 131, 114 | TL | `JBMono-11` | `Codex` | 35 |
| 132, 128 | TL | `VT323-44` | `71%` | 54 |
| 8, 199 | TL | `JBMono-11` | `Dùng Claude` | 77 |
| 231, 199 | TR | `JBMono-11` | `CL 2G 14P · CX 3NG` | 126 |

### XP-Trend — Kiểu XP · Xu hướng

Nguồn `source/XP-Trend.dc.html` · ảnh `screens/@2x/XPTrend.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Xu hướng` | 56 |
| 24, 4 | TL | `JBMono-12B` | `Xu hướng` | 56 |
| 10, 28 | TL | `JBMono-11` | `7 ngày · % hạn mức tuần` | 161 |
| 28, 177 | TC | `JBMono-11` | `T5` | 14 |
| 58, 177 | TC | `JBMono-11` | `T6` | 14 |
| 88, 177 | TC | `JBMono-11` | `T7` | 14 |
| 118, 177 | TC | `JBMono-11` | `CN` | 14 |
| 148, 177 | TC | `JBMono-11` | `T2` | 14 |
| 178, 177 | TC | `JBMono-11` | `T3` | 14 |
| 208, 177 | TC | `JBMono-11` | `T4` | 14 |
| 24, 46 | TL | `JBMono-11` | `Claude` | 42 |
| 96, 46 | TL | `JBMono-11` | `Codex` | 35 |
| 8, 199 | TL | `JBMono-11` | `Hôm nay CL 9 · CX 4` | 133 |
| 231, 199 | TR | `JBMono-11` | `Đỉnh T2` | 49 |

### XP-Weather — Kiểu XP · Thời tiết

Nguồn `source/XP-Weather.dc.html` · ảnh `screens/@2x/XPWeather.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Thời tiết` | 63 |
| 24, 4 | TL | `JBMono-12B` | `Thời tiết` | 63 |
| 10, 28 | TL | `VT323-86` | `29°` | 102 |
| 12, 100 | TL | `JBMono-13` | `Ít mây` | 48 |
| 12, 118 | TL | `JBMono-11` | `31° / 24°` | 63 |
| 229, 32 | TR | `JBMono-11` | `cảm giác 33°` | 84 |
| 229, 50 | TR | `JBMono-11` | `ẩm 74%` | 42 |
| 229, 68 | TR | `JBMono-11` | `gió 12km` | 56 |
| 229, 86 | TR | `JBMono-11` | `UV 7` | 28 |
| 17, 138 | TL | `JBMono-11` | `Mai` | 21 |
| 63, 150 | TC | `VT323-32` | `30/24` | 65 |
| 63, 175 | TC | `JBMono-11` | `Mưa rào` | 49 |
| 131, 138 | TL | `JBMono-11` | `Kia` | 21 |
| 177, 150 | TC | `VT323-32` | `28/23` | 65 |
| 177, 175 | TC | `JBMono-11` | `Mưa` | 21 |
| 8, 199 | TL | `JBMono-11` | `Mặt trời lặn 17:24` | 126 |

### XP-Forecast — Kiểu XP · Dự báo

Nguồn `source/XP-Forecast.dc.html` · ảnh `screens/@2x/XPForecast.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Dự báo` | 42 |
| 24, 4 | TL | `JBMono-12B` | `Dự báo` | 42 |
| 18, 36 | TL | `JBMono-12B` | `Nay` | 21 |
| 18, 56 | TL | `JBMono-11` | `Ít mây` | 42 |
| 112, 48 | TR | `JBMono-11` | `24°` | 21 |
| 222, 48 | TR | `JBMono-11` | `31°` | 21 |
| 18, 89 | TL | `JBMono-12B` | `Mai` | 21 |
| 18, 109 | TL | `JBMono-11` | `Mưa rào` | 49 |
| 112, 101 | TR | `JBMono-11` | `24°` | 21 |
| 222, 101 | TR | `JBMono-11` | `30°` | 21 |
| 18, 142 | TL | `JBMono-12B` | `Kia` | 21 |
| 18, 162 | TL | `JBMono-11` | `Mưa` | 21 |
| 112, 154 | TR | `JBMono-11` | `23°` | 21 |
| 222, 154 | TR | `JBMono-11` | `28°` | 21 |
| 8, 199 | TL | `JBMono-11` | `3 ngày tới` | 70 |

### XP-Clock — Kiểu XP · Đồng hồ

Nguồn `source/XP-Clock.dc.html` · ảnh `screens/@2x/XPClock.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Đồng hồ` | 49 |
| 24, 4 | TL | `JBMono-12B` | `Đồng hồ` | 49 |
| 120, 30 | TC | `JBMono-12B` | `Thứ Tư · 25/11` | 98 |
| 120, 60 | TC | `VT323-86` | `14:32` | 170 |
| 120, 152 | TC | `JBMono-13` | `chào buổi chiều, bạn` | 160 |
| 8, 199 | TL | `JBMono-11` | `Tuần 48` | 49 |
| 231, 199 | TR | `JBMono-11` | `GMT+7` | 35 |

### XP-Info — Kiểu XP · Thông tin

Nguồn `source/XP-Info.dc.html` · ảnh `screens/@2x/XPInfo.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Thông tin` | 63 |
| 24, 4 | TL | `JBMono-12B` | `Thông tin` | 63 |
| 16, 31 | TL | `JBMono-11` | `IP` | 14 |
| 88, 31 | TL | `JBMono-11` | `192.168.100.40` | 98 |
| 16, 48 | TL | `JBMono-11` | `SSID` | 28 |
| 88, 48 | TL | `JBMono-11` | `Anh Viet` | 56 |
| 16, 66 | TL | `JBMono-11` | `Sóng` | 28 |
| 88, 66 | TL | `JBMono-11` | `-58 dBm` | 49 |
| 16, 83 | TL | `JBMono-11` | `Đã chạy` | 49 |
| 88, 83 | TL | `JBMono-11` | `312P` | 28 |
| 16, 101 | TL | `JBMono-11` | `Bộ nhớ` | 42 |
| 88, 101 | TL | `JBMono-11` | `27K trống` | 63 |
| 16, 118 | TL | `JBMono-11` | `Khối lớn` | 56 |
| 88, 118 | TL | `JBMono-11` | `21K` | 21 |
| 16, 136 | TL | `JBMono-11` | `Firmware` | 56 |
| 88, 136 | TL | `JBMono-11` | `v0.23.0-glimmer` | 105 |
| 16, 153 | TL | `JBMono-11` | `Kênh` | 28 |
| 88, 153 | TL | `JBMono-11` | `9 / 13` | 42 |
| 16, 171 | TL | `JBMono-11` | `Cập nhật` | 56 |
| 88, 171 | TL | `JBMono-11` | `1P trước` | 56 |
| 16, 188 | TL | `JBMono-11` | `Lần tới` | 49 |
| 88, 188 | TL | `JBMono-11` | `sau 4P` | 42 |

### XP-Setup — Kiểu XP · Cài đặt

Nguồn `source/XP-Setup.dc.html` · ảnh `screens/@2x/XPSetup.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Cài đặt` | 49 |
| 24, 4 | TL | `JBMono-12B` | `Cài đặt` | 49 |
| 12, 30 | TL | `JBMono-12B` | `Hoàn tất cài đặt` | 112 |
| 12, 48 | TL | `JBMono-11` | `Còn 2 bước nữa là xong.` | 161 |
| 34, 72 | TL | `JBMono-11` | `Khóa Claude` | 77 |
| 34, 94 | TL | `JBMono-11` | `Token Codex` | 77 |
| 34, 116 | TL | `JBMono-11` | `Thời tiết, vị trí, giờ` | 154 |
| 17, 144 | TL | `JBMono-11` | `Mở trong trình duyệt` | 140 |
| 18, 159 | TL | `JBMono-12B` | `glimmer.local` | 91 |
| 222, 176 | TR | `JBMono-11` | `192.168.100.40` | 98 |

### XP-Photo — Kiểu XP · Ảnh

> **P-2026-11-28.27 — ảnh từ điện thoại** (phiếu `docs/phieu_panel/2026-11-27-anh-tu-dien-thoai.md`; theo *Windows Picture
> and Fax Viewer*: giữ ảnh cũ tới khi ảnh mới mở xong, con trỏ đồng hồ cát, không màn trống). Ảnh 188×188 tại (26, 24) như cũ.
>
> | trạng thái | nguồn / ảnh | tiêu đề (`JBMono-12B` white TL (24, 4), bóng (+1, +1)) | khác |
> |---|---|---|---|
> | từ điện thoại (`source.state` online, `remote`) | `XP-Photo-Phone` · `XPPhotoPhone.png` | `Ảnh · 3/40` 70 px — `index/count` của kho trên app | — |
> | đang xin ảnh kế tiếp (≤ 3 s) | `XP-Photo-Asking` · `XPPhotoAsking.png` | giữ tiêu đề của ảnh đang hiện | ảnh cũ giữ nguyên; con trỏ chờ XP-Open: mũi tên 12×19 tại (132, 160) + đồng hồ cát 9×12 tại (142, 169), 4 khung × 200 ms (chế độ chuột: con trỏ của app thành chờ tại chỗ, `Cursor::busy`). Ảnh mới về → vẽ đè ảnh, con trỏ mất (vẽ lại vùng con trỏ). Không hộp tải về. |
> | điện thoại vắng (offline, chiếu ảnh đã lưu) | `XP-Photo-Offline` · `XPPhotoOffline.png` | `Ảnh · 3/8 · đã lưu` 126 px — `current/total` của ảnh trên máy | không thanh trạng thái (ảnh chiếm hết thân) |
> | kho rỗng (app + máy) | `XP-Photo-Empty` · `XPPhotoEmpty.png` | `Ảnh` | `Chưa có ảnh` 16B TC (120, 100) 110 px như cũ; `Thêm ảnh trong app glimmer` 11 TC (120, 128) 182 px; bỏ `hoặc` + `glimmer.local` |
>
> Đổi trạng thái online ↔ offline chỉ vẽ lại tiêu đề (vùng chữ x 22–181, y 2–19), không vẽ lại ảnh.


Nguồn `source/XP-Photo.dc.html` · ảnh `screens/@2x/XPPhoto.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Ảnh · 2/5` | 63 |
| 24, 4 | TL | `JBMono-12B` | `Ảnh · 2/5` | 63 |

### XP-Attention — Kiểu XP · thẻ cần duyệt

Nguồn `source/XP-Attention.dc.html` · ảnh `screens/@2x/XPAttention.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Cần duyệt` | 63 |
| 24, 4 | TL | `JBMono-12B` | `Cần duyệt` | 63 |
| 120, 30 | TC | `JBMono-11` | `CLAUDE · glimmer` | 112 |
| 120, 120 | TC | `JBMono-16B` | `Cần bạn duyệt` | 130 |
| 120, 146 | TC | `JBMono-11` | `Bash · pio run -e nodemcuv2` | 189 |
| 120, 176 | TC | `JBMono-11` | `chờ bạn · 2P` | 84 |

### XP-Claude-Loading — XP · Claude · đang tải

Nguồn `source/XP-Claude-Loading.dc.html` · ảnh `screens/@2x/XPClaudeLoading.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Claude` | 42 |
| 24, 4 | TL | `JBMono-12B` | `Claude` | 42 |
| 120, 92 | TC | `JBMono-12B` | `Đang tải...` | 77 |

### XP-Claude-Stale — XP · Claude · dữ liệu cũ

Nguồn `source/XP-Claude-Stale.dc.html` · ảnh `screens/@2x/XPClaudeStale.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Claude · cũ 14P` | 105 |
| 24, 4 | TL | `JBMono-12B` | `Claude · cũ 14P` | 105 |
| 10, 28 | TL | `JBMono-11` | `Hạn mức tuần` | 84 |
| 10, 40 | TL | `VT323-86` | `38` | 68 |
| 80, 70 | TL | `VT323-44` | `%` | 18 |
| 229, 84 | TR | `JBMono-12B` | `4NG` | 21 |
| 17, 122 | TL | `JBMono-11` | `Phiên 5 giờ` | 77 |
| 224, 135 | TR | `JBMono-11` | `12% · 2G 14P` | 84 |
| 225, 168 | TR | `JBMono-11` | `2P` | 14 |
| 23, 168 | TL | `JBMono-11` | `glimmer` | 49 |
| 79, 168 | TL | `JBMono-11` | `Cần duyệt · Bash` | 112 |
| 225, 181 | TR | `JBMono-11` | `5P` | 14 |
| 23, 181 | TL | `JBMono-11` | `TieuMac3d` | 63 |
| 93, 181 | TL | `JBMono-11` | `Đang chạy` | 63 |
| 225, 194 | TR | `JBMono-11` | `1G` | 14 |
| 23, 194 | TL | `JBMono-11` | `api` | 21 |
| 51, 194 | TL | `JBMono-11` | `Xong` | 28 |

### XP-Claude-KeyExpired — XP · Claude · khóa hết hạn (còn số cũ)

Nguồn `source/XP-Claude-KeyExpired.dc.html` · ảnh `screens/@2x/XPClaudeKeyExpired.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Claude · khóa lỗi` | 119 |
| 24, 4 | TL | `JBMono-12B` | `Claude · khóa lỗi` | 119 |
| 10, 28 | TL | `JBMono-11` | `Hạn mức tuần` | 84 |
| 10, 40 | TL | `VT323-86` | `38` | 68 |
| 80, 70 | TL | `VT323-44` | `%` | 18 |
| 229, 84 | TR | `JBMono-12B` | `4NG` | 21 |
| 17, 122 | TL | `JBMono-11` | `Phiên 5 giờ` | 77 |
| 224, 135 | TR | `JBMono-11` | `12% · 2G 14P` | 84 |
| 24, 168 | TL | `JBMono-11` | `Khóa hết hạn · glimmer.local` | 196 |
| 225, 182 | TR | `JBMono-11` | `2P` | 14 |
| 23, 182 | TL | `JBMono-11` | `glimmer` | 49 |
| 79, 182 | TL | `JBMono-11` | `Cần duyệt · Bash` | 112 |
| 225, 195 | TR | `JBMono-11` | `5P` | 14 |
| 23, 195 | TL | `JBMono-11` | `TieuMac3d` | 63 |
| 93, 195 | TL | `JBMono-11` | `Đang chạy` | 63 |

### XP-Claude-Rejected — XP · Claude · khóa bị từ chối

Nguồn `source/XP-Claude-Rejected.dc.html` · ảnh `screens/@2x/XPClaudeRejected.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Claude · khóa lỗi` | 119 |
| 24, 4 | TL | `JBMono-12B` | `Claude · khóa lỗi` | 119 |
| 48, 38 | TL | `JBMono-12B` | `Khóa bị từ chối` | 105 |
| 48, 58 | TL | `JBMono-11` | `claude.ai từ chối khóa.` | 161 |
| 48, 74 | TL | `JBMono-11` | `Nhập khóa mới tại:` | 126 |
| 48, 96 | TL | `JBMono-12B` | `glimmer.local` | 91 |
| 48, 116 | TL | `JBMono-11` | `192.168.100.40` | 98 |

### XP-Claude-Offline — XP · Claude · mất mạng

Nguồn `source/XP-Claude-Offline.dc.html` · ảnh `screens/@2x/XPClaudeOffline.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Claude` | 42 |
| 24, 4 | TL | `JBMono-12B` | `Claude` | 42 |
| 48, 38 | TL | `JBMono-12B` | `Mất mạng` | 56 |
| 48, 58 | TL | `JBMono-11` | `Không tới được claude.ai.` | 175 |
| 48, 74 | TL | `JBMono-11` | `Kiểm tra Wi-Fi.` | 105 |
| 48, 90 | TL | `JBMono-11` | `` | 0 |
| 48, 106 | TL | `JBMono-11` | `Đang tự động thử lại...` | 161 |

### XP-Claude-NoProject — XP · Claude · chưa có project (Clawd ngủ)

Nguồn `source/XP-Claude-NoProject.dc.html` · ảnh `screens/@2x/XPClaudeNoProject.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Claude` | 42 |
| 24, 4 | TL | `JBMono-12B` | `Claude` | 42 |
| 10, 28 | TL | `JBMono-11` | `Hạn mức tuần` | 84 |
| 10, 40 | TL | `VT323-86` | `38` | 68 |
| 80, 70 | TL | `VT323-44` | `%` | 18 |
| 150, 84 | TR | `JBMono-12B` | `4NG` | 21 |
| 17, 122 | TL | `JBMono-11` | `Phiên 5 giờ` | 77 |
| 224, 135 | TR | `JBMono-11` | `12% · 2G 14P` | 84 |
| 120, 182 | TC | `JBMono-11` | `Chưa có hoạt động project` | 175 |

### XP-Claude-Done — XP · Claude · đã xong hết (Clawd ngủ)

Nguồn `source/XP-Claude-Done.dc.html` · ảnh `screens/@2x/XPClaudeDone.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Claude` | 42 |
| 24, 4 | TL | `JBMono-12B` | `Claude` | 42 |
| 10, 28 | TL | `JBMono-11` | `Hạn mức tuần` | 84 |
| 10, 40 | TL | `VT323-86` | `38` | 68 |
| 80, 70 | TL | `VT323-44` | `%` | 18 |
| 150, 84 | TR | `JBMono-12B` | `4NG` | 21 |
| 17, 122 | TL | `JBMono-11` | `Phiên 5 giờ` | 77 |
| 224, 135 | TR | `JBMono-11` | `12% · 2G 14P` | 84 |
| 225, 168 | TR | `JBMono-11` | `2P` | 14 |
| 23, 168 | TL | `JBMono-11` | `glimmer` | 49 |
| 79, 168 | TL | `JBMono-11` | `Xong` | 28 |
| 225, 181 | TR | `JBMono-11` | `40P` | 21 |
| 23, 181 | TL | `JBMono-11` | `TieuMac3d` | 63 |
| 93, 181 | TL | `JBMono-11` | `Xong` | 28 |
| 225, 194 | TR | `JBMono-11` | `1G` | 14 |
| 23, 194 | TL | `JBMono-11` | `api` | 21 |
| 51, 194 | TL | `JBMono-11` | `Xong` | 28 |

### XP-Codex-Loading — XP · Codex · đang tải

Nguồn `source/XP-Codex-Loading.dc.html` · ảnh `screens/@2x/XPCodexLoading.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Codex` | 35 |
| 24, 4 | TL | `JBMono-12B` | `Codex` | 35 |
| 120, 92 | TC | `JBMono-12B` | `Đang tải...` | 77 |

### XP-Codex-Stale — XP · Codex · dữ liệu cũ

Nguồn `source/XP-Codex-Stale.dc.html` · ảnh `screens/@2x/XPCodexStale.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Codex · cũ 18P` | 98 |
| 24, 4 | TL | `JBMono-12B` | `Codex · cũ 18P` | 98 |
| 10, 28 | TL | `JBMono-11` | `Hạn mức tuần` | 84 |
| 10, 40 | TL | `VT323-86` | `41` | 68 |
| 80, 70 | TL | `VT323-44` | `%` | 18 |
| 229, 68 | TR | `JBMono-11` | `đặt lại sau` | 77 |
| 229, 84 | TR | `JBMono-12B` | `3NG` | 21 |
| 17, 122 | TL | `JBMono-11` | `Phiên 5 giờ` | 77 |
| 18, 137 | TL | `JBMono-11` | `Spark` | 35 |
| 222, 137 | TR | `JBMono-11` | `2G 14P` | 42 |
| 17, 164 | TL | `JBMono-11` | `Đặt lại tuần` | 84 |
| 18, 177 | TL | `JBMono-11` | `còn 2 · 3NG` | 77 |
| 222, 177 | TR | `JBMono-11` | `~70% khi đặt lại` | 112 |

### XP-Codex-Expired — XP · Codex · token hết hạn

Nguồn `source/XP-Codex-Expired.dc.html` · ảnh `screens/@2x/XPCodexExpired.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Codex · khóa lỗi` | 112 |
| 24, 4 | TL | `JBMono-12B` | `Codex · khóa lỗi` | 112 |
| 48, 38 | TL | `JBMono-12B` | `Token hết hạn` | 91 |
| 48, 58 | TL | `JBMono-11` | `Hết hạn ngày 20/11.` | 133 |
| 48, 74 | TL | `JBMono-11` | `Nhập token mới tại:` | 133 |
| 48, 96 | TL | `JBMono-12B` | `glimmer.local` | 91 |
| 48, 116 | TL | `JBMono-11` | `192.168.100.40` | 98 |

### XP-AI-Loading — XP · AI · đang tải

Nguồn `source/XP-AI-Loading.dc.html` · ảnh `screens/@2x/XPAILoading.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `AI hôm nay` | 70 |
| 24, 4 | TL | `JBMono-12B` | `AI hôm nay` | 70 |
| 10, 28 | TL | `JBMono-11` | `Chi phí hôm nay` | 105 |
| 10, 40 | TL | `VT323-86` | `--` | 68 |
| 17, 114 | TL | `JBMono-11` | `Claude` | 42 |
| 18, 128 | TL | `VT323-44` | `--` | 36 |
| 131, 114 | TL | `JBMono-11` | `Codex` | 35 |
| 132, 128 | TL | `VT323-44` | `--` | 36 |
| 8, 199 | TL | `JBMono-11` | `Đang tải...` | 77 |
| 231, 199 | TR | `JBMono-11` | `CL -- · CX --` | 91 |

### XP-AI-KeyBad — XP · AI · khóa Claude lỗi

Nguồn `source/XP-AI-KeyBad.dc.html` · ảnh `screens/@2x/XPAIKeyBad.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `AI hôm nay` | 70 |
| 24, 4 | TL | `JBMono-12B` | `AI hôm nay` | 70 |
| 10, 28 | TL | `JBMono-11` | `Chi phí hôm nay` | 105 |
| 10, 40 | TL | `VT323-86` | `$4.20` | 170 |
| 17, 114 | TL | `JBMono-11` | `Claude` | 42 |
| 18, 128 | TL | `VT323-44` | `Khóa` | 72 |
| 131, 114 | TL | `JBMono-11` | `Codex` | 35 |
| 132, 128 | TL | `VT323-44` | `71%` | 54 |
| 8, 199 | TL | `JBMono-11` | `Khóa Claude bị từ chối` | 154 |

### XP-Home-KeyBad — XP · Trang chủ · khóa Claude lỗi

Nguồn `source/XP-Home-KeyBad.dc.html` · ảnh `screens/@2x/XPHomeKeyBad.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Trang chủ` | 63 |
| 24, 4 | TL | `JBMono-12B` | `Trang chủ` | 63 |
| 10, 30 | TL | `VT323-86` | `14:32` | 170 |
| 229, 66 | TR | `JBMono-12B` | `29°` | 21 |
| 10, 100 | TL | `JBMono-11` | `Thứ Tư 25/11` | 84 |
| 229, 100 | TR | `JBMono-11` | `Ít mây` | 42 |
| 17, 118 | TL | `JBMono-11` | `Hạn mức` | 49 |
| 18, 135 | TL | `JBMono-11` | `Claude` | 42 |
| 70, 135 | TL | `JBMono-11` | `Khóa bị từ chối` | 105 |
| 18, 159 | TL | `JBMono-11` | `Codex` | 35 |
| 222, 159 | TR | `JBMono-11` | `71%` | 21 |
| 8, 199 | TL | `JBMono-11` | `192.168.100.40` | 98 |
| 231, 199 | TR | `JBMono-11` | `Còn 9G hôm nay` | 98 |

### XP-Home-NoWeather — XP · Trang chủ · chưa có thời tiết

Nguồn `source/XP-Home-NoWeather.dc.html` · ảnh `screens/@2x/XPHomeNoWeather.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Trang chủ` | 63 |
| 24, 4 | TL | `JBMono-12B` | `Trang chủ` | 63 |
| 10, 30 | TL | `VT323-86` | `14:32` | 170 |
| 229, 66 | TR | `JBMono-12B` | `--°` | 21 |
| 10, 100 | TL | `JBMono-11` | `Thứ Tư 25/11` | 84 |
| 229, 100 | TR | `JBMono-11` | `chưa có thời tiết` | 119 |
| 17, 118 | TL | `JBMono-11` | `Hạn mức` | 49 |
| 18, 135 | TL | `JBMono-11` | `Claude` | 42 |
| 222, 135 | TR | `JBMono-11` | `38%` | 21 |
| 18, 159 | TL | `JBMono-11` | `Codex` | 35 |
| 222, 159 | TR | `JBMono-11` | `71%` | 21 |
| 8, 199 | TL | `JBMono-11` | `192.168.100.40` | 98 |
| 231, 199 | TR | `JBMono-11` | `Còn 9G hôm nay` | 98 |

### XP-Weather-Loading — XP · Thời tiết · đang tải

> **P-2026-11-26.23 — bỏ:** Thời tiết đang tải = hộp thoại tải về kiểu XP (P-.16, mục XP-Open); source cũ đã gỡ.

Nguồn `source/XP-Weather-Loading.dc.html` · ảnh `screens/@2x/XPWeatherLoading.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Thời tiết` | 63 |
| 24, 4 | TL | `JBMono-12B` | `Thời tiết` | 63 |
| 120, 92 | TC | `JBMono-12B` | `Đang tải thời tiết...` | 147 |

### XP-Weather-Error — Thời tiết · lỗi (tab Hiện tại)

> **P-2026-11-26.23:** vẽ lại theo cửa sổ Thời tiết có tab (P-.17), thay bảng cũ.

Nguồn `source/XP-Weather-Error.dc.html` · ảnh `screens/@2x/XPWeatherError.png`. Khung, tiêu đề `Thời tiết`, tab `Hiện tại` (chọn) /
`Dự báo`, thanh tác vụ như `XPWeatherProps`. Trang tab:

| khối | tọa độ | màu / font | chữ, rộng đo |
|---|---|---|---|
| biểu tượng cảnh báo XP | tam giác 24×21 tại (14, 52): viền xpAmber, nền xpIconWarn, `!` black 2 px (cột 11–12, hàng 7–14 + 16–17) | — | — |
| tiêu đề lỗi | TL (46, 52) | `JBMono-12B` black | `Chưa có thời tiết` 119 |
| chi tiết | TL (46, 72) | `JBMono-11` black | `Máy chủ trả lỗi 500.` 140 (chữ theo lỗi) |
| vạch | (12, 96, 216×1) | xpGroup | — |
| đang thử lại | TL (14, 104) | `JBMono-11` xpLabel | `Đang tự thử lại...` 126 |

### XP-Weather-Stale — Thời tiết · dữ liệu cũ (tab Hiện tại)

> **P-2026-11-26.23:** vẽ lại theo cửa sổ Thời tiết có tab, thay bảng cũ.

Nguồn `source/XP-Weather-Stale.dc.html` · ảnh `screens/@2x/XPWeatherStale.png`. Bố cục y như `XPWeatherProps` (mục XP-Real), khác:

- Tiêu đề cửa sổ `Thời tiết · cũ 2G` (`JBMono-12B`, 119 px; `titleMeta`).
- Giá trị xám xpMuted `#6F6F6F`: mô tả `Ít mây` 16B, nhiệt độ VT323-44, cột giá trị 4 hàng + `31° / 24°`. Nhãn (`Cảm giác:` …) giữ black, `Hà Nội` giữ xpLabel.
- Hàng cuối thay `Mặt trời lặn` bằng `Cập nhật:` (14, 187) + `2 giờ trước` xpAmber TL (112, 187), 77 px.

### XP-Forecast-Empty — Thời tiết · tab Dự báo chưa có

> **P-2026-11-26.23:** vẽ lại theo tab Dự báo (ListView Details, P-.17), thay bảng cũ.

Nguồn `source/XP-Forecast-Empty.dc.html` · ảnh `screens/@2x/XPForecastEmpty.png`. Khung, tab `Dự báo` (chọn), ListView và hàng tiêu đề
cột (`Ngày` / `Trời` / `Thấp` / `Cao`) như `XPForecastDetails`; không có hàng. Chữ `Chưa có dự báo` `JBMono-11` xpMuted căn giữa
x 11–228, y 74 (98 px) — như ListView XP rỗng hiện lời nhắn ở đầu danh sách.

### XP-Trend-Collecting — XP · Xu hướng · đang thu thập

Nguồn `source/XP-Trend-Collecting.dc.html` · ảnh `screens/@2x/XPTrendCollecting.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Xu hướng` | 56 |
| 24, 4 | TL | `JBMono-12B` | `Xu hướng` | 56 |
| 10, 28 | TL | `JBMono-11` | `7 ngày · % hạn mức tuần` | 161 |
| 90, 100 | TC | `JBMono-11` | `Đang thu thập...` | 112 |
| 28, 177 | TC | `JBMono-11` | `T5` | 14 |
| 58, 177 | TC | `JBMono-11` | `T6` | 14 |
| 88, 177 | TC | `JBMono-11` | `T7` | 14 |
| 118, 177 | TC | `JBMono-11` | `CN` | 14 |
| 148, 177 | TC | `JBMono-11` | `T2` | 14 |
| 178, 177 | TC | `JBMono-11` | `T3` | 14 |
| 208, 177 | TC | `JBMono-11` | `T4` | 14 |
| 8, 199 | TL | `JBMono-11` | `Có 2 / 7 ngày` | 91 |

### XP-Agents-Idle — XP · Tác tử · không mục nào chờ

Nguồn `source/XP-Agents-Idle.dc.html` · ảnh `screens/@2x/XPAgentsIdle.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Tác tử` | 42 |
| 24, 4 | TL | `JBMono-12B` | `Tác tử` | 42 |
| 32, 36 | TL | `JBMono-12B` | `Tests · 64%` | 77 |
| 32, 56 | TL | `JBMono-11` | `codex · api · 5p` | 112 |
| 32, 88 | TL | `JBMono-12B` | `Xong` | 28 |
| 32, 108 | TL | `JBMono-11` | `claude · TieuMac3d · 12p` | 168 |
| 8, 199 | TL | `JBMono-11` | `2 mục` | 35 |
| 231, 199 | TR | `JBMono-11` | `không mục nào chờ` | 119 |

### XP-Photo-Empty — XP · Ảnh · chưa có ảnh

> **P-2026-11-28.27:** dòng 2 = `Thêm ảnh trong app glimmer` (182 px); bỏ `hoặc` / `glimmer.local` — xem mục XP-Photo.

Nguồn `source/XP-Photo-Empty.dc.html` · ảnh `screens/@2x/XPPhotoEmpty.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Ảnh` | 21 |
| 24, 4 | TL | `JBMono-12B` | `Ảnh` | 21 |
| 120, 100 | TC | `JBMono-16B` | `Chưa có ảnh` | 110 |
| 120, 128 | TC | `JBMono-11` | `Gửi ảnh từ app glimmer` | 154 |
| 120, 146 | TC | `JBMono-11` | `hoặc` | 28 |
| 120, 162 | TC | `JBMono-12B` | `glimmer.local` | 91 |

### XP-Attention-Input — XP · thẻ lượt bạn

Nguồn `source/XP-Attention-Input.dc.html` · ảnh `screens/@2x/XPAttentionInput.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Lượt bạn` | 56 |
| 24, 4 | TL | `JBMono-12B` | `Lượt bạn` | 56 |
| 120, 30 | TC | `JBMono-11` | `CLAUDE · glimmer` | 112 |
| 120, 120 | TC | `JBMono-16B` | `Lượt bạn` | 80 |
| 120, 146 | TC | `JBMono-11` | `Claude đang chờ câu trả lời` | 189 |
| 120, 176 | TC | `JBMono-11` | `chờ bạn · 45 giây` | 119 |

### XP-Attention-Done — XP · thẻ xong

Nguồn `source/XP-Attention-Done.dc.html` · ảnh `screens/@2x/XPAttentionDone.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Xong` | 28 |
| 24, 4 | TL | `JBMono-12B` | `Xong` | 28 |
| 120, 30 | TC | `JBMono-11` | `CLAUDE · glimmer` | 112 |
| 120, 120 | TC | `JBMono-16B` | `Xong rồi!` | 90 |
| 120, 146 | TC | `JBMono-11` | `Claude đã xong` | 98 |

### XP-Attention-Error — XP · thẻ lỗi

Nguồn `source/XP-Attention-Error.dc.html` · ảnh `screens/@2x/XPAttentionError.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Lỗi` | 21 |
| 24, 4 | TL | `JBMono-12B` | `Lỗi` | 21 |
| 120, 30 | TC | `JBMono-11` | `CLAUDE · glimmer` | 112 |
| 120, 120 | TC | `JBMono-16B` | `build failed` | 120 |
| 120, 146 | TC | `JBMono-11` | `3 lỗi · ch_claude.cpp:120` | 175 |

### XP-Attention-Progress — XP · thẻ tiến độ

Nguồn `source/XP-Attention-Progress.dc.html` · ảnh `screens/@2x/XPAttentionProgress.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `Đang chạy` | 63 |
| 24, 4 | TL | `JBMono-12B` | `Đang chạy` | 63 |
| 120, 30 | TC | `JBMono-11` | `CLAUDE · api` | 84 |
| 120, 120 | TC | `JBMono-16B` | `tests 64%` | 90 |
| 120, 146 | TC | `JBMono-11` | `main · 4 phút` | 91 |

### XP-Night — XP · mặt đồng hồ đêm (giữ đen)

Nguồn `source/XP-Night.dc.html` · ảnh `screens/@2x/XPNight.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 120, 70 | TC | `VT323-86` | `23:47` | 170 |
| 120, 150 | TC | `JBMono-11` | `Thứ Tư 25/11` | 84 |

### XP-NoChannels — XP · chưa có kênh

Nguồn `source/XP-NoChannels.dc.html` · ảnh `screens/@2x/XPNoChannels.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 25, 5 | TL | `JBMono-12B` | `glimmer` | 49 |
| 24, 4 | TL | `JBMono-12B` | `glimmer` | 49 |
| 48, 38 | TL | `JBMono-12B` | `Chưa có kênh` | 84 |
| 48, 58 | TL | `JBMono-11` | `Bật kênh trên trang web:` | 168 |
| 48, 80 | TL | `JBMono-12B` | `glimmer.local` | 91 |

### XP-Splash — XP · khởi động

Nguồn `source/XP-Splash.dc.html` · ảnh `screens/@2x/XPSplash.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 82, 89 | TL | `JBMono-11` | `Clawdsoft` | 63 |
| 82, 103 | TL | `JBMono-16B` | `Window` | 60 |
| 144, 104 | TL | `JBMono-11` | `xp` | 14 |
| 84, 122 | TL | `JBMono-11` | `Professional` | 84 |

### XP-Connecting — XP · welcome / đang kết nối Wi-Fi

Nguồn `source/XP-Connecting.dc.html` · ảnh `screens/@2x/XPConnecting.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|

### XP-SetupMode — XP · màn đăng nhập / cài đặt Wi-Fi

> **P-2026-11-28.26 — mã QR cài Wi-Fi, QR giữa màn:** thay bảng dưới (bản cũ chia trái / phải ở x 116). Phiếu
> `docs/phieu_panel/2026-11-28-qr-man-log-on.md`. Nền, dải trên / dưới, vạch viền màu như cũ (token `themeXP.welcome`);
> không thanh tác vụ, không hoạt ảnh; vẽ một lần, không đổi khi đang ở AP.
>
> | khối | tọa độ | màu / font | chữ, rộng đo |
> |---|---|---|---|
> | cờ ×2 | 28×24 tại (8, 3) — trong dải trên | 4 màu cờ | — |
> | `Window` nghiêng | bitmap 68×12 white tại (40, 9), bóng xpWelcomeShadow (41, 10) | — | — |
> | `xp` | TL (110, 8) | `JBMono-11` xpWelcomeOrange | 14 |
> | mã QR | khối white (46, 35, 148×148); 29×29 ô × 4 px từ (62, 51) (viền trắng 4 ô); ô tối black | `drawSetupQr(46, 35, 4, ssid)` | `WIFI:T:nopass;S:glimmer-setup;;` (v3, ECC M) |
> | hướng dẫn | TL (36, 187) — căn giữa x 120 | `JBMono-11` white | `Quét mã bằng app glimmer` 168 |
> | nút nguồn | 14×14 tại (8, 218), như cũ | white / xpClose | — |
> | `Cài đặt Wi-Fi` | TL (28, 219) | `JBMono-11` white | 91 |
> | tên AP (dự phòng khi không có app) | TL (141, 219) | `JBMono-11` xpWelcomeSub | `glimmer-setup` 91 |
>
> Bỏ: chữ `Để bắt đầu, kết nối Wi-Fi`, vạch dọc x 116, ô chọn người dùng (ảnh Clawd, `glimmer-` / `setup`, `192.168.4.1`).
> Hoa văn QR trong ảnh là mặt nạ 2; thư viện firmware tự chọn mặt nạ — cùng nội dung, cùng cỡ.


Nguồn `source/XP-SetupMode.dc.html` · ảnh `screens/@2x/XPSetupMode.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 81, 103 | TL | `JBMono-11` | `xp` | 14 |
| 14, 126 | TL | `JBMono-11` | `Để bắt đầu,` | 77 |
| 14, 140 | TL | `JBMono-11` | `kết nối Wi-Fi` | 91 |
| 158, 92 | TL | `JBMono-12B` | `glimmer-` | 56 |
| 158, 106 | TL | `JBMono-12B` | `setup` | 35 |
| 158, 121 | TL | `JBMono-11` | `192.168.4.1` | 77 |
| 28, 219 | TL | `JBMono-11` | `Cài đặt Wi-Fi` | 91 |

### XP-OtaProgress — XP · đang cập nhật

> **P-2026-11-27.24 — màn đang tắt máy** cùng kiểu (chrome welcome + chữ nghiêng tại (20, 96)): xem XP-Pointer.

Nguồn `source/XP-OtaProgress.dc.html` · ảnh `screens/@2x/XPOtaProgress.png`

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 120, 130 | TC | `JBMono-11` | `Đừng tắt hay rút điện máy.` | 182 |

### XP-Desktop — màn đầu kiểu desktop (thay Trang chủ)

Nguồn `source/XP-Desktop.dc.html` · ảnh `screens/@2x/XPDesktop.png` (nền dự phòng). Token `themeXP.desktop`.

- **Nền** (x 0–239, y 0–213): ảnh JPEG baseline 240×214 ≤ 40 KB người dùng gửi lên, vẽ ở (0, 0) một lần khi vào màn. Chưa có / hỏng → nền dự phòng vẽ pixel: trời 11 dải xanh đậm → gần trắng (mỗi dải 11 px), vệt mây ti góc trên trái + trên phải, cụm mây nhỏ giữa trên, chùm mây bồng giữa-phải, hàng mây thấp y 106 bên phải, dải núi xa x 160–239 từ y ~123, gò cỏ đỉnh y 112 tại x 96 (mép trái y 118, mép phải y 132), cỏ 5 dải sáng → đậm theo độ sâu, dải tối chéo tiền cảnh trái, mép đáy đậm.
- **Biểu tượng** cột trái, tâm x 40, ô cao 48 từ y 8: Clawd ×2 / cửa sổ dòng lệnh ×2 / ảnh ×2 / thùng rác ×2; nhãn `JBMono-11` white TC dưới icon (y ô + 24) + bóng đen (+1, +1).
- **Bong bóng khay**: 136×50 tại (100, 150), viền đen 1 px, nền xpInfoBar, đuôi chỉ xuống khay giờ (x 206); icon thời tiết xpAmber, `Thời tiết` 12B, 2 dòng 11.
- **Thanh tác vụ**: như §17, không nút skill nào lõm.

| x, y | datum | font | nội dung | px |
|---|---|---|---|---|
| 41, 33 | TC | `JBMono-11` | `Claude 38%` | 70 |
| 40, 32 | TC | `JBMono-11` | `Claude 38%` | 70 |
| 41, 81 | TC | `JBMono-11` | `Codex 71%` | 63 |
| 40, 80 | TC | `JBMono-11` | `Codex 71%` | 63 |
| 41, 129 | TC | `JBMono-11` | `Ảnh` | 21 |
| 40, 128 | TC | `JBMono-11` | `Ảnh` | 21 |
| 41, 177 | TC | `JBMono-11` | `Thùng rác` | 63 |
| 40, 176 | TC | `JBMono-11` | `Thùng rác` | 63 |
| 126, 155 | TL | `JBMono-12B` | `Thời tiết` | 63 |
| 106, 172 | TL | `JBMono-11` | `29° · Ít mây` | 84 |
| 106, 185 | TL | `JBMono-11` | `cảm giác 33°` | 84 |

### XP-Claude-Laptop — Clawd làm việc (lấy laptop → gõ → ngủ)

Nguồn `source/XP-Claude-Laptop.dc.html` (canvas chạy cả vòng) · ảnh `screens/@2x/XPClaudeLaptop.png` (khung gõ đầu), `screens/@2x/XPClaudeLaptopFrames.png` (mọi khung). Token `themeXP.clawdWork` (lưới từng khung).

- Chép theo GIF Clawd: lưới ô 4 px, gốc (136, 30); vùng vẽ lại mỗi khung 98×80 tại (132, 20) — tô xpBody rồi vẽ khung, vẽ lại `4NG` TR (229, 84).
- Màu: thân CLAWD, mắt `#000000` (luật mắt trong token), laptop nét xpLaptop `#808080`.
- **Bắt đầu chạy** (project đầu bảng chuyển sang Đang chạy): đoạn mở đầu **một lần** — khung 0 (300 ms), 3 (105 ms), 4 (90 ms), 3 (105 ms), 4 (90 ms), 9 (195 ms), 11 (210 ms), 13 (90 ms), 14 (210 ms), 16 (90 ms), 17 (105 ms), 18 (105 ms): đứng nhìn thẳng → lắc người → lôi laptop ra, giơ lên, đặt xuống → nhún → ngồi.
- **Đang chạy**: lặp khung 19, 21, 22, mỗi khung 200 ms (= tick 5 Hz).
- **Xong / bảng trống**: chuyển thẳng sang Clawd ngủ (như mục Clawd ngủ) — không có đoạn cất laptop.
- Mắt giữ đen suốt chuỗi; khung 18 (tiếp đất) dùng mắt 1 hàng (không mở to) để không nháy.

| khung | ms | lưới (C thân · K mắt · L laptop) |
|---|---|---|
| 0 | 300 | `.......................` `.......................` `.......................` `..........CCCCCCCCCC...` `..........CKCCCCCCKC...` `.......CCCCCCCCCCCCCCCC` `.......CCCCCCCCCCCCCCCC` `.......CCCCCCCCCCCCCCCC` `..........CCCCCCCCCC...` `..........CCCCCCCCCC...` `..........C.C...CC.C...` `..........C.C...CC.C...` `..........C.C...CC.C...` |
| 3 | 105 | `.......................` `.......................` `.......................` `.......................` `..........CCCCCCCCCC...` `..........CCCCCCCCCCCCC` `..........CKCCCCCKKCCCC` `........CCCCCCCCCCCC...` `........CCCCCCCCCCCC...` `........CCCCCCCCCCCC...` `..........CCCCCCCCCC...` `..........C.C...CC.C...` `..........C.C...CC.C...` |
| 4 | 90 | `.......................` `.......................` `.......................` `.......................` `..........CCCCCCCCCC...` `..........CCCCCCCCCCCCC` `..........CKCCCCCKKCCCC` `..........CCCCCCCCCC...` `........CCCCCCCCCCCC...` `........CCCCCCCCCCCC...` `.........CCCCCCCCCCC...` `..........C.C...CC.C...` `..........C.C...CC.C...` |
| 3 | 105 | `.......................` `.......................` `.......................` `.......................` `..........CCCCCCCCCC...` `..........CCCCCCCCCCCCC` `..........CKCCCCCKKCCCC` `........CCCCCCCCCCCC...` `........CCCCCCCCCCCC...` `........CCCCCCCCCCCC...` `..........CCCCCCCCCC...` `..........C.C...CC.C...` `..........C.C...CC.C...` |
| 4 | 90 | `.......................` `.......................` `.......................` `.......................` `..........CCCCCCCCCC...` `..........CCCCCCCCCCCCC` `..........CKCCCCCKKCCCC` `..........CCCCCCCCCC...` `........CCCCCCCCCCCC...` `........CCCCCCCCCCCC...` `.........CCCCCCCCCCC...` `..........C.C...CC.C...` `..........C.C...CC.C...` |
| 9 | 195 | `.......................` `........L..............` `....LLL................` `....LL....CCCCCCCCCC...` `.......CCCCKCCCCCCKC...` `.......CCCCCCCCCCCCC...` `.......CCCCCCCCCCCCCCCC` `........CCCCCCCCCCCCCCC` `..........CCCCCCCCCC...` `..........CCCCCCCCCC...` `..........C.C...CC.C...` `..........C.C...CC.C...` `..........C.C...CC.C...` |
| 11 | 210 | `.......................` `.......................` `.......CC..............` `.......CCCCCCCCCCCCC...` `.......CCCCKCCCCCCKC...` `..........CCCCCCCCCC...` `..........CCCCCCCCCCCCC` `..........CCCCCCCCCCCCC` `..........CCCCCCCCCC...` `..........CCCCCCCCCC...` `..........C.C...CC.C...` `..........C.C...CC.C...` `..........C.C...CC.C...` |
| 13 | 90 | `.......................` `.......................` `.......................` `..........CCCCCCCCCC...` `..........CCCCCCCCCC...` `.LL.......CKCCCCCCKCCCC` `.LLL....CCCCCCCCCCCCCCC` `..LLLLLLCCCCCCCCCCCCCCC` `.......LCCCCCCCCCCCC...` `.......CCCCCCCCCCCCC...` `.........CC.C...CC.C...` `..........C.C...CC.C...` `..........C.C...CC.C...` |
| 14 | 210 | `.......................` `.......................` `.......................` `..........CCCCCCCCCC...` `..........CCCCCCCCCC...` `..........CKCCCCCCKC...` `..........CCCCCCCCCCCCC` `..........CCCCCCCCCCCCC` `..........CCCCCCCCCC...` `.......CCCCCCCCCCCCC...` `.LL....CCCC.C...CC.C...` `..L.......C.C...CC.C...` `...LLLL...C.C...CC.C...` |
| 16 | 90 | `.......................` `.......................` `.......................` `..........CCCCCCCCCC...` `..........CCCCCCCCCC...` `.......CCCCKCCCCCCKCCCC` `.......CCCCCCCCCCCCCCCC` `.......CCCCCCCCCCCCC...` `..........CCCCCCCCCC...` `..........CCCCCCCCCC...` `L.........C.C...CC.C...` `.LL.......C.C...CC.C...` `...LLLL...C.C...CC.C...` |
| 17 | 105 | `........CCC....CCC.....` `........CCC....CCC.....` `........CCCCCCCCCCC....` `........CCCCCCCCCCC....` `.........CCCCCCCCCC....` `.........KKCCCCCKKC....` `.........CCCCCCCCCC....` `.........CCCCCCCCCC....` `.........CCCCCCCCCC....` `.L.......CCCCCCCCCC....` `..L......C..C...C.C....` `...L.....C..C...C.C....` `.........C..C...C.C....` |
| 18 | 105 | `.......................` `.......................` `.......................` `.......................` `........CCCCCCCCCC.....` `.....CCCCCCCCCCCCC.....` `.....CCCKKCCCKKCCC.....` `.....CCCCCCCCCCCCC.....` `........CCCCCCCCCC.....` `.....CCCCCCCCCCCCC.....` `.LL..CCCC..C...C.......` `..L..CCCC..C...C.......` `...LLLL..C..C...C.C....` |
| 19 | 200 | `.......................` `.......................` `.......................` `.......................` `........CCCCCCCCCC.....` `........CCCCCCCCCC.....` `........KKCCCKKCCC.....` `........CCCCCCCCCC.....` `......CCCCCCCCCCCC.....` `.L...CCCCCCCCCCCCC.....` `..L..CCCCCCCCCCCCC.....` `...L....C..C...C.......` `.........C..C...C.C....` |
| 21 | 200 | `.......................` `.......................` `.......................` `.......................` `........CCCCCCCCCC.....` `........CCCCCCCCCC.....` `........KKCCCKKCCC.....` `......CCCCCCCCCCCC.....` `......CCCCCCCCCCCC.....` `......CCCCCCCCCCCC.....` `.LL.....CCCCCCCCCC.....` `..L..CCCC..C...C.......` `...LLLL..C..C...C.C....` |
| 22 | 200 | `.......................` `.......................` `.......................` `.......................` `........CCCCCCCCCC.....` `........CCCCCCCCCC.....` `........KKCCCKKCCC.....` `.....CCCCCCCCCCCCC.....` `.....CCCCCCCCCCCCC.....` `.....CCCCCCCCCCCCC.....` `.LL...CCCCCCCCCCCC.....` `..L...CCC..C...C.......` `...LLLL..C..C...C.C....` |

### XP-Desk — desktop theo skill, cửa sổ, thanh tác vụ

Nguồn `source/XP-Desk-Agent.dc.html`, `XP-Desk-All.dc.html`, `XP-Desk-Selected.dc.html`, `XP-Win-Open.dc.html` (hình nền chung `XP-Wall.dc.html` = hình nền dự phòng của XP-Desktop) · ảnh `XPDeskAgent.png`, `XPDeskAll.png`, `XPDeskSelected.png`, `XPWinOpen.png`. Token `themeXP.desktop.icons`, `themeXP.taskbar.buttons`.

- **Biểu tượng desktop** (XP Auto Arrange): cột 0 tâm x 40, cột 1 tâm x 120; ô 48 từ y 8. Theo skill bật: Agent → `Claude <x>%`, `Codex <x>%`; Ảnh → `Ảnh`; Thời tiết → `Thời tiết`; Đồng hồ → `Đồng hồ`. Xếp từ trên xuống: cột 0 ô y 8 / 56 / 104, Thùng rác luôn ở ô y 152 cột 0; tiếp cột 1 ô y 8 / 56 / 104 (dừng trên bong bóng thời tiết y 150). Đủ 4 skill: cột 0 Claude, Codex, Ảnh, Thùng rác; cột 1 Thời tiết, Đồng hồ.
- Icon ×2: Clawd 36×20 tại (cx−18, ô+1) mắt đen; dòng lệnh 32×20 tại (cx−16, ô); ảnh 32×22 (cx−16, ô); thùng 28×20 (cx−14, ô); thời tiết / đồng hồ (bitmap 16×14 của thanh tác vụ) ×2 = 32×28 tại (cx−16, ô−6). Nhãn JBMono-11 white TC (cx, ô+24), bóng đen (+1, +1). Bề rộng đo: `Thời tiết` 63 px, `Đồng hồ` 49 px, `Thùng rác` ≤ 80 px.
- Chỉ skill Agent (`XPDeskAgent`): Claude, Codex, Thùng rác ở ô y 104; không bong bóng (skill Thời tiết tắt).
- **Biểu tượng đang chọn** (`XPDeskSelected`; vừa cài skill / vừa chạm trên app): như XP — icon trắng → xpSelectIcon `#98B4E2`, Clawd → xpSelectClawd `#85719E`; nhãn: nền xpSelect `#316AC5` rộng chữ + 1 px mỗi bên, cao 13, chữ white không bóng, viền chấm 1 px white quanh nền. Bỏ chọn khi app mở cửa sổ khác hoặc chạm chỗ trống.
- **Thanh tác vụ** = cửa sổ đang mở (app giữ danh sách, gửi xuống), theo thứ tự mở, tối đa 4 nút 28×20 tại x 71 / 101 / 131 / 161, y 217 (icon như cũ). Cửa sổ trên cùng: nút lõm (xpBtnPressedEdge / xpBtnPressed). Thu nhỏ: nút thường. Desktop đang hiện: không nút nào lõm. Không mở gì: chỉ start + khay. **Không còn vạch tiến độ 2 px** ở đáy nút. Badge amber / nút cam khi agent chờ giữ như cũ, trên nút Claude nếu cửa sổ Claude đang mở.
- **Thu nhỏ** (`XPDeskAll`: Claude đã thu nhỏ): desktop hiện, nút Claude còn trên thanh tác vụ, không lõm. **Tắt (×)**: nút biến mất, hiện cửa sổ mở trước đó chưa thu nhỏ, hết → desktop.
- **Nút □** (`XPWinOpen`, thanh tiêu đề mọi cửa sổ): ô (202, 3, 16×16) viền white, nền xpTitleLight `#2B80F5`, nét □ 8×8 tại (206, 6) màu xpCaptionOff `#7FA4F0` (thanh trên 2 px) — mờ như XP làm với cửa sổ không đổi cỡ. Tâm nút: `_` x 192, `□` x 210, `×` x 228 (y 11).

### XP-Start — Start menu (app chạm start)

> **P-2026-11-27.25 — đủ mọi chương trình:** Tất cả chương trình liệt kê mọi chương trình đã cài (thêm AI hôm nay, Xu hướng, Agents, Dò mìn), cao quá thì dời lên; cột trái = 3 chương trình mở gần nhất — xem XP-Start-All.

> **P-2026-11-27.24 — `Tắt màn` → `Tắt máy`, mục sáng:** nút dưới phải đổi chữ (mở hộp Tắt máy tính); mục dưới con trỏ tô xpSelect — xem XP-Pointer.

> **P-2026-11-26.20 — Start menu kiểu XP trên thiết bị.**

Nguồn `source/XP-Start-Menu.dc.html`, `XP-Start-All.dc.html` · ảnh `XPStartMenu.png`, `XPStartAll.png`. Token `themeXP.startMenu`.
Thành phần XP thật: *Start menu* kiểu mới của XP (Luna, hai cột: dải người dùng, chương trình ghim + hay dùng, *All Programs*,
cột phải xanh nhạt, dải *Log Off* / *Turn Off Computer*), menu con *All Programs* mở ngang.

- **Khi hiện**: app chạm start → lệnh menu kind `start` (như menu chuột phải); vẽ đè từ (0, 0) tới y 213, trên desktop hoặc cửa
  sổ đang hiện. Nút start lún: các hàng xpStartHi → xpStartDark, xpStart → xpGreen (chỉ vẽ lại nút). Đóng như XP-Menu: chọn mục,
  chạm ngoài, `kind:none`, thẻ agent chen ngang → vẽ lại màn dưới bằng `draw()`, nút start nhả. `tick()` của kênh dưới dừng khi
  menu mở. Thiết bị không tự làm gì theo mục — app gửi lệnh.
- **Dải người dùng** (0, 0, 240×32): 6 dải ngang 5–6 px `#3D95FF` `#2B80F5` `#1C6BE8` `#0F5BDC` `#0A50D2` `#0B4CC8`; hàng y 0
  x 3–236 `#5A9BF6`. Ảnh 24×24 tại (5, 4): viền white 1 px, viền trong xpDim, nền xpSelectIcon-sáng `#93C0F3` (y 6–19) + cỏ
  `#76BE37` (y 20–25), Clawd 16×10 `#D97757` tại (9, 11). Tên `Clawd` JBMono-16B white TL (35, 7), bóng xpTitleShadow (+1, +1), 50 px.
- **Vạch cam** y 32 `#F0A030` (20 px hai đầu `#F7C97A`), y 33 `#B8661E`.
- **Thân** y 34–189: viền xpBtnEdge `#1A50C8` x 0 và x 239. Cột trái white x 1–151; x 152 `#95BDEE`; cột phải `#D3E5FA` x 153–238.
- **Cột trái** (chương trình theo skill bật):
  - Ghim (skill agent): Claude — Clawd ×2 36×20 tại (3, 39), `Claude` JBMono-12B bg TL (42, 37) 42 px, `mức dùng` JBMono-11
    xpMuted TL (42, 51) 56 px. Codex — bitmap Command Prompt 32×23 (P-.19) tại (5, 65), `Codex` (42, 66) 35 px, `mức dùng` (42, 80).
  - Vạch xpRowLine (6, 95, 140×1).
  - Chương trình khác, hàng 20 từ y 99: icon 16 tại (6, hàng+2) (Ảnh 16×14 tại hàng+3), chữ JBMono-11 bg TL (28, hàng+4):
    `Ảnh` 21, `Thời tiết` 63, `Đồng hồ` 49 px. Skill tắt → bỏ hàng, dồn lên.
  - Vạch xpRowLine (6, 163, 140×1). `Tất cả chương trình` JBMono-12B bg TL (4, 170), 133 px; mũi tên 12×12 tại (138, 171): viền
    xpStartShadow `#1E5E1E` góc cắt 1 px, nền xpStart, hàng sáng xpStartHi, tam giác trắng 4 cột (cao 8 → 2).
- **Cột phải**, hàng 21 từ y 38, icon 16 tại (156, hàng+2), chữ xpTitleShadow `#0A246A` TL (175, hàng+3): `Desktop` 12B 49 px,
  `Số liệu` 12B 49 px; vạch xpDivider (157, hàng+3, 78×1), bước 8; `Cài đặt` 11 49 px, `Thêm / gỡ` 11 63 px, `Thiết bị` 11 56 px.
  (`Bảng điều khiển` 105 px không vừa — dùng `Cài đặt`.)
- **Dải dưới** (0, 190, 240×24): 5 dải `#4285F4` `#2B72E8` `#1C64DC` `#1758D0` `#134CC2`, hàng y 190 xpTaskHi. Nút 16×16 góc cắt
  1 px: Khởi động lại (8, 194) xanh lá (`#1E5E1E` / xpStart / xpStartHi, mũi tên vòng trắng) + `Khởi động lại` JBMono-11 white TL
  (27, 196) 91 px; Tắt màn (165, 194) đỏ (`#8A1A1A` / xpIconError / `#F06A50`, ký hiệu nguồn trắng) + `Tắt màn` (184, 196) 49 px.
- **Icon 16** (bitmap trong source, nhiều màu như P-.19): Ảnh = thư mục My Pictures nhỏ, Thời tiết = mặt trời, Đồng hồ = mặt
  đồng hồ viền xanh, Desktop = màn hình nền XP, Số liệu = biểu đồ cột, Cài đặt = Control Panel (thanh trượt + chuột), Thêm / gỡ =
  hộp + đĩa CD, Thiết bị = My Computer.
- **Tất cả chương trình mở** (`XPStartAll`): hàng (2, 167, 149×20) xpSelect, chữ white, mũi tên giữ. Menu con (151, 62, 89×131):
  viền xpMenuBorder, nền white; hàng 20 từ y 64: icon tại (154, hàng+2..5), chữ JBMono-11 bg TL (173, hàng+4) — Claude (Clawd
  16×10), Codex (cửa sổ dòng lệnh 16×12), Ảnh, Thời tiết (hết x 236), Đồng hồ; vạch xpMenuBorder (155, +3, 81×1) bước 7; `Thêm / gỡ`.
  Chỉ chương trình đã cài. Đóng menu con → vẽ lại vùng (151, 62, 89×131) bằng cột phải + bỏ tô hàng.

### XP-Menu — menu chuột phải (giữ ≥ 500 ms trên app)

> **P-2026-11-27.24 — mục dưới con trỏ sáng:** thay câu "Không có mục đang trỏ" bên dưới — mục dưới con trỏ / chọn bằng phím tô xpSelect chữ white, mục mờ cũng sáng (chữ giữ xám); xem XP-Pointer.

Nguồn `source/XP-Menu-Desktop.dc.html`, `XP-Menu-Window.dc.html` · ảnh `XPMenuDesktop.png`, `XPMenuWindow.png`. Token `themeXP.menu`.

- Khung XP Luna: viền 1 px xpMenuBorder `#ACA899`, nền white, đệm trong 2 px, không bóng đổ. Mục cao 17: chữ JBMono-11 bg TL tại (x+17, mục+2); mục mờ chữ xpMenuBorder; mũi tên ▸ 4×7 tại (x+w−10, mục+5); vạch ngăn cao 7 (nét 1 px tại +3). Không có mục đang trỏ (chạm trên app chọn thẳng).
- **Desktop** (giữ chỗ trống): mở tại điểm giữ (góc trên trái), dời vào trong y ≤ 213. Rộng 166, cao 129. Mục: Sắp xếp biểu tượng ▸ (126 px), Làm mới, —, Dán (mờ), Dán lối tắt (mờ, 77 px), —, Mới ▸ (mờ), —, Thuộc tính (70 px). Ảnh: mở tại (60, 30).
- **Cửa sổ** (giữ nút thanh tác vụ: góc dưới trái tại (x nút, 213); giữ thanh tiêu đề: tại điểm giữ). Rộng 128, cao 113. Mục, ký hiệu 7×7 tại (x+5, mục+5): Khôi phục (mờ), Di chuyển (mờ), Kích thước (mờ, 70 px), Thu nhỏ, Phóng to (mờ), —, **Đóng** JBMono-12B (28 px) + `Alt+F4` JBMono-11 TR (x+w−17). Cửa sổ đang thu nhỏ: Khôi phục sáng, Thu nhỏ mờ.
- Menu đóng khi chọn mục, chạm ngoài menu, hoặc một thẻ agent chen ngang. Thuộc tính → cửa sổ Thông tin; Làm mới → vẽ lại desktop; Sắp xếp biểu tượng ▸ (menu con chưa vẽ).

### XP-Pointer — con trỏ, mục sáng, nút hot, tắt máy (app là chuột / bàn phím / nút nguồn)

> **P-2026-11-27.24 — Con trỏ chuột, mục đang sáng, tắt máy theo XP thật.**

Nguồn `source/XP-Cursor-Sheet.dc.html`, `XP-Hover-Menu.dc.html`, `XP-Hover-Start.dc.html`, `XP-Hot-Task.dc.html`,
`XP-Hot-Close.dc.html`, `XP-Cursor-Link.dc.html`, `XP-ShutDown.dc.html`, `XP-TurnOff.dc.html` · ảnh `XPCursorSheet.png`,
`XPHoverMenu.png`, `XPHoverStart.png`, `XPHotTask.png`, `XPHotClose.png`, `XPCursorLink.png`, `XPShutDown.png`,
`XPTurnOff.png`. Token `themeXP.pointer`, `themeXP.hot`, `themeXP.shutDown`, `themeXP.turnOff`. Phiếu
`docs/phieu_panel/2026-11-27-con-tro-va-tat-may.md`.

Thành phần XP thật: con trỏ *Normal Select*, *Link Select*, *Working in Background* (bộ con trỏ mặc định của XP, cỡ thật,
không bóng); mục menu dưới chuột tô *Selected Items* (menu ngữ cảnh, Start menu, All Programs); nút Luna *hot* khi chuột
đứng trên (nút thanh tác vụ, nút tiêu đề); màn *Windows is shutting down...* của Welcome screen; hộp *Turn off computer*
(Stand By / Turn Off / Restart + Cancel), mở bằng Start › Turn Off Computer hoặc Alt+F4 trên desktop.

**Con trỏ** (`XPCursorSheet`; ×4 + 1:1 trên hình nền / thanh tiêu đề / menu / thanh tác vụ):

| hình | cỡ | điểm nóng | khi nào |
|---|---|---|---|
| mũi tên | 12×19 | (0, 0) mũi | mặc định |
| bàn tay | 16×19 | (5, 0) đầu ngón | trên link (chữ xpLink gạch chân) và 3 nút của hộp Tắt máy tính |
| chờ = mũi tên + đồng hồ cát | 21×22 (đồng hồ cát 9×12 tại +10, +9; nằm ngang 12×9 tại +8, +11) | (0, 0) mũi | cửa sổ vừa mở (khung trống 200 ms) và đang tải; 4 khung × 200 ms như `themeXP.cursor` |

- Màu: black viền, white thân, cát xpAmber `#C98A00`; không bóng (RGB565, không blend). Ô trong suốt giữ nguyên điểm ảnh
  bên dưới. Pixel đúng bitmap trong `source/XP-Cursor-Sheet.dc.html` (mũi tên + bàn tay = bộ con trỏ firmware hiện có).
- Vẽ đè trên mọi nền (desktop, thân cửa sổ, tiêu đề, menu, Start, thanh tác vụ). **Không có** trên màn Đêm, màn hệ thống
  (khởi động, welcome, đăng nhập, cập nhật, đang tắt máy), khi tắt màn / tắt máy, và khi app không ở chế độ chuột.
- **Thống nhất con trỏ chờ:** XP-Open bước 3–4 vẽ con trỏ chờ **tại chỗ chuột** (điểm nóng = vị trí con trỏ đang có) thay vì
  ô cố định (132, 160); app không ở chế độ chuột → giữ ô cố định như cũ. Hết chờ → con trỏ trở lại hình app gửi.
- App chọn hình và vị trí; thiết bị chỉ vẽ. Đổi hình tại chỗ = vẽ lại ô cũ rồi vẽ hình mới.

**Mục sáng** (`XPHoverMenu`, `XPHoverStart`): mục dưới con trỏ, hoặc mục chọn bằng phím mũi tên.

- Menu chuột phải (desktop / cửa sổ): nền xpSelect `#316AC5` (x+2, mục, w−4 × 17), chữ white, mũi tên ▸ / ký hiệu 7×7 white.
  Ví dụ: `Làm mới` (62, 49, 162×17), chữ (77, 51).
- Start menu, cột trái: hàng (2, hàng, 149×20) xpSelect, icon giữ màu, chữ white (ví dụ `Thời tiết` hàng y 119, chữ (28, 123)).
  Ghim (Claude / Codex): (2, y, 149×28), tên + `mức dùng` white. `Tất cả chương trình` = như `XPStartAll`.
  Cột phải: hàng (154, hàng, 84×21) xpSelect, chữ white. Dải dưới (`Khởi động lại`, `Tắt máy`): nút 16 sáng (hàng trên
  white thay màu sáng của nút), chữ giữ white.
- Menu con Tất cả chương trình: hàng (152, hàng, 87×20) xpSelect, chữ white.
- **Mục mờ**: như XP — vẫn tô xpSelect khi chuột / phím đứng trên, chữ giữ xpMenuBorder; phím mũi tên đi qua cả mục mờ, bỏ
  qua vạch ngăn. Chọn mục mờ = không làm gì.
- Đổi mục sáng: chỉ vẽ lại 2 hàng (hàng cũ về thường, hàng mới sáng), không vẽ lại cả menu.

**Nút hot** (`XPHotTask`, `XPHotClose`): chuột đứng trên → sáng; rời → về thường. Nút đang lún không đổi.

- Nút thanh tác vụ: mặt 26×18 xpBtn → xpTaskHi `#5A9BF6`, viền giữ; icon giữ.
- Nút × của tiêu đề: mặt 14×14 `#E0523C` → `#F06A50`, viền white + dấu × giữ. Nút _ : `#2B80F5` → xpTitleHi `#3D95FF`.
  Nút □ (luôn tắt) không sáng.
- Nút start: không đổi (hot của XP gần như không thấy ở 240 px).

**Đang tắt máy** (`XPShutDown`, màn hệ thống): chrome welcome như `XP-Connecting` (không chữ `welcome`); chữ nghiêng
`đang tắt máy...` bitmap 1-bit 145×18 từ JBMono-16B (nghiêng 1 px / 3 hàng) tại (20, 96), bóng xpWelcomeShadow tại (21, 97) —
cùng kiểu, cùng chỗ với `đang cập nhật...`. Giữ 1,5 s (power `shutting`), rồi đèn tắt (power `off`). Không con trỏ, không
thanh tác vụ. Thẻ agent khẩn vẫn đánh thức như tắt màn.

**Bật lại** (power `booting`): màn khởi động `XP-Splash` (2,4 s) → welcome `XP-Connecting` 1 s → desktop, không cửa sổ
nào mở (như XP thật: boot → Welcome → desktop).

**Hộp Tắt máy tính** (`XPTurnOff`): mở bằng Start › `Tắt máy` hoặc Alt+F4 khi desktop đang hiện (không cửa sổ nào ở trên).

| khối | tọa độ | màu / font | chữ, rộng đo (VLW) |
|---|---|---|---|
| màn phía sau | cả 240×240, điểm (x + y) chẵn → black | black | thay "xám dần" của XP (máy không đọc lại điểm ảnh) |
| khung | (13, 49, 214×130) | black 1 px | — |
| dải tiêu đề | (14, 50, 212×28) | xpWelcomeBand `#00309C` | `Tắt máy tính` JBMono-12B white TL (22, 57) 84 px |
| cờ | 14×12 tại (204, 58) | xpFlagRed / Green / Blue / Yellow | — |
| vạch | (14, 78, 212×1) | xpWelcomeLine `#7FA4F0` | — |
| vùng nút | (14, 79, 212×66) | xpWelcome `#5A7EDC` | — |
| 3 nút | 24×24 góc cắt 1 px, tâm x 50 / 120 / 190, y 90; viền black, viền trong white, mặt 20×20, hàng trên sáng; ký hiệu white 10×12 tại (+7, +6) | Chờ xpIconWarn `#F2C200` (sáng `#FFE680`); Tắt xpIconError `#D8341E` (`#F06A50`); Khởi động lại xpGreen `#2E8A2E` (xpStartHi) | nhãn JBMono-11 white TC tại y 117: `Chờ` 21, `Tắt` 21, `Khởi động` 63 + `lại` 21 (y 129) |
| dải dưới | (14, 145, 212×33) | xpWelcomeBand | — |
| nút Hủy | (164, 151, 54×21) viền `#003C74` góc cắt 1 px, nền `#F4F3EE`, 2 hàng đáy `#D6D0C5` | JBMono-11 black TC (191, 155) | `Hủy` 21 px |

- Nút dưới con trỏ / đang chọn bằng phím: mặt đổi sang màu sáng, hàng trên white (ảnh: `Tắt`). Con trỏ bàn tay trên 3 nút.
  Phím: ←/→ đổi nút, Enter chọn, Esc = Hủy.
- **Chờ** = tắt màn như cũ (đèn 0, máy chạy, thẻ khẩn đánh thức). **Tắt** = đang tắt máy → tối. **Khởi động lại** = đang tắt
  máy → bật lại (khởi động → welcome → desktop trống). **Hủy** / Esc → vẽ lại màn dưới bằng `draw()`.
- Thẻ agent chen ngang → hộp đóng (như menu).

**Start menu** (`XPStartMenu`, `XPStartAll`): nút dưới phải `Tắt màn` → **`Tắt máy`** (49 px, nút đỏ giữ) = *Turn Off Computer*
của XP, mở hộp Tắt máy tính. `Khởi động lại` bên trái giữ như P-.20.

### XP-TaskMgr — Trình quản lý tác vụ (kênh `TaskMgr`)

> **P-2026-11-28.28 — Task Manager kiểu XP.** Phiếu `docs/phieu_panel/2026-11-27-task-manager.md`.

Nguồn `source/XP-TaskMgr-Apps|Hover|Empty|Perf|Net.dc.html` · ảnh `XPTaskMgrApps.png`, `XPTaskMgrHover.png`,
`XPTaskMgrEmpty.png`, `XPTaskMgrPerf.png`, `XPTaskMgrNet.png`. Token `themeXP.taskMgr`. Thành phần XP thật: *Windows Task
Manager* (tab Applications, Performance, Networking; thanh trạng thái 3 ô). Chương trình hệ thống: không thuộc skill, không
biểu tượng desktop; mở bằng Ctrl+Alt+Del của app hoặc chuột phải thanh tác vụ › Trình quản lý tác vụ.

- **Khung**: cửa sổ XP, tiêu đề `Trình quản lý tác vụ` 12B (140 px), biểu tượng 16×16 tại (4, 3): khung xpLabel, dải tiêu đề
  `#0A4BE0`, thân đen, lưới `#004000`, đường đồ thị `#00FF00`. Không thanh menu. □ tắt như mọi cửa sổ.
- **Tab** (y 26–41, như Đồng hồ): `Ứng dụng` (6, w 66) · `Hiệu năng` (72, w 73) · `Mạng` (145, w 38); chữ TL (x+5, 29).
  Trang (6, 41, 228×152) viền xpFieldBorder, nền white (y 42–191).
- **Thanh trạng thái** (2, 196, 236×18) xpBody, vạch trên xpDim; 3 ô lõm (viền trái / trên xpDim, phải / dưới white):
  x 3–78 `Tác vụ: 3` (63), x 80–148 `CPU: 12%` (56), x 150–236 `Trống: 21K` (70); chữ JBMono-11 TL (x+4, 199).
  Vẽ lại mỗi giây chỉ ô nào đổi số.

**Ứng dụng** (`XPTaskMgrApps`):

| khối | tọa độ | màu / font | chữ, rộng đo |
|---|---|---|---|
| ListView | (10, 46, 220×112) viền xpFieldBorder | white | — |
| hàng tiêu đề | (11, 47, 218×15) xpBody, vạch y 62 xpGroup + y 63 xpDim; vạch cột (150, 50, 1×10) xpDim | `JBMono-11` black TL (16, 48) / (156, 48) | `Tác vụ` 42 / `Trạng thái` 70 |
| dòng | cao 18 từ y 64; biểu tượng 16 (Start icons) tại (14, dòng+1…4); tên TL (34, dòng+2); trạng thái TL (156, dòng+2) | `JBMono-11` black | `Claude`, `Thời tiết`, `Ngày và Giờ` 77; `Đang chạy` 63 |
| dòng chọn | (11, dòng, 218×18) xpSelect, chữ white | — | — |
| nút | `Kết thúc tác vụ` (26, 165, 117×21) · `Chuyển tới` (147, 165, 82×21): viền `#003C74` góc cắt 1 px, nền `#F4F3EE`, 2 hàng đáy `#D6D0C5`, chữ căn giữa (y+3) | `JBMono-11` black | 105 / 70 |

- Mỗi cửa sổ trong `windows.open` một dòng, theo thứ tự mở; tên = tiêu đề cửa sổ. Dòng chọn do app gửi.
- **Không cửa sổ nào** (`XPTaskMgrEmpty`): danh sách trống, hai nút chữ xpDim (mờ), `Tác vụ: 0`.
- **Con trỏ trên nút** (`XPTaskMgrHover`, nút *hot* của XP): viền trong cam — hàng y+1 `#FFF0CF`, y+2 và y+h−3 `#F9B348`,
  cột x+1 / x+w−2 (y+2…y+h−3) `#F9B348`, hàng y+h−2 `#E59700`. Chỉ vẽ lại nút đó.

**Hiệu năng** (`XPTaskMgrPerf`):

| khối | tọa độ | màu / font | chữ |
|---|---|---|---|
| groupbox `CPU` | (10, 50, 52×46) | như XP-Real | `CPU` 21 |
| đồng hồ đo CPU | nền đen (14, 56, 44×36); 6 nấc × 2 cột 6×2 px từ (29, 59), bước 3; nấc sáng `#00FF00`, tắt `#007F00`; số TC (36, 79) | `JBMono-11` `#00FF00` | `12 %` 28 |
| groupbox `Lịch sử dùng CPU` | (66, 50, 164×46) | — | 112 |
| đồ thị | nền đen (70, 56, 156×36); lưới `#008040` mỗi 12 px; đường `#00FF00` 1 px, mỗi điểm 4 px (1 s), 38 điểm, mới nhất ở mép phải | — | — |
| groupbox `Bộ nhớ` + đo | (10, 104, 52×46); đo (14, 110, 44×36) = heap đã dùng / tổng; số | — | `Bộ nhớ` 42; `20K` 21 |
| groupbox `Lịch sử bộ nhớ` + đồ thị | (66, 104, 164×46); (70, 110, 156×36) | — | 98 |
| groupbox `Bộ nhớ (KB)` | (10, 158, 130×34); `Còn trống` TL (14, 162) + giá trị TR (136, 162); `Khối lớn` TL (14, 176) + TR (136, 176) | `JBMono-11` black | 63 / 56; `21412` / `15200` 35 (heap, maxblk) |
| groupbox `Đã chạy` | (144, 158, 86×34); giá trị TC (187, 170) | `JBMono-11` | 49; `2NG 3G 14P` 70 (`shortDuration`) |

Mỗi giây: cuộn 2 đồ thị (vẽ lại cả ô đen 156×36), số đo, 2 giá trị KB; `Đã chạy` mỗi phút. Lịch sử giữ trong RAM (38 điểm × 3),
không xoá khi `draw()` vẽ lại dưới con trỏ.

**Mạng** (`XPTaskMgrNet`):

- `Wi-Fi · Đã kết nối` TL (10, 46) xpGroupLabel (126); nhãn trục `100%` TR (38, 62), `0%` TR (38, 120) xpLabel.
- Đồ thị (40, 61, 190×72) như trên = cường độ Wi-Fi % (RSSI −100…−40 dBm → 0…100 %), 48 điểm.
- ListView (10, 140, 220×38): tiêu đề `Mạng` (15) · `Tín hiệu` (80) · `IP` (145), vạch cột x 75 / 140; dòng y 160:
  ssid (tối đa 8 ký tự = 56 px, cắt `Utf8::copy`), `-58 dBm` 49, `192.168.1.23` 84.

### XP-Start-All — Start đủ chương trình (mọi chương trình mở được từ Start)

> **P-2026-11-27.25 — Start đủ chương trình, cột trái hay dùng, biểu tượng Dò mìn.**

Nguồn `source/XP-Start-All-Full.dc.html`, `XP-Start-Recent.dc.html`, `XP-Desk-Fun.dc.html` · ảnh `XPStartAllFull.png`,
`XPStartRecent.png`, `XPDeskFun.png`. Token `themeXP.startAll`. Phiếu `docs/phieu_panel/2026-11-27-start-du-chuong-trinh.md`.
Thành phần XP thật: *All Programs* (mọi chương trình đã cài; menu cao quá màn thì dời lên, thiếu chỗ bên phải thì lấn sang
trái), danh sách *most frequently used* ở cột trái Start, biểu tượng desktop xếp *Auto Arrange* theo cột.

- **Menu con Tất cả chương trình**: thứ tự Claude, Codex, AI hôm nay, Xu hướng, Agents (skill Agent; Agents chỉ khi
  `showAgents`), Ảnh (skill Ảnh), Thời tiết, Đồng hồ, Dò mìn (skill Giải trí `fun`), vạch, `Thêm / gỡ`. Skill tắt → bỏ hàng.
  - Khung (144, y, 96 × (4 + 20·n + 7 + 20)), viền xpMenuBorder, nền white. Rộng 96 vì `AI hôm nay` 70 px (x 166–235);
    lấn 7 px lên cột trái (hàng `Tất cả chương trình` sáng còn thấy tới x 143).
  - Đỉnh y 62 như P-.20 nếu đáy ≤ 213; không thì dời lên cho đáy ≤ 213 (đủ cả: (144, 2, 96×211), đáy y 212). Không chia hai
    cột: đủ cả mới 11 hàng.
  - Hàng 20 từ y+2: icon 16 tại (147, hàng+2) (icon cũ giữ như P-.20), chữ JBMono-11 bg TL (166, hàng+4). Vạch xpMenuBorder
    (148, +3, 88×1), cao 7. Đo: `AI hôm nay` 70, `Xu hướng` 56, `Agents` 42, `Dò mìn` 42 px.
  - Mục sáng như XP-Pointer: hàng (145, hàng, 94×20) xpSelect, chữ white.
- **Icon 16 mới** (bitmap trong source): AI hôm nay = đồng hồ đo (vòng xanh lá → vàng → đỏ, kim đen, đế xám); Xu hướng =
  khung xanh nền white, lưới `#D3E5FA`, đường đỏ đi lên; Agents = hai người (sau xanh dương, trước xanh lá); Dò mìn = mìn
  13×13 tại (+1, +1) (như ô bảng chơi).
- **Cột trái (hay dùng)** (`XPStartRecent`): 3 hàng y 99 / 119 / 139 = 3 chương trình mở gần nhất (mới nhất trên), không kể
  Claude / Codex (đã ghim), chỉ chương trình của skill đang bật; chưa đủ 3 → bù theo thứ tự Ảnh, Thời tiết, Đồng hồ, Dò mìn,
  AI hôm nay, Xu hướng, Agents. Danh sách giữ trong RAM (tắt nguồn → về thứ tự trên).
- **Desktop** (`XPDeskFun`): skill Giải trí bật → biểu tượng `Dò mìn` 32×23 (ô xám nổi 22×22 + mìn, bóng chấm như P-.19).
  Cột 1 đủ 4 ô (Claude, Codex, Ảnh, Thùng rác) → sang cột 2 tâm x 120, ô y 8: icon (104, 8), nhãn `Dò mìn` 42 px TC
  (120, 32), bóng đen (+1, +1). Ít chương trình hơn → Dò mìn vào cột 1 trước Thùng rác (Thùng rác luôn cuối cột 1).
- Một trò chơi → để thẳng `Dò mìn`; có trò thứ hai → thư mục `Trò chơi ▸` như XP (vẽ sau).

### XP-Mines — Dò mìn (kênh `Mines`, skill Giải trí `fun`)

> **P-2026-11-27.25 — Dò mìn như Minesweeper của XP.**

Nguồn `source/XP-Mines.dc.html`, `XP-Mines-Play.dc.html`, `XP-Mines-Win.dc.html`, `XP-Mines-Lose.dc.html` · ảnh
`XPMines.png`, `XPMinesPlay.png`, `XPMinesWin.png`, `XPMinesLose.png`. Token `themeXP.mines`. Phiếu
`docs/phieu_panel/2026-11-27-minesweeper.md`. Thành phần XP thật: *Minesweeper*, mức Beginner 9×9, 10 mìn.

- **Cửa sổ XP** `XP::window`: tiêu đề `Dò mìn` JBMono-12B white (24, 5) 42 px, bóng xpTitleShadow (+1, +1); icon tiêu đề =
  mìn 13×13 tại (6, 5) (black, chấm sáng white). Không thanh trạng thái. Nút thanh tác vụ: mìn 13×13 white tại (nút+7, 220).
- **Không có thanh menu** "Trò chơi  Trợ giúp" (XP có): thân chỉ 192 px, thêm 18 px thì bảng ô 16 tràn y 213. Ván mới =
  click mặt cười (như XP). Chỉ mức Beginner.
- **Thân** (2, 22, 236×192) xám `#C0C0C0`. Viền lõm = trên + trái `#808080`, dưới + phải white; viền nổi ngược lại; góc cắt
  chéo 45°.
- **Bảng đếm** lõm 2 px (45, 26, 150×31).
  - LED hộp lõm 1 px 41×25: mìn còn lại tại (51, 30), giây tại (148, 30); trong black 39×23, 3 số 7 đoạn 13×23 vẽ bằng hình
    (đoạn dày 3, vát đầu), sáng `#FF0000`, tắt `#480000`. Giây 0–999 (dừng ở 999); mìn còn lại = 10 − cờ, âm → `-01`.
  - Mặt cười 26×26 tại (107, 29): viền `#808080` 1 px, nổi 2 px, mặt vàng `#FFFF00` tròn ⌀17 viền black tâm (120, 42).
    `smile` thường; `wow` (miệng tròn) khi chuột trái đang giữ trên ô chưa mở; `cool` (kính) khi thắng; `dead` (mắt X,
    miệng mếu) khi thua. Đang giữ trên mặt cười → nút lõm (viền `#808080` 1 px, mặt dời +1, +1).
- **Bảng** lõm 3 px (45, 61, 150×150); ô 16×16, ô (c, r) tại (48 + 16c, 64 + 16r).
  - Chưa mở: `#C0C0C0`, nổi 2 px. Cờ: chưa mở + cờ 9×9 tại (+4, +3) (lá `#FF0000`, cán + đế black).
  - Đã mở: `#C0C0C0`, vạch `#808080` 1 px trên + trái. Số 1–8 JBMono-16B giữa ô, màu XP: 1 `#0000FF`, 2 `#008000`,
    3 `#FF0000`, 4 `#000080`, 5 `#800000`, 6 `#008080`, 7 black, 8 `#808080`.
  - Đang nhấn (chuột trái giữ trên ô chưa mở, không cờ) = vẽ như ô đã mở trống; rời ô / nhả → về lại. Ô dưới con trỏ không
    sáng (như XP).
  - Thua: mìn 13×13 tại (+2, +2) trên ô mở cho mọi mìn chưa cắm cờ; mìn vừa click nền `#FF0000`; cờ cắm sai = mìn + chéo
    đỏ 2 px; cờ đúng giữ. Thắng: mọi mìn tự cắm cờ, LED trái `000`.
- **Luật như XP**: click đầu không bao giờ trúng mìn (đặt mìn sau click đầu); ô 0 mở lan ô kề; đồng hồ chạy từ click đầu,
  dừng khi thắng / thua; click trái lên cờ không làm gì; click phải ô chưa mở → cờ, lên cờ → gỡ (bỏ dấu `?` của XP); ván
  xong thì bảng không nhận click, chỉ mặt cười. Click hai nút (chord) chưa làm.
- **Vẽ lại từng phần**: mở ô / cắm cờ chỉ vẽ ô đó (vùng lan = các ô vừa mở); giây vẽ lại một LED mỗi giây; mặt cười vẽ lại
  khi đổi. `draw()` vẽ đúng ván đang có (không reset), an toàn dưới con trỏ (`clipHits` theo ô).

### XP-Desk-Tray — thời tiết ở khay, bong bóng XP

Nguồn `source/XP-Desk-Tray.dc.html`, `source/XP-Desk-Balloon.dc.html` · ảnh `XPDeskTray.png`, `XPDeskBalloon.png`. Token `themeXP.taskbar.tray`, `themeXP.desktop.balloon`.

- **Khay** (mọi màn có thanh tác vụ, khi skill Thời tiết bật): x 176–239 (rộng thêm 20 px), viền trái xpTrayEdge x 176, hàng sáng xpTrayHi y 214; biểu tượng thời tiết 16×14 màu xpIconWarn `#F2C200` tại (180, 220); giờ JBMono-11 white TC (218, 221) như cũ. Skill Thời tiết tắt → khay như cũ (x 196). Thanh tác vụ khi đó chứa tối đa **3** nút cửa sổ (x 71 / 101 / 131).
- **Desktop bình thường** (`XPDeskTray`): không có bong bóng; cột 1 xếp được tới 4 biểu tượng (y 8 / 56 / 104 / 152).
> **P-2026-11-26.21 — bỏ bong bóng thời tiết:** desktop không bao giờ hiện bong bóng (bỏ hai mục Bong bóng / Khi hiện dưới đây). Biểu tượng thời tiết ở khay giữ (180, 220); app chạm nó → mở cửa sổ Thời tiết, tab Hiện tại. Thời tiết chỉ còn ở khay + cửa sổ Thời tiết.

- **Bong bóng** (`XPDeskBalloon`, XP notification balloon): hộp (96, 138, 140×62) viền đen 1 px, nền xpInfoBar, góc bo 2 px theo bậc; đuôi mở từ đáy x 178–190 xuống đỉnh (190, 211), cạnh phải thẳng, chỉ vào biểu tượng khay. Tiêu đề: icon thời tiết xpAmber (102, 144) + `Thời tiết` JBMono-12B (122, 144); nút × 12×12 tại (220, 143) (viền xpDim, nền white, × đen 6×6). Thân: `29° · Ít mây` JBMono-11 (102, 164), `cảm giác 33°` xpLabel (102, 178). Đè lên biểu tượng desktop.
- **Khi hiện**: ~10 s khi vào desktop, và khi thời tiết đổi (mô tả khác hoặc nhiệt độ lệch ≥ 3°) lúc desktop đang hiện; rồi tự ẩn (vẽ lại hình nền + biểu tượng dưới hộp và đuôi). App chạm biểu tượng khay → hiện lại 10 s; chạm × → ẩn ngay. Thẻ agent chen ngang → ẩn. Mỗi lúc một bong bóng. Thời tiết chưa có / lỗi: thân `Chưa có thời tiết` xpDim.

### XP-Open — mở / khôi phục / thu nhỏ cửa sổ, đang tải

> **P-2026-11-27.24 — con trỏ chờ tại chỗ chuột:** ở chế độ chuột, con trỏ chờ vẽ tại vị trí con trỏ (điểm nóng = mũi) thay ô cố định (132, 160); xem XP-Pointer.

Nguồn `source/XP-Open-1|2|3.dc.html`, `XP-Open-Play.dc.html` (chạy thử 6 s), `XP-Load-Claude.dc.html` (động), `XP-Load-Static.dc.html` · ảnh `XPOpen1.png`, `XPOpen2.png`, `XPOpen3.png`, `XPLoad.png`. Token `themeXP.open`, `themeXP.cursor`, `themeXP.loading`.

Thành phần XP thật: *Animate windows when minimizing and maximizing* (thanh tiêu đề bay giữa nút thanh tác vụ và cửa sổ), con trỏ *Working in Background* (mũi tên + đồng hồ cát), hộp thoại *File Download* (giấy bay từ quả địa cầu sang thư mục).

**Thứ tự khi một cửa sổ lên màn** (mọi kênh có cửa sổ; không áp cho Night, thẻ Attention, màn hệ thống):

1. **Nút lún trước** (`XPOpen1`): nút của cửa sổ trên thanh tác vụ đổi sang xpBtnPressedEdge / xpBtnPressed ngay; chỉ vẽ lại nút đó (và nút vừa nhả), **không** vẽ lại cả thanh tác vụ.
2. **Thanh tiêu đề bay** (`XPOpen2`) — chỉ khi **khôi phục cửa sổ đang thu nhỏ** (có trong `windows.min`). Dải từ khung nút (71 + 30k, 217, 28×20) tới thanh tiêu đề (0, 0, 240×22), 4 bước t = 0,2 / 0,4 / 0,6 / 0,8 (x, y, w, h nội suy tuyến tính, làm tròn), mỗi bước 40 ms. Mỗi dải: nền xpTitle, hàng đầu xpTitleHi, hàng 2 xpTitleLight, hàng cuối xpTitleEdge. Không xóa dải trước (không có bộ đệm màn) — vệt nằm trong y 0–213 nên cửa sổ phủ hết. **Thu nhỏ** (cửa sổ vào `min`, desktop hiện): ngược lại t = 0,8 → 0,2 vẽ đè lên cửa sổ, rồi desktop vẽ phủ. Mở chương trình mới, chuyển sang cửa sổ đang mở phía sau, thẻ agent chen ngang: **không bay** (như XP thật), đi thẳng bước 3.
3. **Khung trước** (`XPOpen3`): thanh tiêu đề + khung + thân xpBody trống (+ thanh trạng thái trống nếu kênh có), giữ 200 ms (1 nhịp tick); con trỏ chờ hiện.
4. **Nội dung**: có dữ liệu → vẽ nội dung, con trỏ mất (nội dung vẽ đè). Chưa có dữ liệu → màn đang tải mới (dưới), con trỏ giữ tới khi có số liệu.

**Con trỏ chờ** (mũi tên + đồng hồ cát): mũi tên 12×19 mũi tại (132, 160); đồng hồ cát 9×12 tại (142, 169), 4 khung × 200 ms (cát trên → chảy → dưới → nằm ngang 12×9 tại (140, 171)), lặp. Chỉ vẽ lại ô 21×22 của đồng hồ cát mỗi khung, nền xpBody. Không có trên desktop.

**Đang tải** (`XPLoad`, thay mục "Đang tải" ở trên cho Claude / Codex / Thời tiết / AI khi cả cửa sổ chưa có số liệu):

| khối | tọa độ | màu / font | chữ, rộng đo (VLW) |
|---|---|---|---|
| quả địa cầu | 24×24 tại (30, 36) | xpTitleEdge / xpIconInfo / xpGreen | — |
| thư mục | 24×20 tại (186, 38) | xpAmber / xpUserPic | — |
| tờ giấy | 10×11, 6 vị trí x 60 / 80 / 100 / 120 / 140 / 160, y 48 / 43 / 40 / 40 / 43 / 48; 1 vị trí / 200 ms; xóa ô cũ bằng xpBody | xpFieldBorder / white / xpDim | — |
| nhãn | TC (120, 92) | `JBMono-12B` black | `Đang tải...` 77 px |
| thanh chạy | (50, 116, 140×14), khối x 53 + 15i, y 119, 13×8; 3 khối sáng chạy, 1 ô / 200 ms | xpFieldBorder, white, xpBar | — |
| nguồn | TC (120, 140) | `JBMono-11` xpMuted | `từ claude.ai` 84 · `từ chatgpt.com` 98 · `từ open-meteo.com` 119 px |
| con trỏ chờ | như trên | — | — |

Đồng hồ khay: XP thật **không** nhấp nháy dấu `:` — giữ như hiện tại, chỉ đổi theo phút.

**Mũi tên (X black, W white)** (12×19):

```
X...........
XX..........
XWX.........
XWWX........
XWWWX.......
XWWWWX......
XWWWWWX.....
XWWWWWWX....
XWWWWWWWX...
XWWWWWWWWX..
XWWWWWWWWWX.
XWWWWWWXXXXX
XWWWXWWX....
XWWXXWWX....
XWX..XWWX...
XX...XWWX...
X.....XWWX..
......XWWX..
.......XX...
```

**Đồng hồ cát khung 0 (S xpAmber)** (9×12):

```
XXXXXXXXX
.XSSSSSX.
.XSSSSSX.
..XSSSX..
...XSX...
...XWX...
..XWWWX..
.XWWWWWX.
.XWWWWWX.
.XWWWWWX.
.XWWWWWX.
XXXXXXXXX
```

**Đồng hồ cát khung 1 (S xpAmber)** (9×12):

```
XXXXXXXXX
.XWWWWWX.
.XWWWWWX.
..XSSSX..
...XSX...
...XSX...
..XWSWX..
.XWWSWWX.
.XWWWWWX.
.XWWSWWX.
.XSSSSSX.
XXXXXXXXX
```

**Đồng hồ cát khung 2 (S xpAmber)** (9×12):

```
XXXXXXXXX
.XWWWWWX.
.XWWWWWX.
..XWWWX..
...XWX...
...XWX...
..XWWWX..
.XWWWWWX.
.XWSSSWX.
.XSSSSSX.
.XSSSSSX.
XXXXXXXXX
```

**Đồng hồ cát khung 3 (S xpAmber)** (12×9):

```
X..........X
XXX....XXXXX
XWWX..XWWSSX
XWWWXXWWSSSX
XWWWWWWWSSSX
XWWWXXWWSSSX
XWWX..XWWSSX
XXX....XXXXX
X..........X
```

**Quả địa cầu (E xpTitleEdge, B xpIconInfo, L xpGreen)** (24×24):

```
........................
.......EEEEEEEEEE.......
......EEBBBBBBBBEE......
....EELLLBBBBBBBBBEE....
...EELLLLLLBBBBBBBBEE...
...ELLLLLLLBBBBBLLLLE...
..ELLLLLLLLLBBBBLLLLBE..
.EELLLLLLLLLBBBBLLLLBEE.
.EBLLLLLLLLLBBBBBBBBBBE.
.EBLLLLLLLLLBBBBBBBBBBE.
.EBLLLLLLLLLBBBBBBBBBBE.
.EBBLLLLLLLBBBBBBBBBBBE.
.EBBLLLLLLLBBBLLLBBBBBE.
.EBBBBLLLBBBBLLLLLBBBBE.
.EBBBBBBBBBBLLLLLLLBBBE.
.EBBBBBBBBBBLLLLLLLBBBE.
.EEBBBBBBBBBLLLLLLLBBEE.
..EBBBBBBBBBLLLLLLLBBE..
...EBBBBBBBBLLLLLLLBE...
...EEBBBBBBBBLLLLLBEE...
....EEBBBBBBBBLLLBEE....
......EEBBBBBBBBEE......
.......EEEEEEEEEE.......
........................
```

**Thư mục (D xpAmber, F xpUserPic)** (24×20):

```
DDDDDDDD................
DFFFFFFFD...............
DFFFFFFFFDDDDDDDDDDDDDD.
DFFFFFFFFFFFFFFFFFFFFFFD
DFFFFFFFFFFFFFFFFFFFFFFD
DFFFFFFFFFFFFFFFFFFFFFFD
DFFFFFFFFFFFFFFFFFFFFFFD
DFFFFFFFFFFFFFFFFFFFFFFD
DFFFFFFFFFFFFFFFFFFFFFFD
DFFFFFFFFFFFFFFFFFFFFFFD
DFFFFFFFFFFFFFFFFFFFFFFD
DFFFFFFFFFFFFFFFFFFFFFFD
DFFFFFFFFFFFFFFFFFFFFFFD
DFFFFFFFFFFFFFFFFFFFFFFD
DFFFFFFFFFFFFFFFFFFFFFFD
DFFFFFFFFFFFFFFFFFFFFFFD
DFFFFFFFFFFFFFFFFFFFFFFD
DFFFFFFFFFFFFFFFFFFFFFFD
DDDDDDDDDDDDDDDDDDDDDDDD
........................
```

**Tờ giấy (B xpFieldBorder, W white, L xpDim)** (10×11):

```
BBBBBBB...
BWWWWWBB..
BWLLLWWBB.
BWWWWWWWB.
BWLLLLLWB.
BWWWWWWWB.
BWLLLLLWB.
BWWWWWWWB.
BWLLLLLWB.
BWWWWWWWB.
BBBBBBBBB.
```

### XP-Real — Đồng hồ, Thời tiết, Dự báo, Đêm, Desktop theo XP thật

Nguồn `source/XP-Clock-Props.dc.html`, `XP-Weather-Props.dc.html`, `XP-Forecast-Details.dc.html`, `XP-Night-Saver.dc.html` (+ `XP-Night-Saver-Play.dc.html`), `XP-Desk-OneCol.dc.html` · ảnh `XPClockProps.png`, `XPWeatherProps.png`, `XPForecastDetails.png`, `XPNightSaver.png`, `XPDeskOneCol.png`. Token `themeXP.tabs`, `themeXP.dateTime`, `themeXP.weatherSheet`, `themeXP.listView`, `themeXP.saver`, `themeXP.desktop.icons`.

Thành phần XP thật: hộp thoại *Date and Time Properties*, trang thuộc tính (tab *General*), điều khiển tab Luna, ListView dạng *Details*, trình bảo vệ màn hình, desktop chỉ có chương trình đã cài.

**Tab (Luna)** — dùng cho Đồng hồ và Thời tiết:

- Trang tab: viền xpFieldBorder (6, 41, 228×169), nền white (7, 42, 226×167).
- Tab đang chọn: y 26–41, viền xpFieldBorder, nền white liền với trang (che viền trên), hàng y 26 xpWelcomeOrange, y 27–28 xpFlagYellow; chữ `JBMono-11` black TL (x + 5, 29).
- Tab khác: y 28–40, viền xpFieldBorder, nền xpRowLine; chữ như trên.
- Tab xếp liền từ x 6; rộng = chữ + 10 (làm tròn): Đồng hồ `Ngày và giờ` 87, `Múi giờ` 59; Thời tiết `Hiện tại` 66, `Dự báo` 52.
- Groupbox trên trang tab: nền nhãn white (không phải xpBody).

**Đồng hồ = Ngày và Giờ** (`XPClockProps`; kênh `Clock`). Tiêu đề cửa sổ `Ngày và Giờ` 12B (77 px).

> **P-2026-11-26.22 — Ngày và Giờ chạm được, 3 tab** (`XPClockProps`, `XPClockMonth`, `XPClockZone`, `XPClockNet`; source
> `XP-Clock-Props|Month|Zone|Net.dc.html`). Theo *Date and Time Properties* XP thật (tab *Date & Time*, *Time Zone*, *Internet
> Time*). Thay các hàng `tab` và `ô tháng` của bảng dưới; các khối khác giữ.
>
> - **Tab**: `Ngày và giờ` (6, 87 rộng) · `Múi giờ` (93, 59) · `Internet` (152, 66; chữ 56 px). Tab chọn như cũ (viền trên
>   xpWelcomeOrange + 2 hàng xpFlagYellow); app chạm tab → đổi trang, vẽ lại trang (7, 42, 226×167) + 3 tab.
> - **Ô tháng** (14, 62, 67×16): chữ `Thg 11` TL (17, 63) 42 px (tên tháng ngắn của Windows tiếng Việt, `Thg 1`…`Thg 12`);
>   nút xổ (66, 63, 14×14) xpBtn + tam giác white. **Ô năm** (85, 62, 44×16): `2026` TL (87, 63) 28 px; nút tăng giảm
>   (116, 63, 12×14) xpBody, vạch giữa xpFieldBorder, tam giác black. ▲▼ năm → lịch năm đó.
> - **Danh sách tháng mở** (`XPClockMonth`): (14, 78, 67×119) viền black 1 px, nền white; 9 dòng × 13 từ y 79, chữ TL (17,
>   dòng); dòng tháng đang xem xpSelect (15, dòng, 55×13) chữ white. Thanh cuộn x 70–79 nền `#F4F3EE`, nút ▲ / ▼ 10×10
>   xpBtnEdge / xpBtn + mũi tên white 3×2, con trượt xpBtn viền xpBtnEdge. Chọn tháng → đóng danh sách, vẽ lại ô tháng + lịch.
> - **Chạm một ngày** → ô đó xpSelect chữ white (bỏ tô ô cũ); hôm nay không còn tô nếu chọn ngày khác. Chỉ để xem.
> - **Ô giờ chỉ đọc** (giờ đồng bộ Internet): nền xpBody thay white, nút tăng giảm (208, 153) tam giác xpDim.
> - **Tab Múi giờ** (`XPClockZone`): ô chọn (12, 50, 216×18), `(GMT+07:00) Hà Nội` TL (15, 52) 126 px, nút xổ (213, 52).
>   Bản đồ (12, 74, 218×90) viền xpFieldBorder; lưới 27 × 11 ô 8 px từ (13, 75): biển `#3C7FD8`, đất `#5E9E36`; cột múi đang
>   chọn (cột = round((kinh độ giữa múi + 180) / 13,33)) biển `#7FB0EE`, đất `#8FCF5A`. Hình đất: bảng `land` trong token.
>   ☐ (12, 172, 13×13) mờ (viền xpDim, nền xpBody) + `Tự chỉnh giờ mùa hè` xpDim TL (30, 172) 133 px — mờ vì múi không có giờ
>   mùa hè. Chạm ô chọn → danh sách múi giờ (cùng kiểu danh sách tháng, rộng 216); chọn → đổi múi giờ thiết bị, vẽ lại.
> - **Tab Internet** (`XPClockNet`): ☑ (12, 52) viền xpFieldBorder, dấu xpCheck 7×6 tại (+3, +3) + `Tự đồng bộ với máy chủ`
>   (30, 52) 154 px; `Máy chủ:` (12, 77) 56 px + ô (72, 74, 156×18) `pool.ntp.org` (75, 76) 84 px + nút xổ (213, 76); nút XP
>   (125, 98, 103×21) viền `#003C74` góc cắt 1 px, nền `#F4F3EE`, 2 hàng đáy `#D6D0C5`, `Cập nhật ngay` căn giữa 91 px;
>   `Đã đồng bộ lúc 14:00` (12, 130) 140 px, `ngày 26/11/2026.` (12, 144) 112 px, `Lần tới: 15:00.` xpLabel (12, 166) 105 px.
>   Chạm `Cập nhật ngay` → đồng bộ lại; xong → vẽ lại 3 dòng trạng thái.
> - Không có OK / Hủy / Áp dụng (không đủ chỗ): mọi thay đổi áp ngay.


| khối | tọa độ | màu / font | chữ, rộng đo |
|---|---|---|---|
| tab | `Ngày và giờ` (chọn), `Múi giờ` | như trên | 77 / 49 px |
| groupbox Ngày | (10, 54, 122×128), nhãn (17, 47) | xpGroup, nhãn xpGroupLabel 11 | `Ngày` 28 |
| ô tháng | (14, 62, 114×16) viền xpFieldBorder; chữ TL (17, 63); nút xổ (113, 63, 14×14) xpBtn + tam giác white 5×3 (116, 69) | `JBMono-11` black | `11/2026` 49 |
| thứ | ô 16 px từ x 13, chữ căn giữa ô, y 82; vạch xpGroup (13, 96, 112×1) | `JBMono-11` xpGroupLabel | `T2`…`T7`, `CN` 14 |
| ngày | lưới 7 × 6, ô 16 × 13 từ (13, 98), chữ căn giữa; tuần bắt đầu thứ Hai | `JBMono-11` black; ngày tháng trước / sau xpDim | 1–2 chữ số |
| hôm nay | ô (x, y, 16×13) xpSelect, chữ white | — | — |
| groupbox Giờ | (136, 54, 94×128), nhãn (143, 47) | như trên | `Giờ` 21 |
| mặt đồng hồ | tâm (183, 106); vạch giờ ở bán kính 33: 3×3 (12/3/6/9) hoặc 2×2, xpTitle; chấm phút 1×1 bán kính 34, xpDim; không vẽ vòng tròn | — | — |
| kim | giờ dài 18 dày 3 black; phút dài 27 dày 2 black; giây dài 30 dày 1 xpRed; chốt tâm 3×3 black | — | — |
| ô giờ | (145, 152, 76×18) viền xpFieldBorder; chữ TL (148, 153); nút tăng giảm (208, 153, 12×16) xpBody, vạch giữa y 160 xpFieldBorder, tam giác black 5×3 tại (212, 155) / (212, 163) | `JBMono-12B` black | `14:32:15` 56 |
| múi giờ | TL (12, 189) | `JBMono-11` black | `Múi giờ: GMT+7 · Hà Nội` 161 |

Vẽ lại mỗi giây: chỉ vùng mặt đồng hồ (147..219, 70..142) nền white rồi vẽ vạch + kim; ô giờ chỉ vùng chữ. Qua nửa đêm: vẽ lại lịch. 12 h (`clock24h` tắt): ô giờ `2:32 CH` (49 px; `2:32:15 CH` 70 px không vừa ô). Bỏ số VT323 to và câu chào; thanh trạng thái `Tuần 48 | GMT+7` bỏ.

**Thời tiết = trang thuộc tính, tab Hiện tại** (`XPWeatherProps`; kênh `Weather`):

| khối | tọa độ | màu / font | chữ, rộng đo |
|---|---|---|---|
| tab | `Hiện tại` (chọn), `Dự báo` | — | 56 / 42 |
| icon | 32×32 tại (14, 50) (bitmap dưới, theo mã thời tiết) | — | — |
| mô tả | TL (54, 52) | `JBMono-16B` black | `Ít mây` 60 |
| nơi | TL (54, 71) | `JBMono-11` xpLabel | `Hà Nội` (cần firmware) |
| nhiệt độ | TR (226, 45) | `VT323-44` black | `29°` 54 |
| vạch khắc | (12, 90, 216×1), (12, 164, 216×1) | xpGroup | — |
| dòng | nhãn TL (14, 96 + 16i), giá trị TL (112, …) | `JBMono-11` black | `Cảm giác:` `33°` · `Độ ẩm:` `74%` · `Gió:` `12 km/h` · `Chỉ số UV:` `7 · cao` |
| dòng dưới | nhãn TL (14, 171 + 16i), giá trị TL (112, …) | `JBMono-11` black | `Cao / thấp:` `31° / 24°` · `Mặt trời lặn:` (91) `17:24` |

Không thanh trạng thái. Mai / Kia chuyển sang tab Dự báo.

**Dự báo = tab Dự báo của cửa sổ Thời tiết** (`XPForecastDetails`; kênh `Forecast`, tiêu đề cửa sổ `Thời tiết`, cùng nút thanh tác vụ Thời tiết):

| khối | tọa độ | màu / font | chữ |
|---|---|---|---|
| danh sách | (10, 48, 220×157) viền xpFieldBorder, nền white | — | — |
| hàng tiêu đề | (11, 49, 218×15) xpBody; y 64 xpGroup, y 65 xpDim; vạch cột x 95 / 160 / 193, y 52–61 xpDim | `JBMono-11` black: `Ngày` TL (17, 50), `Trời` TL (101, 50), `Thấp` TR (189, 50), `Cao` TR (224, 50) | — |
| dòng | cao 24 từ y 66; icon 16×16 (15, y+4); ngày TL (35, y+3); trời TL (101, y+3); thấp TR (189, y+3); cao TR (224, y+3) | `JBMono-13` black | `Hôm nay` 56 · `Mưa rào` 56 · `24°` 24 |
| dòng chọn | dòng hôm nay (11, y, 218×24) xpSelect, chữ white | — | — |

Không thanh nhiệt độ, không thanh trạng thái. Chưa có dữ liệu: danh sách trống + `Chưa có dự báo` xpDim TL (17, 70).

**Đêm = trình bảo vệ màn hình** (`XPNightSaver`; kênh `Night`): nền `#000000`; `23:47` `VT323-86` xpLabel `#4D4D4D` TL (x, y) — 170 px; ngày `JBMono-11` xpLabel căn giữa (x + 85, y + 85), `Thứ Năm 26/11` 91 px. Mỗi phút (khi số phút đổi) khối nhảy chỗ: xóa khung cũ (x, y, 170×100) bằng đen, vẽ ở chỗ mới — x ∈ [6, 64], y ∈ [6, 134], ngẫu nhiên, cách chỗ cũ ≥ 30 px. Không thanh tác vụ, không cửa sổ (như trước).

**Desktop như XP thật** (`XPDeskOneCol`): chỉ chương trình đã cài — một cột x 40: Claude / Codex / Ảnh / Thùng rác, y 8 / 56 / 104 / 152 (bỏ ô nào thì dồn lên). Bỏ cột x 120 (Thời tiết, Đồng hồ). Thời tiết mở từ biểu tượng khay, Đồng hồ mở từ giờ ở khay (ô giờ không có trạng thái lún — XP không có).

> **P-2026-11-26.18 — nhãn desktop không có %:** nhãn biểu tượng chỉ là tên chương trình, như XP thật: `Claude` (JBMono-11, 42 px) và `Codex` (35 px), TC tại (40, ô+24), bóng đen (+1, +1), không đổi theo số liệu. % chỉ hiện trong cửa sổ Claude / Codex. Thay hàng `Claude 38%` / `Codex 71%` của bảng XP-Desk.
> **P-2026-11-26.19 — biểu tượng desktop kiểu XP** (`XPDeskIcons`, `source/XP-Desk-Icons.dc.html`): Codex, Ảnh, Thùng rác thành bitmap màu 32×23 **pixel thật** (không phóng ×2) tại (24, ô) — Codex ô y 56, Ảnh 104, Thùng rác 152; Clawd không đổi. Bitmap = các `<path>` SVG trong source, mỗi path một màu, `M x y h w v1` = một đoạn ngang; ô không có path = trong suốt (giữ hình nền). Codex = Command Prompt (khung xám nổi 3D, tiêu đề gradient 7 sắc #0A246A→#A6CAF0, thân đen, `C:_` #C0C0C0), 14 màu; Ảnh = My Pictures (thư mục vàng gradient, nắp nghiêng, ảnh trời + mặt trời), 20 màu; Thùng rác = Recycle Bin (thùng lưới xám xanh, sáng trái → tối phải), 18 màu. Bóng chấm #22303F 1 px phải-dưới, ô (x+y) chẵn. Nhãn và vị trí như P-.18. Vẽ một lần cùng hình nền; chọn biểu tượng: XP tô xpSelect 50 % lên icon — ở đây thay mọi màu của bitmap bằng xpSelectIcon theo dither (x+y) chẵn (không pha trong suốt).

**Bitmap icon thời tiết** (Y xpIconWarn, A xpAmber, G xpFieldBorder, W white, B xpIconInfo):

`sun` 16×16:

```
.......YY.......
.......YY.......
...Y...YY...Y...
..YYY......YYY..
...Y...AA...Y...
.....AAYYAA.....
.....AYYYYA.....
YYY.AYYYYYYA.YYY
YYY.AYYYYYYA.YYY
.....AYYYYA.....
.....AAYYAA.....
...Y...AA...Y...
..YYY......YYY..
...Y...YY...Y...
.......YY.......
.......YY.......
```

`sun` 32×32:

```
................................
..............YYYY..............
..............YYYY..............
..............YYYY..............
......YY......YYYY......YY......
.....YYY......YYYY......YYY.....
....YYYYY..............YYYYY....
....YYYYYY............YYYYYY....
......YYY..............YYY......
.......Y....AAAAAAAA....Y.......
...........AAYYYYYYAA...........
..........AYYYYYYYYYYA..........
.........AAYYYYYYYYYYAA.........
.........AYYYYYYYYYYYYA.........
.YYYYY...AYYYYYYYYYYYYA...YYYYY.
.YYYYY...AYYYYYYYYYYYYA...YYYYY.
.YYYYY...AYYYYYYYYYYYYA...YYYYY.
.YYYYY...AYYYYYYYYYYYYA...YYYYY.
.........AYYYYYYYYYYYYA.........
.........AAYYYYYYYYYYAA.........
..........AYYYYYYYYYYA..........
...........AAYYYYYYAA...........
.......Y....AAAAAAAA....Y.......
......YYY..............YYY......
....YYYYYY............YYYYYY....
....YYYYY..............YYYYY....
.....YYY......YYYY......YYY.....
......YY......YYYY......YY......
..............YYYY..............
..............YYYY..............
..............YYYY..............
................................
```

`partly` 16×16:

```
.....YY.........
..Y..YY..Y......
.YY......YY.....
....AAAA........
...AYYYYA.......
YY.AYYYYGGGG....
YY.AYYYGWWWWG...
...AYYGWWWWWWG..
....GGWWWWWWWG..
...GWWWWWWWWWG..
...GWWWWWWWWWWG.
...GWWWWWWWWWWG.
...GWWWWWWWWWWG.
...GGGGGGGGGGGG.
................
................
```

`partly` 32×32:

```
..........YYYY..................
..........YYYY..................
....Y.....YYYY.....Y............
...YYY............YYY...........
..YYYYY..........YYYYY..........
...YYY............YYY...........
....Y....AAAAAA....Y............
.......AAYYYYYYAA...............
.......AYYYYYYYYA...............
......AYYYYYYYYYYA..............
YYY...AYYYYYYYYYYA.GGYYY........
YYY...AYYYYYYYYYGGGWWGGG........
YYY...AYYYYYYYYGWWWWWWWWG.......
YYY...AYYYYYYYGWWWWWWWWWWG......
......AYYYYYYGWWWWWWWWWWWWG.....
.......AYYGGGWWWWWWWWWWWWWG.....
.......AGGWWWWWWWWWWWWWWWWG.....
.......GWWWWWWWWWWWWWWWWWWWG....
.......GWWWWWWWWWWWWWWWWWWWG....
......GWWWWWWWWWWWWWWWWWWWWWG...
......GWWWWWWWWWWWWWWWWWWWWWWG..
......GWWWWWWWWWWWWWWWWWWWWWWG..
......GWWWWWWWWWWWWWWWWWWWWWWWG.
......GWWWWWWWWWWWWWWWWWWWWWWWG.
......GWWWWWWWWWWWWWWWWWWWWWWG..
......GWWWWWWWWWWWWWWWWWWWWWWG..
......GWWWWWWWWWWWWWWWWWWWWWG...
......GGGGGGGGGGGGGGGGGGGGGGG...
................................
................................
................................
................................
```

`rain` 16×16:

```
................
................
................
........GGGG....
.......GWWWWG...
....GGGWWWWWWG..
...GWWWWWWWWWG..
...GWWWWWWWWWWG.
...GWWWWWWWWWWG.
...GWWWWWWWWWWG.
...GWWWWWWWWWWG.
...GGGGGGGGGGGG.
.....B..B...B...
....BB..B..B....
....B..B...B....
...BB..B..B.....
```

`rain` 32×32:

```
................................
................................
................................
................................
................................
...................GG...........
................GGGWWGGG........
...............GWWWWWWWWG.......
..............GWWWWWWWWWWG......
.............GWWWWWWWWWWWWG.....
..........GGGWWWWWWWWWWWWWG.....
........GGWWWWWWWWWWWWWWWWG.....
.......GWWWWWWWWWWWWWWWWWWWG....
.......GWWWWWWWWWWWWWWWWWWWG....
......GWWWWWWWWWWWWWWWWWWWWWG...
......GWWWWWWWWWWWWWWWWWWWWWWG..
......GWWWWWWWWWWWWWWWWWWWWWWG..
......GWWWWWWWWWWWWWWWWWWWWWWWG.
......GWWWWWWWWWWWWWWWWWWWWWWWG.
......GWWWWWWWWWWWWWWWWWWWWWWG..
......GWWWWWWWWWWWWWWWWWWWWWWG..
......GWWWWWWWWWWWWWWWWWWWWWG...
......GGGGGGGGGGGGGGGGGGGGGGG...
................................
................................
..........BB.....BB.....BB......
.........BB.....BB.....BB.......
.........BB.....BB.....BB.......
........BB.....BB.....BB........
........BB.....BB.....BB........
.......BB.....BB.....BB.........
.......BB.....BB.....BB.........
```

