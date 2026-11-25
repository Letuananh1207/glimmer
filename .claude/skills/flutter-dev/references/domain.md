# Lớp domain — model, quy tắc, use case

## Đặt logic ở đâu

| Logic                                                  | Ở                                          |
| ------------------------------------------------------ | ------------------------------------------ |
| Tính toán thuần, không IO, không state                 | `domain/rules/` — hàm hoặc lớp không state |
| Đọc/sửa **một** loại dữ liệu                           | hàm của repository đó                      |
| Đọc/sửa **≥ 2** repository, dùng ở nhiều màn           | `domain/use_cases/`                        |
| Biến dữ liệu thành trạng thái cho **một** màn          | ViewModel của màn                          |

Không tạo use case chỉ để chuyển tiếp một lời gọi repository.

## Model (`domain/models/`)

- Bất biến: trường `final`, constructor `const` khi được, `copyWith` khi cần.
- `fromJson`/`toJson` trong model; mỗi model một file (model nhỏ đi cùng có thể chung file).
- Record (`({int step, DateTime due})`) dùng được cho giá trị nhỏ nội bộ; dữ liệu lưu/đồng bộ → lớp có tên.
- Không import Flutter (trừ `foundation.dart` khi cần `@immutable`).

## Use case (`domain/use_cases/`)

- Một lớp một việc, hàm `call(...)` (hoặc tên động từ). Phụ thuộc là interface repository, nhận qua constructor.
- Được gọi use case khác — không vòng tròn.
- Đồng bộ nếu mọi repository đồng bộ; trả `Future<Result<T>>` khi có bước có thể lỗi.

```dart
class PlaceOrderUseCase {
  PlaceOrderUseCase({required CartRepository cart, required OrderRepository orders})
    : _cart = cart,
      _orders = orders;

  final CartRepository _cart;
  final OrderRepository _orders;

  Future<Result<Order>> call() async {
    final result = await _orders.create(_cart.ids);
    if (result is Ok) _cart.clear();
    return result;
  }
}
```

## Danh sách use case đã có

- `ToggleSkillUseCase` · bật / tắt skill trên app + thiết bị (ít nhất một), theo thiết bị khi lệch (R-SK-1, R-SK-2,
  R-SK-4, R-SK-5) · `SkillRepository`, `DeviceRepository`
- `LoadPhotosUseCase` · danh sách ảnh thiết bị + bản sao làm hình thu nhỏ, bỏ bản sao thừa · `DeviceRepository`,
  `PhotoRepository`
- `SendPhotoUseCase` · vùng cắt → JPEG baseline 188² ≤ 40 KB (giảm chất lượng dần) → gửi → giữ bản sao ·
  `DeviceRepository`, `PhotoRepository`
- `DeletePhotoUseCase` · xoá ảnh trên thiết bị + bản sao (404 = đã xoá) · `DeviceRepository`, `PhotoRepository`

## Quy tắc nghiệp vụ

Quy tắc đã chốt với người dùng nằm ở `docs/testing/quy_tac.md` (mã `R-…`). Đổi hành vi → sửa quy tắc ở đó trước,
rồi test, rồi code.
