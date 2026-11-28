# Đặc tả màn — app glimmer

Khung 390 × 844 dp. Màn dài (Màn hình, Cài đặt, Thiết bị, Skill) được vẽ cao hơn để thấy hết phần cuộn; ảnh của chúng cao hơn
2532 px. Màu / cỡ chữ: `tokens/design_tokens.json`. Chuỗi: `l10n/app_vi.arb`. Widget dùng chung: `components.md`.
Mỗi màn có một prop `state` trong `source/<Màn>.dc.html` để chọn trạng thái.

## 1. Kết nối — `ConnectScreen` (ConnectSearching.png, ConnectNotFound.png, ConnectManual.png)

> **2026-11-28.12 — Lối vào quét mã** (phiếu `app/docs/phieu_thiet_ke/2026-11-28-quet-qr-cai-wifi.md`): nút viền thứ ba đổi thành `connectNewDevice` ("Quét mã QR trên màn thiết bị"), icon qr_code_scanner thay wifi, mở màn **Quét mã** (§10) thay Cài Wi-Fi. Ảnh `ConnectSearching.png`, `ConnectNotFound.png`, `ConnectManual.png` chụp lại.

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

## 2. Màn hình — `DashboardScreen` (Dashboard.png, DashboardEmpty.png, DashboardStale.png, DashboardSetup.png, DashboardLoading.png, DashboardWeather.png, DashboardWeatherNoLocation.png, DashboardClock.png, DashboardSingle.png, DashboardPhoto.png, DashboardPhotoEmpty.png, DashboardPhotoFull.png, DashboardPhotoAdd.png, DashboardPhotoDelete.png, DashboardPhotoDeleting.png, DashboardPhotoDeleteError.png, DashboardLibrary.png, DashboardLibraryFew.png, DashboardLibraryEight.png, DashboardLibraryEmpty.png, DashboardLibraryOffline.png, DashboardLibraryAdding.png, DashboardLibraryAddError.png, DashboardLibraryDelete.png, DashboardLibraryDeleting.png, DashboardLibraryDeleteError.png)

> **2026-11-28.11 — Tab Ảnh thành Kho ảnh** (phiếu `app/docs/phieu_thiet_ke/2026-11-27-kho-anh.md`; luật R-AK-1…5): khi `/api/state` có `photo_source`, tab Ảnh hiện
> kho ảnh trên điện thoại (không giới hạn) thay cho "ảnh trên thiết bị". Không có `photo_source` (firmware cũ) → tab Ảnh giữ
> nguyên các trạng thái `photo*` bên dưới (R-AK-5). Prop `state` thêm `library` (23 ảnh, online), `libraryFew` (5),
> `libraryEight` (8), `libraryEmpty`, `libraryOffline`, `libraryAdding`, `libraryAddError`, `libraryDelete`, `libraryDeleting`,
> `libraryDeleteError`; ảnh `DashboardLibrary*.png`. Khung: 844 (ít ảnh / trống), 900 (8), 1320–1440 (23 ảnh).
> - **Thẻ kho** (như thẻ ảnh cũ, đệm 16): nhãn `photoLibraryTitle` + meta phải `photoLibraryCount` (> 8) / `photoLibraryCountAll`
>   (≤ 8) / `photoLibraryCountEmpty`.
> - **Dòng nguồn ảnh** (`PhotoSourceStatus`, lề trên 12): nền `panel2`, bo 10, đệm 10 12; chấm 8 + chữ 12 ink. `online`: chấm mint
>   `photoSourceOnline`, bên phải `photoSourceShowing` 11 muted. `offline`: chấm muted `photoSourceOffline` + dòng phụ
>   `photoSourceOfflineBody` 11 muted (thụt 16). `state = none` (chưa gửi nguồn) → như offline. Kho trống → không có dòng này.
> - **Lưới** 3 cột cách 8, lề trên 12: ô đầu luôn là "+ Thêm ảnh" (như cũ) → bảng `photoAdd`; sau đó ảnh **mới nhất trước**
>   (mã giảm dần). Ô ảnh (`LibraryTile`) vuông bo 10, cả ô là nút → `libraryDelete` (`photoLibraryTileA11y`).
>   - 8 ảnh mới nhất (bộ đệm, R-AK-3): dấu màn hình góc phải dưới — ô 22 bo 6 nền `bg` 78 %, icon tv 14 mint, cách mép 5.
>     Chỉ để biết, không bấm, không có nút ghim.
>   - Ảnh thiết bị đang chiếu (`photo_source.index` theo thứ tự thêm, chỉ khi `online`): viền trong 2 mint + nhãn
>     `photoLibraryShowingTag` (9/700, nền mint, chữ `bg`, bo 4, đệm 2 5, góc trái trên cách 5). Có thể là ảnh ngoài bộ đệm.
>   - Kho có ảnh không có bản xem: như ô `photoNoPreview` cũ.
> - Dưới thẻ: icon tv 12 mint + `photoLibraryNote` 12 muted (lề 6 20 0; thay `photoNote`), rồi `ShowOnDeviceButton`.
> - **`libraryEmpty`**: giữa thẻ (đệm 28 8 8, cách 10): icon ảnh pixel ×3 muted, `photoLibraryEmptyTitle` 16/700,
>   `photoLibraryEmptyBody` 13 inkDim, nút đặc mint cao 48 bo 24 "+ `photoAdd`" → bảng `photoAdd`. Không ghi chú, không nút hiện.
> - **`libraryAdding`**: sau "Thêm vào kho" ở Cắt ảnh, app về tab này ngay; ô mới đứng sau ô thêm, phủ `bg` 66 % + vòng xoay 24
>   mint + `photoLibraryAdding` 11 ink; meta đã tính ảnh mới. Xong → ô thường có dấu "trên máy"; ảnh thứ 9 tính từ mới nhất
>   mất dấu.
> - **`libraryAddError`** (thiết bị không nhận bản đệm → ảnh không vào kho): thanh báo trên thẻ (như `photoDeleteError`)
>   `photoLibraryAddErrorTitle` coral / `photoLibraryAddErrorBody` + `commonRetry` (gửi lại vùng cắt đã giữ).
> - **`libraryDelete`**: hộp thoại như `photoDelete`, chữ `photoLibraryDeleteTitle` / `photoLibraryDeleteBody`.
> - **`libraryDeleting`**: ô phủ `bg` 66 % + vòng xoay 24 mint + `photoLibraryDeleting`; ô khác vẫn bấm được.
> - **`libraryDeleteError`**: thanh báo `photoDeleteErrorTitle` coral / `photoLibraryDeleteErrorBody` + `commonRetry`.

> **2026-11-26.9 — Nút đặt vị trí** (phiếu `app/docs/phieu_thiet_ke/2026-11-26-vi-tri-thoi-tiet.md`): ở `weatherNoLoc`, nút viền đổi thành `weatherSetLocation` ("Đặt vị trí thời tiết"), icon place (thay tune), mở thẳng màn **Vị trí thời tiết** (§9) thay vì tab Cài đặt. Ảnh `DashboardWeatherNoLocation.png` chụp lại.

> **2026-11-26.5 — Thành màn phụ "Số liệu"** (phiếu `app/docs/phieu_thiet_ke/2026-11-26-app-dieu-khien-thiet-bi.md`): không còn là tab 1. Đẩy từ Điều khiển (chạm ô màn / nút
> "Số liệu"), mở đúng tab của kênh đang hiện; không có thanh dưới. Đầu màn (Clawd, tên, IP) thay bằng thanh trên cao 56:
> nút quay lại 48 (`detailsBackA11y`) → Điều khiển, `detailsTitle` 18/700, nút refresh 44 bên phải. Mọi phần thân, `DockTabBar`
> và các trạng thái giữ như dưới. Ảnh mọi trạng thái `Dashboard*.png` chụp lại.

> **2026-11-25.4 — Tab Ảnh** (phiếu `app/docs/phieu_thiet_ke/2026-11-25-gui-anh-len-thiet-bi.md`): skill Ảnh (`photo`, màu nhấn `skillPhoto` = mint) thành tab thứ 2 của
> `DockTabBar` khi bật. Prop `state` thêm `photo`, `photoEmpty`, `photoFull`, `photoAdd`, `photoDelete`, `photoDeleting`,
> `photoDeleteError`; ảnh mỗi trạng thái một file `DashboardPhoto*.png`. Cả màn vừa 844 (`photoFull`, `photoDeleteError` 900).
> - **`DockTabBar` 4 tab** (đã vẽ): lưới 4 cột, tab ≥ 56 (`dockTabStacked`), đệm 0 2, cột: icon ×1.25 + 4 + nhãn 12. Huy hiệu
>   Agent nằm trên góc phải icon (tuyệt đối: trên 4, giữa + 10). Đang chọn / vạch màu như 3 tab. 2–3 tab giữ bố cục cũ.
>   Icon tab Ảnh `icons/dock-photo.svg` (khung ảnh 16×11 của dock thiết bị), nhãn `skillPhotoName`.
> - **Thẻ ảnh** (`photo`): thẻ đệm 16 — nhãn `photoOnDevice` + meta `photoCount` ("5/8 · còn 3 chỗ", muted). Lưới 3 cột
>   cách 8, lề trên 14, ô vuông bo 10 (`photoTile`). Ô ảnh = hình thu nhỏ phủ kín ô, cả ô là nút (`photoTileA11y`) → hỏi xoá.
>   Ảnh app không có bản sao (gửi từ trang web thiết bị / máy khác): ô nền `panel2`, icon ảnh ×1.75 muted, tên file 11
>   inkDim, `photoNoPreview` 10 muted. Ô cuối "+ Thêm ảnh": viền 1.5 đứt mint, nền mint 8 %, "+" 28 + `photoAdd` 13/500 mint
>   → bảng `photoAdd`. Thứ tự ô = thứ tự trên thiết bị (`photos[]`). Không đánh dấu ảnh đang chiếu (thiết bị không báo).
> - Dưới thẻ: ô vuông 8 amber + `photoNote` 12 muted (lề 6 20 0) — nhắc cập nhật đầy đủ xoá ảnh. Rồi `ShowOnDeviceButton`
>   (`homeShowOnDevice`, skill = "Ảnh").
> - **`photoEmpty`**: meta `photoCountEmpty`; giữa thẻ (đệm 28 8 8): icon ảnh ×3 muted, cách 10 `photoEmptyTitle` 16/700, `photoEmptyBody`
>   13 inkDim; nút đặc mint cao 48 bo 24, đệm 0 24, "+" 20 + `photoAdd` 14/700 màu bg → bảng chọn nguồn. Không có `photoNote`.
> - **`photoFull`** (8/8): meta `photoCountFull` amber; ô thêm khoá: viền 1 đứt `line`, ổ khoá 20 + `photoFullTile` 12 muted,
>   không bấm được; dưới lưới (cách 12) `photoFullBody` 13 inkDim.
> - **`photoAdd`** (bảng dưới): lớp phủ đen 60 %; bảng nền `panel`, bo trên 20 (`sheet`), đệm 10 20 28: tay nắm 36×4
>   `line`, cách 14 `photoAdd` 16/700, `photoAddHint` 12 muted, hai dòng ≥ 56 (icon 24 mint + 16 + chữ 15 ink, kẻ `line`):
>   `photoFromGallery`, `photoFromCamera` → trình chọn / máy ảnh của hệ thống → `PhotoCrop`; nút `commonCancel` cao 48 bo 14 `panel2`.
> - **`photoDelete`** (hộp thoại): rộng 312, nền `panel`, bo 20, đệm 24, cách 14: `photoDeleteTitle` 18/700; hình ảnh 96 bo
>   10 + `photoDeleteBody` 13 inkDim; nút chữ `commonCancel` (inkDim) và `photoDelete` (coral 700), cao 44.
> - **`photoDeleting`**: ô đang xoá phủ bg 66 %, vòng xoay 24 mint + `photoDeleting` 11 ink; ô khác vẫn bấm được.
> - **`photoDeleteError`**: thanh báo trên thẻ (như lỗi skill): `photoDeleteErrorTitle` coral, `photoDeleteErrorBody`, `commonRetry`.

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

> **2026-11-26.9 — Nhóm THỜI TIẾT** (phiếu `app/docs/phieu_thiet_ke/2026-11-26-vi-tri-thoi-tiet.md`): giữa BAN ĐÊM và SỐ LIỆU CLAUDE thêm tiêu đề nhóm `settingsSectionWeather` và một dòng 72 là liên kết: icon place 24 `skillWeather`, `settingsWeatherLocation` 16 ink, phụ 12 muted = `weatherPlace` của thiết bị (rỗng → `settingsWeatherLocationNone`; firmware cũ → toạ độ), mũi tên chevron 24 muted → màn **Vị trí thời tiết** (§9). Dòng này không tính vào `settingsSaveCount`: đổi vị trí áp ngay ở màn kia. Khung cao 1520 (`normal`, `changed`); ảnh `Settings.png`, `SettingsChanged.png` chụp lại.

> **2026-11-26.5:** thanh dưới tab 1 đổi thành "Điều khiển" (`navControl`, `icons/nav-control.svg`, huy hiệu agent chờ giữ nguyên); ảnh chụp lại.

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

> **2026-11-26.5:** thanh dưới tab 1 đổi thành "Điều khiển" (`navControl`, `icons/nav-control.svg`, huy hiệu agent chờ giữ nguyên); ảnh chụp lại.

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

## 5. Cài Wi-Fi — `WifiSetupScreen` (WifiSetup.png, WifiSetupWorking.png, WifiSetupDone.png, WifiSetupFailed.png, WifiSetupFormScanned.png, WifiSetupPassword.png, WifiSetupSaved.png, WifiSetupForget.png)

> **2026-11-28.12 — Quét mã, chỉ hỏi mật khẩu, mật khẩu đã nhớ** (phiếu `app/docs/phieu_thiet_ke/2026-11-28-quet-qr-cai-wifi.md`; R-WF-4, R-WF-5): prop `state` thêm
> `formScanned`, `password`, `saved`, `forget`. Khung `form` / `saved` / `forget` 900. Mọi ảnh `WifiSetup*.png` chụp lại.
> - **`form`:** trên ghi chú, nút **quét** (`WifiScanEntry`): cao ≥ 64, bo 14, viền 1 `clawd`, nền `clawd` 8 %, đệm 10 14, cách 12:
>   ô 40 bo 12 nền `clawd` 16 % + icon qr 24 `clawd`; `wifiScanEntry` 15/500 ink + `wifiScanEntrySub` 12 muted; chevron 24 muted →
>   màn Quét mã. Dưới: vạch `wifiOrManual` (label giữa hai kẻ 1 `line`, lề 16 0 14), rồi ghi chú + form như cũ. Dưới nút gửi
>   (lề trên 10, căn giữa, cao 44): icon key 16 + `wifiSavedLink` 13 inkDim → `saved`; không có mật khẩu nhớ → ẩn.
> - **`password`** (quét được, mạng điện thoại chưa nhớ mật khẩu): thanh báo `panel2` bo 14 đệm 12 14 (lề dưới 18): icon check 20
>   mint + `wifiScannedTitle` 14/700 + `wifiScannedBody` 13 inkDim. Nhãn `wifiNetworkToSend`; hàng cao 52 bo 12 nền `panel`: icon
>   wifi 22 inkDim + tên mạng 16 ink (chỉ đọc) + nút chữ `wifiChangeNetwork` 13/500 `clawd` → `form` (tên đã điền, sửa được). Cách 18:
>   ô mật khẩu nhãn `wifiPassFor`, nút mắt. Dưới ô: icon lock 14 + `wifiRememberNote` 12 muted. Nút `wifiSend`.
> - **`formScanned`** (quét được, điện thoại không ở Wi-Fi nào): thanh báo như trên với `wifiScannedNoNetwork`, rồi ghi chú + form
>   (tên trống), không có nút quét / mật khẩu đã nhớ.
> - Quét được + mạng đã nhớ mật khẩu → vào thẳng `working`, không hỏi.
> - **`saved`** (bảng dưới): lớp phủ 60 %; `panel`, bo trên 20, đệm 10 20 28: tay nắm, `wifiSavedTitle` 16/700, `wifiSavedBody` 12
>   muted; mỗi mạng một dòng ≥ 60 kẻ trên `line`: icon wifi 22 inkDim, tên 15 ink + `wifiSavedLastUsed` 12 muted, nút chữ `wifiForget`
>   13/500 coral → `forget`; nút `commonClose` cao 48 bo 14 `panel2`.
> - **`forget`** (hộp thoại 312, bo 20, đệm 24): `wifiForgetTitle` 18/700, `wifiForgetBody` 13 inkDim, `commonCancel` / `wifiForget`
>   (coral 700).
> - `working`: chi tiết `wifiStepJoinApDetail` mới. `done`: `wifiDoneDetail` có "đã nhớ mật khẩu"; nút Xong → Điều khiển. `failed`:
>   `wifiNotFound` mới (mật khẩu vừa gửi không được nhớ).

> **2026-11-25.1 — Bản đầu:** vẽ lại đúng app hiện có.

- Thanh trên 64: nút quay lại + `wifiTitle` (`appBarTitle`). Không có thanh điều hướng dưới. Đệm thân 20.
- Clawd 120 giữa: form → mở, working → mở + bước, done → vui, failed → buồn. 20.
- `form`: `wifiNote` (label) → 16 → ô `wifiSsid` (điền sẵn mạng điện thoại đang dùng) → 12 → ô `wifiPass` (ẩn chữ, nút mắt) →
  20 → nút chính `wifiSend` (icon send).
- Các trạng thái khác: dòng trạng thái `heading` căn giữa (ink / mint / coral) → 10 → chi tiết `body` → 24 → vòng xoay
  (working) hoặc nút `commonRetry` (failed) / `wifiDoneButton` (done). Đang làm thì không quay lại được.

## 6. Skill — `SkillsScreen` (Skills.png, SkillsSwitching.png, SkillsError.png, SkillsLegacy.png, SkillsLastOne.png, SkillsPhotoHint.png, SkillsPhotoFirmware.png, SkillsFunOn.png, SkillsFunSending.png, SkillsFunFw.png, SkillsFunLastOne.png)

> **2026-11-28.13 — Hàng skill Giải trí (Dò mìn)** (phiếu `app/docs/phieu_thiet_ke/2026-11-27-skill-giai-tri.md`; R-SK-1, R-SK-2, R-SK-4, R-DK-23): Giải trí thành `SkillRow` thật,
> đứng cuối (thứ tự dock: Agent, Ảnh, Thời tiết, Đồng hồ, Giải trí), **mặc định tắt**. Icon `icons/dock-fun.svg` (quả mìn pixel
> 15×15, ×1.5 = 22,5) màu `skillFun` khi bật / muted khi tắt; nền ô `skillFunTint` / `panel2`. Mô tả `skillFunDesc` (đổi chữ).
> Có trong mọi trạng thái trừ `legacy`. Chip "Sắp có" bỏ Giải trí (còn Tin nhắn, Nhạc, Mạng xã hội). Khung +72: 972 (lỗi 1062).
> Prop `state` thêm `funOn`, `funSending` (vòng xoay 24 thay công tắc + `skillsSending`), `funFw` (thiết bị không báo `fun` trong
> `skills`: ô icon muted, `skillsNeedFirmware` amber, nút viền `skillsUpdateFirmware` → tab Thiết bị — như `photoFw`),
> `funLastOne` (Giải trí là skill duy nhất bật: công tắc khoá mờ 38 %, mô tả `skillsLastOne` amber). Mọi ảnh `Skills*.png` chụp lại.
> Màu `skillFun` (amber) trùng Đồng hồ — giữ theo token có sẵn (người dùng chốt 2026-11-28.13).

> **2026-11-26.5:** thanh dưới tab 1 đổi thành "Điều khiển" (`navControl`, `icons/nav-control.svg`, huy hiệu agent chờ giữ nguyên); ảnh chụp lại.

> **2026-11-25.4 — Dòng skill Ảnh** (phiếu `app/docs/phieu_thiet_ke/2026-11-25-gui-anh-len-thiet-bi.md`): `SkillRow` Ảnh đứng thứ 2 (thứ tự dock: Agent, Ảnh, Thời tiết, Đồng hồ),
> icon `dock-photo` ×1.5, màu nhấn `skillPhoto`, `skillPhotoName` / `skillPhotoDesc`; **mặc định tắt**. Có thêm trong mọi
> trạng thái trừ `legacy`. Prop `state` thêm `photoHint`, `photoFw`. Màn cao 900 (lỗi 990) vì thêm một dòng; ảnh 4 trạng
> thái cũ (trừ legacy) chụp lại + `SkillsPhotoHint.png`, `SkillsPhotoFirmware.png`.
> - **`photoHint`** (skill Ảnh tắt, `/api/state` `photos` > 0): mô tả thay bằng `skillsPhotoHint` màu mint.
> - **`photoFw`** (firmware không có `photos` trong `/api/state`): ô icon nền `panel2` icon muted, mô tả `skillsNeedFirmware`
>   amber; thay công tắc bằng nút viền ≥ 44 bo 22 (viền `line`, icon tải firmware 16 + `skillsUpdateFirmware` 13/500 `clawd`) → tab Thiết bị.

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

## 7. Cắt ảnh — `PhotoCropScreen` (PhotoCrop.png, PhotoCropSending.png, PhotoCropDone.png, PhotoCropFull.png, PhotoCropTooBig.png, PhotoCropNoSpace.png, PhotoCropRejected.png, PhotoCropOffline.png)

> **2026-11-28.11 — Thêm vào kho** (phiếu `app/docs/phieu_thiet_ke/2026-11-27-kho-anh.md`): firmware có `photo_source` → nút chính đổi thành `photoCropAddToLibrary`; bấm là lưu vào kho và quay về tab Ảnh ngay (`libraryAdding`), việc gửi bản đệm hiện trên ô ảnh. Các trạng thái `sending`, `done`, `full`, `noSpace` của màn này chỉ còn cho firmware cũ. Chưa vẽ lại artboard (chỉ đổi chữ nút).

> **2026-11-25.4 — Màn mới** (phiếu `app/docs/phieu_thiet_ke/2026-11-25-gui-anh-len-thiet-bi.md`). Push từ tab Ảnh sau khi chọn / chụp ảnh; ngoài khung tab (không thanh dưới).
> Prop `state`: `crop`, `sending`, `done`, `full`, `tooBig`, `noSpace`, `rejected`, `offline`. Mọi trạng thái 844.

- **Thanh trên** cao 56, đệm 0 8: nút quay lại 48 (mũi tên 24 ink) → tab Ảnh; `photoCropTitle` 18/700.
- **Vùng cắt** cao 340 (`cropStage`), nền đen: ảnh phủ ngang 390, giữa dọc. Khung vuông 260 (`cropFrame`) giữa vùng: viền 1
  ink, ngoài khung phủ đen 60 %, lưới chia ba 1 px ink 35 %, 4 góc chữ L 22 nét 4 ink. Kéo để dời ảnh, chụm để phóng
  (ảnh luôn phủ kín khung; phóng nhỏ nhất = cạnh ngắn của ảnh bằng khung). Nhãn đọc màn hình `photoCropAreaA11y`.
- `photoCropHint` 12 muted giữa, cách vùng cắt 10.
- **Xem trước**: nhãn `photoCropPreview` 12 muted (đệm 14 20 8). Hàng đệm 0 16 cách 16: ô 180 (`devicePreview`) = màn thiết
  bị 240 px thu ×0.75, nền đen, bo 6, viền 1 `line` — vẽ lại bố cục màn Ảnh của thiết bị (`design/panel` `Photo.png`): tiêu
  đề "Ảnh" 12 ink giữa, meta "6/6" 10 muted phải, kẻ 1 mint dưới tiêu đề, dock dọc trái (4 icon ×0.75, tab Ảnh nền `panel2`
  + vạch mint), **vùng ảnh 141 (`devicePreviewPhoto`) tại (30, 21)** = đúng vùng đang cắt, vạch tiến độ 2 mint ở đáy. Cột
  phải: `photoCropPreviewBody` 13 ink, `photoCropPreviewNote` 12 muted. Xem trước cập nhật theo khi kéo / phóng.
- **Đáy** (đệm 16 16 24, cách 12), theo `state`:
  - `crop`: hai nút cao 48 bo 24 chia đều cách 10 — `photoCropPickOther` (viền `line`, icon thư viện 18 inkDim, chữ ink 500) và
    `photoCropSend` (nền mint, icon gửi 18 + chữ màu bg 700).
  - `sending`: thẻ `panel` bo 14 đệm 16: vòng xoay 24 mint + `photoCropSending` 14 ink + phần trăm 14/700 mint; thanh 6 bo 3
    nền `panel2` phần chạy mint; `photoCropKeepOpen` 12 muted. Dưới: nút `commonCancel` (viền). Gồm cả bước nén ảnh.
  - `done`: thẻ `panel`: vòng 32 nền mint 16 % dấu tích 20 mint + `photoCropDoneTitle` 15/700, `photoCropDoneBody` 13 inkDim.
    Nút `photoCropAddAnother` (viền) → trình chọn ảnh; `photoCropDone` (mint) → tab Ảnh.
  - Lỗi: thanh báo `panel2` bo 14 đệm 14 16 (`role=alert`): tiêu đề 14/700 coral + nội dung 13 inkDim; rồi hàng nút:
    `full` → `photoCropErrorFull*` + `photoCropBackToList`; `tooBig` → `photoCropErrorTooBig*` + `photoCropPickOther`, `photoCropRecrop` (mint);
    `noSpace` → `photoCropErrorNoSpace*` + `photoCropBackToList`, `commonRetry` (mint); `rejected` → `photoCropErrorRejected*` +
    `commonCancel`, `commonRetry`; `offline` → `photoCropErrorOffline*` + `commonCancel`, `commonRetry`. Vùng cắt giữ nguyên.
- Gửi: thu nhỏ vùng cắt về 188 × 188, JPEG **baseline**, ≤ 40 KB — quá thì giảm chất lượng dần, chỉ báo `tooBig` khi đã hết bậc.
  Gửi xong app giữ bản sao (làm hình thu nhỏ ở tab Ảnh).

## 8. Điều khiển — `ControlScreen` (Control.png, ControlDragging.png, ControlKeyAlt.png, ControlClickRight.png, ControlPoweringOff.png, ControlOff.png, ControlPoweringOn.png, ControlCard.png, ControlNight.png, ControlBrightness.png, ControlFailed.png, ControlOldFw.png, ControlSetup.png, ControlOffline.png)

> **2026-11-28.12 — Thanh báo glimmer-setup** (phiếu `app/docs/phieu_thiet_ke/2026-11-28-quet-qr-cai-wifi.md`): nút chữ đổi thành icon qr 18 + `controlSetupAction` ("Quét mã trên màn") → màn **Quét mã** (§10). Ảnh `ControlSetup.png` chụp lại.

> **2026-11-27.10 — App là chuột, bàn phím, nút nguồn** (phiếu `app/docs/phieu_thiet_ke/2026-11-27-dieu-khien-chuot-ban-phim-nguon.md`). **Bỏ toàn bộ ô màn trên app** (`TouchMirror`, thanh tác
> vụ vẽ lại, desktop, `StartMenuSheet`, `AllProgramsSheet`, nút tròn "Tắt màn"): người dùng nhìn màn thật; con trỏ, Start, menu
> vẽ trên thiết bị. Mọi mục 2026-11-26.5 → .8 bên dưới **bỏ**, trừ thẻ agent, thanh báo, thanh báo nổi. Prop `state`:
> `normal`, `dragging`, `keyAlt`, `clickRight`, `poweringOff`, `off`, `poweringOn`, `card`, `night`, `brightness`, `failed`, `oldFw`, `setup`, `offline`. Tất cả 844. Ảnh 14 `Control*.png`.
> - **Đầu màn** (đệm 10 16 6 20, cách 12): Clawd ×1.75, "glimmer" 16/700, chấm + mạng · IP 11 muted; phải **`PowerButton`** tròn 48
>   (`powerButton`, lề phải −4) viền 2, icon ⏻ 24: bật = viền mint, icon ink, nền `panel` (`powerOff`); tắt = viền + icon coral, nền
>   coral 12 % (`powerOn`); đang tắt / đang khởi động = vòng cung 3 px amber / mint quay quanh nút (`powerShutting`, `powerBooting`).
> - **`Trackpad`** (lề 6 16 0): cao 280 (`trackpad`; 190 khi có thẻ agent, 220 khi có thanh báo), viền 1 `line` (không viền dưới), bo
>   20 20 0 0, gradient `trackpadTop` → `trackpadBottom`, bóng trong 0 2 8 đen 45 %; giữa có icon chuột 40 ink mờ 18 %. Cả vùng là
>   bề mặt rê (`controlTrackpadA11y`). Đang rê (`dragging`): viền mint 55 %, vệt ngón tay mint 35 % rộng 10 + quầng mint 22 % ở đầu
>   ngón. Không vẽ con trỏ trên app.
> - **`MouseButtons`** liền dưới bàn rê: hai nửa bằng nhau cao 60 (`mouseButton`), khe 2 màu `line`, viền ngoài `line`, bo 0 0 20 20,
>   nền `panel`, chữ 13/500 inkDim `controlMouseLeft` / `controlMouseRight`. Đang bấm: nền `panel2` + bóng trong (lõm).
> - **`KeyPad`** (lề 12 16 0, 3 hàng cách 8): phím cao 52 (`key`) bo 10, mặt gradient `keyFaceTop` → `keyFaceBottom`, gờ dưới inset 3
>   `keyEdge` + viền sáng trên 1 px trắng 6 %, chữ 13/700 ink; đang bấm: `keyPressed` + bóng trong. Hàng 1: `keyWindows` (lá cờ 4 màu
>   16) · `keyAltTab` · `keyAltF4` (mỗi phím rộng 1.2) · `keyEsc`. Hàng 2: `keyTab` (icon tab 20 + chữ) · `keyEnter` (rộng 1.6, icon
>   enter + chữ) · `keyText` mờ 35 % với icon bàn phím + `keyTextSoon` 10 muted. Hàng 3: 4 mũi tên ← ↑ ↓ → bằng nhau, icon 22.
>   Tổ hợp là **phím có sẵn**, bấm một chạm (không phím dính). Rung nhẹ mỗi lần bấm phím / nút chuột / chạm click.
> - **Hàng cuối** (lề 12 16 0, cách 8): thẻ độ sáng (như cũ, co giãn) + hai nút vuông 52 (`controlSquare`) bo 14 viền `line`: chế độ
>   đêm (`controlNightA11y`; bật = nền lilac 16 %, viền + icon lilac) và Số liệu (`controlDetailsA11y`) → màn Số liệu.
> - Trạng thái: `keyAlt` (Alt+Tab lõm), `clickRight` (nửa Phải lõm), `poweringOff` / `poweringOn` (nút nguồn vòng quay; bàn rê, nút
>   chuột, phím, hàng cuối mờ 35 %, không bấm được), `off` (nút nguồn coral; mọi thứ mờ trừ nút nguồn; giữa bàn rê nút tròn 120 viền
>   coral nền coral 10 %, icon ⏻ 40 + `powerOn` 14/700 coral), `card` (`HoldCardPanel` trên bàn rê), `night` (bàn rê, chuột, phím mờ —
>   màn đêm không có con trỏ; độ sáng 15 %; nút đêm sáng lilac), `brightness` (bong bóng % trên núm), `failed` (`CommandSnackbar`
>   "Thiết bị không nhận lệnh "Alt+F4"."), `oldFw` (`controlOldFwTitle` / `controlOldFwBody` + `controlUpdateFirmware`; bàn rê, chuột,
>   phím, nút nguồn mờ, độ sáng vẫn dùng), `setup` / `offline` (thanh báo như cũ; mọi điều khiển mờ).

> **2026-11-26.8 — Bỏ thẻ hướng dẫn chạm.** `TouchLegend` ("Chạm màn như dùng chuột") **bỏ**: dưới ô màn không còn chữ nào về chuyển,
> thu nhỏ, tắt app. Thứ tự dưới ô màn: thẻ độ sáng (lề 12 16 0), ba nút tròn. Ảnh 16 `Control*.png` chụp lại.

> **2026-11-26.7 — Thanh tác vụ theo cửa sổ đang mở, bỏ vòng chạm và chữ trạng thái.** Prop `state`: `normal`, `opened`, `twoOpen`, `minimized`, `closed`, `installed`, `start`, `allPrograms`, `failed`, `card`, `screenOff`, `night`, `brightness`, `oldFw`, `setup`, `offline`
> (bỏ `tapMin`, `tapIcon`, `tapClose`, `sending`; thêm `opened`, `twoOpen`, `closed`; `normal` nay là desktop lúc mới vào).
> 844, trừ `card` / `oldFw` / `setup` / `offline` 960. Ảnh 16 `Control*.png`.
> - **Bỏ `TapRipple` và `StatusChip`** và dòng chữ dưới ô màn (`controlOpenOnDevice`, `controlMinimizedNote`…): màn đổi ngay là phản
>   hồi. Dòng dưới ô màn chỉ còn ở `screenOff` / `night`. Lỗi vẫn là `CommandSnackbar`.
> - **Thanh tác vụ trên ô màn** (y 214–239, giữa start và khay x 69–195) = **cửa sổ đang mở**, theo thứ tự mở: nút 28 × 20 tại
>   x 71 + 30·i, y 217 (ngoài 1 px + trong 26 × 18), icon dock giữa nút (Claude màu `clawd`, còn lại trắng). Cửa sổ trên cùng:
>   lõm (ngoài #163E91, trong #1E4FB5); còn lại / thu nhỏ: nổi (ngoài #1A50C8, trong #3C81F3). Huy hiệu vàng 9 × 9 trên nút Claude
>   khi có agent chờ. **Không vạch tiến độ.** Nền phần trống giữ dải màu thanh tác vụ XP.
>   - `normal`: mới vào → desktop, thanh trống. `opened`: mở Claude → [Claude lõm]. `twoOpen`: mở thêm Thời tiết →
>     [Claude][Thời tiết lõm]. `minimized`: `_` trên Claude → desktop, [Claude nổi]. `closed`: `×` trên Claude khi đang có Thời
>     tiết → cửa sổ Thời tiết, [Thời tiết lõm]. Tắt cửa sổ cuối → desktop, thanh trống. `installed`: desktop, thanh trống.
> - Ô màn hiện bằng lớp vẽ chồng lên file XP của `design/panel` (thanh tác vụ panel đang cố định 4 nút skill) — màn thiết bị thật
>   phải đổi theo (xem CHANGELOG).

> **2026-11-26.6 — Màn thiết bị chạm được, mô hình Windows XP.** App là "máy tính" (xử lý, nhớ cửa sổ đang mở, chương trình đã
> cài), thiết bị là màn hình. **Không tự xoay, không có nút kênh trước / sau / dừng xoay, không có `JumpTabBar`, không thanh
> tiến độ slide** — các mục đó và `paused` / `single` bên dưới **bỏ**. Prop `state`: `normal`, `tapMin`, `minimized`, `installed`, `tapIcon`, `tapClose`, `sending`, `start`, `allPrograms`, `failed`, `card`, `screenOff`, `night`, `brightness`, `oldFw`, `setup`, `offline`.
> 844, trừ `card` / `oldFw` / `setup` / `offline` 960. Ảnh `Control*.png` (17); `ControlPaused.png`, `ControlSingle.png` bỏ.
> - **`TouchMirror`** (thay `DeviceMirror` ×1.2): vỏ 376 × 376 (`deviceShell`), lề trên 6, đệm 6, bo 20, gradient như cũ; màn
>   364 nền đen bo 6 đệm 2; vùng vẽ **360 = 240 px × 1.5** (`deviceScale`). Vẽ đúng px theo `design/panel` (§17). Cả vùng là
>   bề mặt chạm (`controlScreenA11y`): chạm = chuột trái tại điểm đó (đổi toạ độ ÷ 1.5), giữ ≥ 500 ms = chuột phải. Vùng
>   chạm nhỏ của XP (nút cửa sổ 15 px ≈ 22 dp, nút thanh tác vụ 28 px ≈ 42 dp) được nới ra **44 × 44** quanh tâm khi tính trúng.
>   - Nút cửa sổ `_` (tâm 192, 11) thu nhỏ → desktop, nút app vẫn ở thanh tác vụ; `□` (207, 11) phóng to; `×` (228, 11) tắt app
>     → bỏ khỏi thanh tác vụ, thiết bị về cửa sổ trước đó (hết thì desktop).
>   - Thanh tác vụ y 214–239: start (0–65) → bảng `Start` của app; nút app (28 px từ x 71) → đưa app lên màn.
>   - Desktop: chạm biểu tượng → mở app.
> - **Phản hồi chạm** (`TapRipple` + `StatusChip`): vòng 44 (`tapRipple`) viền 2 trắng, nền trắng 28 %, viền ngoài 4 `tapRing`, tại
>   điểm chạm; chip trên góc trái vỏ (trên −12, trái 14): cao 28 bo 14 `panel2` viền `line`, vòng xoay 16 (hoặc dấu tích mint khi
>   xong) + chữ 12: `controlMinimizing`, `controlClosing`, `controlOpening`, `controlOpeningApp`, `controlInstalled`. Ô màn đổi ngay
>   theo kết quả dự kiến; thiết bị không nhận → về như máy + `CommandSnackbar` (`controlFailed`, vd. "Tắt Claude").
> - **Dòng dưới ô màn** (đệm 12 24 0): ô 8 bo 2 màu nhấn app + tên app 13/700 + ghi chú 13 muted (`controlOpenOnDevice`,
>   `controlJustOpened`, `controlMinimizedNote`, `controlInstalledNote`, `controlTapIconNote`). Không có thanh.
> - **`TouchLegend`** (lề 10 16 0, đệm 10 14, bo 14 `panel`): `controlLegendTitle` 12 muted, lưới 2 cột cách 6 12: ô ký hiệu
>   (≥ 22 × 20 bo 4 `panel2`, chữ 11/700 ink) + nhãn 12 inkDim — `_` thu nhỏ, `□` phóng to, `×` tắt app, `▭` nút dưới: đổi app,
>   `start` mở Start, `giữ` chuột phải. Mờ 38 % khi không dùng được.
> - Độ sáng, ba nút tròn (Tắt màn · Chế độ đêm · Số liệu), thẻ agent, màn tắt, đêm, thanh báo: như dưới.
> - **Desktop** (`minimized`, `installed`, `tapIcon`): **mỗi skill đã cài = một biểu tượng** (`DesktopIcon`): icon dock ×1.6 trắng
>   bóng đen 1 px + nhãn 11 trắng bóng đen, xếp cột 1 (tâm x 40) rồi cột 2 (tâm x 122), bước 46, từ trên xuống, tránh bong bóng
>   thời tiết. Vừa cài (`installed`): biểu tượng mới ở trạng thái chọn — nhãn nền `xpSelect`, viền chấm trắng — + chip
>   `controlInstalled`. Bố cục chính xác của desktop do `design/panel` vẽ (đang là lớp minh hoạ chồng lên).
> - **`StartMenuSheet`** (`start`; lớp phủ đen 60 % trên cả màn, cả thanh dưới): bảng `panel` bo trên 20 đệm 10 12 20, tay nắm.
>   Đầu: ô 44 bo 10 nền `skillAgentTint` + Clawd ×1.75, "glimmer" 16/700, `startSubtitle` 11 muted. Lưới 2 cột cách 8: trái nền
>   `panel2` bo 14 — Claude (`startClaudeSub`), Codex (`startCodexSub`) đậm; kẻ; Thời tiết, Ảnh, Đồng hồ (ghim / hay dùng); phải
>   nền `bg` bo 14 — `startDesktop`, `startDetails`; kẻ; `startControlPanel` (`startControlPanelSub`) → Cài đặt, `startAddRemove`
>   (`startAddRemoveSub`, icon + `clawd`) → Skill, `startDevice` (`startDeviceSub`) → Thiết bị. Hàng ≥ 48: icon 20–22 trong ô 28,
>   chữ 13 (đậm 700 / thường 500), phụ 11 muted. Dưới lưới hàng `startAllPrograms` (nền `panel2`, icon lưới mint, mũi tên mint).
>   Chân (kẻ `line` trên): nút chữ `startTurnOff` (power, amber) và `startRestart` (restart, coral), cao 44.
> - **`AllProgramsSheet`** (`allPrograms`): cùng khung; đầu nút quay lại 44 (`allProgramsBackA11y`) + `allProgramsTitle` 16/700.
>   Nhóm (`allProgramsGroup*` 12 muted) lưới 4 cột cách 8: ô ≥ 76 bo 14 `panel2`, icon 24 + tên 12 (`app*`), chấm mint 6 góc trên
>   phải = đang mở (`allProgramsOpenLegend`). Cuối: hàng viền đứt `allProgramsAddRemove` (+ `allProgramsAddRemoveSub`) → Skill.
> - `oldFw`: `controlOldFwTitle` / `controlOldFwBody`; ô màn vẫn hiện, chạm không gửi; Start vẫn dùng được.

> **2026-11-26.5 — Màn mới, tab 1** (phiếu `app/docs/phieu_thiet_ke/2026-11-26-app-dieu-khien-thiet-bi.md`). App thành remote của thiết bị. Prop `state`: `normal`, `sending`, `failed`,
> `card`, `paused`, `screenOff`, `night`, `brightness`, `single`, `oldFw`, `setup`, `offline`. 844, trừ `card` / `oldFw` /
> `setup` / `offline` 960 (cuộn).

- **Đầu màn** (đệm 10 16 4 20, cách 12): Clawd ×1.75 + cột: "glimmer" 16/700, chấm 7 (mint; amber khi setup, coral khi mất
  kết nối) + mạng · IP 11 muted. Phải: nút refresh 44 inkDim (`controlRefreshA11y`) → `POST /api/refresh`.
- **Ô màn `DeviceMirror`**: vỏ 312 × 312 (`deviceShell`), giữa ngang, lề trên 4, đệm 10, bo 22, gradient 160°
  `deviceShellTop` → `deviceShellBottom`, viền sáng trong 1 px trắng 8 %, bóng 0 10 24 đen 50 %. Trong: màn 292 nền đen bo 6
  đệm 2, vùng vẽ **288 × 288 = màn thiết bị 240 px × 1.2** (`deviceScale`). Vẽ **đúng từng px** theo `design/panel`
  (§17 kiểu XP): `source/DeviceXP*.dc.html` là bản chép nguyên của `panel/source/XP-*.dc.html` (Claude-A, Weather, Attention,
  Night, SetupMode) để tra; kênh khác theo file XP tương ứng của panel. Dữ liệu từ `/api/state` (kênh, số, project, thời tiết, ảnh, giờ).
  Cả ô là một nút (`controlScreenA11y`): chạm → Số liệu ở tab của kênh; vuốt trái → kênh sau, vuốt phải → kênh trước.
- **Dòng kênh** (đệm 12 24 0, cách 8): tên kênh 13/700 ink + ghi chú 13 muted (`controlNextIn`); thanh 3 bo 2 nền `panel2`,
  phần chạy màu nhấn kênh = thời gian đã qua của slide (cần `slide_left_ms`).
- **D-pad** (đệm 14 16 0, cách 10): 3 nút chia đều ≥ 64 (`padButton`) bo 18 nền `panel`: icon 28 ink + nhãn 11 inkDim —
  `controlPrev` (chevron trái), `controlPause` / `controlResume` (pause / play), `controlNext`. Đang dừng: nút giữa nền amber 16 %,
  icon + nhãn amber. Không dùng được: mờ 38 %; thiếu firmware: mờ + ổ khoá 14 góc trên phải.
- **Nút tab** (`JumpTabBar`, lề 12 16 0): như `DockTabBar` 4 tab xếp dọc (ô 56, icon dock ×1.25 + nhãn 12), nút sáng = kênh
  đang hiện trên thiết bị (không phải tab đang chọn của app); huy hiệu amber trên Agent. Bấm → `POST /api/channel {name}`.
  Một skill bật (`single`): không có hàng này, thay bằng `controlSingleNote` 12 muted (lề 10 24 0).
- **Độ sáng** (lề 12 16 0): thẻ ≥ 52 `panel` bo 14 đệm 0 16, cách 14: mặt trời 20 inkDim, thanh trượt (rãnh 4 `panel2`, phần
  sáng amber, núm 20 ink có bóng; vùng chạm cao 44), số "80%" 13 ink rộng 40. Đang kéo: núm 28 + bong bóng ink chữ bg 12/700
  trên núm; ô màn phủ đen theo độ sáng (minh hoạ). Gửi `brightness` khi thả tay.
- **Nút tròn** (đệm 16 16 0, 3 cột): vòng 56 (`roundButton`) nền `panel` viền 1 `line`, icon 24 ink + nhãn 12 inkDim cách 6:
  `controlScreenOff` (power), `controlNight` (moon), `controlDetails` (bar chart → Số liệu). Bật: nền tint + viền + icon + nhãn
  màu nhấn — màn tắt amber (`controlScreenOn`), đêm lilac.
- **`sending`**: ô màn đổi ngay sang kênh mới (lạc quan), chip trên góc phải vỏ (trên −10, phải 10): cao 28 bo 14 `panel2` viền
  `line`, vòng xoay 16 + `controlSending` 12. Dòng kênh `controlJustSwitched`.
- **`failed`**: ô màn về đúng kênh thiết bị; thanh báo nổi trên thanh dưới (trái / phải 12, đáy 92): nền `snackbar` bo 12 bóng,
  `controlFailed` 13 ink + `commonRetry` 14/700 `clawd`. Tự ẩn sau 6 s.
- **`card`** (thẻ agent giữ màn, `/push` có approval / input đang hiện): ô màn = thẻ XP Attention; thay dòng kênh bằng thẻ (lề 12
  16 0, đệm 14 16, bo 14, nền amber 10 %, viền amber 40 %): `controlCardLabel` 12 amber, `controlCardBody` 14 ink (tên công cụ
  đậm), `controlCardNote` 12 inkDim, nút viền `controlDismissCard` cao 40 bo 20 → bỏ thẻ theo id. **Không có nút duyệt.**
- **`paused`**: dòng kênh amber `controlPausedNote`, thanh dừng; nút giữa `controlResume`.
- **`screenOff`**: ô màn nền `screenOff` + `controlScreenOffOverlay` 12 #3A3540; dòng `controlScreenOffTitle` + `controlScreenOffNote`
  amber; d-pad, tab, độ sáng, đêm mờ; nút power sáng amber.
- **`night`**: ô màn = mặt đêm của thiết bị; dòng `controlNightTitle` + `controlNightNote` lilac; d-pad + tab mờ; nút đêm sáng lilac.
- **`oldFw`** (firmware thiếu lệnh): thanh báo amber đầu màn (`controlOldFwTitle`, `controlOldFwBody`, `controlUpdateFirmware` →
  Thiết bị); nút thiếu (kênh trước, dừng xoay, tắt màn) mờ + ổ khoá; dòng kênh không có thời gian.
- **`setup`**: thanh báo amber `controlSetupTitle` / `controlSetupBody` / `controlSetupAction` → Cài Wi-Fi; ô màn = màn cài đặt của
  thiết bị; mọi nút mờ.
- **`offline`**: thanh báo coral `controlOfflineTitle` / `controlOfflineBody` + `commonRetry`; ô màn giữ hình cuối, phủ bg 72 %
  + `controlOfflineOverlay` 14/700 + `controlOfflineOverlayNote` 12 muted; mọi nút mờ. Chưa từng kết nối / đang tìm → màn Kết nối.
- Thanh điều hướng dưới, tab 1 (Điều khiển) đang chọn.

## 9. Vị trí thời tiết — `WeatherLocationScreen` (WeatherLocation.png, WeatherLocationUnset.png, WeatherLocationGpsLoading.png, WeatherLocationGpsDenied.png, WeatherLocationGpsOff.png, WeatherLocationGpsFail.png, WeatherLocationSearching.png, WeatherLocationResults.png, WeatherLocationNoResults.png, WeatherLocationSearchError.png, WeatherLocationConfirm.png, WeatherLocationSending.png, WeatherLocationSendFailed.png, WeatherLocationDone.png, WeatherLocationClear.png, WeatherLocationOldFw.png)

> **2026-11-26.9 — Màn mới** (phiếu `app/docs/phieu_thiet_ke/2026-11-26-vi-tri-thoi-tiet.md`): đặt vị trí thời tiết của thiết bị từ điện thoại. Màn đẩy (không thanh dưới), mở từ
> Cài đặt › THỜI TIẾT và từ nút `weatherSetLocation` của tab Thời tiết. Prop `state`: `set`, `unset`, `gpsLoading`,
> `gpsDenied`, `gpsOff`, `gpsFail`, `searching`, `results`, `noResults`, `searchError`, `confirm`, `sending`, `sendFailed`,
> `done`, `clear`, `oldFw`. Khung 844.

- **Dữ liệu:** đọc `weatherLat`, `weatherLon`, `weatherPlace` từ `GET /api/settings`; ghi bằng `POST /api/settings
  {weatherLat, weatherLon, weatherPlace}` (thiết bị áp ngay). Không lưu vị trí riêng trên app. Có khoá `weatherPlace` = firmware
  hiện tên nơi; không có → `oldFw`.
- **Thanh trên** 56: nút quay lại 48 → màn mở nó, `weatherLocationTitle` 18/700.
- **Thẻ hiện tại** (`panel`, bo 14, đệm 16, lề 6 16): `weatherLocationCurrent` (label) → hàng cách 12, lề trên 12: ô 40 bo 12 nền
  `skillWeatherTint` + icon place 24 `skillWeather`; cột: tên nơi 20/700 ink, `weatherLocationCoords` 12 muted. Kẻ 1 `line` (lề 14 0 4).
  Hai nút chữ cao 44 căn phải: `weatherLocationRename` 13/500 inkDim → bảng sửa tên; `weatherLocationClear` 13/500 coral → hỏi xoá.
  - `unset`: ô 40 nền `panel2`, icon muted; `weatherNoLocationTitle` 16/700 + `weatherLocationUnsetBody` 13 inkDim; không có nút.
  - `oldFw`: tên = toạ độ (20/700); thêm `weatherLocationOldFwNote` 12 amber (lề trên 10).
- **Nút GPS** (`LocationGpsButton`, lề 6 16): cao ≥ 68, bo 14, nền `skillWeatherWash`, viền 1 `skillWeather`, đệm 12 14, cách 12:
  ô 40 bo 12 `skillWeatherTint` + icon my_location 24 `skillWeather`; `weatherLocationUseGps` 15/500 ink + `weatherLocationUseGpsSub`
  12 muted; chevron 24 muted. Bấm → xin quyền (hộp thoại của hệ thống) → lấy vị trí → bảng xác nhận. Chỉ lấy vị trí khi bấm.
  - `gpsLoading`: vòng xoay 24 thay icon, viền `line`, không bấm được, `weatherLocationGpsLoading` / `…Sub`, không chevron.
  - Tên nơi từ toạ độ: dịch vụ tra địa chỉ của điện thoại (Open-Meteo không tra ngược); không có tên → ô tên để trống, người dùng gõ.
- **Thanh báo GPS** (`panel2`, bo 14, đệm 14 16, lề 0 16 6, dưới nút GPS): tiêu đề 14/700 + thân 13 inkDim + nút căn phải.
  - `gpsDenied` amber `weatherLocationGpsDeniedTitle` / `…Body`, nút viền `weatherLocationOpenAppSettings` (khi bị từ chối hẳn;
    còn hỏi được thì bấm lại nút GPS là hệ thống hỏi lại).
  - `gpsOff` amber `weatherLocationGpsOffTitle` / `…Body`, nút viền `weatherLocationTurnOnGps`.
  - `gpsFail` coral `weatherLocationGpsFailTitle` / `…Body`, nút chữ `commonRetry`.
- **Tìm thành phố:** `weatherLocationSearchSection` (label, đệm 18 20 8). Ô tìm (`LocationSearchField`, lề 0 16): cao 52, bo 12,
  nền `panel`, viền 1 `line` (có chữ: `skillWeather`), đệm 0 14, icon search 22 inkDim, chữ 16 (`weatherLocationSearchHint` muted
  khi trống), nút × 44 (`weatherLocationSearchClearA11y`) khi có chữ. Dưới ô: `weatherLocationSearchPrivacy` 11 muted (lề 6 4 0).
  Tìm sau khi ngừng gõ ~400 ms, từ 2 ký tự, Open-Meteo geocoding (`language=vi`, tối đa 10 kết quả).
  - Kết quả (thẻ `panel` bo 14, lề 10 16 0): mỗi dòng ≥ 60, đệm 8 16, kẻ trên 1 `line` từ dòng 2: icon place 20 muted, tên 16 ink,
    `weatherLocationResultSub` 12 muted. Bấm → bảng xác nhận.
  - `searching`: một dòng 60 vòng xoay 20 + `weatherLocationSearching` 14 inkDim.
  - `noResults`: thẻ đệm 18 16: `weatherLocationNoResultsTitle` 14/700 + `…Body` 13 inkDim.
  - `searchError`: thanh báo coral `weatherLocationSearchErrorTitle` / `…Body` + `commonRetry`.
- **Bảng xác nhận** (`LocationConfirmSheet`, `confirm`): lớp phủ đen 60 %; bảng `panel` bo trên 20, đệm 10 20 28: tay nắm 36×4 `line`
  (lề dưới 14) → `weatherLocationConfirmTitle` 16/700 → vùng + toạ độ 12 muted (lề 4 0 16) → `weatherLocationNameLabel` → ô tên cao
  52 bo 12 nền `bg` viền 1 `skillWeather`, chữ 16, bộ đếm `weatherLocationNameCount` 12 muted bên phải; tối đa 16 ký tự (thiết bị cắt
  thêm nếu vẫn quá khe) → `weatherLocationNameHint` 11 muted → khung xem trước (`panel2` bo 12, đệm 12 14, lề trên 14):
  `weatherLocationPreview` + `weatherLocationPreviewWeather` / `…Clock` 13 ink, tên nơi 700 `skillWeather` → hai nút cao 48 bo 14 cách
  10 (lề trên 18): `commonCancel` (nền `panel2`, ink, flex 1) và `weatherLocationApply` (nền `skillWeather`, chữ `bg` 14/700, flex 1.4).
  Tên mặc định = tên kết quả / tên tra được; sửa được.
  - Sửa tên (nút `weatherLocationRename`): cùng bảng, tiêu đề `weatherLocationRenameTitle`, nút `weatherLocationSaveName`; chỉ gửi
    `weatherPlace`.
  - `sending`: nút chính vòng xoay 18 màu `bg` + `weatherLocationSending`, cả hai nút khoá.
  - `sendFailed` (thiết bị không trả lời / lỗi): trên tiêu đề thanh báo (`panel2` bo 12, đệm 12 14, lề dưới 14)
    `weatherLocationRejectedTitle` coral 14/700 + `…Body`; nút chính thành `commonRetry`. Vị trí cũ giữ nguyên.
  - `oldFw`: không có ô tên và xem trước; thay bằng `weatherLocationOldFwSheet` 13 amber; nút `weatherLocationApplyCoords`; chỉ gửi
    `weatherLat` / `weatherLon`.
- `done`: thiết bị nhận → đóng bảng, thẻ hiện tại cập nhật, thông báo nhỏ (nền ink, chữ `bg` 14/500, bo 12, đệm 14 16, cách đáy 24,
  lề 16) `weatherLocationDone`, tự ẩn sau 3 s.
- `clear`: hộp thoại rộng 312, `panel`, bo 20, đệm 24, cách 14: `weatherLocationClearTitle` 18/700, `weatherLocationClearBody` 13
  inkDim, nút chữ `commonCancel` inkDim và `weatherLocationClearOk` coral 700, cao 44. Xoá = gửi `weatherLat` 0, `weatherLon` 0,
  `weatherPlace` "" (thiết bị coi là chưa đặt) → về `unset`.

## 10. Quét mã — `WifiScanScreen` (WifiScan.png, WifiScanFound.png, WifiScanWrongCode.png, WifiScanNoCamera.png)

> **2026-11-28.12 — Màn mới** (phiếu `app/docs/phieu_thiet_ke/2026-11-28-quet-qr-cai-wifi.md`; R-WF-4): đọc mã QR trên màn cài Wi-Fi của thiết bị (panel P-2026-11-28.26). Màn đẩy toàn
> màn, không thanh dưới. Mở từ Kết nối, thanh báo glimmer-setup của Điều khiển, nút quét ở Cài Wi-Fi. Prop `state`: `scanning`,
> `found`, `wrongCode`, `noCamera`. Khung 844.

- **Camera** phủ cả màn (nền tối khi chưa có hình). Khung ngắm 240 × 240 tại (75, 98), bo 12, ngoài khung phủ đen 50 %; bốn góc
  34 × 34, nét 4, bo ngoài 14: `scanning` ink + vạch quét ngang 2 `clawd` có quầng; `found` mint + phủ mint 18 % + vòng 72 mint
  dấu check 44 màu `bg`; `wrongCode` coral.
- **Thanh trên** 64 (nền chuyển đen 55 % → trong): nút × 48 (`wifiScanCloseA11y`) → màn mở nó, `wifiScanTitle` 18/700 ink.
- **Bảng dưới** (`panel`, bo trên 20, đệm 20 20 28, cách 14):
  - `scanning`: ảnh màn log-on thật của thiết bị 88 × 88 bo 8 viền 1 `line`, vẽ sắc (`images/panel-setup-qr.png`, xuất từ
    `design/panel/screens/@2x/XPSetupMode.png`; nhãn `wifiScanHelpImageA11y`) + `wifiScanHelpTitle` 15/700 + `wifiScanHelpBody` 13
    inkDim; nút chữ `wifiScanManual` 13/500 `clawd` cao 44 căn giữa → Cài Wi-Fi `form`.
  - `found`: icon check 28 mint + `wifiScanFound` 15/700 + `wifiScanFoundBody` 13 inkDim. Rung nhẹ, ~0,6 s rồi tự đóng sang Cài
    Wi-Fi ở bước đúng (`working` nếu mạng đã nhớ mật khẩu, `password`, hoặc `formScanned`).
  - `wrongCode`: `wifiScanWrongTitle` 15/700 coral + `wifiScanWrongBody` 13 inkDim; nút chính `wifiScanAgain` (icon qr);
    `wifiScanManual`. Không vào Wi-Fi nào, không gửi gì.
  - `noCamera`: thay camera là nền `#0B0A0E`, giữa (trên bảng): icon camera 56 muted, `wifiScanCameraTitle` 16/700,
    `wifiScanCameraBody` 13 inkDim. Bảng: nút chính `wifiScanAllowCamera` (icon camera) → hộp xin quyền; nút viền
    `wifiScanOpenSettings` (khi bị từ chối hẳn); `wifiScanManual`.
