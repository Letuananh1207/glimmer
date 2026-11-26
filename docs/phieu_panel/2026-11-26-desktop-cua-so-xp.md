# Phiếu màn thiết bị: Desktop theo skill, cửa sổ thu nhỏ / phóng to / tắt, menu chuột phải — như Windows XP

- Trạng thái: đã áp (P-2026-11-26.14, P-2026-11-26.15)
- Đã vẽ: P-2026-11-26.14, P-2026-11-26.15 (bong bóng thời tiết tạm + biểu tượng khay)
- Ngày: 2026-11-26 · Nguồn: thiết kế app `2026-11-26.6` (màn Điều khiển chạm được như XP, mục "Cần thiết kế màn thiết
  bị"); kế hoạch `app/docs/tasks/2026-11-26-thiet-ke-2026-11-26.6.md`. Người dùng chốt: thiết bị **không tự xoay** nữa.

## Dán vào canvas

**Kênh / màn:** `Home` (desktop XP), khung cửa sổ XP của mọi kênh (`XP::window`), thanh tác vụ — không phải kênh mới.
**Cần:** Máy trông và cư xử như một màn Windows XP mà app điều khiển bằng chạm (app = máy tính, thiết bị = màn hình):
1. **Desktop có một biểu tượng cho mỗi skill đã cài** (Agent, Ảnh, Thời tiết, Đồng hồ, sau này Tin nhắn, Nhạc…), xếp như
   XP thật (cột từ trên xuống, bên trái, rồi sang cột kế); biểu tượng **đang chọn** (XP: nhãn nền xanh chọn, viền chấm) —
   dùng khi vừa cài một skill và khi người dùng vừa chạm biểu tượng.
2. **Cửa sổ thu nhỏ**: cửa sổ biến mất, desktop hiện ra, nút của nó **vẫn ở thanh tác vụ** (XP: nút không nhấn).
   **Tắt (×)**: nút biến khỏi thanh tác vụ, máy về cửa sổ trước đó (hết → desktop). **Phóng to (□)**: cửa sổ trên máy
   vốn đã đầy màn — vẽ theo XP thật (nút □ ↔ nút khôi phục) hoặc quyết định bỏ hiệu ứng.
3. **Menu chuột phải** (giữ ≥ 500 ms trên app): như menu ngữ cảnh XP — trên desktop (vd. Sắp xếp biểu tượng, Làm mới,
   Thuộc tính), trên nút thanh tác vụ (Khôi phục, Thu nhỏ, Đóng), trên thanh tiêu đề cửa sổ.
4. **Bỏ vạch tiến độ slide** ở đáy nút thanh tác vụ đang nhấn (không còn xoay).
**Trạng thái phải vẽ:** desktop với 1, 3, 5 skill · biểu tượng đang chọn · desktop có cửa sổ thu nhỏ (nút thanh tác vụ
không nhấn) · một cửa sổ đang mở với nút thanh tác vụ nhấn, không vạch · menu chuột phải trên desktop / nút thanh tác vụ
/ thanh tiêu đề · bong bóng thời tiết không bị biểu tượng che.
**Luật phải theo:** XP thật cho mọi chỗ đặc tả im lặng. Thẻ agent (duyệt / câu hỏi / lỗi) vẫn chen ngang mọi cửa sổ;
mặt đêm không có thanh tác vụ. Thanh tác vụ do `main.cpp` vẽ, kênh không vẽ. Vùng chạm do app nới 44 dp quanh tâm, máy
không cần nút to hơn XP. Không hiệu ứng chuyển (thu nhỏ / phóng to là cắt ngay, không có hoạt hình "bay" về thanh tác vụ).
**Dữ liệu từ firmware:** `skills_on` (skill đã cài), `active_channel`. Cần thêm (ghi "Cần firmware"): danh sách cửa sổ
đang mở + cửa sổ trên cùng + cửa sổ thu nhỏ (app gửi xuống, máy báo lại trong `/api/state`); lệnh thu nhỏ / đóng / mở
menu; tắt tự xoay.
**Chữ:** nhãn biểu tượng = tên skill (Agent? hay Claude?) — đo với cột 80 px, JBMono-11; mục menu ngữ cảnh tiếng Việt
(đo với bề rộng menu).
**Dùng lại:** desktop hiện có (`XP-Desktop`, hình nền, bóng chữ), icon dock của taskbar, `XP::window`, màu `xpSelect`.
**Gợi ý (không bắt buộc):** thiết kế app (`design/source/Control.dc.html`, trạng thái `minimized` / `installed` /
`tapIcon`) đang vẽ lớp minh hoạ: biểu tượng trắng bóng đen tâm x 40 rồi x 122, bước 46.
**Máy đang có:** desktop cố định 4 biểu tượng (Claude %, Codex %, Ảnh, Thùng rác), cửa sổ luôn phóng to, xoay vòng có
vạch tiến độ trên nút thanh tác vụ; app hiện đã chạm được (app đổi chạm ra `/api/channel {name}`), `_` = về desktop.
