# Quy tắc nghiệp vụ đã xác nhận

Nguồn sự thật cho test: mỗi test ghi mã quy tắc nó kiểm (`R-…`). Sửa quy tắc → sửa file này trước, rồi test, rồi code.
`dart tool/rule_trace.dart` đọc các dòng bảng `| R-<VÙNG>-<số> | … | App |` ở đây.

Cột **App**: `ok` = code đã chạy đúng · `sửa` = code phải đổi theo quy tắc (test viết trước, đỏ tới khi sửa) ·
`tk` = code đúng, chỉ thiết kế ghi sai · thêm "miễn test (<lý do>)" khi không kiểm được bằng test.

"Ngày" luôn là ngày lịch theo giờ máy người dùng, sang ngày mới lúc 00:00.

## 1. <Vùng đầu tiên>

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-VD-1 | _(ví dụ — xoá dòng này khi có quy tắc thật)_ Thêm sản phẩm đã có trong giỏ → giỏ không đổi. | Giỏ [A], thêm A → [A] | sửa |
