# Phong cách Dart (Effective Dart, rút gọn)

## Tên

- Kiểu, extension: `UpperCamelCase`. Biến, hàm, hằng: `lowerCamelCase`. File, thư mục: `lowercase_with_underscores`.
- Viết tắt > 2 chữ cái viết như từ thường (`HttpClient`, không `HTTPClient`). Không tiền tố kiểu `kFoo` cho hằng mới.
- Thuật ngữ nhất quán; khái niệm nghiệp vụ dùng tên đã có trong code/thiết kế, không đặt tên mới cho cùng một thứ.

## Code

- File mới: `dart format`. File cũ: giữ định dạng đang có, không format lại cả file (diff lớn, khó review).
- Trường và biến `final` khi được; `const` constructor khi được.
- Có ngoặc nhọn cho mọi `if/for/while` nhiều dòng.
- Kiểu tường minh ở tham số và kiểu trả về của hàm public; không ghi kiểu thừa cho biến cục bộ đã khởi tạo.
- Tránh `dynamic`; JSON đọc vào ép kiểu ngay tại `fromJson`.
- Tránh tham số `bool` vị trí → dùng tham số có tên.
- Không trả `Future`/`Stream`/collection nullable — trả rỗng.
- `async/await` thay `.then()`; `Future<void>` cho hàm async không trả gì; `unawaited(...)` khi cố ý không chờ.
- Lỗi: `on Exception catch (e)` — không `catch` trống, không bắt `Error`; `rethrow` khi ném lại.
- Import: `dart:` → `package:` → tương đối, mỗi nhóm theo ABC. Trong `lib/` dùng import **tương đối**.
- Không truy cập `src/` của gói khác.

## Comment

- Tiếng Việt, mật độ như code hiện có: `///` cho lớp/hàm public, câu đầu tóm tắt.
- Ghi **vì sao** và nguồn quy tắc (mã quy tắc `R-…`, mục thiết kế, mã lỗi `L-…`), không lặp lại code.
- Dùng `[tên]` để tham chiếu; đặt `<…>` trong backtick (tránh cảnh báo HTML trong doc comment).

## Async và vòng đời

- Kiểm `mounted` (`context.mounted`) sau mỗi `await` trong widget trước khi dùng `context`/`setState`.
- Huỷ `StreamSubscription`, `AnimationController`, listener trong `dispose()`.
