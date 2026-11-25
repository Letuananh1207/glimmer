# Phiếu màn thiết bị: vẽ lại các màn đang trái luật khung

- Trạng thái: đã áp (P-2026-11-25.4) — chờ thử máy
- Đã vẽ: P-2026-11-25.4
- Ngày: 2026-11-25 · Nguồn: `/panel-apply` kiểm bản đầu `P-2026-11-25.1` — người dùng chọn "gửi phiếu vẽ lại"

## Dán vào canvas

**Kênh / màn:** Home, Agents, Clock, Info, Forecast.
**Cần:** bản đầu chép đúng máy, nhưng máy đang trái luật khung ở các màn này. Vẽ lại cho đúng luật, giữ thông tin mỗi màn đang cho người nhìn biết.

1. **Home, Agents, Clock**: không có status bar, vẽ từ y 6–10 (ngoài vùng nội dung y 24–219). Hoặc thêm status bar như các kênh khác, hoặc đề xuất "màn toàn khung" là ngoại lệ có lý do (ghi dòng `Đổi luật` để phía code chốt).
2. **Home**: chữ số phút VT323-86 (x 110–177, y 6–92) chồng lên cột thời tiết phải (x ≥ 154: nhiệt độ, `c.giác`, mô tả). Bố cục mới phải tách hẳn vùng giờ và vùng thời tiết, mỗi vùng có dải xoá riêng không đè nhau. Chân trang trái (`CLAUDE BỊ TỪ CHỐI`, x 10–129) chỉ cách IP (từ x 132) 3 px — cho khe rõ ràng (IP dài nhất `192.168.100.200`).
3. **Info**: 10 dòng bước 20 từ y 36 → dòng cuối `Lần tới` ở y 216–229, quá đáy y 219. Cho vừa vùng nội dung (bớt dòng, giảm bước, hoặc gộp).
4. **Forecast**: đoạn nhiệt min→max tô chuyển màu xanh→đỏ (luật: không gradient). Thay bằng màu đặc (vd một màu nhấn, hoặc ô rời như pixelBar). Cột cuối của đoạn NAY tràn 1 px khỏi rãnh (x 220 > 219).

**Trạng thái phải vẽ:** như bản đầu của từng màn; Home thêm trạng thái thời tiết lỗi/trống (`--°`, `c.giác --`).
**Luật phải theo:** `layout.h` — nội dung chỉ y 24–219, status y 0–21; không gradient; một màu nhấn mỗi màn; đo nhãn với khe.
**Dữ liệu từ firmware:** có sẵn, không cần thêm.
**Dùng lại:** status bar (`chrome`), pixelBar, Clawd, màu kênh.
**Máy đang có:** như bản đầu `P-2026-11-25.1`.

## Ghi chú phía code
- Chặn việc: `docs/loi.md` L-1, L-2 (lỗi xoá đè ở Home) — sửa cùng lúc khi áp bản vẽ lại Home.
