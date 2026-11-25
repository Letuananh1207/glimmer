# Đặc tả màn — app glimmer

Khung 390 × 844 dp. Màn dài (Màn hình, Cài đặt, Thiết bị, Skill) được vẽ cao hơn để thấy hết phần cuộn; ảnh của chúng cao hơn
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

## 2. Màn hình — `DashboardScreen` (Dashboard.png, DashboardEmpty.png, DashboardStale.png, DashboardSetup.png, DashboardLoading.png, DashboardWeather.png, DashboardWeatherNoLocation.png, DashboardClock.png, DashboardSingle.png)

> **2026-11-25.3 — Màn hình theo tab dock** (phiếu `app/docs/phieu_thiet_ke/2026-11-25-skill-theo-dock.md`): tab 1 của thanh dưới thành **Màn hình** (`navHome`), chia theo
> các tab dock đang bật giống màn thiết bị. Prop `state` thêm `weather`, `weatherNoLoc`, `clock`, `single`. Ảnh 5 trạng
> thái cũ chụp lại, 4 ảnh mới. Các mục cũ bên dưới vẫn đúng cho phần thân tab Agent, trừ đầu màn và hai nút cuối.
> - **Đầu màn gọn:** Clawd 44 (thay 72), "glimmer" 18/700, đệm 12 16 8 20, cách 12. Bên phải nút icon refresh 44 màu
>   inkDim (nhãn đọc màn hình `dashboardRefreshNow`) — thay nút "Tải số liệu ngay".
> - **Thanh tab `DockTabBar`** (khi ≥ 2 skill bật, dưới đầu màn và thanh báo): lề 4 16 6, đệm 4, nền `panel`, bo 14, lưới
>   chia đều cách 4. Tab ≥ 48 bo 10: icon pixel của dock ×1.25 (`icons/dock-*.svg`; Clawd màu `clawd`, còn lại inkDim)
>   + 7 + nhãn 13 = tên skill. Đang chọn: nền `panel2`, nhãn 700 ink, vạch 20×3 bo 2 màu nhấn skill cách đáy 3. Khác:
>   nền trong, nhãn 500 inkDim. Tab Agent có huy hiệu 18×18 bo 4 nền amber, số 11/700 màu bg = số agent chờ (approval +
>   input, như `countWaiting`); 0 → ẩn, > 9 → "9+". Thứ tự = dock: Agent, (Tin nhắn), Thời tiết, Đồng hồ — chỉ skill
>   đang bật. Một skill bật → không có thanh (`single`). Từ 4 tab trở lên: nhãn xuống dưới icon (chưa vẽ).
> - **Tab Agent:** thân như cũ. Hai nút cuối thay bằng một `ShowOnDeviceButton` (`homeShowOnDevice`, skill = "Agent").
> - **Tab Thời tiết** (`weather`): thẻ đệm 16 — nhãn `weatherTitle` + meta `weatherMeta` ("Hà Nội · 10m trước"); hàng
>   cách 16 lề trên 14: mặt trời pixel ×3.5 màu `skillWeather`, nhiệt "29°" 56/700 ink, cột cách 4: mô tả 16 ink,
>   `weatherHiLo` 12 inkDim, `weatherFeels` 12 muted. Kẻ 1 `line` (lề 16 0 4). 3 dòng dự báo ≥ 44 kẻ giữa: thứ 12 muted
>   rộng 36 (`weatherDayTomorrow` MAI, `weatherDayAfter` KIA, rồi T7…), mô tả 14 inkDim, "30° / 25°" 14 (thấp muted).
>   Không icon ở dòng dự báo. Nút "Hiện Thời tiết trên thiết bị".
> - **`weatherNoLoc`** (thiết bị chưa có `weatherLat/Lon`): meta amber `weatherNoLocationMeta`; giữa thẻ (đệm 24 8 8)
>   mặt trời muted ×3.5, `weatherNoLocationTitle` 16/700, `weatherNoLocationBody` 13 inkDim; nút viền `weatherSetLocation`
>   (icon tune) → tab Cài đặt. Không có nút hiện trên thiết bị.
> - **Tab Đồng hồ** (`clock`): nhãn `clockTitle`; giờ 72/700 căn giữa, lề trên 18: giờ ink, ":" `coral`, phút amber
>   (như kênh Clock); `clockDate` 14 inkDim (lề 10 0 14); 3 dòng ≥ 44 kẻ giữa, nhãn 14 inkDim / giá trị 14 ink phải:
>   `clockTz` (UTC+7), `clockFormat` (`clockFormat24` / `clockFormat12`), `clockNight` (`clockNightValue`). Nút "Hiện Đồng hồ
>   trên thiết bị". Giờ lấy từ `time` của `/api/state` + `tzMinutes`; kiểu giờ, ban đêm từ `/api/settings`.
> - **`ShowOnDeviceButton`:** đệm 8 16 24, rộng hết, cao ≥ 48, bo 14, nền `panel2`, icon tv 18 inkDim + 10 + chữ 14/500 ink.
>   Gửi `POST /api/channel` kênh chính của tab (Agent → Claude, Thời tiết → Weather, Đồng hồ → Clock).
> - **Thanh dưới:** tab 1 `navHome`, icon `icons/nav-home.svg`; huy hiệu 16×16 bo 4 amber, số 10/700 bg, góc trên phải icon
>   (top −2, left 38 trong viên 64). Hiện ở mọi tab của khung.

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

> **2026-11-25.3:** thanh dưới tab 1 đổi thành "Màn hình" (`navHome`, có huy hiệu agent chờ); ảnh chụp lại.

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

> **2026-11-25.3:** thanh dưới tab 1 đổi thành "Màn hình" (`navHome`, có huy hiệu agent chờ); ảnh chụp lại.

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

## 6. Skill — `SkillsScreen` (Skills.png, SkillsSwitching.png, SkillsError.png, SkillsLegacy.png, SkillsLastOne.png)

> **2026-11-25.3 — Bật / tắt skill theo dock** (phiếu `app/docs/phieu_thiet_ke/2026-11-25-skill-theo-dock.md`): thay lưới chọn một skill bằng **danh sách có công tắc**; mọi mục
> của bản .2 bên dưới (lưới, `SkillTile`, thẻ kênh, thanh báo đang đổi) **bỏ**, trừ đầu màn. Prop `state`: `normal`,
> `switching`, `error`, `lastOne` (mới), `legacy`. Ảnh 4 trạng thái cũ chụp lại + `SkillsLastOne.png`. Cả màn vừa 844.
> - Đầu màn như cũ, `skillsSubtitle` mới (một dòng).
> - Thẻ danh sách: lề 6 16, nền `panel`, bo 14, đệm 4 16. Mỗi dòng `SkillRow` ≥ 72, đệm 10 0, kẻ 1 `line` giữa các dòng:
>   ô icon 44 bo 12 + 14 + cột (tên 16/700, cách 2, mô tả 12 muted một dòng `skill…Desc`) + công tắc `SkillSwitch`.
>   Bật: nền ô `skill…Tint`, icon pixel dock màu nhấn (Clawd ×1.75, khác ×1.5), tên ink. Tắt: nền ô `panel2`, icon muted,
>   tên inkDim. Thứ tự dòng = thứ tự tab trên dock: Agent, Thời tiết, Đồng hồ. Chạm công tắc → gửi thiết bị ngay.
> - `SkillSwitch`: vùng chạm 60×48 (lề phải −4); rãnh 52×32 bo 16. Bật: nền + viền 2 màu nhấn skill, núm 24 màu bg ở
>   phải. Tắt: nền `panel2`, viền 2 muted, núm 16 muted ở trái. Khoá: mờ 38 %.
> - `switching`: dòng đang gửi thay công tắc bằng vòng xoay 24 (`clawd`), mô tả → `skillsSending` inkDim; công tắc khác
>   khoá. **Không** thanh báo. App giữ trạng thái thiết bị tới khi thiết bị nhận (R-SK-5).
> - `error`: thanh báo (như bản .2) `skillsErrorOffTitle` / `skillsErrorOnTitle` coral + `skillsErrorOffBody` /
>   `skillsErrorOnBody` + `commonRetry`; công tắc về trạng thái thiết bị đang có.
> - `lastOne`: chỉ một skill bật → công tắc của nó khoá; mô tả thay bằng `skillsLastOne` amber. Không có hộp thoại.
> - `legacy` (R-SK-4): thanh báo amber `skillsLegacyTitle` / `skillsLegacyBody` + nút viền `deviceUpdateFw` → tab Thiết bị.
>   Agent: ổ khoá 20 muted thay công tắc. Thời tiết, Đồng hồ: bật (màu nhấn), không công tắc, mô tả `skillsAlwaysOn`.
>   Không có dòng chú thích.
> - Dưới thẻ (trừ legacy): lề 6 20 0, ô vuông 8 amber + 8 + `skillsOrderNote` 12/16 muted.
> - `skillsSoonTitle` (12 muted, đệm 14 20 4) + chip xuống dòng cách 8, đệm 4 16 0: cao 36, bo 18, viền 1 `line`, đệm
>   0 12 0 10, icon 16 muted + 8 + tên 13 muted. Tin nhắn (`icons/dock-chat.svg`), Nhạc, Mạng xã hội, Giải trí. Không bấm được.

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
