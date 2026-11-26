# Nhật ký thay đổi thiết kế — màn thiết bị glimmer (240×240)

Mỗi mục có mã `P-YYYY-MM-DD.N` (N tăng liên tục). Mục mới nhất ở trên cùng. "Việc cần làm trong code" ghi tên kênh /
màn và việc cần làm — không ghi đường dẫn file hay cách code. Phía firmware ghi mục đã áp ở `.panel_design_sync.json`.

---

## P-2026-11-26.19 — Biểu tượng desktop vẽ lại theo kiểu Windows XP

- **Kênh Home — desktop** (`source/XP-Desk-Icons.dc.html`, `screen_specs.md` §17 mục XP-Real; ảnh `XPDeskIcons.png`):
  - Codex = **Command Prompt** của XP: khung xám nổi 3D, thanh tiêu đề gradient xanh đậm → xanh nhạt, thân đen, `C:\_`.
  - Ảnh = **My Pictures**: thư mục vàng chuyển sắc, nắp trước nghiêng, tấm ảnh trời xanh + mặt trời bên trong.
  - Thùng rác = **Recycle Bin** (trống): thùng lưới xám xanh, sáng trái → tối phải, khe dọc, hai vành, miệng bầu dục tối.
  - Cả ba: bitmap màu 32×23 pixel thật tại (24, ô), không phóng ×2; đổ sáng trên-trái, viền là sắc tối của vật; bóng chấm
    #22303F 1 px phải-dưới thay bóng mờ XP. Clawd, nhãn, vị trí không đổi (P-.18).
  - Máy đang vẽ icon nét trắng 16×10 phóng ×2.
- Cần firmware: màu mới chỉ trong bitmap biểu tượng (Codex 14, Ảnh 20, Thùng rác 18 — lấy từ `fill` trong source), lưu
  flash; mặt nạ trong suốt để giữ hình nền.

**Việc cần làm trong code:**
- Kênh `Home`: sinh bitmap 3 biểu tượng từ source (path SVG → RGB565 + mặt nạ), vẽ tại (24, 56) / (24, 104) / (24, 152);
  trạng thái chọn = thay màu bitmap bằng xpSelectIcon theo dither (x+y) chẵn. Vẽ lại phần hình nền dưới icon như nhãn.

## P-2026-11-26.18 — Claude và Codex trên desktop không hiện %

- **Kênh Home — desktop** (`source/XP-Desk-OneCol.dc.html`, `screen_specs.md` §17 mục XP-Real; ảnh `XPDeskOneCol.png`):
  - Nhãn biểu tượng chỉ là tên chương trình, như XP thật (biểu tượng desktop XP không mang số liệu): `Claude` (JBMono-11,
    42 px) và `Codex` (35 px), white TC tại (40, ô+24), bóng đen (+1, +1). Vị trí, biểu tượng, trạng thái chọn không đổi.
  - Máy đang vẽ `Claude <x>%` / `Codex <x>%` và vẽ lại nhãn khi % đổi. % vẫn hiện trong cửa sổ Claude / Codex.

**Việc cần làm trong code:**
- Kênh `Home`: nhãn biểu tượng Claude / Codex = `Claude` / `Codex`, không kèm %; `tick()` không còn vẽ lại nhãn khi số liệu
  đổi (chỉ khi chọn / bỏ chọn biểu tượng hoặc bong bóng ẩn).

## P-2026-11-26.17 — Đồng hồ, Thời tiết, Dự báo, Đêm và desktop theo Windows XP thật

- **Kênh Clock** (`source/XP-Clock-Props.dc.html`; `screen_specs.md` §17 mục XP-Real; ảnh `XPClockProps.png`): thành hộp
  thoại Ngày và Giờ của XP — tiêu đề `Ngày và Giờ` (77 px); tab `Ngày và giờ` / `Múi giờ`; groupbox Ngày (10, 54, 122×128):
  ô tháng `11/2026`, lịch tháng ô 16×13 từ (13, 98), tuần từ thứ Hai, ngày tháng khác xpDim, hôm nay xpSelect chữ white;
  groupbox Giờ (136, 54, 94×128): đồng hồ kim tâm (183, 106), ô giờ `14:32:15` 12B (56 px) có nút tăng giảm; dòng
  `Múi giờ: GMT+7 · Hà Nội` (161 px). Bỏ số VT323 to, câu chào, thanh trạng thái.
- **Kênh Weather** (`source/XP-Weather-Props.dc.html`; ảnh `XPWeatherProps.png`): trang thuộc tính kiểu tab Chung — tab
  `Hiện tại` / `Dự báo`; icon 32×32 (14, 50), `Ít mây` 16B, nơi 11 xpLabel, `29°` VT323-44 TR (226, 45); 6 dòng
  `nhãn:` / giá trị (giá trị x 112), hai vạch khắc. Bỏ groupbox Mai / Kia và thanh trạng thái.
- **Kênh Forecast** (`source/XP-Forecast-Details.dc.html`; ảnh `XPForecastDetails.png`): thành tab `Dự báo` của cửa sổ
  Thời tiết (tiêu đề `Thời tiết`); danh sách dạng Chi tiết (10, 48, 220×157), hàng tiêu đề `Ngày | Trời | Thấp | Cao`,
  dòng 24 px JBMono-13 + icon 16×16, dòng hôm nay xpSelect. Bỏ thanh nhiệt độ.
- **Kênh Night** (`source/XP-Night-Saver.dc.html`, `XP-Night-Saver-Play.dc.html`; ảnh `XPNightSaver.png`): trình bảo vệ
  màn hình — giữ nền đen, chữ xpLabel; khối `23:47` VT323-86 (170 px) + ngày nhảy chỗ mỗi phút trong x 6–64, y 6–134.
- **Desktop** (`source/XP-Desk-OneCol.dc.html`; ảnh `XPDeskOneCol.png`): chỉ chương trình đã cài, một cột x 40 (Claude %,
  Codex %, Ảnh, Thùng rác); bỏ biểu tượng Thời tiết, Đồng hồ (XP thật không có).
- Đổi luật: biểu tượng desktop không còn theo skill `weather` / `clock` (thay phần đó của P-2026-11-26.14); Thời tiết
  mở từ biểu tượng khay, Đồng hồ mở từ giờ ở khay. Forecast thành tab của cửa sổ Thời tiết: một nút thanh tác vụ, một
  cửa sổ (`windows` coi Weather + Forecast là một chương trình). Skill Đồng hồ tắt → khay vẫn hiện giờ.
- Cần firmware: tên nơi của thời tiết (dòng `Hà Nội`) nếu chưa có; dữ liệu lịch tháng (thứ của ngày 1, số ngày) tính từ
  giờ máy; múi giờ dạng `GMT+7` + tên nơi.

**Việc cần làm trong code:**
- Thành phần tab Luna dùng chung (tab chọn / không chọn, trang tab white, groupbox nền white).
- Kênh `Clock`: vẽ lại theo bảng §17 XP-Real; mỗi giây chỉ vẽ lại mặt đồng hồ (147..219, 70..142) và chữ ô giờ; qua
  nửa đêm vẽ lại lịch.
- Kênh `Weather`: trang Hiện tại theo bảng; icon 32×32 theo mã thời tiết (bitmap nắng / ít mây / mưa trong đặc tả).
- Kênh `Forecast`: tab Dự báo trong cửa sổ Thời tiết; danh sách Chi tiết; icon 16×16 từng dòng.
- Kênh `Night`: khối giờ + ngày nhảy chỗ ngẫu nhiên mỗi phút (xóa khung cũ bằng đen).
- Desktop: bỏ biểu tượng Thời tiết và Đồng hồ; cột x 40 dồn lên. Taskbar: Weather và Forecast chung một nút.

## P-2026-11-26.16 — Mở cửa sổ như XP: nút lún, thanh tiêu đề bay, khung trước, con trỏ chờ, hộp tải về

- **Mọi kênh có cửa sổ** (`source/XP-Open-1|2|3.dc.html`, `XP-Open-Play.dc.html`; `screen_specs.md` §17 mục XP-Open;
  ảnh `XPOpen1.png`, `XPOpen2.png`, `XPOpen3.png`):
  - Nút cửa sổ trên thanh tác vụ lún trước; chỉ vẽ lại nút đổi, không vẽ lại cả thanh tác vụ (máy đang vẽ lại cả dải sau cửa sổ).
  - Khôi phục cửa sổ đang thu nhỏ: thanh tiêu đề bay từ nút (71 + 30k, 217, 28×20) lên (0, 0, 240×22), 4 bước × 40 ms,
    dải xpTitle / xpTitleHi / xpTitleLight / xpTitleEdge, vệt giữ lại tới khi cửa sổ phủ. Thu nhỏ: ngược lại. Mở mới /
    chuyển cửa sổ phía sau / thẻ agent: không bay (như XP thật — thành phần "Animate windows").
  - Khung trước: tiêu đề + khung + thân xpBody trống 200 ms, rồi nội dung.
  - Con trỏ "Working in Background" (mũi tên 12×19 mũi (132, 160) + đồng hồ cát 9×12 tại (142, 169), 4 khung × 200 ms) từ
    lúc khung hiện tới khi có nội dung.
- **Đang tải Claude / Codex / Thời tiết / AI** (`source/XP-Load-Claude.dc.html`, `XP-Load-Static.dc.html`; ảnh `XPLoad.png`):
  hộp tải về kiểu XP — quả địa cầu 24×24 (30, 36) → tờ giấy bay 6 vị trí → thư mục 24×20 (186, 38); `Đang tải...` 12B TC
  (120, 92) 77 px và thanh chạy (50, 116) giữ nguyên; thêm `từ claude.ai` JBMono-11 xpMuted TC (120, 140) 84 px
  (`từ chatgpt.com` 98, `từ open-meteo.com` 119); con trỏ chờ.
- Đồng hồ khay: giữ không nhấp nháy dấu `:` (XP thật cũng không).
- Đổi luật: "No animated transitions — every switch is an instant cut" → cho phép đúng một hiệu ứng: thanh tiêu đề bay
  4 bước × 40 ms khi khôi phục / thu nhỏ cửa sổ (~160 ms chặn vòng lặp), và khung trống 200 ms trước nội dung. Các chuyển
  khác vẫn cắt ngay.

**Việc cần làm trong code:**
- Thanh tác vụ: khi đổi cửa sổ trên cùng chỉ vẽ lại nút cũ và nút mới, không vẽ lại cả dải.
- Mở cửa sổ (mọi kênh trừ Night / Attention / màn hệ thống): nút lún → (nếu khôi phục từ thu nhỏ: 4 dải tiêu đề bay theo
  tọa độ trên) → khung + thân trống + con trỏ chờ, đợi 1 nhịp 200 ms → nội dung. Thu nhỏ: 4 dải ngược rồi vẽ desktop.
- Con trỏ chờ: bitmap mũi tên + 4 khung đồng hồ cát (§17 XP-Open), đổi khung mỗi tick, chỉ vẽ lại ô đồng hồ cát; mất khi nội
  dung vẽ.
- Đang tải Claude / Codex / Thời tiết / AI: thêm quả địa cầu, thư mục, tờ giấy bay (xóa ô cũ bằng xpBody) và dòng nguồn
  `từ <host>`; giữ nhãn và thanh chạy.

## P-2026-11-26.15 — Thời tiết thành biểu tượng khay, bong bóng hiện tạm như XP

- **Desktop + thanh tác vụ** (`source/XP-Desk-Tray.dc.html`, `XP-Desk-Balloon.dc.html`; `screen_specs.md` §17 mục XP-Desk-Tray;
  ảnh `XPDeskTray.png`, `XPDeskBalloon.png`):
  - Bỏ bong bóng thời tiết luôn mở trên desktop (XP thật không giữ bong bóng mãi).
  - Khay hệ thống rộng thêm 20 px (x 176–239) với biểu tượng thời tiết 16×14 xpIconWarn tại (180, 220), khi skill Thời tiết bật.
  - Bong bóng XP thật (góc bo, nút ×, đuôi chỉ vào biểu tượng khay) hiện ~10 s khi vào desktop và khi thời tiết đổi, rồi tự ẩn;
    app chạm biểu tượng khay → hiện lại, × → ẩn.
  - Thanh tác vụ còn tối đa 3 nút cửa sổ khi khay có biểu tượng; cột 1 của desktop xếp được 4 biểu tượng.
- Phiếu: `docs/phieu_panel/2026-11-26-desktop-cua-so-xp.md` (người dùng hỏi thêm trong phiên thiết kế)
- Đổi luật: thời tiết trên desktop không còn hiện thường trực — chỉ trong bong bóng tạm và cửa sổ Thời tiết.
- Cần firmware: hẹn giờ ẩn bong bóng (10 s), nhận lệnh "hiện / ẩn bong bóng" từ app (chạm biểu tượng khay, ×).

**Việc cần làm trong code:**
- Thanh tác vụ: khay x 176 khi skill Thời tiết bật, vẽ biểu tượng thời tiết; giới hạn 3 nút cửa sổ.
- Kênh `Home`: bỏ bong bóng thường trực; vẽ bong bóng mới khi vào desktop / thời tiết đổi / app yêu cầu, ẩn sau 10 s bằng cách vẽ lại
  hình nền (giải mã một phần) + biểu tượng dưới vùng hộp và đuôi.
- Bản xem trước màn trên máy tính vẽ theo.

## P-2026-11-26.14 — Desktop theo skill, thanh tác vụ theo cửa sổ đang mở, menu chuột phải

- **Desktop (kênh Home kiểu XP)** (`source/XP-Desk-Agent.dc.html`, `XP-Desk-All.dc.html`, `XP-Desk-Selected.dc.html`, hình nền chung
  `XP-Wall.dc.html`; `screen_specs.md` §17 mục XP-Desk; ảnh `XPDeskAgent.png`, `XPDeskAll.png`, `XPDeskSelected.png`):
  - Một biểu tượng cho mỗi chương trình của skill bật (Agent → Claude, Codex; Ảnh; Thời tiết; Đồng hồ), xếp như XP Auto Arrange: cột tâm
    x 40 rồi x 120, ô 48 từ y 8; Thùng rác giữ ô y 152 cột 0; cột 1 dừng trên bong bóng thời tiết.
  - Biểu tượng đang chọn như XP: icon pha xanh chọn, nhãn nền xpSelect + viền chấm.
- **Thanh tác vụ** (mọi màn có thanh tác vụ; `XP-Win-Open.dc.html`, ảnh `XPWinOpen.png`): nút = cửa sổ đang mở (tối đa 4), cửa sổ trên
  cùng lõm, thu nhỏ thì thường; không mở gì → chỉ start + khay. Bỏ vạch tiến độ slide.
- **Thanh tiêu đề**: nút □ luôn mờ (nét xpCaptionOff) — cửa sổ đầy màn, không đổi cỡ (thành phần XP: nút phóng to bị tắt).
- **Menu chuột phải** (`XP-Menu-Desktop.dc.html`, `XP-Menu-Window.dc.html`; ảnh `XPMenuDesktop.png`, `XPMenuWindow.png`): menu ngữ cảnh desktop
  và menu cửa sổ (system menu) của XP, chữ tiếng Việt; mục không dùng được mờ.
- Phiếu: `docs/phieu_panel/2026-11-26-desktop-cua-so-xp.md`
- Đổi luật: thiết bị không tự xoay kênh; nút thanh tác vụ là cửa sổ đang mở (không còn một nút cố định cho mỗi skill); bấm `×` bỏ nút đó;
  biểu tượng desktop theo skill bật.
- Cần firmware: màu xpSelectIcon `#98B4E2`, xpSelectClawd `#85719E` (xpMenu = white, xpMenuBorder = xpDim, xpCaptionOff = xpWelcomeLine đã
  có); danh sách cửa sổ đang mở + cửa sổ trên cùng + cửa sổ thu nhỏ (app gửi xuống, báo lại trong `/api/state`); lệnh mở / đóng menu
  chuột phải tại toạ độ, chọn mục; tắt tự xoay.

**Việc cần làm trong code:**
- Kênh `Home`: vẽ biểu tượng theo skill bật theo lưới 2 cột (§17 XP-Desk); trạng thái chọn một biểu tượng.
- Thanh tác vụ: nút theo danh sách cửa sổ đang mở, lõm = trên cùng; bỏ vạch tiến độ; badge / nút cam trên nút Claude khi nó đang mở.
- Mọi cửa sổ XP: nút giữa thanh tiêu đề vẽ □ mờ.
- Menu chuột phải: vẽ đè lên màn tại toạ độ (desktop / cửa sổ), đóng khi chọn mục / chạm ngoài / thẻ agent chen ngang.
- Ghi chú cho app: tâm nút □ trên máy là x 210 (app đang tính 207).

## P-2026-11-26.13 — Clawd làm việc theo GIF (lấy laptop, gõ, ngủ)

- **Kênh Claude kiểu XP** (`source/XP-Claude-Laptop.dc.html`, `screen_specs.md` §17 mục XP-Claude-Laptop, token `themeXP.clawdWork`;
  ảnh `XPClaudeLaptop.png`, `XPClaudeLaptopFrames.png`):
  - Project đầu bảng Đang chạy: thay dáng bước chân bằng Clawd chép theo GIF Clawd — đoạn mở đầu một lần (đứng → lắc → lôi laptop
    ra → đặt xuống → nhún → ngồi; 12 khung, 90–300 ms) rồi lặp 3 khung gõ, 200 ms / khung.
  - Laptop là nét xám `#808080` nhìn nghiêng; Clawd quay ¾ sang trái, mắt đen 1 hàng (không nháy).
  - Xong / bảng trống: chuyển thẳng sang ngủ, không cất laptop.
- **Clawd ngủ** (`source/XP-Claude-NoProject.dc.html`, `source/XP-Claude-Done.dc.html`; ảnh `XPClaudeNoProject.png`, `XPClaudeDone.png`):
  Clawd nâng lên y 44, Zz bay trong y 24–38; `4NG` đứng yên TR (229, 84) — sửa lỗi `4NG` bị đẩy sang trái (150, 84).
- Đổi luật: đoạn mở đầu vẽ lại theo nhịp riêng (90–300 ms / khung, nhanh hơn tick 5 Hz) — chỉ vùng 98×80 px.
- Cần firmware: màu xpLaptop `#808080` (token); lưới các khung trong token `themeXP.clawdWork.frames`.

**Việc cần làm trong code:**
- Kênh `Claude`: máy trạng thái Clawd — Đang chạy: phát mở đầu một lần rồi lặp khung gõ; rời Đang chạy → Clawd ngủ ngay.
  Mỗi khung tô vùng 98×80 tại (132, 20) bằng xpBody, vẽ lưới ô 4 px tại (136, 30), vẽ lại `4NG`.
- Clawd ngủ: (156, 44), Zz theo công thức §17; `4NG` luôn ở (229, 84).
- Bản xem trước màn trên máy tính vẽ theo.

## P-2026-11-26.12 — Màn đầu kiểu desktop XP (thay Trang chủ)

- **Màn desktop** — mới (`source/XP-Desktop.dc.html`, `screen_specs.md` §17 mục XP-Desktop, token `themeXP.desktop`; ảnh `XPDesktop.png`):
  - Nền = ảnh JPEG người dùng gửi lên (baseline, đúng 240×214, ≤ 40 KB) vẽ ở (0, 0) một lần khi vào màn. Chưa có / hỏng → nền
    dự phòng vẽ pixel phỏng bố cục hình nền XP (trời xanh đậm → nhạt, mây ti, mây bồng, núi xa, gò cỏ).
  - Biểu tượng desktop cột trái (tâm x 40, bước 48): Claude 38%, Codex 71%, Ảnh, Thùng rác — nhãn trắng có bóng đen.
  - Bong bóng vàng ở khay (136×50 tại (100, 150), đuôi chỉ khay giờ): thời tiết `29° · Ít mây`, `cảm giác 33°`.
  - Thanh tác vụ như mọi màn, không nút nào lõm.
- Đổi luật: kênh Trang chủ (Home) kiểu cửa sổ thay bằng màn desktop; IP và "Còn 9G hôm nay" không còn trên màn đầu.
- Cần firmware: lưu ảnh nền JPEG trên LittleFS + API tải lên / xoá ảnh nền; 24 màu nền dự phòng (token `themeXP.color`, tên `xpDesk_*`).
- Cần app: chọn ảnh nền, cắt / thu nhỏ 240×214, gửi lên máy (phiên `/ui-design`).

**Việc cần làm trong code:**
- Kênh `Home` → màn desktop: vẽ ảnh nền (hoặc nền dự phòng), biểu tượng + nhãn có bóng, bong bóng thời tiết, thanh tác vụ không nút lõm.
  `tick()`: cập nhật % trong nhãn Claude / Codex và chữ bong bóng — chỉ vẽ lại vùng nhãn / bong bóng (vẽ lại phần nền dưới nó từ ảnh hoặc màu dự phòng).
- Ảnh nền: lưu, tải lên, xoá; kiểm tra baseline + đúng 240×214 khi tải.
- Bản xem trước màn trên máy tính vẽ theo.

## P-2026-11-26.11 — Màu theo XP, mắt Clawd đen

- **Mọi màn XP** (`source/XP-*.dc.html`, `screen_specs.md` §17, token `themeXP.color` / `themeXP.rules`; ảnh 44 màn `XP*.png`):
  - Số to — `38%` Claude, `41%` Codex, `38%` / `71%` AI hôm nay — màu đen như chữ hộp thoại XP; màu báo mức chỉ ở thanh tiến độ khối.
  - Chữ / số liệu mờ (dữ liệu cũ, đang tải, chưa có thời tiết): `#ACA899` (trước `#A0A0A0`) — màu chữ mờ của XP.
  - Link `glimmer.local`: `#0066CC` (trước `#0033CC`).
  - Mắt Clawd luôn đen (`#000000`) trên mọi nền — thân be, thanh tiêu đề, nút thanh tác vụ, thẻ agent, ô người dùng; kể cả vạch mắt ngủ,
    mắt to, mắt buồn và mắt `^ ^` + miệng khi vui.
- Cần firmware: đổi giá trị xpDim, xpLink (RGB565 trong token).

**Việc cần làm trong code:**
- Clawd: trước khi vẽ thân, tô `#000000` các ô mắt (và lỗ nửa ô khi vui) thay vì để lộ nền — áp ở mọi chỗ vẽ Clawd trong kiểu XP.
- Kênh Claude / Codex / AI: số to vẽ màu đen; thanh tiến độ giữ màu báo mức.
- Dữ liệu cũ / đang tải: dùng xpDim mới; link dùng xpLink mới. Bản xem trước màn trên máy tính vẽ theo.

## P-2026-11-26.10 — Màn khởi động: góc dưới phải là chữ Clawdsoft

- **Màn khởi động** (`source/XP-Splash.dc.html`, `screen_specs.md` §17, token `themeXP.boot.corner`; ảnh `XPSplash.png`):
  - Góc dưới phải: bỏ Clawd trắng (212, 224); thay bằng chữ `Clawdsoft` trắng nghiêng nhỏ (bitmap từ JBMono-11, nghiêng 1 px / 3
    hàng), căn mép phải x 231, đỉnh y 226 — đúng chỗ tên hãng trên màn khởi động XP.

**Việc cần làm trong code:**
- Màn khởi động: vẽ bitmap `Clawdsoft` (token) ở góc dưới phải thay Clawd. Bản xem trước màn trên máy tính vẽ theo.

## P-2026-11-26.9 — Nút start kiểu XP, màn hệ thống theo XP thật, tên Clawdsoft Window xp

- **Thanh tác vụ** (mọi màn có cửa sổ; `screen_specs.md` §17, token `themeXP.taskbar`):
  - Nút start x 0–67, mép phải bo tròn: cờ 4 ô 14×12 tại (7, 221) + chữ `start` nghiêng trắng có bóng (bitmap trong token).
  - 4 nút skill 28×20 tại x 71 + 30k; Clawd (x+5, 222), icon căn tâm (x+14, 227); huy hiệu (x+18, 215); tiến độ dài 26.
- **Màn hệ thống** (`source/XP-Splash|Connecting|SetupMode|OtaProgress.dc.html`; token `themeXP.boot`, `themeXP.welcome`), vẽ theo ảnh chụp XP:
  - Khởi động: nền đen, cờ ×3, logo `Clawdsoft` / `Window` / `xp` / `Professional` căn giữa, ô 3 khối xanh chạy; bỏ dòng phiên bản.
  - Welcome (đang kết nối Wi-Fi): chỉ chữ `welcome` nghiêng — bỏ tên mạng, lần thử.
  - Đăng nhập (cài đặt Wi-Fi): trái cờ + `Window xp` + "Để bắt đầu, kết nối Wi-Fi"; phải ô `glimmer-setup` + `192.168.4.1`; nút nguồn đỏ.
  - Cập nhật: `đang cập nhật...` nghiêng + "Đừng tắt hay rút điện máy." — bỏ thanh và %.
- Ảnh: 44 màn `XP*.png` vẽ lại.
- Đổi luật: màn kết nối Wi-Fi và cập nhật không còn hiện tên mạng / lần thử / phần trăm (xem trên trang web).
- Cần firmware: 4 màu cờ + màu màn welcome / đăng nhập (token `themeXP.color`); bitmap chữ nghiêng `start`, `welcome`, `Window`,
  `đang cập nhật...` (sinh từ JBMono, nghiêng 1 px / 3 hàng).

**Việc cần làm trong code:**
- Thanh tác vụ: nút start 68 px (cờ + `start` nghiêng), nút skill 28 px tại x 71 + 30k.
- Màn khởi động / kết nối Wi-Fi / chế độ cài đặt / cập nhật: vẽ theo §17 và token `themeXP.boot` / `themeXP.welcome`; thanh 3 khối chạy 0,2 s / bước.
- Bản xem trước màn trên máy tính vẽ theo.

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
