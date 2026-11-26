# Phiếu thiết kế: App thành "điều khiển" thiết bị — màn thiết bị + nút điều khiển

- Trạng thái: chờ thiết kế
- Ngày: 2026-11-26 · Nguồn: yêu cầu người dùng ("app giúp người dùng tương tác điều khiển thiết bị phần cứng, chứ không như
  hiện tại"); người dùng chọn: trung tâm là màn thiết bị + nút điều khiển; giữ phong cách app hiện tại (nền tối, chữ mono)

## Dán vào canvas

**Màn / widget:** đổi cách tiếp cận cả app — tab 1 (hiện là "Màn hình" chia tab dock: `DashboardScreen`) thành **màn điều
khiển** mới; các màn khác (Skill, Cài đặt, Thiết bị, Cắt ảnh, Kết nối, Cài Wi-Fi) xếp lại quanh nó. Thiết kế quyết thanh
điều hướng dưới còn những tab nào.

**Cần:** Mở app là thấy ngay **thiết bị đang hiện gì** (một ô 240×240 vẽ lại đúng màn máy — kiểu Windows XP như thiết bị,
`design/panel/` §17) và **điều khiển được nó như một cái remote**: chuyển kênh trước / sau, nhảy thẳng tới một tab (Claude /
Ảnh / Thời tiết / Đồng hồ), dừng / tiếp tục xoay vòng, chỉnh độ sáng, bật chế độ đêm / tắt màn, làm mới số liệu, xử lý thẻ
agent đang chiếm màn. Số liệu chi tiết (mức dùng, project, thời tiết, ảnh) vẫn xem được nhưng là màn phụ, đi từ màn điều khiển.

**Trạng thái phải vẽ:**
- Đang điều khiển: ô màn thiết bị đang hiện kênh X (vd Claude), nút tab đang sáng theo kênh, thanh tiến độ slide.
- Bấm một nút: phản hồi tức thì trên app (ô màn đổi ngay), đang gửi, thiết bị không nhận (lỗi + thử lại).
- Thẻ agent đang chiếm màn thiết bị (cần duyệt / lượt bạn): ô màn hiện thẻ; nút "bỏ thẻ" (xoá khỏi màn) — **không** duyệt hộ
  (duyệt vẫn ở máy tính).
- Xoay vòng đang dừng; màn đang tắt / chế độ đêm; độ sáng đang kéo.
- Chưa kết nối / đang tìm thiết bị / thiết bị ở chế độ cài Wi-Fi (`glimmer-setup`) / firmware cũ (thiếu chức năng → nút mờ +
  gợi ý cập nhật).
- Chỉ một skill bật (ít nút tab).

**Luật phải theo:**
- R-SK-1…6 (skill bật / tắt, tab theo skill bật, Ảnh mặc định tắt).
- R-SK-3: thẻ duyệt / chờ trả lời của agent chen ngang mọi kênh trên thiết bị.
- Cài đặt (độ sáng, đêm, thời gian mỗi kênh, xoay vòng) đổi trên app → gửi `/api/settings`, thiết bị áp ngay.

**Dữ liệu từ thiết bị (có sẵn):**
- `GET /api/state`: `active_channel`, `skills_on`, `night_face`, `claude_usage`, `projects`, `weather`, `photos`, `time`, …
- `POST /api/channel {"action":"next"}` (kênh sau) · `{"name":"Weather"}` (nhảy tới kênh) — trả `active`.
- `POST /api/refresh` (làm mới số liệu) · `GET/POST /api/settings` (`brightness`, `autoRotate`, `channelSec`, `nightMode`…)
  · `GET /push` + `POST /push/clear` (thẻ agent) · `POST /api/reboot`.
- **Chưa có — phía firmware làm khi áp:** kênh **trước**; **dừng xoay tạm thời** (không đổi cài đặt lưu); **tắt / bật màn**
  ngay (không đợi giờ đêm); thời gian còn lại của slide hiện tại (để thanh tiến độ trên app khớp máy); bỏ một thẻ theo id
  (có `clear_card` ở MCP — cần lộ qua HTTP nếu chưa).
- Ô màn thiết bị: thiết bị **không gửi được ảnh màn** (không đọc ngược được màn hình) → app tự vẽ lại kênh từ dữ liệu
  `/api/state` theo kiểu XP của thiết bị (`design/panel/` §17). Thiết kế quyết mức chi tiết (đúng từng px, hay bản thu gọn
  giữ dáng cửa sổ XP + số chính).

**Chuỗi:** có sẵn `navHome`, `homeShowOnDevice`, `dashboard…`, `skills…`, `settings…`, `commonRetry`. Cần mới: tên các nút
điều khiển (trước, sau, dừng / tiếp tục xoay, tắt màn, làm mới, bỏ thẻ), trạng thái (đang gửi, thiết bị không nhận, xoay
đang dừng, màn đang tắt), nhãn độ sáng.

**Dùng lại:** `DockTabBar` (tab skill), `ShowOnDeviceButton`, thanh báo trạng thái, `SkillRow`, `CountBadge`, Clawd, token màu
skill; icon dock (`icons/dock-*.svg`); toàn bộ màn số liệu hiện có (tab Agent / Thời tiết / Đồng hồ / Ảnh) chuyển thành màn phụ.

**Gợi ý (không bắt buộc):** ô màn thiết bị chiếm nửa trên, khung như cái máy SmallTV thật; dưới là "d-pad" ‹ ›, hàng nút tab
skill (icon dock), thanh trượt độ sáng, nút tròn tắt màn / đêm; vuốt trái-phải trên ô màn = kênh trước / sau; chạm ô màn = mở
chi tiết kênh đó.

**App đang có:** tab 1 "Màn hình" = các tab Agent / Ảnh / Thời tiết / Đồng hồ hiện số liệu + nút "Hiện … trên thiết bị" ở
cuối mỗi tab (điều khiển chỉ là phụ).

## Ghi chú phía code
- Firmware cần thêm (khi áp): `POST /api/channel {"action":"prev"}`, dừng xoay tạm (`{"action":"pause"|"resume"}`), tắt / bật
  màn ngay, `slide_left_ms` trong `/api/state`, bỏ thẻ theo id qua HTTP. Những thay đổi này phải theo Windows XP thật nếu có
  phần hiện trên màn thiết bị (vd. biểu tượng "tạm dừng" ở khay).
