# Đặc tả màn thiết bị glimmer (240×240)

Tọa độ px panel thật (x, y, w×h); datum căn chữ theo TFT_eSPI (TL / TC / TR / MC / MR — điểm neo là (x, y)).
Font là file VLW trong `data/fonts/`; màu là tên token trong `tokens/panel_tokens.json` (`CLAWD` = #D97757).
Cột **px** = độ rộng chữ đo bằng font VLW thật. Số liệu mẫu (38 %, 14:32, 29°…) chỉ để minh hoạ.
Vùng: status y 0–21 · gạch nhấn y 22 · nội dung y 24–219 · trống y 220–229 · vạch chỉ báo y 230 (2 px).

## 1. Attention — kênh `Attention`

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Thẻ toàn màn cho agent (duyệt / câu hỏi / xong / tiến độ / lỗi).

- Không có status bar: nền đen từ y 0, dòng `AGENT · project` ở y 30.
- Clawd 18×10 ô, ô 5 px → 90×50 tại (75, 62); huy hiệu 7×7 ô 3 px (21×21) tại (165, 56); thẻ Codex tô Clawd LILAC.
- Chuyển động trong `tick()`: chờ bạn → chớp mắt 150 ms mỗi 4 s; tiến độ → bước chân mỗi 400 ms. Chỉ vẽ lại khung 90×50 của Clawd.
- Dòng `chờ bạn · 2M` (MUTED) vẽ lại mỗi giây khi đổi; nhiều thẻ giữ màn → chấm hàng đợi 6×6 tại y 204 (thẻ đang hiện màu loại thẻ, còn lại LINE); thẻ kết quả một mình → vạch hết giờ 60 px tại (90, 206).
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
| 120, 180 | TC | `JBMono-11` | MUTED | `chờ bạn · 2M` | 84 |
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
| 120, 180 | TC | `JBMono-11` | MUTED | `chờ bạn · 45S` | 91 |
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

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Mặt đồng hồ ban đêm (`nightMode` 2) — không xoay vòng.

- Không status bar. Giờ VT323-86 căn giữa: HH INK_DIM, `:` MUTED, MM INK_DIM, y 64.
- `tick()`: phút đổi → vẽ lại MM; giờ đổi → vẽ lại HH và ngày.

### Night — Night · mặt đồng hồ đêm

Nguồn `source/Night.dc.html` · ảnh `screens/@2x/Night.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 35, 64 | TL | `VT323-86` | INK_DIM | `23` | 68 |
| 103, 64 | TL | `VT323-86` | MUTED | `:` | 34 |
| 137, 64 | TL | `VT323-86` | INK_DIM | `47` | 68 |
| 120, 168 | TC | `JBMono-11` | MUTED | `THỨ TƯ 25/11` | 84 |

## 3. Setup — kênh `Setup`

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Setup-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Danh sách cài đặt lần đầu — chỉ hiện khi chưa có khóa Claude lẫn token Codex.

- Ô đánh dấu 11×11 (LINE / MINT), xong thì tô ô 5×5 MINT bên trong.
- Màn tĩnh, không có `tick()`.

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
| 0, 230, 96×2 |  |  | AMBER | vạch tiến độ slide (vẽ ở 40 %) |  |

## 4. Home — kênh `Home`

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Home-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

"dấu hiệu sinh tồn": đồng hồ, thời tiết, hai đồng hồ đo AI, dải 24 giờ.

- **Không có status bar** — đồng hồ VT323-86 bắt đầu từ y 6 (ngoài vùng nội dung y 24–219 của luật khung).
- **Chồng chữ**: MM (x 110–177) đè lên cột thời tiết phải (x ≥ 154: `29°`, `c.giác 33°`). Ảnh vẽ bằng font thật cho thấy rõ; cần kiểm trên máy.
- Đồng hồ đo: thẻ JBMono-12B ở x 10; `pixelBar` (40, y+3, 150×7); giá trị TR x 230. Màu thanh theo phần **còn lại** (≤ 20 % CORAL, ≤ 50 % AMBER, còn lại MINT), số hiện phần **đã dùng**.
- Khóa lỗi → thay thanh bằng ghi chú (`khóa bị từ chối · cập nhật`, CORAL); chưa có khóa → `thêm khóa · glimmer.local` MUTED; đang tải → 3 chấm 6×6 ở x 196.
- Chân trang trái, theo ưu tiên: lỗi khóa (CORAL/AMBER) > khóa sắp hết hạn (`CLAUDE CÒN 2NG`, AMBER) > gợi ý mưa (SKY) > `TRANG CHỦ` (MUTED). Khe ≈ 128 px; `CLAUDE BỊ TỪ CHỐI` chạm sát IP.
- `tick()`: MM / HH, nhiệt độ (đổi > 0,4°), biểu tượng (đổi mã), đồng hồ đo (đổi > 0,4 %), dải giờ (mỗi giờ), chân trang (mỗi phút).

### Home — Home · bình thường

Nguồn `source/Home.dc.html` · ảnh `screens/@2x/Home.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 8, 6 | TL | `VT323-86` | INK | `14` | 68 |
| 76, 6 | TL | `VT323-86` | CORAL | `:` | 34 |
| 110, 6 | TL | `VT323-86` | AMBER | `32` | 68 |
| 230, 14 | TR | `VT323-32` | INK | `29°` | 39 |
| 230, 48 | TR | `JBMono-11` | MUTED | `c.giác 33°` | 70 |
| 204, 62, 32×32 |  |  | SKY | bitmap `PARTCLOUD` |  |
| 200, 78 | TR | `JBMono-11` | INK_DIM | `Ít mây` | 42 |
| 10, 92 | TL | `JBMono-12B` | INK_DIM | `THỨ TƯ 25/11` | 84 |
| 10, 108, w 220 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 10, 114 | TL | `JBMono-12B` | CORAL | `CL` | 14 |
| 40, 117, 150×7 |  |  | MINT | `pixelBar` 9 ô, 38 % |  |
| 230, 114 | TR | `JBMono-11` | MINT | `38%` | 21 |
| 10, 132 | TL | `JBMono-12B` | LILAC | `CX` | 14 |
| 40, 135, 150×7 |  |  | AMBER | `pixelBar` 9 ô, 71 % |  |
| 230, 132 | TR | `JBMono-11` | AMBER | `71%` | 21 |
| 10, 152, w 220 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 10, 154 | TL | `JBMono-12B` | MUTED | `HÔM NAY` | 49 |
| 10, 180, 220×1 |  |  | LINE | khối |  |
| 10, 177, 1×3 |  |  | INK_DIM | khối |  |
| 19, 178, 1×2 |  |  | LINE | khối |  |
| 28, 178, 1×2 |  |  | LINE | khối |  |
| 37, 178, 1×2 |  |  | LINE | khối |  |
| 46, 178, 1×2 |  |  | LINE | khối |  |
| 55, 178, 1×2 |  |  | LINE | khối |  |
| 65, 177, 1×3 |  |  | INK_DIM | khối |  |
| 74, 178, 1×2 |  |  | LINE | khối |  |
| 83, 178, 1×2 |  |  | LINE | khối |  |
| 92, 178, 1×2 |  |  | LINE | khối |  |
| 101, 178, 1×2 |  |  | LINE | khối |  |
| 110, 178, 1×2 |  |  | LINE | khối |  |
| 120, 177, 1×3 |  |  | INK_DIM | khối |  |
| 129, 178, 1×2 |  |  | LINE | khối |  |
| 138, 174, 1×6 |  |  | CORAL | khối |  |
| 147, 178, 1×2 |  |  | LINE | khối |  |
| 156, 178, 1×2 |  |  | LINE | khối |  |
| 165, 178, 1×2 |  |  | LINE | khối |  |
| 175, 177, 1×3 |  |  | INK_DIM | khối |  |
| 184, 178, 1×2 |  |  | LINE | khối |  |
| 193, 178, 1×2 |  |  | LINE | khối |  |
| 202, 178, 1×2 |  |  | LINE | khối |  |
| 211, 178, 1×2 |  |  | LINE | khối |  |
| 220, 178, 1×2 |  |  | LINE | khối |  |
| 137, 172, 3×3 |  |  | AMBER | khối |  |
| 230, 154 | TR | `JBMono-11` | INK_DIM | `CÒN 9H` | 42 |
| 10, 200 | TL | `JBMono-11` | MUTED | `TRANG CHỦ` | 63 |
| 230, 200 | TR | `JBMono-11` | MUTED | `192.168.100.40` | 98 |
| 0, 230, 96×2 |  |  | AMBER | vạch tiến độ slide (vẽ ở 40 %) |  |

### Home-KeyBad — Home · khóa Claude lỗi

Nguồn `source/Home-KeyBad.dc.html` · ảnh `screens/@2x/HomeKeyBad.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 8, 6 | TL | `VT323-86` | INK | `14` | 68 |
| 76, 6 | TL | `VT323-86` | CORAL | `:` | 34 |
| 110, 6 | TL | `VT323-86` | AMBER | `32` | 68 |
| 230, 14 | TR | `VT323-32` | INK | `29°` | 39 |
| 230, 48 | TR | `JBMono-11` | MUTED | `c.giác 33°` | 70 |
| 204, 62, 32×32 |  |  | SKY | bitmap `PARTCLOUD` |  |
| 200, 78 | TR | `JBMono-11` | INK_DIM | `Ít mây` | 42 |
| 10, 92 | TL | `JBMono-12B` | INK_DIM | `THỨ TƯ 25/11` | 84 |
| 10, 108, w 220 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 10, 114 | TL | `JBMono-12B` | CORAL | `CL` | 14 |
| 230, 114 | TR | `JBMono-11` | CORAL | `khóa bị từ chối · cập nhật` | 182 |
| 10, 132 | TL | `JBMono-12B` | LILAC | `CX` | 14 |
| 40, 135, 150×7 |  |  | AMBER | `pixelBar` 9 ô, 71 % |  |
| 230, 132 | TR | `JBMono-11` | AMBER | `71%` | 21 |
| 10, 152, w 220 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 10, 154 | TL | `JBMono-12B` | MUTED | `HÔM NAY` | 49 |
| 10, 180, 220×1 |  |  | LINE | khối |  |
| 10, 177, 1×3 |  |  | INK_DIM | khối |  |
| 19, 178, 1×2 |  |  | LINE | khối |  |
| 28, 178, 1×2 |  |  | LINE | khối |  |
| 37, 178, 1×2 |  |  | LINE | khối |  |
| 46, 178, 1×2 |  |  | LINE | khối |  |
| 55, 178, 1×2 |  |  | LINE | khối |  |
| 65, 177, 1×3 |  |  | INK_DIM | khối |  |
| 74, 178, 1×2 |  |  | LINE | khối |  |
| 83, 178, 1×2 |  |  | LINE | khối |  |
| 92, 178, 1×2 |  |  | LINE | khối |  |
| 101, 178, 1×2 |  |  | LINE | khối |  |
| 110, 178, 1×2 |  |  | LINE | khối |  |
| 120, 177, 1×3 |  |  | INK_DIM | khối |  |
| 129, 178, 1×2 |  |  | LINE | khối |  |
| 138, 174, 1×6 |  |  | CORAL | khối |  |
| 147, 178, 1×2 |  |  | LINE | khối |  |
| 156, 178, 1×2 |  |  | LINE | khối |  |
| 165, 178, 1×2 |  |  | LINE | khối |  |
| 175, 177, 1×3 |  |  | INK_DIM | khối |  |
| 184, 178, 1×2 |  |  | LINE | khối |  |
| 193, 178, 1×2 |  |  | LINE | khối |  |
| 202, 178, 1×2 |  |  | LINE | khối |  |
| 211, 178, 1×2 |  |  | LINE | khối |  |
| 220, 178, 1×2 |  |  | LINE | khối |  |
| 137, 172, 3×3 |  |  | AMBER | khối |  |
| 230, 154 | TR | `JBMono-11` | INK_DIM | `CÒN 9H` | 42 |
| 10, 200 | TL | `JBMono-11` | CORAL | `CLAUDE BỊ TỪ CHỐI` | 119 |
| 230, 200 | TR | `JBMono-11` | MUTED | `192.168.100.40` | 98 |
| 0, 230, 96×2 |  |  | AMBER | vạch tiến độ slide (vẽ ở 40 %) |  |

## 5. Agents — kênh `Agents`

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Agents-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Danh sách hàng đợi agent (≤ 3 dòng; > 3 → 2 dòng + `+ N mục khác`).

- Không có status bar; tiêu đề `TÁC TỬ` JBMono-12B MUTED căn giữa ở y 10.
- Mỗi dòng cao 60 px từ y 40: ô màu loại 6×6 tại (20, y+4), dòng chính INK (36, y), dòng phụ MUTED (36, y+15), cắt ở 190 px; kẻ LINE 200 px tại y+44.
- Vẽ lại cả danh sách khi hàng đợi đổi hoặc sang phút mới.

### Agents — Agents · 3 mục

Nguồn `source/Agents.dc.html` · ảnh `screens/@2x/Agents.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 120, 10 | TC | `JBMono-12B` | MUTED | `TÁC TỬ` | 42 |
| 20, 44, 6×6 |  |  | AMBER | khối |  |
| 36, 40 | TL | `JBMono-11` | INK | `Cần bạn · Bash` | 98 |
| 36, 55 | TL | `JBMono-11` | MUTED | `claude · glimmer · 2m` | 147 |
| 20, 84, 200×1 |  |  | LINE | khối |  |
| 20, 104, 6×6 |  |  | LILAC | khối |  |
| 36, 100 | TL | `JBMono-11` | INK | `Tests · 64%` | 77 |
| 36, 115 | TL | `JBMono-11` | MUTED | `codex · api · 5m` | 112 |
| 20, 144, 200×1 |  |  | LINE | khối |  |
| 20, 164, 6×6 |  |  | MINT | khối |  |
| 36, 160 | TL | `JBMono-11` | INK | `Xong` | 28 |
| 36, 175 | TL | `JBMono-11` | MUTED | `claude · TieuMac3d · 12m` | 168 |
| 0, 230, 96×2 |  |  | AMBER | vạch tiến độ slide (vẽ ở 40 %) |  |

### Agents-More — Agents · 4 mục (+ N khác)

Nguồn `source/Agents-More.dc.html` · ảnh `screens/@2x/AgentsMore.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 120, 10 | TC | `JBMono-12B` | MUTED | `TÁC TỬ` | 42 |
| 20, 44, 6×6 |  |  | AMBER | khối |  |
| 36, 40 | TL | `JBMono-11` | INK | `Cần bạn · Bash` | 98 |
| 36, 55 | TL | `JBMono-11` | MUTED | `claude · glimmer · 2m` | 147 |
| 20, 84, 200×1 |  |  | LINE | khối |  |
| 20, 104, 6×6 |  |  | LILAC | khối |  |
| 36, 100 | TL | `JBMono-11` | INK | `Tests · 64%` | 77 |
| 36, 115 | TL | `JBMono-11` | MUTED | `codex · api · 5m` | 112 |
| 20, 144, 200×1 |  |  | LINE | khối |  |
| 120, 160 | TC | `JBMono-11` | MUTED | `+ 2 mục khác` | 84 |
| 0, 230, 96×2 |  |  | AMBER | vạch tiến độ slide (vẽ ở 40 %) |  |

## 6. Claude — kênh `Claude`

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Claude-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.2 — Clawd ngủ khi chưa có project:** bảng project trống → Clawd mắt `sleep` (vạch ngang 2 ô ở hàng mắt dưới) thay cho `shut`, kèm chữ "Zz" pixel MUTED ở góc trên phải Clawd. Xem `Claude-NoProject`.
> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Hạn mức Claude: số to tuần, phiên 5 giờ, bảng project.

- Số to VT323-86 = phần **đã dùng**; màu theo phần còn lại; dữ liệu cũ / khóa lỗi → MUTED.
- Cột phải: Clawd 72×40 (ô 4) tại (156, 58), biểu cảm theo bảng project (không có project → ngủ: mắt `sleep` + "Zz", từ P-2026-11-25.2); đếm ngược JBMono-12B CORAL TR (228, 112).
- Hàng dưới y 176, mỗi dòng 14 px, ≤ 3 dòng: project (cắt 84 px) + trạng thái màu (`Cần duyệt` AMBER, `Chờ bạn` SKY, `Lỗi` CORAL, `Đang chạy` LILAC, `Xong` MINT) + tuổi TR. Khóa lỗi khi còn số → dải 224×14 màu lỗi chiếm dòng đầu.
- Không có số liệu mà khóa lỗi / mất mạng → thẻ credential (biểu tượng chìa khóa hoặc vòng cấm, tiêu đề JBMono-16B, 2 dòng lý do, `glimmer.local` SKY + IP).
- Meta status bar (≈ 72 px): `CŨ 14M` AMBER khi cũ; `KHÓA LỖI` CORAL khi khóa lỗi; `BỊ CHẶN` AMBER.

### Claude — Claude · bình thường

Nguồn `source/Claude.dc.html` · ảnh `screens/@2x/Claude.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn CORAL | Status bar `Claude`; gạch nhấn y 22 | 42 |
| 12, 32 | TL | `JBMono-11` | MUTED | `TUẦN` | 28 |
| 156, 58, 72×40 |  |  | CLAWD | Clawd (ô 4, mắt `wide`, chân `stand`) |  |
| 228, 112 | TR | `JBMono-12B` | CORAL | `4d` | 14 |
| 12, 46 | TL | `VT323-86` | MINT | `38` | 68 |
| 82, 76 | TL | `VT323-44` | MINT | `%` | 18 |
| 12, 128, 216×8 |  |  | MINT | `pixelBar` 9 ô, 38 % |  |
| 12, 146, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 150 | TL | `JBMono-11` | MUTED | `PHIÊN 5 GIỜ` | 77 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `12% · 2h 14m` | 84 |
| 12, 164, 216×4 |  |  | MINT | `pixelBar` 9 ô, 12 % |  |
| 12, 170, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 180, 5×5 |  |  | AMBER | khối |  |
| 228, 176 | TR | `JBMono-11` | MUTED | `2M` | 14 |
| 22, 176 | TL | `JBMono-11` | INK_DIM | `glimmer` | 49 |
| 79, 176 | TL | `JBMono-11` | AMBER | `Cần duyệt · Bash` | 112 |
| 12, 194, 5×5 |  |  | LILAC | khối |  |
| 228, 190 | TR | `JBMono-11` | MUTED | `5M` | 14 |
| 22, 190 | TL | `JBMono-11` | INK_DIM | `TieuMac3d` | 63 |
| 93, 190 | TL | `JBMono-11` | LILAC | `Đang chạy · Edit` | 112 |
| 12, 208, 5×5 |  |  | MINT | khối |  |
| 228, 204 | TR | `JBMono-11` | MUTED | `1H` | 14 |
| 22, 204 | TL | `JBMono-11` | INK_DIM | `api` | 21 |
| 51, 204 | TL | `JBMono-11` | MINT | `Xong` | 28 |
| 0, 230, 96×2 |  |  | CORAL | vạch tiến độ slide (vẽ ở 40 %) |  |

### Claude-NoProject — Claude · chưa có project

Nguồn `source/Claude-NoProject.dc.html` · ảnh `screens/@2x/ClaudeNoProject.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn CORAL | Status bar `Claude`; gạch nhấn y 22 | 42 |
| 12, 32 | TL | `JBMono-11` | MUTED | `TUẦN` | 28 |
| 156, 58, 72×40 |  |  | CLAWD | Clawd (ô 4, mắt `sleep`, chân `stand`) |  |
| 202, 46, 8×8 |  |  | MUTED | bitmap `z` 4×4 ô, ô 2 px (`####` `..#.` `.#..` `####`) |  |
| 214, 30, 10×10 |  |  | MUTED | bitmap `Z` 5×5 ô, ô 2 px (`#####` `...#.` `..#..` `.#...` `#####`) |  |
| 228, 112 | TR | `JBMono-12B` | CORAL | `4d` | 14 |
| 12, 46 | TL | `VT323-86` | MINT | `38` | 68 |
| 82, 76 | TL | `VT323-44` | MINT | `%` | 18 |
| 12, 128, 216×8 |  |  | MINT | `pixelBar` 9 ô, 38 % |  |
| 12, 146, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 150 | TL | `JBMono-11` | MUTED | `PHIÊN 5 GIỜ` | 77 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `12% · 2h 14m` | 84 |
| 12, 164, 216×4 |  |  | MINT | `pixelBar` 9 ô, 12 % |  |
| 12, 170, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 176 | TL | `JBMono-11` | MUTED | `Chưa có hoạt động project` | 175 |
| 0, 230, 96×2 |  |  | CORAL | vạch tiến độ slide (vẽ ở 40 %) |  |

### Claude-Low — Claude · sắp hết hạn mức

Nguồn `source/Claude-Low.dc.html` · ảnh `screens/@2x/ClaudeLow.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn CORAL | Status bar `Claude`; gạch nhấn y 22 | 42 |
| 12, 32 | TL | `JBMono-11` | MUTED | `TUẦN` | 28 |
| 156, 58, 72×40 |  |  | CLAWD | Clawd (ô 4, mắt `open`, chân `stand`) |  |
| 228, 112 | TR | `JBMono-12B` | CORAL | `18h 5m` | 42 |
| 12, 46 | TL | `VT323-86` | CORAL | `92` | 68 |
| 82, 76 | TL | `VT323-44` | CORAL | `%` | 18 |
| 12, 128, 216×8 |  |  | CORAL | `pixelBar` 9 ô, 92 % |  |
| 12, 146, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 150 | TL | `JBMono-11` | MUTED | `PHIÊN 5 GIỜ` | 77 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `97% · 2h 14m` | 84 |
| 12, 164, 216×4 |  |  | CORAL | `pixelBar` 9 ô, 97 % |  |
| 12, 170, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 180, 5×5 |  |  | LILAC | khối |  |
| 228, 176 | TR | `JBMono-11` | MUTED | `5M` | 14 |
| 22, 176 | TL | `JBMono-11` | INK_DIM | `TieuMac3d` | 63 |
| 93, 176 | TL | `JBMono-11` | LILAC | `Đang chạy · Edit` | 112 |
| 12, 194, 5×5 |  |  | MINT | khối |  |
| 228, 190 | TR | `JBMono-11` | MUTED | `1H` | 14 |
| 22, 190 | TL | `JBMono-11` | INK_DIM | `api` | 21 |
| 51, 190 | TL | `JBMono-11` | MINT | `Xong` | 28 |
| 0, 230, 96×2 |  |  | CORAL | vạch tiến độ slide (vẽ ở 40 %) |  |

### Claude-Stale — Claude · dữ liệu cũ

Nguồn `source/Claude-Stale.dc.html` · ảnh `screens/@2x/ClaudeStale.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn CORAL | Status bar `Claude` · meta `CŨ 14M` (AMBER, 42 px); gạch nhấn y 22 | 42 |
| 12, 32 | TL | `JBMono-11` | MUTED | `TUẦN` | 28 |
| 156, 58, 72×40 |  |  | CLAWD | Clawd (ô 4, mắt `wide`, chân `stand`) |  |
| 228, 112 | TR | `JBMono-12B` | CORAL | `4d` | 14 |
| 12, 46 | TL | `VT323-86` | MUTED | `38` | 68 |
| 82, 76 | TL | `VT323-44` | MUTED | `%` | 18 |
| 12, 128, 216×8 |  |  | MUTED | `pixelBar` 9 ô, 38 % |  |
| 12, 146, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 150 | TL | `JBMono-11` | MUTED | `PHIÊN 5 GIỜ` | 77 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `12% · 2h 14m` | 84 |
| 12, 164, 216×4 |  |  | MINT | `pixelBar` 9 ô, 12 % |  |
| 12, 170, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 180, 5×5 |  |  | AMBER | khối |  |
| 228, 176 | TR | `JBMono-11` | MUTED | `2M` | 14 |
| 22, 176 | TL | `JBMono-11` | INK_DIM | `glimmer` | 49 |
| 79, 176 | TL | `JBMono-11` | AMBER | `Cần duyệt · Bash` | 112 |
| 12, 194, 5×5 |  |  | LILAC | khối |  |
| 228, 190 | TR | `JBMono-11` | MUTED | `5M` | 14 |
| 22, 190 | TL | `JBMono-11` | INK_DIM | `TieuMac3d` | 63 |
| 93, 190 | TL | `JBMono-11` | LILAC | `Đang chạy · Edit` | 112 |
| 12, 208, 5×5 |  |  | MINT | khối |  |
| 228, 204 | TR | `JBMono-11` | MUTED | `1H` | 14 |
| 22, 204 | TL | `JBMono-11` | INK_DIM | `api` | 21 |
| 51, 204 | TL | `JBMono-11` | MINT | `Xong` | 28 |
| 0, 230, 96×2 |  |  | CORAL | vạch tiến độ slide (vẽ ở 40 %) |  |

### Claude-KeyExpired — Claude · khóa hết hạn (còn số cũ)

Nguồn `source/Claude-KeyExpired.dc.html` · ảnh `screens/@2x/ClaudeKeyExpired.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn CORAL | Status bar `Claude` · meta `KHÓA LỖI` (CORAL, 56 px); gạch nhấn y 22 | 42 |
| 12, 32 | TL | `JBMono-11` | MUTED | `TUẦN` | 28 |
| 156, 58, 72×40 |  |  | CLAWD | Clawd (ô 4, mắt `wide`, chân `stand`) |  |
| 228, 112 | TR | `JBMono-12B` | CORAL | `4d` | 14 |
| 12, 46 | TL | `VT323-86` | MUTED | `38` | 68 |
| 82, 76 | TL | `VT323-44` | MUTED | `%` | 18 |
| 12, 128, 216×8 |  |  | MUTED | `pixelBar` 9 ô, 38 % |  |
| 12, 146, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 150 | TL | `JBMono-11` | MUTED | `PHIÊN 5 GIỜ` | 77 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `12% · 2h 14m` | 84 |
| 12, 164, 216×4 |  |  | MINT | `pixelBar` 9 ô, 12 % |  |
| 12, 170, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 8, 176, 224×14 |  |  | CORAL | khối |  |
| 120, 183 | MC | `JBMono-11` | BG | `KHÓA HẾT HẠN · glimmer.local` | 196 |
| 12, 194, 5×5 |  |  | AMBER | khối |  |
| 228, 190 | TR | `JBMono-11` | MUTED | `2M` | 14 |
| 22, 190 | TL | `JBMono-11` | INK_DIM | `glimmer` | 49 |
| 79, 190 | TL | `JBMono-11` | AMBER | `Cần duyệt · Bash` | 112 |
| 12, 208, 5×5 |  |  | LILAC | khối |  |
| 228, 204 | TR | `JBMono-11` | MUTED | `5M` | 14 |
| 22, 204 | TL | `JBMono-11` | INK_DIM | `TieuMac3d` | 63 |
| 93, 204 | TL | `JBMono-11` | LILAC | `Đang chạy · Edit` | 112 |
| 0, 230, 96×2 |  |  | CORAL | vạch tiến độ slide (vẽ ở 40 %) |  |

### Claude-Loading — Claude · đang tải

Nguồn `source/Claude-Loading.dc.html` · ảnh `screens/@2x/ClaudeLoading.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn CORAL | Status bar `Claude`; gạch nhấn y 22 | 42 |
| 120, 100 | MC | `JBMono-16B` | MUTED | `Đang tải` | 80 |
| 99, 128 |  |  | CORAL | 5 chấm tải 6×6, bước 9 |  |
| 0, 230, 96×2 |  |  | CORAL | vạch tiến độ slide (vẽ ở 40 %) |  |

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
| 0, 230, 96×2 |  |  | CORAL | vạch tiến độ slide (vẽ ở 40 %) |  |

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
| 0, 230, 96×2 |  |  | CORAL | vạch tiến độ slide (vẽ ở 40 %) |  |

## 7. Codex — kênh `Codex`

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
| 228, 26 | TR | `VT323-32` | LILAC | `3d` | 26 |
| 12, 46 | TL | `VT323-86` | MINT | `41` | 68 |
| 82, 76 | TL | `VT323-44` | MINT | `%` | 18 |
| 12, 128, 216×8 |  |  | MINT | `pixelBar` 9 ô, 41 % |  |
| 12, 146, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 150 | TL | `JBMono-11` | MUTED | `SPARK` | 35 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `2h 14m` | 42 |
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
| 0, 230, 96×2 |  |  | LILAC | vạch tiến độ slide (vẽ ở 40 %) |  |

### Codex-Stale — Codex · dữ liệu cũ

Nguồn `source/Codex-Stale.dc.html` · ảnh `screens/@2x/CodexStale.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn LILAC | Status bar `Codex` · meta `CŨ 18M` (AMBER, 42 px); gạch nhấn y 22 | 35 |
| 12, 32 | TL | `JBMono-12B` | MUTED | `TUẦN` | 28 |
| 228, 26 | TR | `VT323-32` | LILAC | `3d` | 26 |
| 12, 46 | TL | `VT323-86` | MUTED | `41` | 68 |
| 82, 76 | TL | `VT323-44` | MUTED | `%` | 18 |
| 12, 128, 216×8 |  |  | MUTED | `pixelBar` 9 ô, 41 % |  |
| 12, 146, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 150 | TL | `JBMono-11` | MUTED | `SPARK` | 35 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `2h 14m` | 42 |
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
| 0, 230, 96×2 |  |  | LILAC | vạch tiến độ slide (vẽ ở 40 %) |  |

### Codex-Loading — Codex · đang tải

Nguồn `source/Codex-Loading.dc.html` · ảnh `screens/@2x/CodexLoading.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn LILAC | Status bar `Codex`; gạch nhấn y 22 | 35 |
| 120, 100 | MC | `JBMono-16B` | MUTED | `Đang tải` | 80 |
| 99, 128 |  |  | LILAC | 5 chấm tải 6×6, bước 9 |  |
| 0, 230, 96×2 |  |  | LILAC | vạch tiến độ slide (vẽ ở 40 %) |  |

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
| 0, 230, 96×2 |  |  | LILAC | vạch tiến độ slide (vẽ ở 40 %) |  |

## 8. AI — kênh `AI`

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
| 228, 158 | TR | `JBMono-11` | INK_DIM | `2h 14m` | 42 |
| 12, 174 | TL | `JBMono-12B` | LILAC | `CX` | 14 |
| 228, 174 | TR | `JBMono-11` | INK_DIM | `3d` | 14 |
| 12, 192, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 120, 198 | TC | `JBMono-11` | INK | `DÙNG CLAUDE · ĐẶT LẠI 2G` | 168 |
| 0, 230, 96×2 |  |  | INK_DIM | vạch tiến độ slide (vẽ ở 40 %) |  |

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
| 228, 158 | TR | `JBMono-11` | INK_DIM | `2h 14m` | 42 |
| 12, 174 | TL | `JBMono-12B` | LILAC | `CX` | 14 |
| 228, 174 | TR | `JBMono-11` | INK_DIM | `3d` | 14 |
| 0, 230, 96×2 |  |  | INK_DIM | vạch tiến độ slide (vẽ ở 40 %) |  |

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
| 228, 158 | TR | `JBMono-11` | INK_DIM | `2h 14m` | 42 |
| 12, 174 | TL | `JBMono-12B` | LILAC | `CX` | 14 |
| 228, 174 | TR | `JBMono-11` | INK_DIM | `3d` | 14 |
| 12, 192, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 120, 198 | TC | `JBMono-11` | CORAL | `KHÓA CLAUDE BỊ TỪ CHỐI` | 154 |
| 0, 230, 96×2 |  |  | INK_DIM | vạch tiến độ slide (vẽ ở 40 %) |  |

## 9. Trend — kênh `Trend`

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Trend-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Phần trăm hạn mức tuần dùng mỗi ngày, 7 ngày.

- Hai khối (CLAUDE y 30, CODEX y 98; chỉ khối có khóa): cột 27 px, bước 31, cao tối đa 44, đáy y+60; hôm nay tô màu nhà cung cấp, các ngày khác INK_DIM; khóa lỗi → LINE.
- Nhãn thứ y 168 hiện là **chữ Anh 2 ký tự** (`TH FR … WE`, do `strftime %a`) — trái luật giao diện tiếng Việt.
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
| 25, 168 | TC | `JBMono-11` | MUTED | `TH` | 14 |
| 56, 168 | TC | `JBMono-11` | MUTED | `FR` | 14 |
| 87, 168 | TC | `JBMono-11` | MUTED | `SA` | 14 |
| 118, 168 | TC | `JBMono-11` | MUTED | `SU` | 14 |
| 149, 168 | TC | `JBMono-11` | MUTED | `MO` | 14 |
| 180, 168 | TC | `JBMono-11` | MUTED | `TU` | 14 |
| 211, 168 | TC | `JBMono-11` | INK | `WE` | 14 |
| 120, 194 | TC | `JBMono-11` | MUTED | `% hạn mức tuần dùng mỗi ngày` | 196 |
| 0, 230, 96×2 |  |  | MINT | vạch tiến độ slide (vẽ ở 40 %) |  |

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
| 25, 168 | TC | `JBMono-11` | MUTED | `TH` | 14 |
| 56, 168 | TC | `JBMono-11` | MUTED | `FR` | 14 |
| 87, 168 | TC | `JBMono-11` | MUTED | `SA` | 14 |
| 118, 168 | TC | `JBMono-11` | MUTED | `SU` | 14 |
| 149, 168 | TC | `JBMono-11` | MUTED | `MO` | 14 |
| 180, 168 | TC | `JBMono-11` | MUTED | `TU` | 14 |
| 211, 168 | TC | `JBMono-11` | INK | `WE` | 14 |
| 120, 194 | TC | `JBMono-11` | MUTED | `% hạn mức tuần dùng mỗi ngày` | 196 |
| 0, 230, 96×2 |  |  | MINT | vạch tiến độ slide (vẽ ở 40 %) |  |

## 10. Weather — kênh `Weather`

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Weather-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Thời tiết hiện tại + 3 ô ngày.

- Meta: `LẶN 17:24` / `MỌC 5:48` MUTED; cũ → `CŨ 2G` AMBER và số to MUTED.
- Ô ngày: 69×64, nền PANEL, viền LINE, bước 73 từ x 12, y 150.
- UV: ≥ 8 CORAL, ≥ 6 AMBER, còn lại MUTED.
- Chưa có dữ liệu → `đang tải...` (hoặc lỗi) JBMono-16B MUTED giữa màn.

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
| 0, 230, 96×2 |  |  | SKY | vạch tiến độ slide (vẽ ở 40 %) |  |

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
| 0, 230, 96×2 |  |  | SKY | vạch tiến độ slide (vẽ ở 40 %) |  |

### Weather-Loading — Weather · đang tải

Nguồn `source/Weather-Loading.dc.html` · ảnh `screens/@2x/WeatherLoading.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn SKY | Status bar `Thời tiết` · meta `--` (MUTED, 14 px); gạch nhấn y 22 | 63 |
| 120, 110 | MC | `JBMono-16B` | MUTED | `đang tải...` | 110 |
| 0, 230, 96×2 |  |  | SKY | vạch tiến độ slide (vẽ ở 40 %) |  |

## 11. Forecast — kênh `Forecast`

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Forecast-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

3 dòng ngày: NAY / MAI / KIA.

- Dòng cao 52, bước 56 từ y 32; hôm nay nền PANEL toàn chiều ngang + vạch trái 2 px CORAL (ngày khác LINE).
- Thanh nhiệt 130×8 tại (90, y+10) nền PANEL2; đoạn min→max **tô chuyển màu** từng cột từ xanh (#52C3FF) sang đỏ (#FF514A) — trái luật "không gradient".
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
| 106, 42, 114×8 |  |  | xanh→đỏ | đoạn nhiệt min→max (chuyển màu) |  |
| 204, 60 | TR | `JBMono-11` | MUTED | `24` | 14 |
| 230, 60 | TR | `JBMono-11` | INK | `31` | 14 |
| 0, 88, 2×52 |  |  | LINE | khối |  |
| 10, 92 | TL | `JBMono-16B` | INK_DIM | `MAI` | 30 |
| 10, 114, 16×16 |  |  | MUTED | bitmap `RAIN` |  |
| 28, 116 | TL | `JBMono-11` | MUTED | `Mưa rào` | 49 |
| 90, 98, 130×8 |  |  | PANEL2 | khối |  |
| 106, 98, 98×8 |  |  | xanh→đỏ | đoạn nhiệt min→max (chuyển màu) |  |
| 204, 116 | TR | `JBMono-11` | MUTED | `24` | 14 |
| 230, 116 | TR | `JBMono-11` | INK | `30` | 14 |
| 0, 144, 2×52 |  |  | LINE | khối |  |
| 10, 148 | TL | `JBMono-16B` | INK_DIM | `KIA` | 30 |
| 10, 170, 16×16 |  |  | MUTED | bitmap `RAIN` |  |
| 28, 172 | TL | `JBMono-11` | MUTED | `Mưa` | 21 |
| 90, 154, 130×8 |  |  | PANEL2 | khối |  |
| 90, 154, 82×8 |  |  | xanh→đỏ | đoạn nhiệt min→max (chuyển màu) |  |
| 204, 172 | TR | `JBMono-11` | MUTED | `23` | 14 |
| 230, 172 | TR | `JBMono-11` | INK | `28` | 14 |
| 0, 230, 96×2 |  |  | SKY | vạch tiến độ slide (vẽ ở 40 %) |  |

### Forecast-Empty — Forecast · chưa có dự báo

Nguồn `source/Forecast-Empty.dc.html` · ảnh `screens/@2x/ForecastEmpty.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn SKY | Status bar `Dự báo` · meta `3 NGÀY` (MUTED, 42 px); gạch nhấn y 22 | 42 |
| 120, 110 | MC | `JBMono-16B` | MUTED | `chưa có dự báo` | 140 |
| 0, 230, 96×2 |  |  | SKY | vạch tiến độ slide (vẽ ở 40 %) |  |

## 12. Clock — kênh `Clock`

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Clock-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Đồng hồ lớn + lời chào + dải 24 giờ.

- **Không có status bar**: ngày `THỨ TƯ · 25/11` MUTED ở (10, 8); chế độ 12 giờ thêm `AM` / `PM` AMBER TR (230, 8) — chữ Anh, `CLAUDE.md` ghi `SA` / `CH`.
- Giờ VT323-86 căn giữa y 42: HH / MM INK, `:` CORAL.
- Dải 24 chấm 4×4, khe 3, từ x 37 y 178: giờ đã qua AMBER, giờ hiện tại INK, còn lại LINE.
- `tick()`: phút → MM; giờ → HH, ngày, lời chào, dải.

### Clock — Clock · đồng hồ

Nguồn `source/Clock.dc.html` · ảnh `screens/@2x/Clock.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 10, 8 | TL | `JBMono-11` | MUTED | `THỨ TƯ · 25/11` | 98 |
| 35, 42 | TL | `VT323-86` | INK | `14` | 68 |
| 103, 42 | TL | `VT323-86` | CORAL | `:` | 34 |
| 137, 42 | TL | `VT323-86` | INK | `32` | 68 |
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
| 230, 208 | TR | `JBMono-11` | MUTED | `tuần 48` | 49 |
| 0, 230, 96×2 |  |  | AMBER | vạch tiến độ slide (vẽ ở 40 %) |  |

## 13. Info — kênh `Info`

> **P-2026-11-25.3 — Dock dọc:** bố cục có dock của kênh này ở §15 · `Info-Dock` (chờ chốt "Đổi luật").

> **P-2026-11-25.1 — Bản đầu:** vẽ lại đúng màn firmware v0.23.0 đang chạy.

Chẩn đoán thiết bị.

- 10 dòng, bước 20 từ y 36, chấm kẻ y+16. **Dòng cuối (`Lần tới`) nằm ở y 216–229, quá đáy vùng nội dung (219).**
- Sóng: > −60 dBm MINT, > −75 AMBER, còn lại CORAL.
- `tick()`: vẽ lại riêng dòng có giá trị đổi.

### Info — Info · chẩn đoán

Nguồn `source/Info.dc.html` · ảnh `screens/@2x/Info.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn MINT | Status bar `Thông tin` · meta `CHẨN ĐOÁN` (MUTED, 63 px); gạch nhấn y 22 | 63 |
| 12, 36 | TL | `JBMono-11` | MUTED | `IP` | 14 |
| 228, 36 | TR | `JBMono-11` | INK | `192.168.100.40` | 98 |
| 12, 52, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 56 | TL | `JBMono-11` | MUTED | `SSID` | 28 |
| 228, 56 | TR | `JBMono-11` | INK | `Anh Viet` | 56 |
| 12, 72, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 76 | TL | `JBMono-11` | MUTED | `Sóng` | 28 |
| 228, 76 | TR | `JBMono-11` | MINT | `-58 dBm` | 49 |
| 12, 92, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 96 | TL | `JBMono-11` | MUTED | `Đã chạy` | 49 |
| 228, 96 | TR | `JBMono-11` | INK_DIM | `312m` | 28 |
| 12, 112, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 116 | TL | `JBMono-11` | MUTED | `Bộ nhớ` | 42 |
| 228, 116 | TR | `JBMono-11` | AMBER | `27K trống` | 63 |
| 12, 132, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 136 | TL | `JBMono-11` | MUTED | `Khối lớn` | 56 |
| 228, 136 | TR | `JBMono-11` | INK_DIM | `21K` | 21 |
| 12, 152, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 156 | TL | `JBMono-11` | MUTED | `Firmware` | 56 |
| 228, 156 | TR | `JBMono-11` | INK_DIM | `v0.23.0-glimmer` | 105 |
| 12, 172, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 176 | TL | `JBMono-11` | MUTED | `Kênh` | 28 |
| 228, 176 | TR | `JBMono-11` | INK_DIM | `9 / 13` | 42 |
| 12, 192, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 196 | TL | `JBMono-11` | MUTED | `Cập nhật` | 56 |
| 228, 196 | TR | `JBMono-11` | INK_DIM | `1m trước` | 56 |
| 12, 212, w 216 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 12, 216 | TL | `JBMono-11` | MUTED | `Lần tới` | 49 |
| 228, 216 | TR | `JBMono-11` | MINT | `sau 4m` | 42 |
| 0, 230, 96×2 |  |  | MINT | vạch tiến độ slide (vẽ ở 40 %) |  |

## 14. Màn hệ thống

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

> **P-2026-11-25.3 — Dock dọc nổi bám lề trái:** thành phần mới `Dock` + 11 kênh xếp lại theo bề ngang mới. **Chờ phía code chốt dòng "Đổi luật" trong CHANGELOG** trước khi áp.

Dock = thanh tab kiểu Slide Over của iPad: báo đang ở tab nào và tab nào có việc. Không có nút bấm — tab đổi theo vòng xoay.

**Thành phần `Dock`** (`source/Dock.dc.html`) — khối 30×150 tại (2, 34), nằm dưới status bar, không chạm vạch y 230:

| phần | tọa độ trong dock (gốc = góc trong viền) | màu |
|---|---|---|
| khung | 30×150, viền 1 px | nền PANEL, viền LINE |
| ô tab k (k = 0…3: Claude, Tin nhắn, Thời tiết, Đồng hồ) | tâm (14, 19 + 36k) | — |
| icon | Clawd 18×10 (ô 1 px) · bong bóng 16×12 · mặt trời 16×14 · đồng hồ 16×14, căn giữa tâm ô; nét 2 px | Clawd CLAWD, còn lại INK_DIM |
| tab đang hiện | ô 24×24 tại (2, cy − 12) + vạch 2×10 tại (0, cy − 5) | ô PANEL2, vạch = màu nhấn của kênh |
| huy hiệu số | 9×9 vạt góc 1 px tại (19, cy − 14); chữ số bitmap 3×5 tại (22, cy − 12); > 9 → `+`; 0 → ẩn | Claude AMBER (agent chờ duyệt), Tin nhắn SKY (tin mới); chữ số BG |

Bitmap icon và chữ số (lưới `#`) nằm trong `source/Dock.dc.html` (`ICONS`, `DIGITS`) và `tokens/panel_tokens.json` → `component.dock`.

**Bố cục có dock:** nội dung kênh x 40–228 (rộng 188), y 24–219 như cũ; status bar và vạch tiến độ y 230 phủ hết 240 px. Huy hiệu thay cho vạch vàng / xanh liền y 230 khi agent chờ. Tab đang hiện theo kênh: Claude cho kênh skill agent (Home, Agents, Claude, Codex, AI, Trend, Setup); Thời tiết cho Weather, Forecast; Đồng hồ cho Clock; Info không tab nào (`none`). Không dock: Attention, Night, màn hệ thống.

Khác bản không dock: Home, Agents, Clock có status bar (`Trang chủ` meta `29° Ít mây` 70 px; `Tác tử` meta `3 MỤC`; `Đồng hồ` meta `tuần 48`); Home tách giờ (x 40–210, y 30–100) khỏi thời tiết (chuyển lên meta + dòng `c.giác`); Info bước 19 px (dòng cuối y 201–214); Weather 2 ô ngày 92 px (MAI, KIA), nhiệt cao/thấp hôm nay `31°/24°` cạnh mô tả; Trend cột 23 px bước 27, chú thích `% hạn mức tuần mỗi ngày`; Forecast nền dòng hôm nay từ x 36, rãnh nhiệt 92 px tại x 104.

Vẫn như bản đầu (chưa giải quyết trong mục này): thanh nhiệt Forecast tô chuyển màu; nhãn thứ Trend chữ Anh; đếm ngược `3d` / `2h 14m`.

### Claude-Dock — Claude · có dock

Nguồn `source/Claude-Dock.dc.html` · ảnh `screens/@2x/ClaudeDock.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 |  |  | BG | khối |  |
| 120, 11 | MC | `JBMono-12B` | INK | `Claude` | 42 |
| 0, 22, 240×1 |  |  | CORAL | khối |  |
| 40, 32 | TL | `JBMono-11` | MUTED | `TUẦN` | 28 |
| 156, 58, 72×40 |  |  | CLAWD | Clawd (ô 4, mắt `open`, chân `stand`) |  |
| 228, 112 | TR | `JBMono-12B` | CORAL | `4d` | 14 |
| 40, 46 | TL | `VT323-86` | MINT | `38` | 68 |
| 110, 76 | TL | `VT323-44` | MINT | `%` | 18 |
| 40, 128, 188×8 |  |  | MINT | `pixelBar` 9 ô, 38 % |  |
| 40, 146, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 150 | TL | `JBMono-11` | MUTED | `PHIÊN 5 GIỜ` | 77 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `12% · 2h 14m` | 84 |
| 40, 164, 188×4 |  |  | MINT | `pixelBar` 9 ô, 12 % |  |
| 40, 170, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 180, 5×5 |  |  | AMBER | khối |  |
| 228, 176 | TR | `JBMono-11` | MUTED | `2M` | 14 |
| 50, 176 | TL | `JBMono-11` | INK_DIM | `glimmer` | 49 |
| 107, 176 | TL | `JBMono-11` | AMBER | `Cần duyệt` | 63 |
| 40, 194, 5×5 |  |  | LILAC | khối |  |
| 228, 190 | TR | `JBMono-11` | MUTED | `5M` | 14 |
| 50, 190 | TL | `JBMono-11` | INK_DIM | `TieuMac3d` | 63 |
| 121, 190 | TL | `JBMono-11` | LILAC | `Đang chạy` | 63 |
| 40, 208, 5×5 |  |  | MINT | khối |  |
| 228, 204 | TR | `JBMono-11` | MUTED | `1H` | 14 |
| 50, 204 | TL | `JBMono-11` | INK_DIM | `api` | 21 |
| 79, 204 | TL | `JBMono-11` | MINT | `Xong` | 28 |
| 2, 34, 30×150 |  |  | nhấn CORAL | Dock (`Dock.dc.html`), tab đang hiện `claude`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 96×2 |  |  | CORAL | khối |  |

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
| 228, 170 | TR | `JBMono-11` | INK_DIM | `CÒN 9H` | 42 |
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

### Agents-Dock — Agents · có dock

Nguồn `source/Agents-Dock.dc.html` · ảnh `screens/@2x/AgentsDock.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn AMBER | Status bar `Tác tử` · meta `3 MỤC` (MUTED, 35 px); gạch nhấn y 22 | 42 |
| 40, 36, 6×6 |  |  | AMBER | khối |  |
| 54, 32 | TL | `JBMono-11` | INK | `Cần bạn · Bash` | 98 |
| 54, 47 | TL | `JBMono-11` | MUTED | `claude · glimmer · 2m` | 147 |
| 40, 76, 188×1 |  |  | LINE | khối |  |
| 40, 96, 6×6 |  |  | LILAC | khối |  |
| 54, 92 | TL | `JBMono-11` | INK | `Tests · 64%` | 77 |
| 54, 107 | TL | `JBMono-11` | MUTED | `codex · api · 5m` | 112 |
| 40, 136, 188×1 |  |  | LINE | khối |  |
| 40, 156, 6×6 |  |  | MINT | khối |  |
| 54, 152 | TL | `JBMono-11` | INK | `Xong` | 28 |
| 54, 167 | TL | `JBMono-11` | MUTED | `claude · TieuMac3d · 12m` | 168 |
| 2, 34, 30×150 |  |  | nhấn AMBER | Dock (`Dock.dc.html`), tab đang hiện `claude`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 96×2 |  |  | AMBER | khối |  |

### Codex-Dock — Codex · có dock

Nguồn `source/Codex-Dock.dc.html` · ảnh `screens/@2x/CodexDock.png`

| x, y (w×h) | datum | font | màu | nội dung | px |
|---|---|---|---|---|---|
| 0, 0, 240×22 | MC / MR | `JBMono-12B` / `JBMono-11` | INK / nhấn LILAC | Status bar `Codex`; gạch nhấn y 22 | 35 |
| 40, 32 | TL | `JBMono-12B` | MUTED | `TUẦN` | 28 |
| 228, 26 | TR | `VT323-32` | LILAC | `3d` | 26 |
| 40, 46 | TL | `VT323-86` | MINT | `41` | 68 |
| 110, 76 | TL | `VT323-44` | MINT | `%` | 18 |
| 40, 128, 188×8 |  |  | MINT | `pixelBar` 9 ô, 41 % |  |
| 40, 146, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 150 | TL | `JBMono-11` | MUTED | `SPARK` | 35 |
| 228, 150 | TR | `JBMono-11` | INK_DIM | `2h 14m` | 42 |
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
| 228, 158 | TR | `JBMono-11` | INK_DIM | `2h 14m` | 42 |
| 40, 174 | TL | `JBMono-12B` | LILAC | `CX` | 14 |
| 228, 174 | TR | `JBMono-11` | INK_DIM | `3d` | 14 |
| 40, 192, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 134, 198 | TC | `JBMono-11` | INK | `DÙNG CLAUDE · ĐẶT LẠI 2G` | 168 |
| 2, 34, 30×150 |  |  | nhấn INK_DIM | Dock (`Dock.dc.html`), tab đang hiện `claude`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 96×2 |  |  | INK_DIM | khối |  |

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
| 51, 168 | TC | `JBMono-11` | MUTED | `TH` | 14 |
| 78, 168 | TC | `JBMono-11` | MUTED | `FR` | 14 |
| 105, 168 | TC | `JBMono-11` | MUTED | `SA` | 14 |
| 132, 168 | TC | `JBMono-11` | MUTED | `SU` | 14 |
| 159, 168 | TC | `JBMono-11` | MUTED | `MO` | 14 |
| 186, 168 | TC | `JBMono-11` | MUTED | `TU` | 14 |
| 213, 168 | TC | `JBMono-11` | INK | `WE` | 14 |
| 134, 194 | TC | `JBMono-11` | MUTED | `% hạn mức tuần mỗi ngày` | 161 |
| 2, 34, 30×150 |  |  | nhấn MINT | Dock (`Dock.dc.html`), tab đang hiện `claude`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 96×2 |  |  | MINT | khối |  |

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
| 115, 42, 81×8 |  |  | xanh→đỏ | đoạn nhiệt min→max (chuyển màu) |  |
| 206, 60 | TR | `JBMono-11` | MUTED | `24` | 14 |
| 228, 60 | TR | `JBMono-11` | INK | `31` | 14 |
| 36, 88, 2×52 |  |  | LINE | khối |  |
| 44, 92 | TL | `JBMono-16B` | INK_DIM | `MAI` | 30 |
| 44, 114, 16×16 |  |  | MUTED | bitmap `RAIN` |  |
| 62, 116 | TL | `JBMono-11` | MUTED | `Mưa rào` | 49 |
| 104, 98, 92×8 |  |  | PANEL2 | khối |  |
| 115, 98, 70×8 |  |  | xanh→đỏ | đoạn nhiệt min→max (chuyển màu) |  |
| 206, 116 | TR | `JBMono-11` | MUTED | `24` | 14 |
| 228, 116 | TR | `JBMono-11` | INK | `30` | 14 |
| 36, 144, 2×52 |  |  | LINE | khối |  |
| 44, 148 | TL | `JBMono-16B` | INK_DIM | `KIA` | 30 |
| 44, 170, 16×16 |  |  | MUTED | bitmap `RAIN` |  |
| 62, 172 | TL | `JBMono-11` | MUTED | `Mưa` | 21 |
| 104, 154, 92×8 |  |  | PANEL2 | khối |  |
| 104, 154, 58×8 |  |  | xanh→đỏ | đoạn nhiệt min→max (chuyển màu) |  |
| 206, 172 | TR | `JBMono-11` | MUTED | `23` | 14 |
| 228, 172 | TR | `JBMono-11` | INK | `28` | 14 |
| 2, 34, 30×150 |  |  | nhấn SKY | Dock (`Dock.dc.html`), tab đang hiện `weather`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 96×2 |  |  | SKY | khối |  |

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
| 228, 87 | TR | `JBMono-11` | INK_DIM | `312m` | 28 |
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
| 228, 182 | TR | `JBMono-11` | INK_DIM | `1m trước` | 56 |
| 40, 197, w 188 |  |  | LINE | chấm kẻ (1 px mỗi 4 px) |  |
| 40, 201 | TL | `JBMono-11` | MUTED | `Lần tới` | 49 |
| 228, 201 | TR | `JBMono-11` | MINT | `sau 4m` | 42 |
| 2, 34, 30×150 |  |  | nhấn MINT | Dock (`Dock.dc.html`), tab đang hiện `none`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 96×2 |  |  | MINT | khối |  |

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
| 2, 34, 30×150 |  |  | nhấn AMBER | Dock (`Dock.dc.html`), tab đang hiện `claude`, huy hiệu Claude 1 / Tin nhắn 3 |  |
| 0, 230, 96×2 |  |  | AMBER | khối |  |
