# Test

## Bắt buộc

| Lớp                            | Khi nào                                       | Cách                                              |
| ------------------------------ | --------------------------------------------- | ------------------------------------------------- |
| `domain/rules/`                | mọi thay đổi                                  | `test()` thuần                                    |
| Repository, use case           | mọi thay đổi                                  | service giả từ `testing/fakes/`                   |
| ViewModel                      | mọi thay đổi                                  | repository `…Local` + service giả (hoặc repo giả) |
| Di trú dữ liệu (sau phát hành) | mọi thay đổi, giữ mãi                         | dữ liệu mẫu mọi đời định dạng                     |
| View                           | nên có cho luồng chính, redirect, điều hướng  | `testWidgets` + ViewModel dựng từ bản giả         |

Sửa lỗi → `/loi` (sổ `docs/loi.md`): thêm test tái hiện lỗi **đỏ trước**, rồi mới sửa.

## Vị trí

- `lib/a/b.dart` → `test/a/b_test.dart`. Luồng nhiều màn → `test/flows/<luồng>_test.dart`.
- Bản giả dùng chung: `testing/fakes/fake_<tên>.dart` (vd `FakeKeyValueService` = lưu trong `Map`).
- Helper dựng app/phụ thuộc: `testing/app.dart` (`makeDeps`, `pumpApp`…). Test **không** tự dựng chuỗi phụ thuộc
  dài — đổi kiến trúc chỉ phải sửa helper. Thêm helper mới → ghi một dòng vào bảng dưới.

  | Helper | Làm gì |
  | ------ | ------ |
  | _(chưa có)_ | |

## Viết test

- Đồng hồ: truyền `Clock` giả (`() => DateTime(2026, 1, 1)`), không dùng `DateTime.now()` trong test.
- Mỗi test tự dựng dữ liệu của nó; không phụ thuộc thứ tự chạy.
- Tên test tiếng Việt, mô tả hành vi: `'thêm sản phẩm đã có → giỏ không đổi'`.
- Tìm widget theo chữ từ `AppLocalizations` hoặc `Key`, không theo vị trí trong cây.
- Golden test chỉ khi kết xuất ổn định trên máy chạy test (font tải mạng, Windows hay làm hỏng).
- Gộp nhiều kỳ vọng bằng record `expect((a, b), (1, true))` **chỉ với giá trị vô hướng** (List/Map/matcher trong
  record luôn hỏng).

## Quy tắc nghiệp vụ ↔ test

- Nguồn: `docs/testing/quy_tac.md` — mỗi quy tắc một mã `R-…`, cột App `ok` / `sửa` / `tk`. Tên test **bắt đầu bằng mã**:
  `test('R-GIO-2 thêm trùng → không đổi', …)` → chạy riêng: `flutter test --plain-name R-GIO-2`.
- Quy tắc logic → `test/rules/<vùng>_test.dart`, dùng ví dụ trong `quy_tac.md` làm ca kiểm. Quy tắc màn hình → gắn mã
  vào test widget ở đường dẫn gương.
- Đổi / thêm quy tắc: sửa `quy_tac.md` trước → test (đỏ) → code → đổi cột App sang `ok`.
  `dart tool/rule_trace.dart` phải báo 0 quy tắc `ok` / `tk` thiếu test (thoát mã 1 nếu thiếu).

## Chạy (ít đầu ra)

```
flutter test -r failures-only test/<thư mục hoặc file>   # phần vừa sửa
flutter test -r failures-only                            # toàn bộ, trước commit
```
Chỉ in test hỏng; im lặng + mã thoát 0 = qua. Đổi quy tắc / thêm test quy tắc → thêm `dart tool/rule_trace.dart`.
