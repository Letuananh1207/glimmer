# Widget dùng chung — app glimmer

> **2026-11-25.1 — Bản đầu:** ghi lại các widget app đang dùng. Màu theo tên token.

| Widget | Mô tả |
|---|---|
| `Clawd` | Linh vật 18 × 10 ô, màu `clawd`, vẽ sắc cạnh; rộng tùy chỗ (144 / 120 / 72), cao = rộng × 10/18. Biểu cảm: `open`, `wide`, `happy`, `sad`, `sleep`; `walking` đổi chân mỗi 450 ms; chớp mắt mỗi ~4 s khi mắt mở. |
| Nút chính (FilledButton) | Cao ≥ 40, bo 20, nền `clawd`, chữ `bg` 14/500, icon 18 cách 8, đệm 16 trái 24 phải. Tắt: nền ink 12%, chữ ink 38%. Nhãn dài xuống dòng, nút cao lên. |
| Nút viền (OutlinedButton) | Như nút chính, nền trong, viền 1 `outline`, chữ `clawd`. |
| Nút tonal | Như nút chính, nền mint, chữ đen (mặc định Flutter, chưa chọn có chủ đích). |
| Nút chữ (TextButton) | Cao 40, đệm ngang 12, chữ `clawd` (12 trong tiêu đề thẻ, 14 ở chỗ khác). |
| Thẻ (Card) | Nền `panel`, bo 14, lề 16 ngang 6 dọc, không bóng. Thẻ nhấn mạnh: nền `panel2`. |
| Nhãn thẻ | `label` IN HOA (MỨC DÙNG CLAUDE, PROJECT…). |
| Dòng danh sách (ListTile) | Cao 56 (1 dòng) / 72 (2 dòng); icon đầu 24 ink cách 16; tiêu đề 16 ink; phụ 12 muted; đệm 16 trái 24 phải. Tắt: mờ 38%. |
| Công tắc (Switch) | 52 × 32. Bật: rãnh `clawd`, nút 24 màu `bg`. Tắt: rãnh `panel`, viền 2 `outline`, nút 16 `outline`. |
| Thanh trượt | Rãnh 4, phần đã chọn `clawd`, phần còn lại `clawd` 24%, nút 20. |
| Chọn (Dropdown) | Chữ 16 + mũi tên 24, gạch dưới 1 #BDBDBD. |
| Ô nhập | Viền 1 `outline`, bo 4, cao 56, chữ 16; nhãn nổi 12 `inkDim` khi có giá trị. Ô mật khẩu có nút mắt 48. |
| Thanh % mức dùng | Bo 3, nền `panel2`; cao 8 (tuần) / 5 (phiên); màu theo % còn lại. |
| Thanh điều hướng dưới | **2026-11-25.3:** tab 1 = **Màn hình** (`navHome`, icon `icons/nav-home.svg`) cho mọi skill, huy hiệu amber 16×16 bo 4 số agent chờ ở góc icon (ẩn khi 0). Còn lại như dưới. **2026-11-25.2:** cao 80, nền `panel`, **4 tab** chia đều: (1) màn chính của skill đang dùng — nhãn = tên skill, icon = icon skill (Agent: Clawd 24 không mắt; khi chọn tô `clawd`); (2) `navSkills`, icon apps; (3) `navSettings`, tune; (4) `navDevice`, memory. Tab đang chọn: viên 64 × 32 bo 16 nền `panel2`, icon ink (bỏ icon đen của bản đầu), nhãn 12/700 ink; tab khác: nhãn 12/500 inkDim. |
| Hộp thoại | Nền `panel`, bo 28, đệm 24, tiêu đề 24/400, nút căn phải. Lớp phủ `scrim`. |
| Vòng xoay | 40, nét 4, `clawd`. |
| `SkillTile` | **2026-11-25.3: bỏ** — thay bằng `SkillRow`. **2026-11-25.2:** ô skill trong lưới màn Skill — 4 kiểu: đang dùng / chọn được / đang đổi / sắp có. Số đo ở `screen_specs.md` §6. Màu nhấn theo skill: `skillAgent`, `skillMusic`, `skillSocial`, `skillFun`. |
| Thanh báo trạng thái | **2026-11-25.2:** thẻ `panel2` đầu màn: tiêu đề 14/700 màu loại (coral lỗi, amber cảnh báo) hoặc vòng xoay 24 + chữ 14 ink; thân 13 inkDim; nút căn phải hoặc nút viền. |
| `DockTabBar` | **2026-11-25.3:** thanh tab của Màn hình, giống dock thiết bị nằm ngang. Số đo `screen_specs.md` §2. Tab = skill đang bật theo thứ tự dock; tab đang chọn nền `panel2` + vạch màu nhấn 20×3; tab Agent mang huy hiệu amber. Ẩn khi chỉ một skill bật. |
| `SkillRow` | **2026-11-25.3:** dòng skill trong thẻ danh sách màn Skill: ô icon 44 + tên / mô tả + `SkillSwitch` (hoặc vòng xoay khi đang gửi, ổ khoá khi firmware cũ). §6. |
| `SkillSwitch` | **2026-11-25.3:** công tắc tô theo màu nhấn của skill (không phải `clawd` chung): rãnh 52×32, vùng chạm 60×48. §6. |
| `ShowOnDeviceButton` | **2026-11-25.3:** nút cuối mỗi tab của Màn hình — rộng hết, cao 48, bo 14, nền `panel2`, icon tv + "Hiện {skill} trên thiết bị". Thay hai nút xanh đặc. §2. |
| Icon dock | **2026-11-25.3:** `icons/dock-clawd.svg`, `dock-weather.svg`, `dock-clock.svg`, `dock-chat.svg` — bitmap đúng của dock thiết bị (`panel/tokens/panel_tokens.json` → `component.dock.icon`), tô `currentColor`, vẽ sắc cạnh (crispEdges), phóng ×1–×3.5. |
