# Quy tắc nghiệp vụ đã xác nhận

Nguồn sự thật cho test: mỗi test ghi mã quy tắc nó kiểm (`R-…`). Sửa quy tắc → sửa file này trước, rồi test, rồi code.
`dart tool/rule_trace.dart` đọc các dòng bảng `| R-<VÙNG>-<số> | … | App |` ở đây.

Cột **App**: `ok` = code đã chạy đúng · `sửa` = code phải đổi theo quy tắc (test viết trước, đỏ tới khi sửa) ·
`tk` = code đúng, chỉ thiết kế ghi sai · thêm "miễn test (<lý do>)" khi không kiểm được bằng test.

"Ngày" luôn là ngày lịch theo giờ máy người dùng, sang ngày mới lúc 00:00.

Các quy tắc dưới đây ghi lại hành vi app đang có lúc chuyển sang MVVM (2026-11-25, kế hoạch
`docs/tasks/2026-11-25-thiet-ke-2026-11-25.1.md`), để lần chuyển không làm lệch.

## 1. Kết nối thiết bị

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-KN-1 | Tìm thiết bị theo thứ tự: địa chỉ lần trước → NSD (`_http._tcp` tên glimmer*) → `glimmer.local` → AP cài đặt `192.168.4.1`. Địa chỉ trả lời được lưu lại, trừ AP cài đặt. | Lần trước 10.0.0.9 không trả lời, NSD thấy 10.0.0.5 → thử 10.0.0.5 | ok |
| R-KN-2 | Đã kết nối thì tự làm mới mỗi 5 s, chỉ khi app đang mở; mở lại app → làm mới ngay. | App xuống nền → ngừng hỏi thiết bị | ok |
| R-KN-3 | Chưa kết nối → màn Kết nối; kết nối được → khung 3 tab (Tổng quan). "Kết nối thiết bị khác" quên thiết bị → về Kết nối. | Bấm "Kết nối thiết bị khác" → màn Kết nối | ok |
| R-KN-4 | Thiết bị có API token mà app chưa có → vẫn hiện trạng thái, thẻ để trống, báo cần nhập token trong Cài đặt. | `/push` trả 401 → "Thiết bị có API token — …" | ok |

## 2. Mức dùng Claude (Tổng quan)

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-DUNG-1 | Màu % đã dùng theo % còn lại: còn ≤ 20 → coral, ≤ 50 → amber, còn lại → mint; chưa biết → muted, hiện `--`. | 38 → mint, 60 → amber, 92 → coral | ok |
| R-DUNG-2 | Dòng phụ thẻ mức dùng, ưu tiên: chưa có khóa (amber) > khóa lỗi `expired`/`rejected` (coral) > bị chặn `blocked` (amber) > số liệu cũ "số liệu cũ (X trước)" (amber) > "X trước" (chỉ khi đã tải được và đồng hồ thiết bị đã đồng bộ) > trống. | cred `blocked`, stale → "claude.ai đang chặn…" | ok |
| R-DUNG-3 | Thời gian ngắn, chữ đơn vị tiếng Anh như màn thiết bị: đếm ngược `4d 3h` / `2h 14m` / `12m`, đã tới → `ngay`, chưa biết → không hiện "đặt lại sau"; đã qua `45s` / `12m` / `3h` (< 48 h) / `2d`. | reset sau 2 h 14 phút → "đặt lại sau 2h 14m" | ok |
| R-DUNG-4 | Số liệu cũ → cả hai số và thanh % chuyển màu muted. | stale → 66% muted | ok |

## 3. Bảng project

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-PRJ-1 | Chỉ hiện project `shown`, xếp approval → input → error → working → done. Dòng phụ: nhãn trạng thái · chi tiết · tên agent nếu không phải claude. | [done A, approval B] → B, A | ok |
| R-PRJ-2 | Clawd ở Tổng quan: bảng trống → ngủ; có approval → mắt to; có error → buồn; có working/input → mắt mở; còn lại → vui. Có working → Clawd bước. | [done, error] → buồn | ok |

## 4. Cài đặt

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-CD-1 | Chỉ gửi khóa đã đổi; đổi về đúng giá trị cũ → không còn tính là đổi. Nút "Lưu (n)" + "Bỏ thay đổi" chỉ hiện khi có thay đổi; lưu xong tải lại. | Độ sáng 60 → 80 → 60: không có thay đổi | ok |
| R-CD-2 | Khóa bí mật (khóa Claude, API token) thiết bị trả về dạng ẩn; dòng hiện "đã đặt" / "chưa đặt", "sẽ đổi khi lưu" khi người dùng vừa nhập; chỉ gửi khi người dùng nhập giá trị mới. | claudeKey `***` → "đã đặt" | ok |
| R-CD-3 | Giờ Từ/Đến chỉ hiện khi chế độ ban đêm ≠ Không; độ sáng ban đêm chỉ khi chế độ = Giảm sáng. | Chế độ Đồng hồ → có Từ/Đến, không có độ sáng ban đêm | ok |

## 5. Thiết bị (cập nhật, sao lưu)

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-TB-1 | Có bản mới khi bản phát hành `latest` mới hơn lúc build của thiết bị quá 30 phút. | build 10:00, phát hành 10:20 → đã cập nhật | ok |
| R-TB-2 | Tệp khôi phục phải là config.json của glimmer (có `wifi_ssid`), không thì báo tệp không hợp lệ và không gửi gì. | `{"a":1}` → "Tệp không hợp lệ" | ok |
| R-TB-3 | Cập nhật đầy đủ: sao lưu cấu hình (không đọc được → dừng), tải firmware + hệ thống tệp, nạp firmware, chờ thiết bị trả lời (không → dừng), nạp hệ thống tệp, chờ 20 s rồi khôi phục cấu hình (thẳng hoặc qua glimmer-setup). | Thiết bị không trả lời sau firmware → dừng, chưa nạp hệ thống tệp | ok |
| R-TB-4 | Khi đang chạy một việc dài (nạp, khôi phục, khởi động lại), mọi dòng thao tác bị tắt và thẻ tiến trình hiện ở đầu màn. | Đang nạp firmware → "Khởi động lại" tắt | ok |

## 6. Cài Wi-Fi cho thiết bị

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-WF-1 | Gửi Wi-Fi mới thẳng cho thiết bị chỉ khi đang kết nối, thiết bị không ở chế độ cài đặt và trả lời ngay lúc đó; còn lại vào Wi-Fi glimmer-setup (cần quyền vị trí) rồi gửi qua đó. | Thiết bị đã rời mạng → đi qua glimmer-setup | ok |
| R-WF-2 | Lệnh có khởi động lại (lưu Wi-Fi, khôi phục cấu hình, khởi động lại) mà thiết bị không kịp trả lời vẫn tính là thành công; lỗi HTTP vẫn là lỗi. | Gửi Wi-Fi, mất kết nối → bước tiếp | ok |
| R-WF-3 | Gửi xong: rời glimmer-setup, tìm lại thiết bị trên mạng mới; không thấy → "Chưa thấy thiết bị trên …". Tên Wi-Fi điền sẵn bằng mạng điện thoại đang dùng (trừ glimmer-setup). | Không thấy sau ~4 phút → lỗi | ok |
