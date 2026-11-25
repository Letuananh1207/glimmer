# Nhật ký thay đổi thiết kế — màn thiết bị glimmer (240×240)

Mỗi mục có mã `P-YYYY-MM-DD.N` (N tăng liên tục). Mục mới nhất ở trên cùng. "Việc cần làm trong code" ghi tên kênh /
màn và việc cần làm — không ghi đường dẫn file hay cách code. Phía firmware ghi mục đã áp ở `.panel_design_sync.json`.

---

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
