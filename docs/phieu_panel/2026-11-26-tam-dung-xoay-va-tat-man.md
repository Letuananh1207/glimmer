# Phiếu màn thiết bị: Báo "đang tạm dừng xoay" và "màn tắt từ app" trên thiết bị

- Trạng thái: bỏ (thiết kế app 2026-11-26.6: thiết bị không tự xoay nữa, không còn lệnh tạm dừng; phần desktop / cửa sổ sang phiếu `2026-11-26-desktop-cua-so-xp.md`)
- Ngày: 2026-11-26 · Nguồn: thiết kế app `2026-11-26.5` (màn Điều khiển, dòng "Cần firmware") — app ra lệnh dừng / tiếp
  tục xoay, tắt / bật màn; máy cần cho người đứng trước nó biết.

## Dán vào canvas

**Kênh / màn:** thanh tác vụ (khay, mọi màn có cửa sổ XP) — không phải kênh mới.
**Cần:** Người nhìn máy biết **xoay vòng đang bị tạm dừng** (từ app) — nếu không họ tưởng máy treo ở một kênh. Khi app bật
lại màn vừa tắt, không cần báo gì thêm.
**Trạng thái phải vẽ:** khay khi xoay bình thường (như hiện tại) · khay khi đang tạm dừng · (nếu thiết kế thấy cần) lúc vừa
dừng: bong bóng khay XP thật kiểu "Đã tạm dừng xoay kênh — tiếp tục từ app glimmer" vài giây.
**Luật phải theo:** dừng xoay là tạm (mất khi khởi động lại), không đổi cài đặt `autoRotate`; thẻ agent cần duyệt vẫn chen
ngang khi đang dừng; thanh tiến độ slide ở đáy nút đang hiện **không chạy** khi dừng.
**Dữ liệu từ firmware:** có cờ "đang dừng" (thêm cùng lệnh `pause`/`resume`), giờ ở khay.
**Chữ:** nếu có bong bóng: tiêu đề + 1 dòng, ≤ bề ngang bong bóng khay hiện có (136 px, P-2026-11-26.12).
**Dùng lại:** khay giờ (x 196–239), bong bóng vàng của màn desktop (P-2026-11-26.12), icon 16 px kiểu khay XP.
**Gợi ý (không bắt buộc):** theo **Windows XP thật**: icon nhỏ ở khay cạnh giờ (như icon "tạm dừng" của trình phát / icon
thông báo khay), di chuột không có nên chỉ icon + bong bóng khay lần đầu (kiểu "balloon tip" XP có nút đóng ×).
**Máy đang có:** chưa có — firmware tạm dừng xoay mà không hiện gì.
