---
name: flutter-dev
description: Bộ chuẩn lập trình Flutter của glimmer — đọc TRƯỚC khi viết, sửa, chuyển hay review bất kỳ code Dart nào trong lib/, test/, testing/ (màn, widget, ViewModel, repository, service, use case, model, routing, test). Kiến trúc MVVM offline-first, quy tắc lớp, mẫu code, cách kiểm tra ít token.
---

# flutter-dev — bộ chuẩn code của glimmer

Nguồn sự thật cho **cách viết code**. Lý do của từng quyết định lớn: `decisions/` (chỉ đọc khi cần biết *vì sao*).

**Ưu tiên khi mâu thuẫn:** thiết kế đã chốt (nếu dự án có `design/`) > `CLAUDE.md` (quy tắc dự án) > bộ chuẩn này >
thói quen chung.

## Quy trình mỗi lần sửa

1. **Xác định lớp** của việc cần làm (bảng dưới) → đọc **đúng một** file `references/` tương ứng, không đọc hết.
2. **Đọc tối thiểu:** mở file theo đường dẫn đoán được; không quét cả thư mục. Không đọc file sinh tự động
   (`lib/l10n/app_localizations*.dart`, `*.g.dart`, `assets/**`).
3. **Sửa** theo mẫu trong reference. Logic mới ở ViewModel / repository / use case / rules → **kèm unit test**.
4. **Kiểm** (đầu ra ngắn, chỉ in lỗi):
   ```
   dart tool/check.dart --changed
   flutter analyze
   flutter test -r failures-only test/<phần vừa sửa>
   ```
   Trước khi commit: `flutter test -r failures-only` (toàn bộ). Hook Stop và git pre-commit tự chạy
   `tool/guard.dart` — bị chặn thì sửa lỗi, không lách.
5. Đổi model/repository **dữ liệu người dùng** → cập nhật `docs/backend/` cùng commit.

## Việc → đọc gì

| Việc                                                            | Reference                        |
| --------------------------------------------------------------- | -------------------------------- |
| Không rõ file thuộc lớp nào, đặt file mới ở đâu, được import gì | `references/architecture.md`     |
| Màn, widget, ViewModel, Command, routing, hiệu năng UI          | `references/ui_layer.md`         |
| Repository, service, lưu trữ, di trú dữ liệu, chuẩn bị backend  | `references/data_layer.md`       |
| Logic chạm nhiều repository, quy tắc nghiệp vụ                  | `references/domain.md`           |
| Viết/sửa test, bản giả                                          | `references/testing.md`          |
| Đặt tên, comment, async, lỗi, import                            | `references/dart_style.md`       |

## Đường dẫn đoán được

| Cần                          | Ở                                                                         |
| ---------------------------- | ------------------------------------------------------------------------- |
| Màn X                        | `lib/ui/<tính năng>/widgets/x_screen.dart`                                |
| ViewModel của màn X          | `lib/ui/<tính năng>/view_models/x_view_model.dart`                        |
| Widget dùng chung            | `lib/ui/core/widgets/…`                                                   |
| Repository Y                 | `lib/data/repositories/y/y_repository.dart` (+ `y_repository_local.dart`) |
| Service Z                    | `lib/data/services/z_service.dart`                                        |
| Use case                     | `lib/domain/use_cases/<việc>_use_case.dart`                               |
| Quy tắc thuần                | `lib/domain/rules/…`                                                      |
| Model                        | `lib/domain/models/<model>.dart`                                          |
| Route, đường dẫn             | `lib/routing/router.dart`, `lib/routing/routes.dart`                      |
| Nối phụ thuộc                | `lib/config/dependencies.dart`                                            |
| Test của file `lib/a/b.dart` | `test/a/b_test.dart`; bản giả ở `testing/fakes/`                          |

## Điều cấm (máy kiểm bằng `tool/check.dart`)

- Widget gọi `context.read/watch/select` hay `Provider.of` → lấy dữ liệu qua ViewModel (E-context).
- Import ngược lớp, ViewModel/màn của tính năng khác, repository gọi nhau (E-lop).
- `material`/`provider`/`go_router` ngoài UI; gói lưu trữ / mạng / analytics ngoài service (E-goi).
- File nằm ngoài cấu trúc lớp (`lib/screens/`, `lib/widgets/`…) (E-ngoai).
- Màu `Color(0x…)`, `fontSize:` số, chuỗi tiếng Việt viết thẳng (W-mau, W-co-chu, W-chuoi).
- File > 400 dòng (W-dai) → tách widget con thành **lớp**, không phải hàm.
- Singleton, cache tĩnh, biến toàn cục giữ state.

Thêm gói ngoài mới (lưu trữ, mạng, SDK) → thêm vào `_packageOwners` trong `tool/check.dart` cùng lúc.

## Cập nhật bộ chuẩn

Đổi quy tắc → sửa reference liên quan + một dòng trong `CHANGELOG.md`; quyết định lớn → thêm `decisions/000N-….md`.
Giữ mỗi reference ngắn (≤ ~150 dòng): đây là thứ được đọc mỗi lần sửa code.
