# Phiếu màn thiết bị: Calculator (Máy tính bỏ túi)

- Trạng thái: đã vẽ (P-2026-11-28.31) — chờ áp
- Đã vẽ: P-2026-11-28.31
- Ngày: 2026-11-27 · Nguồn: lộ trình `app/docs/tasks/2026-11-27-chuong-trinh-xp-con-thieu.md` (bạn đồng ý 2026-11-27), mục 5

## Dán vào canvas

**Kênh / màn:** kênh mới `Calc` — cửa sổ XP "Calculator" ("Máy tính bỏ túi"), chế độ Standard. Thuộc skill Giải trí
`fun` hay một skill "Phụ kiện" mới (XP: Start › All Programs › Accessories) — thiết kế đề xuất. Có mục Start; biểu
tượng desktop thì không (XP không có).

**Cần:** Bấm phép tính bằng chuột của app (click nút) hoặc phím số của app, thấy kết quả như Calculator của XP.

**Trạng thái phải vẽ (theo XP thật):**
- Thanh menu XP (Sửa · Xem · Trợ giúp — giữ hay bỏ, thiết kế quyết).
- Ô hiển thị trắng, số căn phải (khoảng 12 chữ số vừa 220 px), "0." lúc đầu.
- Hàng Backspace · CE · C (chữ đỏ như XP); MC MR MS M+ (chữ đỏ) bên trái; lưới 7 8 9 / sqrt · 4 5 6 * % · 1 2 3 - 1/x
  · 0 +/- . + = (số xanh dương, phép tính đỏ). Ô "M" nhỏ khi có bộ nhớ.
- Nút đang nhấn (lõm), nút hover dưới con trỏ (giữ như XP hoặc viền cam như nút XP Luna; thiết kế quyết).
- Lỗi: "Không thể chia cho 0." như XP.
- Nút đủ to để con trỏ trúng (≥ 20 × 18 px; 6 cột × ~34 px vừa thân 220 px).

**Luật phải theo:**
- Theo XP thật (người dùng yêu cầu 2026-11-26): tính từ trái sang phải như Standard XP (không ưu tiên nhân chia), `=`
  lặp lại phép cuối.
- App là bộ xử lý (như Dò mìn: app giữ phép tính, gửi chuỗi hiển thị + nút đang nhấn); thiết bị chỉ vẽ.
- Partial redraw: bấm một nút chỉ vẽ lại nút đó + ô hiển thị.

**Dữ liệu từ firmware:** chưa có — cần kiểu `POST /api/calc {display, mem, down}` (phía code làm).

**Chữ:** "Máy tính bỏ túi", "Sửa", "Xem", "Trợ giúp", "Backspace", "CE", "C", "Không thể chia cho 0.". Số / ký hiệu đo
theo JBMono-12B.

**Dùng lại:** `XP::window`, nút XP (`BTN_*`, bevel của Dò mìn), `XP::field` (ô hiển thị).

**Máy đang có:** chưa có.
