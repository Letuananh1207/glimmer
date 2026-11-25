# Nhật ký thay đổi thiết kế — app glimmer

Mỗi mục có mã `YYYY-MM-DD.N` (N tăng liên tục). Mục mới nhất ở trên cùng. "Việc cần làm trong code" chỉ ghi tên màn /
widget và việc cần làm — không ghi đường dẫn file hay cách code. Phía code ghi mục đã áp ở `app/.design_sync.json`.

---

## 2026-11-25.4 — Skill Ảnh: gửi ảnh từ điện thoại lên thiết bị

- **Màn hình · `DashboardScreen`** (`source/Dashboard.dc.html`, `screen_specs.md` §2; ảnh mới `DashboardPhoto.png`,
  `DashboardPhotoEmpty.png`, `DashboardPhotoFull.png`, `DashboardPhotoAdd.png`, `DashboardPhotoDelete.png`,
  `DashboardPhotoDeleting.png`, `DashboardPhotoDeleteError.png`):
  - Tab **Ảnh** thứ 2 của `DockTabBar` (khi skill Ảnh bật). Bốn tab → nhãn xuống dưới icon, ô 56; 2–3 tab như cũ.
  - Thẻ "ẢNH TRÊN THIẾT BỊ" + "5/8 · còn 3 chỗ", `PhotoGrid` 3 cột: hình thu nhỏ, ô "không có bản xem" cho ảnh không do
    app gửi, ô `AddPhotoTile` cuối (đủ 8 → khoá + dòng giải thích). Bấm ảnh → `DeletePhotoDialog`; đang xoá phủ vòng xoay
    trên ô; xoá lỗi → thanh báo + Thử lại. Chưa có ảnh → giữa thẻ + nút mint "+ Thêm ảnh".
  - "+ Thêm ảnh" → `PhotoSourceSheet` (thư viện / chụp ảnh) → màn Cắt ảnh. Chú thích: cập nhật đầy đủ xoá hết ảnh.
  - Nút cuối `ShowOnDeviceButton` "Hiện Ảnh trên thiết bị" (kênh `Photo`).
- **Cắt ảnh · `PhotoCropScreen`** — màn mới (`source/PhotoCrop.dc.html`, §7; ảnh `PhotoCrop.png`,
  `PhotoCropSending.png`, `PhotoCropDone.png`, `PhotoCropFull.png`, `PhotoCropTooBig.png`, `PhotoCropNoSpace.png`,
  `PhotoCropRejected.png`, `PhotoCropOffline.png`):
  - `CropFrame` vuông 260 kéo / phóng; `DevicePhotoPreview` 180 vẽ lại đúng màn Ảnh của thiết bị (ảnh 188 tại 40, 28 có dock).
  - Gửi: tiến độ %, xong (thêm ảnh khác / xong), lỗi `full`, `too_big` (sau khi app đã tự giảm chất lượng), `no_space`,
    từ chối (`not_jpeg` / `progressive` / `bad_size` / `truncated` / `empty` — báo chung), mất kết nối.
- **Skill · `SkillsScreen`** (`source/Skills.dc.html`, §6; ảnh `Skills.png`, `SkillsSwitching.png`, `SkillsError.png`,
  `SkillsLastOne.png` chụp lại, mới `SkillsPhotoHint.png`, `SkillsPhotoFirmware.png`):
  - Dòng **Ảnh** thứ 2 (thứ tự dock), mặc định tắt. Tắt mà thiết bị có ảnh → mô tả mint "N ảnh đã có trên thiết bị. Bật
    để xoay." Firmware chưa có ảnh → "Cần firmware mới" + nút "Cập nhật" sang Thiết bị.
- **Token:** `skillPhoto` (#8FE574 = mint), `skillPhotoTint`; size `dockTabStacked` 56, `cropStage`, `cropFrame`,
  `devicePreview`, `devicePreviewPhoto`; radius `photoTile` 10, `sheet` 20. **Icon:** `icons/dock-photo.svg`.
  **Chuỗi:** 53 khoá mới (`skillPhoto…`, `skills…`, `photo…`, `photoCrop…`).
- Phiếu: `app/docs/phieu_thiet_ke/2026-11-25-gui-anh-len-thiet-bi.md`
- Đổi luật: không — theo R-SK-1 (Ảnh mặc định tắt), R-SK-2, R-SK-3. Đề xuất ghi thêm: tab Ảnh chỉ có khi skill Ảnh bật;
  quản lý ảnh khi skill tắt = bật skill trước (màn Skill gợi ý).
- Cần firmware: không bắt buộc. Hình thu nhỏ lấy từ **bản sao app giữ** khi gửi; ảnh gửi từ nơi khác hiện ô "không có
  bản xem". Nếu muốn hình thật cho mọi ảnh → firmware thêm `GET /api/photos/<name>`; muốn đánh dấu ảnh đang chiếu →
  `/api/state` trả ảnh hiện tại (chưa vẽ).

**Việc cần làm trong code:**
- `DockTabBar`: thêm tab Ảnh (thứ 2, icon `dock-photo`, vạch mint); ≥ 4 tab dùng bố cục icon trên nhãn dưới, ô 56.
- `DashboardScreen` tab Ảnh: tải `GET /api/photos`, hiện `PhotoGrid` (bản sao app làm hình thu nhỏ, ghép theo tên
  file; không có → ô không có bản xem), meta số ảnh / chỗ trống (`max_count`), các trạng thái chưa có / đủ 8 / xoá.
  Xoá: `DeletePhotoDialog` → `DELETE /api/photos?name=` → đang xoá trên ô → lỗi thì thanh báo + Thử lại.
- `PhotoSourceSheet` → trình chọn ảnh / máy ảnh hệ thống → `PhotoCropScreen`.
- `PhotoCropScreen` (mới, ngoài khung tab): cắt vuông kéo / phóng, xem trước kiểu màn thiết bị cập nhật theo; gửi
  JPEG baseline 188 × 188 ≤ 40 KB (giảm chất lượng dần), tiến độ, xong, 5 lỗi như đặc tả; gửi xong giữ bản sao ảnh.
- `SkillsScreen`: dòng Ảnh (mặc định tắt), gợi ý bật khi `photos` > 0, kiểu "cần firmware" khi `/api/state` không có `photos`.
- Chuỗi, token, icon mới theo trên.

## 2026-11-25.3 — Skill bật / tắt theo dock, Màn hình chia tab như thiết bị

- **Skill · `SkillsScreen`** (`source/Skills.dc.html`, `screen_specs.md` §6; ảnh `Skills.png`, `SkillsSwitching.png`,
  `SkillsError.png`, `SkillsLegacy.png`, mới `SkillsLastOne.png`):
  - Lưới chọn một skill → **danh sách công tắc** `SkillRow` + `SkillSwitch`: Agent, Thời tiết, Đồng hồ; mỗi skill bật là
    một tab dock thiết bị, thứ tự dòng = thứ tự dock. Icon pixel lấy đúng dock thiết bị, công tắc tô màu nhấn từng skill.
  - Đang gửi: vòng xoay ngay trên dòng (`skillsSending`), không thanh báo. Lỗi: thanh báo + `commonRetry`, công tắc về như
    thiết bị. Còn một skill: công tắc khoá, mô tả `skillsLastOne`. Firmware cũ: Agent ổ khoá, Thời tiết / Đồng hồ "Luôn có".
  - Bỏ thẻ "Màn thiết bị đang xoay"; thay bằng một dòng chú thích. "Sắp có" thành chip (Tin nhắn, Nhạc, Mạng xã hội, Giải trí).
  - Hiện app: lưới 2 cột `SkillTile` chọn một skill.
- **Màn hình · `DashboardScreen`** (`source/Dashboard.dc.html`, §2; ảnh 5 trạng thái cũ chụp lại, mới `DashboardWeather.png`,
  `DashboardWeatherNoLocation.png`, `DashboardClock.png`, `DashboardSingle.png`):
  - Thanh tab `DockTabBar` dưới đầu màn: Agent · Thời tiết · Đồng hồ (skill đang bật); tab Agent có huy hiệu amber số
    agent chờ. Một skill bật → không có thanh.
  - Tab Thời tiết (hôm nay + 3 ngày; chưa có vị trí → nút sang Cài đặt), tab Đồng hồ (giờ, múi giờ, kiểu giờ, ban đêm).
  - Đầu màn gọn: Clawd 44, nút icon refresh thay "Tải số liệu ngay". Hai nút xanh đặc cuối → một `ShowOnDeviceButton`
    nền `panel2` "Hiện {skill} trên thiết bị".
- **Khung · thanh dưới** (`components.md`; ảnh Cài đặt, Thiết bị mọi trạng thái chụp lại): tab 1 thành "Màn hình"
  (`navHome`, `icons/nav-home.svg`) với huy hiệu amber số agent chờ.
- **Token:** `skillWeather`, `skillClock` + `…Tint`; size `dockTab`, `skillRow`, `skillIcon`, `switchW/H`, `chip`, `headerClawd`;
  radius `dockBar`, `dockTab`, `chip`, `badge`. **Icon:** `icons/dock-*.svg`, `nav-home.svg`. **Chuỗi:** 40 khoá mới / đổi;
  16 khoá cũ đánh dấu "Không dùng từ 2026-11-25.3".
- Phiếu: `app/docs/phieu_thiet_ke/2026-11-25-skill-theo-dock.md`
- Đổi luật:
  - R-SK-1 → "Nhiều skill bật cùng lúc, **ít nhất một**; mặc định Agent + Thời tiết + Đồng hồ (giữ đúng thứ đang xoay trên
    thiết bị khi nâng cấp)". Phiếu đề xuất "mặc định chỉ Agent"; thiết kế đổi vì Thời tiết / Đồng hồ giờ là skill.
  - R-SK-2 → "Bật / tắt trên app → gửi thiết bị danh sách skill bật; thiết bị xoay mọi tab dock đang bật + Thông tin, Ban đêm".
  - Thời tiết, Đồng hồ **thành skill tắt được** (không còn là kênh hệ thống luôn có). R-SK-3/4/5 giữ.
- Cần firmware:
  - Setting dạng danh sách skill bật (ví dụ `skills_on`), `/api/state` báo lại; dock thiết bị chỉ hiện tab của skill bật.
    Tắt Thời tiết = tắt Weather + Forecast, tắt Đồng hồ = tắt Clock (Night vẫn là hệ thống).
  - `/api/state` thêm thời tiết hiện tại + 3 ngày (nhiệt, mô tả, cao / thấp, cảm giác, tuổi số liệu; tên nơi nếu có) — hiện
    app không có dữ liệu này. Giờ / ban đêm đã có (`time`, `/api/settings`).
- Cài đặt chưa có ô vị trí thời tiết (`weatherLat/Lon` đã có trong `/api/settings`) — cần một mục vẽ sau; tạm thời nút
  `weatherSetLocation` mở tab Cài đặt.

**Việc cần làm trong code:**
- Sổ quy tắc: chốt R-SK-1, R-SK-2 mới (và Thời tiết / Đồng hồ thành skill) trước khi làm; test theo luật mới.
- `SkillsScreen`: thay lưới bằng thẻ danh sách `SkillRow` có `SkillSwitch`; trạng thái đang gửi / lỗi / còn một / firmware cũ
  như §6; chip "Sắp có"; dòng chú thích. Bỏ thẻ kênh và thanh báo đang đổi.
- `SkillRepository` / use case: từ một skill thành danh sách bật (ít nhất một), gửi thiết bị, theo thiết bị khi khác (R-SK-5).
- `DashboardScreen` → Màn hình: đầu màn gọn + nút refresh icon; `DockTabBar` (ẩn khi một skill); tab Agent = thân cũ +
  `ShowOnDeviceButton`; tab Thời tiết, tab Đồng hồ như §2; huy hiệu agent chờ trên tab Agent.
- Thanh điều hướng dưới: tab 1 "Màn hình" + icon mới + huy hiệu agent chờ, ở mọi màn có thanh.
- Firmware: setting danh sách skill + dock theo đó; thời tiết trong `/api/state` (bốn file, `CLAUDE.md` gốc mục Settings round-trip).

## 2026-11-25.2 — Chọn skill: màn Skill và thanh điều hướng 4 tab

- **Skill · `SkillsScreen`** (màn mới; `source/Skills.dc.html`, `screen_specs.md` §6; ảnh `Skills.png`, `SkillsSwitching.png`,
  `SkillsError.png`, `SkillsLegacy.png`):
  - Lưới 2 cột ô skill (`SkillTile`): Agent (đang dùng, viền `skillAgent`), Nhạc / Mạng xã hội / Giải trí "Sắp có" — hiện mờ,
    không bấm được. Chạm ô chọn được → đổi skill ngay; chạm ô đang dùng → mở màn chính của skill.
  - Đang đổi: thanh báo + ô đích viền nét đứt có vòng xoay; ô đang dùng giữ tới khi thiết bị nhận.
  - Đổi lỗi: thanh báo coral `skillsErrorTitle` / `skillsErrorBody` + `commonRetry`; skill vẫn như cũ.
  - Firmware cũ: thanh báo amber `skillsLegacyTitle` / `skillsLegacyBody` + nút viền `deviceUpdateFw` → tab Thiết bị; chỉ Agent.
  - Thẻ kênh thiết bị của skill đang dùng + kênh hệ thống + dòng nhắc thẻ duyệt (R-SK-3).
  - Trạng thái đang đổi / lỗi trên canvas minh họa bằng Nhạc như đã có gói.
- **Khung điều hướng · thanh dưới** (`components.md` "Thanh điều hướng dưới"; `screen_specs.md` §2–4; ảnh mọi trạng thái
  Tổng quan, Cài đặt, Thiết bị chụp lại):
  - 4 tab: tab 1 = màn chính của skill đang dùng (nhãn = tên skill, icon = icon skill; Agent → Tổng quan, icon Clawd),
    tab 2 Skill, tab 3 Cài đặt, tab 4 Thiết bị. Cài đặt / Thiết bị dùng chung; Kết nối, Cài Wi-Fi ngoài khung tab.
  - Tab đang chọn: icon ink (bỏ icon đen của bản đầu), nhãn 12/700; tab khác nhãn inkDim.
  - Hiện app: 3 tab Tổng quan · Cài đặt · Thiết bị.
- **Token**: màu nhấn `skillAgent/Music/Social/Fun` + nền `…Tint`. **Chuỗi**: `navSkills`, `skill…Name/Desc`, `skills…`
  (26 khoá mới). `navDashboard` không còn trên thanh dưới.
- Phiếu: `app/docs/phieu_thiet_ke/2026-11-25-chon-skill.md`
- Id `music` / `social` / `fun` là id đặt tạm cho ô "sắp có"; firmware và app hiện chỉ có `agent` — không cần đổi firmware.

**Việc cần làm trong code:**
- `SkillsScreen` (mới): lưới ô skill từ danh mục app; trạng thái theo R-SK-1…5 — đang dùng theo thiết bị, đổi gửi thiết bị,
  đang đổi / lỗi (thử lại), firmware cũ → thanh báo + nút sang Thiết bị, không đổi được. Ô "sắp có" hiện nhưng không bấm.
- Thanh điều hướng dưới: 4 tab như trên; tab 1 lấy tên + icon + màn chính từ skill đang dùng; icon tab đang chọn màu ink.
- `SkillTile`, thanh báo trạng thái: widget dùng chung theo `components.md`.

## 2026-11-25.1 — Bản đầu: vẽ lại app hiện có

- **Cả 5 màn** (`source/*.dc.html`, `screen_specs.md` §1–5; ảnh `screens/@3x/*.png`): vẽ lại đúng giao diện app đang có
  để làm nền chung, chưa đổi gì:
  - Kết nối `ConnectScreen` — đang tìm, không thấy thiết bị, hộp thoại nhập IP.
  - Tổng quan `DashboardScreen` — có dữ liệu, chưa có khóa / trống, số liệu cũ, thiết bị ở glimmer-setup, đang tải.
  - Cài đặt `SettingsScreen` — bình thường, có thay đổi chưa lưu, lỗi tải.
  - Thiết bị `DeviceScreen` — bình thường, đang nạp firmware.
  - Cài Wi-Fi `WifiSetupScreen` — nhập mạng, đang gửi, xong, lỗi.
- **Token** (`tokens/design_tokens.json`): bảng màu `G` (trùng `src/core/theme.h`), cỡ chữ, khoảng cách, bo góc đang dùng.
- **Chuỗi** (`l10n/app_vi.arb`): mọi chuỗi đang hiện trong app, đặt khóa theo tiền tố màn.
- Ghi nhận (từ màu mặc định Flutter, chưa xem trên máy thật; chưa sửa trong bản này): icon tab đang chọn ở thanh điều
  hướng có thể màu đen trên `panel2`; hai nút ở Tổng quan nền mint chữ đen; viền nút viền và ô nhập màu trắng; thanh tiến độ
  nạp firmware nền mint.

**Việc cần làm trong code:**
- Không đổi giao diện. Ghi `2026-11-25.1` là đã áp trong bản ghi đồng bộ thiết kế.
- Nếu muốn dùng ngay: sinh `AppColors` từ `color` của token và chuyển chuỗi cứng sang `app_vi.arb` (cùng khóa); màn phải
  trông y như ảnh.
