# Nhật ký thay đổi thiết kế — màn thiết bị glimmer (240×240)

Mỗi mục có mã `P-YYYY-MM-DD.N` (N tăng liên tục). Mục mới nhất ở trên cùng. "Việc cần làm trong code" ghi tên kênh /
màn và việc cần làm — không ghi đường dẫn file hay cách code. Phía firmware ghi mục đã áp ở `.panel_design_sync.json`.

---

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
