# Nhật ký thay đổi thiết kế — màn thiết bị glimmer (240×240)

Mỗi mục có mã `P-YYYY-MM-DD.N` (N tăng liên tục). Mục mới nhất ở trên cùng. "Việc cần làm trong code" ghi tên kênh /
màn và việc cần làm — không ghi đường dẫn file hay cách code. Phía firmware ghi mục đã áp ở `.panel_design_sync.json`.

---

## P-2026-11-26.8 — Giao diện kiểu XP (bản A, thân be)

- **Toàn máy** (`source/XP-*.dc.html`, `screen_specs.md` §17, token `themeXP`; ảnh `XP*.png`, 44 màn):
  - Mỗi kênh là một cửa sổ kiểu XP: thanh tiêu đề xanh 5 dải (y 0–21) có icon + tên kênh + 3 nút, khung xanh 2 px, thân be
    xpBody (x 2–237, y 22–213), thanh trạng thái tuỳ kênh (y 196–213).
  - Thanh tác vụ y 214–239 thay dock dọc: nút bắt đầu xanh lá (Clawd + `glimmer`), 4 nút skill Claude / Ảnh / Thời tiết /
    Đồng hồ (nút đang hiện lõm), huy hiệu agent chờ trên nút Claude, khay giờ. Tiến độ slide = vạch 2 px ở đáy nút đang hiện.
  - Thành phần: thanh tiến độ khối xanh lá (9 khối), groupbox, ô trắng / danh sách, hộp thoại lỗi / cảnh báo / thông tin,
    thanh chạy "đang tải", dải thông báo vàng, tiêu đề `· cũ 14P` cho dữ liệu cũ.
  - Kênh: Claude, Codex, AI, Tác tử, Trang chủ, Xu hướng, Thời tiết, Dự báo, Đồng hồ, Thông tin, Cài đặt, Ảnh + mọi trạng
    thái phụ; 4 thẻ agent (nút Claude sáng cam khi cần bạn); Clawd ngủ dời xuống y 52 (Zz dời theo).
  - Màn hệ thống: khởi động (nền đen, thanh 3 khối xanh chạy), Wi-Fi / cài đặt Wi-Fi (màn chào xanh), cập nhật (thanh
    khối xanh lá), chưa có kênh (hộp thoại). Đêm giữ nền đen, chữ xám tối.
  - Chỉ lấy dáng XP: không logo, tên, ảnh nền hay font của Microsoft.
- Đổi luật: bỏ dock dọc (§15) và vạch chỉ báo y 230; vùng nội dung thành x 2–237, y 22–213 (thân cửa sổ), thanh tác vụ
  y 214–239 vẽ bởi khung chung (không phải kênh). Thẻ agent cần bạn: nút Claude sáng cam thay vạch vàng / xanh liền.
  Nền thân là xpBody (be), không còn `#000000` — trừ màn Đêm và màn hệ thống.
- Cần firmware: 60 màu mới (token `themeXP.color`, có RGB565). Không font mới.

**Việc cần làm trong code:**
- Khung chung: vẽ thanh tiêu đề (tên + icon kênh), khung, thân be, thanh tác vụ (nút skill bật, nút đang hiện lõm, huy
  hiệu agent chờ, giờ ở khay, tiến độ slide ở đáy nút) — vẽ một lần khi đổi kênh; giờ ở khay cập nhật mỗi phút.
- Mọi kênh: bố cục theo §17 (tọa độ trong bảng từng màn); mọi dải xoá của `tick()` tô xpBody, không tô BG.
- Thành phần mới: thanh tiến độ XP, groupbox, ô trắng, hộp thoại 3 loại, thanh chạy đang tải, dải thông báo.
- Thẻ agent: cửa sổ theo loại thẻ; nút Claude sáng cam khi thẻ cần bạn.
- Màn hệ thống: khởi động, Wi-Fi, cài đặt Wi-Fi, cập nhật, chưa có kênh theo §17. Đêm: chữ #4D4D4D trên đen.
- Bản xem trước màn trên máy tính vẽ theo kiểu XP.

## P-2026-11-25.7 — Skill Ảnh: hiện ảnh của người dùng

- **Kênh Ảnh** — mới (`source/Photo.dc.html`, `source/Photo-Empty.dc.html`, `screen_specs.md` §16; ảnh `Photo.png`,
  `PhotoEmpty.png`):
  - Skill thứ 2 sau agent; màu nhấn MINT. Status bar `Ảnh` (21 px), meta `2/5` = ảnh thứ mấy / tổng (21 px).
  - Ảnh 188×188 tại (40, 28) trong bố cục có dock, vẽ thẳng không viền. Mỗi slide một ảnh, lượt sau ảnh kế tiếp.
  - Chưa có ảnh: icon khung ảnh ×3 LINE (110, 56); `Chưa có ảnh` 16B MUTED TC (134, 104) 110 px; `Gửi ảnh từ app
    glimmer` 11 INK_DIM (134, 132) 154 px; `hoặc glimmer.local` 11 MUTED (134, 148) 126 px; vạch y 230 MUTED liền.
- **Dock** (`source/Dock.dc.html`, §15, token `component.dock`): tab 2 = **Ảnh** (icon khung ảnh 16×11 INK_DIM, không
  huy hiệu) thay Tin nhắn. Thứ tự tab: Claude / Ảnh / Thời tiết / Đồng hồ. Ảnh 11 màn có dock vẽ lại phần tab 2.
- Đổi luật: thêm skill `photo` vào `Skill::kAll` sau `agent` (`agent`, `photo`, `weather`, `clock`); kênh `Photo` gắn
  skill `photo`, tab dock Ảnh.
- Cần firmware: lưu ảnh JPEG trên LittleFS (thư mục ảnh, 15–30 KB mỗi ảnh; FS 1 MB → khoảng 5–8 ảnh), giải mã JPEG
  baseline từng khối thẳng ra màn (không framebuffer); API tải ảnh lên / liệt kê / xoá; số ảnh trong `/api/state`.
- Cần app: màn chọn ảnh, cắt vuông, thu nhỏ 188×188, gửi lên máy (phiên `/ui-design`).

**Việc cần làm trong code:**
- Kênh `Photo` (mới, skill `photo`): `draw()` vẽ status bar `Ảnh` + meta `<i>/<n>`, ảnh thứ i tại (40, 28); `tick()`
  không vẽ. Hết slide → lượt sau ảnh kế tiếp. Ảnh hỏng → bỏ qua. Không ảnh → màn chưa có ảnh theo §16.
- Dock: tab 2 Ảnh khi skill `photo` bật; vẽ icon khung ảnh. Tab Ảnh sáng (PANEL2 + vạch MINT) khi kênh `Photo` đang hiện.
- Cài đặt skill: `photo` trong `skills_on` / `skillsOn`; tải ảnh lên / xoá qua web và API.
- Bản xem trước màn trên máy tính: thêm màn Ảnh, Ảnh · chưa có ảnh; dock tab 2 Ảnh.

## P-2026-11-25.6 — Zz động khi Clawd ngủ

- **Kênh Claude** (`source/Claude-NoProject.dc.html`, `source/Claude-Done.dc.html`, `screen_specs.md` §6 mục "Zz động";
  ảnh `ClaudeNoProject.png`, `ClaudeDone.png`, `ClaudeZzFrames.png`):
  - Chữ "Zz" đứng yên (z (202, 46) + Z (214, 30)) thay bằng **một chữ z bay lên**: 12 khung × 0,4 s, nghỉ 1,2 s, chu
    kỳ 6,0 s. Bay ~2 px/khung từ (198, 52) lên (209, 26), lắc ngang 0…2 px, lớn dần `z3` 3×3 → `z4` 4×4 → `Z5` 5×5
    (ô 2 px). Khung 0, 10, 11 màu LINE (hiện ra / tan đi), còn lại MUTED.
  - Mỗi khung chỉ vẽ lại vùng 196, 24, 30×34 (tô BG rồi vẽ chữ). Clawd đứng yên, không chớp.
  - Tọa độ từng khung: token `component.clawd.sleepMark.frames`.

**Việc cần làm trong code:**
- Kênh `Claude`, khi Clawd ngủ (bảng trống hoặc mọi project Xong): bỏ "Zz" tĩnh, vẽ Zz động theo bảng khung — đổi khung
  trong `tick()` mỗi 0,4 s, xoá đúng vùng 196, 24, 30×34; `draw()` bắt đầu khung 0. Bản xem trước màn trên máy tính vẽ
  khung 6.

## P-2026-11-25.5 — Xong hết thì Clawd ngủ; Clawd vui mới cho thẻ xong

- **Kênh Claude** (`source/Claude-Done.dc.html`, `screen_specs.md` §6; ảnh `ClaudeDone.png`):
  - Mới **Claude · đã xong hết**: mọi project trên bảng `Xong` (ô + chữ MINT, tuổi MUTED TR) → Clawd **ngủ** (mắt
    `sleep` + "Zz" MUTED tại (202, 46) / (214, 30)), y như bảng trống.
  - Máy đang vẽ mắt `happy` khi project gấp nhất là P_DONE → đổi sang ngủ. Các trạng thái khác giữ: chờ duyệt `wide`,
    lỗi `sad`, đang chạy `open` + bước đi.
- **Clawd** (`source/Clawd.dc.html`, token `component.clawd`): mắt `happy` vẽ lại — lấp kín lỗ mắt rồi khoét theo
  **nửa ô** (ô 4 px → lỗ 2 px; ô 5 px → lỗ 2 px, vị trí `x + hx·ô/2` làm tròn xuống): mỗi mắt `^` 3×2 nửa ô, miệng cười
  `‿` 4×2 nửa ô. Tọa độ nửa ô trong `happyHoles`. Dùng ở thẻ **Attention · xong** (§1; ảnh `AttentionDone.png`).
- Đổi luật: mặt Clawd trên màn Claude khi mọi project đã xong = ngủ (trước: vui).

**Việc cần làm trong code:**
- Kênh `Claude`: project đứng đầu bảng là P_DONE → Clawd mắt `sleep` + "Zz" (như bảng trống), không chớp.
- Clawd mắt `happy`: lấp lỗ mắt, khoét lỗ nửa ô theo `happyHoles` (mắt `^ ^` + miệng cười); dùng cho thẻ Attention ·
  xong (ô 5 px). Bản xem trước màn trên máy tính vẽ theo.

## P-2026-11-25.4 — Khớp máy, Việt hoá đơn vị, vẽ lại đúng luật khung

- **Mọi màn có vạch chỉ báo** (`screen_specs.md` mọi mục; ảnh mọi màn): vạch y 230 = tiến độ màu kênh + phần chưa chạy
  **PANEL** hết 240 px. Setup, Agents: vạch MUTED; Agents có mục chờ duyệt: **AMBER liền** 240 px (câu hỏi: SKY liền).
  Night không vạch. Áp cả các màn có dock (§15).
- **Đơn vị tiếng Việt** (token `text`): thời lượng `P` / `G` / `NG` — đếm ngược `4NG`, `2G 14P`, `18G 5P`, `14P`, quá hạn
  `ngay`, chưa đồng bộ `--`; meta `CŨ 14P`, `CŨ 18P`; tuổi hàng project `2P`, `5P`, `1G`; danh sách Agents chữ thường `2p`,
  `12p`; thẻ chờ `chờ bạn · 2P`, dưới 1 phút `chờ bạn · 45 giây` (84–119 px, vừa 216). 12 giờ `SA` / `CH` thay `AM` / `PM`
  (Clock, Night, gợi ý mưa `MƯA 60% 4CH`). Trend nhãn thứ `T5 T6 T7 CN T2 T3 T4`. Info `312P`, `1P trước`, `sau 4P`.
- **Kênh Home** (`source/Home*.dc.html`, §4; ảnh `Home`, `HomeKeyBad`, `HomeNoWeather`):
  - Status bar `Trang chủ`, meta thời tiết `29° Ít mây` (70 px) / `--°`. Giờ VT323-86 x 12–182, y 30–100; biểu tượng
    thời tiết ×2 SKY tại (194, 40) — hai vùng không chạm nhau.
  - Ngày (12, 104); `c.giác 33°` / `c.giác --` TR (228, 105); đồng hồ đo y 128 / 146; `HÔM NAY` + `CÒN 9G` y 170; dải 24
    giờ đáy y 198; chấm đang tải x 206 / 215 / 224.
  - Chân trang y 204: thông báo viết theo thẻ đồng hồ đo — `CL BỊ TỪ CHỐI` (91 px), `CL HẾT HẠN`, `CL BỊ CHẶN`,
    `CX CÒN 2NG`, gợi ý mưa; IP TR (228, 204), dài nhất `192.168.100.200` 105 px → khe ≥ 20 px.
  - Mới: **Home · chưa có thời tiết** (`--°`, `c.giác --`, không biểu tượng).
- **Kênh Agents** (§5; ảnh `Agents`, `AgentsMore`, `AgentsIdle`): status bar `Tác tử`, meta `3 MỤC`, gạch MUTED; dòng từ
  y 32 bước 60; `+ N mục khác` TC (120, 152). Mới: **Agents · không mục nào chờ** (vạch MUTED).
- **Kênh Clock** (§12; ảnh `Clock`, `Clock12h`): status bar `Đồng hồ`, meta `tuần 48` (49 px); ngày TC (120, 32); giờ
  căn giữa y 46; mới **Clock · 12 giờ**: giờ ` 2` (`%2d`) + `CH` 12B AMBER tại (209, 95).
- **Kênh Info** (§13): bước 19 từ y 30, dòng cuối y 201–214 (hết tràn đáy).
- **Kênh Forecast** (§11): đoạn nhiệt min→max **màu đặc** — SKY hôm nay, MUTED ngày khác; điểm cuối ≤ x 219.
- **Kênh Weather** (§10): mới **Weather · lỗi** — `Chưa có thời tiết` 16B MUTED MC (120, 100), chi tiết 11 MUTED MC
  (120, 124), chấm kẻ (30, 140), `đang tự thử lại` INK_DIM MC (120, 158).
- **Kênh AI** (§8): đang tải → cột đặt lại `--` (giờ đã đồng bộ mà quá hạn: `ngay`), không đếm ngược.
- Ảnh vẽ bằng font VLW thật; chuỗi phiên bản màn hệ thống `v0.23.0-glimmer`.
- Phiếu: `docs/phieu_panel/2026-11-25-sua-ban-ve-cho-khop-may.md`, `docs/phieu_panel/2026-11-25-ve-lai-dung-luat-khung.md`
- Đổi luật: Home, Agents, Clock có status bar như mọi kênh (bỏ ngoại lệ "toàn khung").

**Việc cần làm trong code:**
- Vạch chỉ báo: phần chưa chạy PANEL hết 240 px — đã đúng trên máy, giữ.
- Thời lượng / đếm ngược / 12 giờ / thứ / Info: đổi chữ theo token `text` (`P`, `G`, `NG`, `ngay`, `--`, `SA`, `CH`,
  `T2`…`CN`); danh sách Agents giữ chữ thường; thẻ chờ dưới 1 phút `<n> giây`.
- Kênh `Home`: bố cục mới theo §4 (status bar, giờ trái, biểu tượng thời tiết phải, chân trang viết tắt `CL` / `CX`);
  xoá vùng giờ và vùng thời tiết riêng (gỡ lỗi chồng phút). Trạng thái chưa có thời tiết.
- Kênh `Agents`, `Clock`: thêm status bar, dời nội dung theo §5 / §12; Clock 12 giờ vẽ `SA` / `CH` cạnh giờ.
- Kênh `Info`: bước 19 px từ y 30.
- Kênh `Forecast`: đoạn nhiệt màu đặc, kẹp điểm cuối trong rãnh.
- Kênh `Weather`: trạng thái lỗi 3 dòng, đổi chuỗi lỗi theo bảng `text.weatherError`.
- Kênh `AI`: đang tải hiện `--` / `ngay` ở cột đặt lại.
- Bản xem trước màn trên máy tính vẽ lại cho khớp.

## P-2026-11-25.3 — Dock dọc nổi bám lề trái (thanh tab kiểu iPad)

- **Thành phần Dock** (`source/Dock.dc.html`, `screen_specs.md` §15; token `component.dock`):
  - Khối 30×150 tại (2, 34), nền PANEL viền LINE, 4 tab dọc bước 36 px: Claude (Clawd), Tin nhắn (bong bóng), Thời tiết
    (mặt trời), Đồng hồ — icon bitmap 16 px nét 2 px, INK_DIM; Clawd màu CLAWD.
  - Tab đang hiện: ô PANEL2 24×24 + vạch 2×10 màu nhấn của kênh ở mép trái. Info: không tab nào sáng.
  - Huy hiệu số 9×9 (vạt góc 1 px, chữ số bitmap 3×5 màu BG; > 9 → `+`; 0 → ẩn): AMBER trên Claude = số agent chờ
    duyệt / câu hỏi; SKY trên Tin nhắn = số tin mới.
- **Bố cục có dock** — 11 kênh xếp lại, nội dung x 40–228 (ảnh `ClaudeDock`, `HomeDock`, `AgentsDock`, `CodexDock`,
  `AIDock`, `TrendDock`, `WeatherDock`, `ForecastDock`, `ClockDock`, `InfoDock`, `SetupDock`; `screen_specs.md` §15):
  - Home: thêm status bar `Trang chủ`, meta `29° Ít mây` (70 px); giờ VT323-86 x 40–210 y 30–100 tách khỏi thời tiết;
    `c.giác 33°` TR (228, 105); IP riêng ở (228, 204) — hết chồng phút / cột thời tiết.
  - Agents: status bar `Tác tử`, meta `3 MỤC`; 3 dòng từ y 32 bước 60, chữ từ x 54.
  - Clock: status bar `Đồng hồ`, meta `tuần 48`; ngày, giờ, lời chào, dải 24 giờ căn giữa x 134.
  - Info: bước 19 px từ y 30 — dòng cuối y 201–214, hết tràn đáy.
  - Weather: 2 ô ngày 92×64 (MAI, KIA); `31°/24°` hôm nay TR (228, 119) cạnh mô tả.
  - Trend: cột 23 px bước 27 từ x 40; chú thích `% hạn mức tuần mỗi ngày` (161 px).
  - Claude, Codex, AI, Forecast, Setup: bố cục cũ dịch sang x 40, co theo bề ngang 188 px; hàng project Claude bỏ phần
    chi tiết khi không vừa (`Cần duyệt` thay `Cần duyệt · Bash`).
  - Chỉ vẽ trạng thái bình thường mỗi kênh; trạng thái đang tải / cũ / lỗi theo cùng lề x 40–228.
- Liên quan phiếu `docs/phieu_panel/2026-11-25-ve-lai-dung-luat-khung.md` mục 1–3 (Home / Agents / Clock status bar, Home
  chồng chữ, Info tràn đáy) — **chỉ giải trong bố cục có dock**; phiếu chưa đánh dấu đã vẽ. Mục 4 (Forecast gradient) và
  phiếu `2026-11-25-sua-ban-ve-cho-khop-may.md` chưa làm.
- Đổi luật: (1) vùng nội dung mọi kênh có dock là x 40–228 (dock chiếm x 2–31, y 34–183); (2) huy hiệu trên dock thay
  vạch vàng / xanh liền y 230 khi agent chờ — vạch y 230 chỉ còn tiến độ slide; (3) tab = skill: Claude, Tin nhắn, Thời
  tiết, Đồng hồ cùng xoay vòng, khác luật hiện tại "một skill chiếm màn" — phía code chốt trước khi áp.
- Cần firmware: bitmap 3 icon dock + chữ số 3×5 (token `component.dock`); đếm số tin mới cho huy hiệu Tin nhắn (gói
  `chat` đang chờ duyệt — tới lúc đó huy hiệu Tin nhắn ẩn).

**Việc cần làm trong code:**
- Chờ chốt 3 dòng "Đổi luật" trên; nếu không chốt, bỏ qua mục này.
- Thành phần dock: vẽ một lần khi vào kênh; khi đổi kênh chỉ vẽ lại ô tab cũ và mới; huy hiệu vẽ lại khi số đổi.
- Mọi kênh có dock: lề trái nội dung x 40, phải x 228; Home / Agents / Clock thêm status bar theo đặc tả §15.
- Attention, Night, màn hệ thống: không vẽ dock (giữ toàn màn).
- Bản xem trước màn trên máy tính vẽ thêm các màn có dock.

## P-2026-11-25.2 — Clawd đang ngủ khi chưa có project

- **Kênh Claude** (`source/Claude-NoProject.dc.html`, `source/Clawd.dc.html`, `screen_specs.md` §6; ảnh `ClaudeNoProject.png`):
  - Bảng project trống: Clawd (72×40, ô 4, tại 156, 58) đổi từ mắt `shut` (lấp kín lỗ mắt, nhìn như khối trơn) sang mắt
    **`sleep`**: hàng mắt trên (hàng 2) lấp, hàng mắt dưới (hàng 3) khoét cột 4–5 và 12–13 → hai vạch ngang 2 ô.
  - Thêm chữ "Zz" bitmap màu MUTED: `z` 4×4 ô × 2 px = 8×8 tại (202, 46); `Z` 5×5 ô × 2 px = 10×10 tại (214, 30). Nằm
    trong vùng nội dung, không chạm `4d` (y 112) hay Clawd (y ≥ 58).
  - Máy hiện vẽ mắt `shut` khi bảng trống — từ xa trông như lỗi, không ra "đang ngủ".
  - Artboard Clawd dùng chung có thêm dáng chân `tuck` (nằm) từ lúc thử phương án — **chưa dùng**, phía code bỏ qua.
- Cần firmware: kiểu mắt `sleep` của Clawd; bitmap "Zz" (2 glyph nhỏ).

**Việc cần làm trong code:**
- Clawd: thêm kiểu mắt `sleep` (hàng mắt trên lấp, hàng mắt dưới thành vạch ngang 2 ô mỗi mắt). Giữ `shut` cho chớp mắt.
- Kênh `Claude`: khi bảng project trống, vẽ Clawd mắt `sleep` thay `shut` và vẽ "Zz" MUTED tại (202, 46) / (214, 30);
  có project trở lại thì xoá vùng "Zz" (khoảng 202–224 × 30–54). Không chớp mắt khi đang ngủ.
- Tuỳ chọn: "Zz" đổi hình mỗi 1 s (chỉ `z` ↔ `z` + `Z`), vẽ lại riêng vùng đó.
- Bản xem trước màn trên máy tính (màn "Claude · chưa có project") vẽ lại cho khớp.

## P-2026-11-25.1 — Bản đầu: vẽ lại màn hiện có

Vẽ lại đúng các màn firmware v0.23.0 đang chạy, làm nền chung cho các lần sửa sau. **Chưa đổi gì so với máy.**
40 màn (13 kênh + màn hệ thống), mỗi trạng thái chính một artboard; tọa độ, chữ, màu lấy từ firmware.

- **Kênh Attention** (`source/Attention-*.dc.html`, `screen_specs.md` §1; ảnh `AttentionApproval/Input/Done/Progress/Error.png`): thẻ cần duyệt, lượt bạn, xong, tiến độ, lỗi.
- **Kênh Night** (§2; `Night.png`), **Setup** (§3; `Setup.png`).
- **Kênh Home** (§4; `Home.png`, `HomeKeyBad.png`): bình thường, khóa Claude lỗi.
- **Kênh Agents** (§5; `Agents.png`, `AgentsMore.png`): 3 mục, 4 mục (`+ 2 mục khác`).
- **Kênh Claude** (§6; `Claude*.png`): bình thường, chưa có project, sắp hết, dữ liệu cũ, khóa hết hạn còn số, đang tải, khóa bị từ chối, mất mạng.
- **Kênh Codex** (§7; `Codex*.png`): bình thường, dữ liệu cũ, đang tải, token hết hạn.
- **Kênh AI** (§8), **Trend** (§9), **Weather** (§10), **Forecast** (§11), **Clock** (§12), **Info** (§13).
- **Màn hệ thống** (§14; `Splash`, `Connecting`, `SetupMode`, `OtaProgress`, `NoChannels`).
- Ảnh vẽ bằng font VLW thật và tọa độ firmware (không chụp từ canvas — canvas dùng Google Fonts, lệch 1–2 px).
- Ghi nhận khi vẽ lại — máy hiện **trái luật khung**, chưa sửa trong bản này (để bản sau quyết định):
  - Home, Agents, Clock không có status bar và vẽ từ y 6–10 (ngoài vùng nội dung y 24–219).
  - Home: phút (VT323-86, x 110–177) chồng lên cột thời tiết phải (x ≥ 154); chân trang `CLAUDE BỊ TỪ CHỐI` chạm sát IP.
  - Info: dòng cuối `Lần tới` ở y 216–229, quá đáy vùng nội dung.
  - Trend: nhãn thứ là chữ Anh 2 ký tự (`TH FR SA SU MO TU WE`).
  - Clock 12 giờ hiện `AM`/`PM` (chữ Anh); `CLAUDE.md` ghi `SA`/`CH`.
  - Forecast: đoạn nhiệt min→max tô chuyển màu xanh → đỏ (luật: không gradient).

**Việc cần làm trong code:**
- Không có thay đổi giao diện. Đánh dấu `P-2026-11-25.1` là đã áp (thiết kế = máy hiện tại).
- Nếu thấy lệch giữa ảnh `screens/@2x/` và máy thật (nhất là chỗ chồng chữ ở Home), báo lại để phiên thiết kế sửa bản vẽ.
