# Phiếu màn thiết bị: con trỏ chuột, mục đang sáng, tắt máy

- Trạng thái: chờ thiết kế
- Ngày: 2026-11-27 · Nguồn: kế hoạch `app/docs/tasks/2026-11-27-app-la-chuot-ban-phim-nguon.md` (bạn duyệt 2026-11-27)

## Dán vào canvas

**Kênh / màn:** mọi màn có XP (desktop, mọi cửa sổ, thanh tác vụ, menu chuột phải, Start menu) + màn hệ thống mới
"đang tắt máy" (`display.cpp`, cạnh boot / welcome / log-on).

**Cần:** App điện thoại thành **chuột + bàn phím + nút nguồn**, thiết bị là **màn hình** — người dùng không còn thấy
màn trên điện thoại, chỉ nhìn thiết bị. Màn phải cho thấy **con trỏ đang ở đâu và trỏ vào gì**, mục nào của menu /
Start đang được chọn (chuột đứng trên hoặc phím mũi tên), và việc tắt / bật máy — **như Windows XP thật**.

**Trạng thái phải vẽ:**
1. **Con trỏ XP** ở px thật trên màn 240 × 240 (bản thật 32 × 32 / mũi tên ~12 × 19, quá to trên màn nhỏ? — chọn cỡ
   đọc được ở khoảng cách bàn làm việc). Ba hình như XP: **mũi tên** (trắng viền đen), **bàn tay** chỉ (trên link / nút
   bấm được), **đồng hồ cát** (đang chờ — cửa sổ vừa mở, đã có "wait cursor" trong `XP::emptyFrame`; thống nhất làm một).
   Điểm nóng (hotspot) của từng hình. Con trỏ trên mọi nền: desktop (hình nền JPEG / pixel), thân cửa sổ beige, thanh
   tiêu đề xanh, thanh tác vụ, menu.
2. **Mục sáng (hover)**: menu chuột phải (desktop / cửa sổ, `xp_menu`) và Start menu (P-2026-11-26.20, hai cột + Tất
   cả chương trình) — mục dưới con trỏ / đang chọn bằng phím vẽ kiểu XP (nền xanh chọn, chữ trắng); mục mờ không sáng.
   Nút thanh tác vụ / nút cửa sổ khi con trỏ đứng trên: XP có sáng nhẹ (hot) — vẽ hay không, thiết kế quyết.
3. **Màn "đang tắt máy"** kiểu XP: XP hiện "Windows is shutting down..." (nền xanh, logo) rồi tắt. Bản tiếng Việt,
   ~2 s, rồi đèn tắt. Thiết bị vẫn chạy (thẻ agent khẩn vẫn đánh thức như "tắt màn" hiện nay).
4. **Khởi động lại khi bật**: dùng màn boot hiện có (cờ, logo, hộp 3 khối) → welcome → desktop trống — xác nhận
   hay cần thêm.
5. (Tuỳ, theo XP thật) **Alt+F4 trên desktop** → hộp "Tắt máy tính" (Turn off computer: Đứng / Tắt / Khởi động lại).
   Thiết kế quyết có làm không; có thì vẽ hộp + mục đang chọn.

**Luật phải theo:**
- XP thật là chuẩn (người dùng yêu cầu 2026-11-26): con trỏ, mục sáng, màn tắt máy đúng như XP làm.
- Partial redraw: con trỏ vẽ đè có lưu nền (≤ 32 × 32 px), kênh vẽ lại thì ẩn con trỏ rồi hiện lại — **không** vẽ
  lại cả màn khi chuột di. RAM rất ít (~2 KB cho phần nền dưới con trỏ là tối đa).
- Không hiệu ứng chuyển (trừ hai cái đã duyệt). Night face, màn hệ thống: không con trỏ.
- App chọn hình con trỏ và mục sáng; thiết bị chỉ vẽ.

**Dữ liệu từ firmware:** đang thêm — vị trí + hình con trỏ qua UDP; `/api/menu` thêm `hover` (chỉ số mục); `/api/power
{on}` và `/api/state` `power` (`on` / `shutting` / `off` / `booting`).

**Chữ:** màn tắt máy: "Đang tắt máy..." (hoặc theo XP Việt hoá: "Windows đang tắt..."). Hộp Tắt máy tính (nếu làm):
"Tắt máy tính", "Đứng", "Tắt", "Khởi động lại", "Huỷ". Đo theo khe font JBMono đã đóng gói.

**Dùng lại:** `Theme::XP` (xanh chọn của menu / Start), `xp_menu`, Start menu P-.20, màn boot / welcome (§ màn hệ thống),
`XP::dialog` cho hộp Tắt máy tính.

**Gợi ý (không bắt buộc):** con trỏ cỡ ~11 × 17 (mũi tên XP thu nhỏ còn đọc được ở 240 px); bóng đổ của con trỏ XP bỏ
(tốn nền lưu).

**Máy đang có:** chưa có con trỏ; Start / menu chuột phải chỉ vẽ, không có mục sáng; "Tắt màn" chỉ tắt đèn
(`/api/screen`), không có màn tắt máy.
