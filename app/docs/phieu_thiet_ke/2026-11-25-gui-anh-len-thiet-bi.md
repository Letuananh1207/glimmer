# Phiếu thiết kế: Skill Ảnh — gửi ảnh từ điện thoại lên thiết bị

- Trạng thái: chờ thiết kế
- Đã vẽ: 2026-11-25.4
- Ngày: 2026-11-25 · Nguồn: yêu cầu người dùng ("nạp ảnh lên qua app"); firmware skill Ảnh đã có (thiết kế màn
  thiết bị `P-2026-11-25.7`, ảnh `design/panel/screens/@2x/Photo.png`, `PhotoEmpty.png`)

## Dán vào canvas

**Màn / widget:** skill mới **Ảnh** trong app: dòng skill trên màn Skill (`SkillsScreen`, `SkillRow`) + tab **Ảnh**
trên Màn hình (`DashboardScreen`, `DockTabBar` — thứ tự dock: Agent, Ảnh, Thời tiết, Đồng hồ) + luồng chọn / cắt /
gửi ảnh (màn mới hoặc bottom sheet — thiết kế quyết).

**Cần:** Người dùng chọn ảnh trong thư viện điện thoại (hoặc chụp), cắt vuông (chọn vùng), xem trước đúng như trên
màn thiết bị 188×188, rồi gửi lên. Thấy danh sách ảnh đang có trên thiết bị (tối đa 8), xoá từng ảnh, biết còn bao
nhiêu chỗ. Bật / tắt skill Ảnh như các skill khác; gợi ý bật khi đã có ảnh mà skill đang tắt.

**Trạng thái phải vẽ:**
- Tab Ảnh: chưa có ảnh (gợi ý thêm ảnh); có ảnh (lưới ảnh, ảnh nào đang hiện trên thiết bị nếu biết); đủ 8 ảnh (nút
  thêm khoá, nói phải xoá bớt); skill Ảnh đang tắt (có ảnh nhưng thiết bị không xoay — nút bật).
- Cắt ảnh: khung vuông kéo / phóng; xem trước 188×188.
- Gửi: đang gửi (tiến độ), xong, lỗi — đầy (`full`), ảnh quá lớn (`too_big`, app tự giảm chất lượng trước khi báo),
  hết chỗ (`no_space`), thiết bị không nhận (`not_jpeg` / `progressive` / `bad_size` — lỗi của app, chỉ báo chung),
  mất kết nối.
- Xoá ảnh: hỏi lại trước khi xoá; đang xoá; lỗi.
- Firmware cũ (không có `photos` trong `/api/state`): skill Ảnh "cần cập nhật firmware", nút sang tab Thiết bị.

**Luật phải theo:**
- R-SK-1: nhiều skill bật cùng lúc, ít nhất một; mặc định Agent + Thời tiết + Đồng hồ — **Ảnh mặc định tắt**
  (firmware chọn 2026-11-25).
- R-SK-2: bật / tắt → gửi `skillsOn`; skill app chưa có gói vẫn giữ nguyên khi gửi.
- R-SK-3: thẻ duyệt của agent vẫn chen ngang mọi skill.
- Ảnh trên thiết bị mất khi nạp filesystem (cập nhật "đầy đủ" ở tab Thiết bị) — nên nhắc ở đâu đó (thiết kế quyết).

**Dữ liệu từ thiết bị (đã có, firmware mới):**
- `GET /api/photos` → `{photos:[{name,size}], free, total, max_count: 8, max_bytes: 40960, reserve, side: 188}`.
- `POST /api/photos` multipart trường `photo` → `{ok, name, count}`; lỗi `{error, count}`: `full` / `too_big` (413),
  `no_space` (507), `not_jpeg` / `progressive` / `bad_size` / `truncated` / `empty` (400), 401 sai token.
- `DELETE /api/photos?name=p3.jpg` → `{ok, count}`.
- `/api/state` → `photos` (số ảnh), `skills` có `photo`, `skills_on`.
- **Chưa có:** tải lại ảnh từ thiết bị để làm hình thu nhỏ (`GET` một ảnh) và ảnh nào đang hiện — nếu thiết kế cần
  lưới ảnh thật, phía code thêm `GET /api/photos/<name>` (firmware) hoặc app giữ bản sao ảnh đã gửi.

**Chuỗi:** có sẵn `commonRetry`, `commonCancel`, `skills…`, `homeShowOnDevice`. Cần mới: tên / mô tả skill Ảnh, tiêu
đề tab, thêm ảnh, cắt ảnh, gửi, xoá, các lỗi trên, "còn N chỗ", nhắc ảnh mất khi cập nhật đầy đủ.

**Dùng lại:** `SkillRow` + `SkillSwitch`, `DockTabBar` (tab Ảnh, icon `dock-photo` theo dock thiết bị — token
`component.dock.icon.photo` trong `design/panel/tokens/panel_tokens.json`), `ShowOnDeviceButton` ("Hiện Ảnh trên thiết
bị" → kênh `Photo`), thanh báo trạng thái, màu nhấn mint (kênh Ảnh trên thiết bị là MINT).

**Gợi ý (không bắt buộc):** lưới 2–3 cột ảnh vuông, ô cuối là "+ Thêm ảnh"; cắt ảnh toàn màn kiểu ảnh đại diện.

**App đang có:** chưa có gì (ảnh chỉ gửi được qua trang web thiết bị).

## Ghi chú phía code
- Phần không dính giao diện làm trước được nếu người dùng muốn: service / repository gọi 3 API ảnh, xử lý ảnh (cắt
  vuông, thu nhỏ 188×188, mã hoá JPEG **baseline** ≤ 40 KB, giảm chất lượng dần), use case gửi / xoá, test.
- Thư viện dự kiến: `image_picker` (chọn ảnh), `image` (thu nhỏ + mã hoá JPEG baseline); phần cắt theo thiết kế.
