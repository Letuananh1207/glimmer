---
name: panel-design
description: Phiên THIẾT KẾ màn hình 240×240 của thiết bị glimmer (firmware, GeekMagic SmallTV-Ultra) — Claude ngoài VS Code (claude.ai/code, trình duyệt hoặc app máy tính). Trò chuyện với người dùng để vẽ / sửa màn trên canvas "glimmer – màn thiết bị", nhận phiếu từ phía firmware, giữ đúng giới hạn phần cứng (px thật, RGB565, chỉ các cỡ font VLW đã đóng gói), và khi người dùng "chốt" thì xuất sang design/panel/ rồi đẩy lên GitHub. Dùng khi người dùng gõ /panel-design, dán một phiếu màn thiết bị, hoặc nói "vẽ màn thiết bị", "sửa giao diện trên máy", "thiết kế kênh …", "chốt thiết kế màn thiết bị". Không dùng cho app Android (dùng /ui-design).
argument-hint: "[<yêu cầu> | <phiếu dán vào> | phieu | chot | xem]"
---

# /panel-design: phiên thiết kế màn thiết bị

Lệnh: $ARGUMENTS

Vai trò: người thiết kế màn 240×240 của thiết bị. Thiết kế của màn thiết bị ở **`design/panel/`** (thiết kế app ở
`design/` phần còn lại — không đụng). Phiên này **chỉ** ghi `design/panel/` (và trạng thái phiếu trong
`docs/phieu_panel/`). **Không sửa** `src/`, `data/`, `tools/`, `test/`, `app/`, `.claude/`, `platformio.ini`. Việc cần
code làm thì ghi vào CHANGELOG; phía firmware (VS Code, `/panel-apply`) áp vào code, build và nạp lên máy.

**Canvas**: "glimmer – màn thiết bị" https://claude.ai/artifact/Kkt5gUfTSSTjxKBZ6mPuZA (loại Design). Sửa bằng công cụ
Artifact theo hướng dẫn của loại Design (đọc `SKILL.md` của canvas trước lần sửa đầu: `read` path `SKILL.md`). Chỉ ghi
dưới `project/`. Không tạo canvas mới. Artboard `Main.dc.html` là **khung mẫu** (vùng, màu, font) — giữ nguyên, chép nó
khi vẽ màn mới.

**Mọi lần báo cho người dùng** mở đầu bằng dòng:
`Canvas: glimmer – màn thiết bị — https://claude.ai/artifact/Kkt5gUfTSSTjxKBZ6mPuZA` (đang sửa một màn thì thêm
`· màn <Tên> (project/<Màn>.dc.html)`). Không đọc được canvas → nói rõ ngay, không đoán từ `design/panel/`.

| Lệnh | Làm gì |
|---|---|
| `/panel-design <yêu cầu>` hoặc `<phiếu>` | Vẽ / sửa trên canvas, trò chuyện tới khi người dùng chốt (mục 1–2). |
| `/panel-design phieu` | Liệt kê phiếu `chờ thiết kế` trong `docs/phieu_panel/`, chọn một để làm. |
| `/panel-design chot` (hoặc người dùng nói "chốt") | Xuất sang `design/panel/`, commit, đẩy lên GitHub (mục 3). |
| `/panel-design xem` | Đọc `project/canvas.json` + danh sách file canvas (`list` scope `files`), so với `design/panel/source/` bằng **kích thước + mã băm**: số artboard, màn đã sửa mà chưa chốt. Chỉ báo. |

## Giới hạn phần cứng — luật cứng, không phải gu

Màn là ST7789 240×240 trên ESP8266 (~25 KB heap). Thiết kế vẽ được nhưng máy không làm được thì vô ích.

- **Khung**: artboard 240 × 240, **1 px canvas = 1 px panel**, tọa độ nguyên. Vùng (`src/core/layout.h`): status bar
  y 0–21 · gạch màu kênh y 22 (1 px) · **nội dung y 24–219** (không vẽ ngoài) · y 220–229 để trống · vạch chỉ báo y 230,
  cao 2 px (tiến độ slide theo màu kênh; vàng/xanh liền khi agent chờ).
- **Màu**: chỉ bảng `src/core/theme.h` — nền `#000000`, PANEL `#1F1A28`, PANEL2 `#2A2236`, LINE `#34293F`, INK `#FFF8E8`,
  INK_DIM `#D8CDB8`, MUTED `#8A7F96`; nhấn CORAL `#FF5247` (Claude), AMBER `#FFD23F` (Đồng hồ / duyệt), MINT `#8FE574`
  (Thông tin / OK), SKY `#54B6FF` (Thời tiết / câu hỏi), LILAC `#C385FF` (Codex). **Một màu nhấn mỗi màn.** Không
  gradient, không trong suốt, không bóng đổ (RGB565, không blend). Màu mới → ghi "Cần firmware: màu mới" (phía code thêm
  vào `theme.h`); đừng đổi nền khỏi `#000000` (`#0E0D12` lên panel thành xám xanh).
- **Chữ**: chỉ các cỡ đã đóng gói (`data/fonts/`): JetBrains Mono **11**, **13**, **12 đậm**, **16 đậm**; VT323 **32**,
  **44**, **86** (86 chỉ có chữ số). Trên canvas dùng Google Fonts `JetBrains Mono` / `VT323` cùng cỡ px — gần đúng, không
  đúng tuyệt đối. Cỡ mới = font mới tốn chỗ (FS chỉ 1 MB) và phải nạp lại filesystem → chỉ khi người dùng đồng ý, ghi
  "Cần firmware: font <họ>-<cỡ>". Ký tự: ASCII, `°`, `·`, đủ chữ tiếng Việt; **không** `…` (viết `...`), không emoji, không
  ký tự khác.
- **Tiếng Việt chạy dài**: đo mọi nhãn với khe của nó (tiêu đề status ≈ 88 px, meta phải ≈ 72 px). Đo chính xác bằng
  font thật: `python tools/vlwpreview.py /tmp/x.png data/fonts/JBMono-12B.vlw "NHÃN"` (ảnh ×3, chia 3 = px). Không vừa →
  rút gọn chữ, không ép cỡ nhỏ hơn bảng trên. Đơn vị ngắn có sẵn: `P` phút, `G` giờ, `NG` ngày, `SA`/`CH`.
- **Hình khối**: hình chữ nhật, đường 1 px, chấm, bitmap nhỏ (linh vật Clawd: lưới 10 hàng, có các biểu cảm mắt). Ảnh
  lớn / ảnh chụp không được (không có framebuffer). Bo góc nhỏ thì được nhưng tốn — dùng ít.
- **Thanh `pixelBar`**: 9 ô rời, khe 1 px, mỗi ô sáng hẳn hoặc tắt — **không** tô một phần ô (≥ 89% = đầy).
- **Chuyển động**: không có hiệu ứng chuyển màn (cắt ngay). Bên trong màn chỉ đổi giá trị (5 lần/giây) — số đếm, chớp
  mắt Clawd được; trượt / mờ dần thì không. Màn xoay vòng theo thứ tự kênh, mỗi màn một slide.
- **Dữ liệu**: chỉ vẽ thứ firmware có (`/api/state`, `CLAUDE.md` gốc). Dữ liệu mới → "Cần firmware: …".
- Không có cảm ứng, không nút bấm: màn chỉ để **nhìn từ xa ~1 m** — chữ chính to, ít chữ phụ.

## 0. Lần đầu: canvas chỉ có khung mẫu, `design/panel/` chưa có

Bản thiết kế gốc của màn thiết bị đã mất; việc đầu tiên là **vẽ lại hiện trạng** lên canvas để có nền chung, rồi mới sửa:

1. Lấy ảnh hiện trạng: `python tools/screens.py /tmp/now.png` (vẽ bằng font VLW thật và tọa độ firmware; xem số màn
   trong ảnh) — đây là **chuẩn tham chiếu**, giống máy hơn canvas. Tọa độ, chữ: `src/channels/ch_*.cpp`, `chrome.cpp`
   (status bar, thẻ credential), `src/core/display.cpp` (Clawd, màn hệ thống). Chỉ đọc để lấy bố cục.
2. Mỗi kênh một artboard `project/<Kênh>.dc.html`, tên theo `kChannels[]` trong `src/main.cpp`: `Claude`, `Codex`, `AI`,
   `Agents`, `Attention`, `Home`, `Trend`, `Weather`, `Forecast`, `Clock`, `Night`, `Info`, `Setup`; màn hệ thống
   `Splash`, `Connecting`, `SetupMode`, `OtaProgress`. Trạng thái chính mỗi màn (đang tải, có số liệu, cũ/STALE, lỗi,
   credential hỏng; thẻ Attention: duyệt / câu hỏi / xong / lỗi) — trạng thái = prop `data-props` (enum) hoặc artboard
   riêng `<Kênh>-<TrạngThái>.dc.html`. Xếp mỗi kênh một hàng trên canvas (80 px giữa artboard, 120 px giữa hàng).
3. Cho người dùng xem, sửa tới khi ưng, rồi **chốt lần đầu** (mục 3) — tạo khung `design/panel/`: `README.md`,
   `CHANGELOG.md` (phần đầu như mẫu + `## P-<ngày>.1 — Bản đầu: vẽ lại màn hiện có`), `tokens/panel_tokens.json`,
   `docs/screen_specs.md`, `source/`, `screens/@2x/`.

**`panel_tokens.json`** (phía code chép tay sang `theme.h` / font; không có script sinh):

```json
{
  "meta": { "name": "glimmer panel", "frame": { "width": 240, "height": 240, "unit": "px" } },
  "zone":  { "status": [0, 21], "accentLine": 22, "content": [24, 219], "indicator": { "y": 230, "h": 2 } },
  "color": { "bg": { "value": "#000000", "rgb565": "0x0000", "use": "Nền mọi màn" } },
  "font":  { "jb11": { "file": "JBMono-11", "family": "JetBrains Mono", "size": 11, "weight": 400, "use": "Chữ phụ" } },
  "slot":  { "statusTitle": 88, "statusMeta": 72 }
}
```

## 1. Giữ canvas và `design/panel/` nhẹ (mọi lượt)

- Không nhúng base64 vào `.dc.html`; bitmap Clawd vẽ bằng ô `div` / SVG `rect`, dùng chung một file `Clawd.dc.html`
  qua `<dc-import>`. `.dc.html` > 300 KB → báo.
- Không đọc nguyên trang lớn vào ngữ cảnh: `read` canvas lưu file cục bộ → `grep -n` → `sed -n 'a,bp'`.

## 2. Trước khi vẽ, và khi vẽ

- `git pull`. Phiếu → đọc `docs/phieu_panel/<…>.md`: phiếu nói **cần gì**, phiên này quyết định vẽ thế nào.
- Đọc đúng chỗ: mục của màn trong `design/panel/docs/screen_specs.md` (grep `## <số>. <Màn>`), token
  `design/panel/tokens/panel_tokens.json`.
- Luật hành vi của màn ở `CLAUDE.md` gốc (mục Channels, Attention queue, Stale data & night modes, Credential states):
  thứ tự ưu tiên thẻ, thời gian giữ thẻ, khi nào dim / tối, kênh nào hiện theo skill. Vẽ trái luật → nói ngay: đổi luật
  (dòng "Đổi luật" trong CHANGELOG, phía code chốt) hay đổi ý tưởng.
- Phong cách hiện có (từ P-2026-11-26.8/.9): **kiểu Windows XP (Luna)** — cửa sổ thanh tiêu đề xanh, thân be, thanh
  tác vụ có nút start; số VT323, linh vật Clawd, tiếng Việt. Đổi phong cách là quyết định của người dùng.
- **Chức năng mới phía thiết bị phải tham khảo kỹ Windows XP thật** (người dùng yêu cầu 2026-11-26): tìm thành phần XP
  thật tương ứng (hộp thoại, bong bóng khay, thanh tiến độ khối, danh sách, groupbox, màn welcome / đăng nhập…) và vẽ đúng
  dáng, chữ, trạng thái, cách XP thật hành xử — không tự chế. Ghi trong ghi chú/CHANGELOG thành phần XP nào được dùng.
- Sửa đúng artboard, chỉ phần được yêu cầu. Mỗi lượt: sửa → một dòng đã đổi gì → người dùng xem trên canvas. Chưa chắc →
  2–3 phương án, mỗi cái một artboard cạnh nhau.
- Nhãn mới: đo theo mục Giới hạn **ngay khi vẽ**, ghi số px vào ghi chú để lúc chốt chép vào đặc tả.
- Chưa chốt thì **không** ghi `design/panel/`, không commit.

## 3. Chốt: xuất sang `design/panel/` và đẩy lên GitHub

1. **Mã** `P-YYYY-MM-DD.N` (tiền tố `P` để khỏi lẫn với mã của app): `N` = số mục trên cùng + 1, liên tục —
   `grep -m1 -oE '^## P-[0-9-]+\.[0-9]+' design/panel/CHANGELOG.md`. Bản đầu `.1`.
2. **Source**: chép `project/<Màn>.dc.html` sang `design/panel/source/<Màn>.dc.html` (nguyên văn).
3. **Ảnh** `design/panel/screens/@2x/<Màn><TrạngThái>.png` (480 × 480, phóng ×2 không làm mịn) cho mọi trạng thái đổi
   / mới, chụp bằng trình duyệt không giao diện. Không chụp được → giữ ảnh cũ, ghi "ảnh chưa cập nhật" trong CHANGELOG.
4. **Đặc tả** `design/panel/docs/screen_specs.md` — dòng `> **<mã> — <tiêu đề>:** …` lên **đầu** mục của màn. Mỗi khối
   ghi **tọa độ px** (x, y, w, h), font (`JBMono-12B`…), màu (tên token), datum căn chữ (TL / TC / TR / MC…), nguyên văn
   chữ và độ rộng đo được, khi nào đổi giá trị (vẽ lại phần nào). Màn mới → `## <số>. <Tên> — kênh \`<Tên>\``.
5. **Token** đổi → `design/panel/tokens/panel_tokens.json`.
6. **CHANGELOG**: mục mới **trên cùng** (dưới `---`), theo mẫu; viết ra file tạm rồi chèn bằng script.
7. **Commit và đẩy**: chỉ file trong `design/panel/` (và dòng `- Đã vẽ: <mã>` trong phiếu đáp ứng). Thông điệp
   `design-panel <mã>: <tóm tắt>`. Đẩy lên `main`; bị từ chối → `git pull --rebase` rồi đẩy lại; xung đột → hỏi.
8. Báo: mã, tóm tắt, và "trong VS Code chạy `/panel-apply`".

### Phần đầu `design/panel/CHANGELOG.md`

```markdown
# Nhật ký thay đổi thiết kế — màn thiết bị glimmer (240×240)

Mỗi mục có mã `P-YYYY-MM-DD.N` (N tăng liên tục). Mục mới nhất ở trên cùng. "Việc cần làm trong code" ghi tên kênh /
màn và việc cần làm — không ghi đường dẫn file hay cách code. Phía firmware ghi mục đã áp ở `.panel_design_sync.json`.

---
```

### Mẫu mục CHANGELOG

```markdown
## <mã> — <tiêu đề nói bằng lời người dùng>

- **Kênh <Tên>** (`source/<Màn>.dc.html`, `screen_specs.md` §<số>; ảnh `<Ảnh>.png`):
  - <thay đổi: tọa độ px, font, màu token, chữ + độ rộng đo được>
  - <máy đang làm gì khác, nếu biết>
- Phiếu: `docs/phieu_panel/<…>.md` (bỏ dòng nếu không từ phiếu)
- Đổi luật: <hành vi mới đề xuất — phía code phải chốt trước> (bỏ dòng nếu không)
- Cần firmware: <màu / font / dữ liệu mới> (bỏ dòng nếu không)

**Việc cần làm trong code:**
- Kênh `<Tên>`: <cần làm gì, nói theo hành vi và tọa độ>.
```
