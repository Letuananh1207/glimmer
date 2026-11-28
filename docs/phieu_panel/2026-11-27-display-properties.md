# Phiếu màn thiết bị: Display Properties (Thuộc tính màn hình)

- Trạng thái: đã vẽ (P-2026-11-28.30) — chờ áp
- Đã vẽ: P-2026-11-28.30
- Ngày: 2026-11-27 · Nguồn: lộ trình `app/docs/tasks/2026-11-27-chuong-trinh-xp-con-thieu.md` (bạn đồng ý 2026-11-27), mục 4

## Dán vào canvas

**Kênh / màn:** kênh mới `Display` — property sheet XP "Display Properties" ("Thuộc tính màn hình"). Mở bằng chuột phải
desktop › Thuộc tính (menu desktop đã có, mục này nay mở được), Start › Bảng điều khiển (nếu thiết kế thêm).

**Cần:** Đổi giao diện màn ngay trên thiết bị bằng chuột: chọn hình nền, chế độ bảo vệ màn hình (mặt đêm) và giờ của
nó, độ sáng, tối khi rảnh — như Đồng hồ (Date and Time Properties) đã làm.

**Trạng thái phải vẽ (theo XP thật):**
- Các tab như XP: **Màn nền** (Desktop), **Bảo vệ màn hình** (Screen Saver), **Cài đặt** (Settings). XP còn Themes,
  Appearance — đề xuất bỏ; thiết kế quyết.
- Tab Màn nền: màn CRT nhỏ xem trước (như XP: khung máy tính có hình nền thu nhỏ) + danh sách hình nền ("(Không)", hình
  mặc định, ảnh của bạn `/wallpaper.jpg`), một mục chọn; nút "Duyệt..." (mờ — ảnh gửi từ app).
- Tab Bảo vệ màn hình: xem trước mặt đêm trong khung CRT, danh sách chế độ ("(Không)", Tối dần, Đồng hồ, Tắt màn) =
  `nightMode` 0–3, giờ Bắt đầu / Kết thúc (field read-only như Đồng hồ), hộp kiểm "Tối khi rảnh 15 phút" (`idleDim`).
- Tab Cài đặt: thanh trượt "Độ sáng" kiểu XP (Ít → Nhiều), "Đảo màu" (`invertDisplay`), dòng "240 × 240, 16 bit".
- Nút OK / Hủy / Áp dụng của property sheet (XP); mục đang hover dưới con trỏ.

**Luật phải theo:**
- Theo XP thật (người dùng yêu cầu 2026-11-26).
- Cài đặt vẫn lưu một chỗ (`/config.json`); app gửi `POST /api/settings` như màn Cài đặt của app — Display Properties
  chỉ là chỗ khác để chỉnh, hai bên phải khớp.
- Partial redraw: đổi một mục chỉ vẽ lại mục đó + khung xem trước.
- An toàn khi vẽ lại ô dưới con trỏ; ảnh xem trước giải mã thu 1/4 (TJpgDec) và có `clipHits`.

**Dữ liệu từ firmware:** đã có trong settings: `brightness`, `nightMode`, giờ đêm, `idleDim`, `invertDisplay`,
hình nền (`/api/wallpaper`). Chưa có: nhiều hình nền để chọn (hiện chỉ một file) — thiết kế quyết có cần không.

**Chữ:** "Thuộc tính màn hình", "Màn nền", "Bảo vệ màn hình", "Cài đặt", "Hình nền", "(Không)", "Duyệt...", "Bắt đầu",
"Kết thúc", "Tối khi rảnh", "Độ sáng", "Ít", "Nhiều", "Đảo màu", "OK", "Hủy", "Áp dụng". Đo theo JBMono.

**Dùng lại:** `XP::tabs`, `XP::field`, `XP::groupBox`, danh sách Múi giờ của Đồng hồ, mặt đêm (`XPCore::saverSpot`),
hình nền dự phòng `desk_wallpaper.h`.

**Máy đang có:** chưa có; mục Thuộc tính của menu desktop chưa mở gì.
