# Phiếu màn thiết bị: My Computer / Explorer + mở Thùng rác

- Trạng thái: đã áp (P-2026-11-28.32)
- Đã vẽ: P-2026-11-28.32
- Ngày: 2026-11-27 · Nguồn: lộ trình `app/docs/tasks/2026-11-27-chuong-trinh-xp-con-thieu.md` (bạn đồng ý 2026-11-27), mục 3

## Dán vào canvas

**Kênh / màn:** kênh mới `Explorer` — cửa sổ XP Explorer dùng chung cho "My Computer" ("Máy tính"), thư mục Ảnh và
"Thùng rác". Mở bằng: biểu tượng desktop "Máy tính" (mới), Start › Máy tính (cột phải XP có), biểu tượng Thùng rác
(nay mở được), Start › Ảnh của tôi.

**Cần:** Người nhìn thấy thiết bị chứa gì: ổ nhớ còn trống bao nhiêu, ảnh mẫu và ảnh của bạn, hình nền, ảnh đã xoá.
Mở một ảnh (sang cửa sổ Ảnh), xoá ảnh (vào Thùng rác), khôi phục / dọn Thùng rác — bằng chuột của app.

**Trạng thái phải vẽ (theo XP thật):**
- My Computer: thanh địa chỉ "Máy tính" (XP có toolbar Back / Up / Views — giữ tối thiểu hay bỏ, thiết kế quyết), nhóm
  "Ổ đĩa": ổ "Bộ nhớ (C:)" với thanh dung lượng + "trống x KB / 1 MB" (LittleFS); nhóm "Thư mục": Ảnh của tôi, Hình nền.
- Thư mục Ảnh: chế độ Thumbnails của XP (xem giới hạn dưới) hoặc Icons / Details (tên `p1.jpg`, cỡ KB, "Ảnh mẫu" /
  "Ảnh của bạn"); một mục được chọn; rỗng.
- Thùng rác: rỗng (biểu tượng thùng rỗng) / có mục (biểu tượng đầy, đổi cả biểu tượng desktop như XP); "Dọn sạch Thùng
  rác", "Khôi phục".
- Hộp thoại xác nhận XP "Bạn có chắc muốn xoá ...?" (Có / Không) — `XP::dialog`.
- Thanh trạng thái: "N đối tượng · x KB".
- Mục được chọn / hover dưới con trỏ như XP.

**Luật phải theo:**
- Theo XP thật (người dùng yêu cầu 2026-11-26).
- Kho ảnh nay ở app (R-AK-*, `photo_source`): thiết bị chỉ giữ `p<N>.jpg` (8 ảnh mới nhất của app) + ảnh mẫu; thiết kế
  ghi rõ có hiện ảnh trong kho của app không.
- Thiết bị **không co ảnh tuỳ ý**: TJpgDec chỉ thu 1/2, 1/4, 1/8 → ảnh 188 px thành 94 / 47 / 23 px. Thumbnails dùng ô
  47 px là rẻ nhất.
- Heap ~25 KB: vẽ từng ảnh khi cần, an toàn khi vẽ lại dưới con trỏ (mỗi thumbnail có `clipHits` riêng).
- App là bộ xử lý: click / chọn / xoá do app tính và gửi lệnh.

**Dữ liệu từ firmware:** có `photos`, `photo_samples`, `wallpaper` trong `/api/state`; `GET /api/photos`. Chưa có: dung
lượng FS tổng / trống, Thùng rác (xoá = chuyển vào `/trash/`?) — phía code làm.

**Chữ:** "Máy tính", "Bộ nhớ (C:)", "Ổ đĩa", "Thư mục", "Ảnh của tôi", "Hình nền", "Thùng rác", "Dọn sạch Thùng rác",
"Khôi phục", "đối tượng", "trống", "Ảnh mẫu", "Ảnh của bạn". Đo theo JBMono.

**Dùng lại:** `XP::window`, `XP::progress` (thanh dung lượng), ListView Details (Dự báo), `XP::dialog`, biểu tượng Thùng
rác 32×23 của desktop (cần thêm bản đầy), biểu tượng Ảnh.

**Máy đang có:** Thùng rác chỉ là biểu tượng desktop, mở không được; chưa có My Computer.
