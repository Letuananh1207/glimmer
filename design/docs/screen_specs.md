# Đặc tả màn — app glimmer

Khung 390 × 844 dp. Màn dài (Tổng quan, Cài đặt, Thiết bị) được vẽ cao hơn để thấy hết phần cuộn; ảnh của chúng cao hơn
2532 px. Màu / cỡ chữ: `tokens/design_tokens.json`. Chuỗi: `l10n/app_vi.arb`. Widget dùng chung: `components.md`.
Mỗi màn có một prop `state` trong `source/<Màn>.dc.html` để chọn trạng thái.

## 1. Kết nối — `ConnectScreen` (ConnectSearching.png, ConnectNotFound.png, ConnectManual.png)

> **2026-11-25.1 — Bản đầu:** vẽ lại đúng app hiện có.

- Đệm 24 bốn phía. Từ trên xuống: khoảng trống co giãn → Clawd 144 (giữa) → 28 → tiêu đề `screenTitle`
  (`connectSearchingTitle` / `connectIdleTitle`) → 8 → thân `body` căn giữa → khoảng trống co giãn → 3 nút xếp dọc, cách 10:
  nút chính `connectRetry` (icon search), nút viền `connectManual` (icon edit), nút viền `connectNewDevice` (icon wifi, nhãn
  xuống 2 dòng, nút cao theo nhãn).
- `searching`: Clawd mắt mở, đang bước; thân `connectSearchingBody`; cả 3 nút tắt (nền ink 12%, chữ ink 38%).
- `notFound`: Clawd ngủ; thân là lỗi (`connectNotFound`, `connectNoDeviceAt`) hoặc `connectIdleBody` khi không có lỗi.
- `manual`: hộp thoại `connectManualTitle` trên lớp phủ `scrim`, nền `panel`, bo 28, đệm 24, lề ngang 40: gợi ý
  `connectManualHint` (label) → ô `connectManualIp` (đã điền IP lần trước) → ô `connectManualToken` (ẩn chữ) → nút chữ
  `commonCancel` + nút chính `connectManualOk` căn phải.

## 2. Tổng quan — `DashboardScreen` (Dashboard.png, DashboardEmpty.png, DashboardStale.png, DashboardSetup.png, DashboardLoading.png)

> **2026-11-25.2 — Thanh điều hướng theo skill:** thanh dưới thành 4 tab (Agent · Skill · Cài đặt · Thiết bị), xem `components.md` "Thanh điều hướng dưới"; ảnh của mọi trạng thái màn này chụp lại. Đây là màn chính (tab 1) của skill Agent; nội dung không đổi.

> **2026-11-25.1 — Bản đầu:** vẽ lại đúng app hiện có.

- Đầu màn (đệm 16 20 8 20): Clawd 72 (biểu cảm theo bảng project: approval → mở to, error → buồn, working/input → mở,
  chỉ xong → vui, trống → ngủ; bước khi có project đang chạy) + 16 + cột: "glimmer" `screenTitle`, chấm 9 (mint trực tuyến /
  amber khi ở glimmer-setup) + "SSID · IP" hoặc `dashboardSetupMode` (label).
- Dòng lỗi (nếu có) amber 12, đệm 4 16.
- `setup`: thẻ `panel2`, đệm 14, chữ amber 14: `dashboardSetupNote`.
- Thẻ mức dùng (đệm 16): nhãn `dashboardUsageTitle` + meta bên phải (muted "2m trước"; amber `dashboardUsageNoKey` /
  `dashboardUsageBlocked` / `dashboardUsageStale`; coral `dashboardUsageKeyBad`). Dòng tuần: số 40/700 + "%" 20 + 10 +
  `dashboardWeek` 14 + `dashboardResetIn` bên phải; thanh 8 bo 3 nền `panel2`. 14. Dòng phiên: số 24 + "%" 14, thanh 5.
  Màu số và thanh theo % còn lại: ≤ 20 coral, ≤ 50 amber, còn lại mint; số liệu cũ → muted; chưa có → "--".
- Thẻ project (đệm 12 8 8 16): nhãn `dashboardProjects` + nút chữ `dashboardProjectsClear` (12). Mỗi dòng ≥ 56: ô vuông 10
  màu trạng thái, tên 16 ink, dòng phụ 12 màu trạng thái "Trạng thái · chi tiết · agent (khi không phải claude)", tuổi bên
  phải (label). Sắp: approval, input, error, working, done. Trống → `dashboardProjectsEmpty`.
- Thẻ "thẻ trên màn hình" (chỉ khi có thẻ): nhãn `dashboardCards` + `dashboardCardsClearAll`; mỗi dòng ≥ 64: tiêu đề 16 màu
  loại thẻ, phụ label tối đa 2 dòng "Loại · project · nội dung · tuổi trước", nút X 48.
- Hai nút tonal xuống dòng khi chật (đệm 8 16 24, cách 10): `dashboardRefreshNow` (refresh), `dashboardShowClaude` (tv).
  Hiện nền mint chữ đen (mặc định Flutter).
- `loading`: chỉ vòng xoay 40 giữa màn.
- Thanh điều hướng dưới, tab 1 (Agent).

## 3. Cài đặt — `SettingsScreen` (Settings.png, SettingsChanged.png, SettingsError.png)

> **2026-11-25.2 — Thanh điều hướng theo skill:** thanh dưới thành 4 tab (Agent · Skill · Cài đặt · Thiết bị), xem `components.md` "Thanh điều hướng dưới"; ảnh của mọi trạng thái màn này chụp lại. Tab 3, dùng chung mọi skill; mục SỐ LIỆU CLAUDE và AGENT thuộc skill Agent (chưa tách), nội dung không đổi.

> **2026-11-25.1 — Bản đầu:** vẽ lại đúng app hiện có.

- Danh sách trên nền `bg` (không thẻ). Tiêu đề nhóm: 12, giãn 0.5, màu `clawd`, đệm 20 20 6.
- MÀN HÌNH: thanh trượt `settingsBrightness` ("Độ sáng: 80%", 5–100, bước 5); công tắc `settingsIdleDim` (+phụ),
  `settingsWeeklyHero` (+phụ), `settingsClock24h`.
- BAN ĐÊM: chọn `settingsNightMode` (Không / Giảm sáng / Đồng hồ / Tắt màn). Khác "Không" thì thêm `settingsNightFrom`,
  `settingsNightTo` (giờ HH:MM bên phải, 11/500, bấm mở chọn giờ), và với Giảm sáng: thanh trượt `settingsNightBright`.
- SỐ LIỆU CLAUDE: `settingsClaudeKey` (phụ đã đặt / chưa đặt / sẽ đổi khi lưu, icon edit → hộp thoại ẩn chữ),
  chọn `settingsRefresh` (1, 2, 3, 5, 10, 15 phút), `settingsUserName` (≤ 16 ký tự).
- AGENT: công tắc `settingsShowAgents` (+phụ), `settingsPinApprovals`, `settingsDoneCards`; chọn `settingsApprovalTtl`
  (5, 15, 30 phút, 1 giờ, Không bao giờ); `settingsApiToken`; `settingsAppToken` (icon key).
- Dòng 1 dòng cao 56, 2 dòng 72; đệm 16 trái 24 phải. Công tắc 52×32.
- `changed`: thanh nổi cách đáy 16 (trên thanh điều hướng), lề 16: nút viền `settingsDiscard` + nút chính `settingsSaveCount`,
  chia đôi, cách 12. Chỉ gửi những mục đã đổi.
- `error`: lỗi (body) + nút chữ `commonRetry` giữa màn.
- Thanh điều hướng dưới, tab 3 (Cài đặt).

## 4. Thiết bị — `DeviceScreen` (Device.png, DeviceBusy.png)

> **2026-11-25.2 — Thanh điều hướng theo skill:** thanh dưới thành 4 tab (Agent · Skill · Cài đặt · Thiết bị), xem `components.md` "Thanh điều hướng dưới"; ảnh của mọi trạng thái màn này chụp lại. Tab 4, dùng chung mọi skill; nội dung không đổi.

> **2026-11-25.1 — Bản đầu:** vẽ lại đúng app hiện có.

- `busy`: thẻ `panel2` trên cùng: bước đang làm (`heading`), thanh tiến độ 4 (màu `clawd`, nền hiện là mint — mặc định
  Flutter), `deviceBusyNote`. Mọi dòng bên dưới mờ 38% và không bấm được.
- Thẻ THIẾT BỊ: cặp khóa (cột 120, label) – giá trị (13 ink): Firmware, Bản build, Wi-Fi "SSID (RSSI dBm)", IP, Đã chạy,
  Bộ nhớ trống.
- Thẻ thao tác: `deviceChangeWifi` (+phụ, icon wifi → Cài Wi-Fi), `deviceReboot` (icon restart, hộp thoại xác nhận),
  `deviceForget` (icon link_off → Kết nối).
- Thẻ CẬP NHẬT: dòng trạng thái 13 (mint khi có bản mới hơn, inkDim khi không) "Bản mới nhất: ngày · commit" + dòng thứ hai;
  `deviceUpdateFw` (+phụ, icon system_update), `deviceUpdateFull` (+phụ, icon layers). Mỗi dòng mở hộp thoại xác nhận.
- Thẻ sao lưu: `deviceBackup` (+phụ, icon save_alt), `deviceRestore` (icon restore).
- Thanh điều hướng dưới, tab 4 (Thiết bị).

## 5. Cài Wi-Fi — `WifiSetupScreen` (WifiSetup.png, WifiSetupWorking.png, WifiSetupDone.png, WifiSetupFailed.png)

> **2026-11-25.1 — Bản đầu:** vẽ lại đúng app hiện có.

- Thanh trên 64: nút quay lại + `wifiTitle` (`appBarTitle`). Không có thanh điều hướng dưới. Đệm thân 20.
- Clawd 120 giữa: form → mở, working → mở + bước, done → vui, failed → buồn. 20.
- `form`: `wifiNote` (label) → 16 → ô `wifiSsid` (điền sẵn mạng điện thoại đang dùng) → 12 → ô `wifiPass` (ẩn chữ, nút mắt) →
  20 → nút chính `wifiSend` (icon send).
- Các trạng thái khác: dòng trạng thái `heading` căn giữa (ink / mint / coral) → 10 → chi tiết `body` → 24 → vòng xoay
  (working) hoặc nút `commonRetry` (failed) / `wifiDoneButton` (done). Đang làm thì không quay lại được.

## 6. Skill — `SkillsScreen` (Skills.png, SkillsSwitching.png, SkillsError.png, SkillsLegacy.png)

> **2026-11-25.2 — Màn mới: chọn skill** (phiếu `app/docs/phieu_thiet_ke/2026-11-25-chon-skill.md`): tab 2 của thanh dưới.

- Đầu màn (đệm 16 20 8, cách 4): `skillsTitle` (`screenTitle`), `skillsSubtitle` (label).
- Thanh báo (chỉ khi có), thẻ `panel2`, đệm 14 16, lề 6 16:
  - `switching`: vòng xoay 24 + `skillsSwitchingBanner` (14 ink) / `skillsSwitchingHint` (label).
  - `error`: `skillsErrorTitle` (14/700 coral), `skillsErrorBody` (13 inkDim), nút chữ `commonRetry` căn phải — gửi lại skill vừa chọn.
  - `legacy` (R-SK-4): `skillsLegacyTitle` (14/700 amber), `skillsLegacyBody` (13 inkDim, `fw` = firmware thiết bị), nút viền
    `deviceUpdateFw` (icon system_update) → tab Thiết bị.
- Lưới 2 cột, cách 12, đệm 8 16. Thứ tự: Agent, Nhạc, Mạng xã hội, Giải trí (`skills.catalog` trong `navigation.json`).
- Ô skill (`SkillTile`, `components.md`): cao ≥ 176, đệm 14, bo 14, nền `panel`, viền 2. Từ trên: ô icon 48 bo 12 (nền
  `skill…Tint`; Agent = Clawd 40 mắt mở, khác = icon 28 màu nhấn) → tên 16/700 → mô tả 12 muted (giãn) → nhãn trạng thái:
  - đang dùng: viền màu nhấn liền; chấm 8 màu nhấn + `skillsCurrent` 12 ink. Chạm → màn chính của skill (tab 1).
  - chọn được: viền trong suốt; `skillsUse` 12/500 màu nhấn. Chạm → đổi skill ngay (không hỏi lại).
  - đang đổi: viền màu nhấn nét đứt; vòng xoay 16 + `skillsSwitching`. Ô "đang dùng" giữ nguyên tới khi thiết bị nhận
    (R-SK-2, R-SK-5: app theo `skill` thiết bị báo).
  - sắp có (chưa có gói): ô icon nền `panel2`, icon muted, tên inkDim, `skillsSoon` muted; không bấm được. Hiện, không ẩn.
  - Trong lúc đổi, các ô khác không bấm được.
- Thẻ kênh (nền `panel`, đệm 16): `skillsChannelsTitle` → kênh của skill đang dùng (`skillAgentChannels`, 13 ink) →
  `skillsChannelsSystem` (12 muted) → đường kẻ 1 `line` (cách 12) → ô vuông 8 amber + `skillsAttentionNote` (12 inkDim).
  Danh sách kênh là chữ tĩnh theo skill (thiết bị không trả về).
- Trạng thái `switching` / `error` trên canvas minh họa bằng Nhạc như đã có gói; hiện chỉ Agent có gói nên thực tế
  chưa có ô "chọn được".
- Thanh điều hướng dưới, tab 2 (Skill).
