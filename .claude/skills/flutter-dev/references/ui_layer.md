# Lớp UI — View, ViewModel, routing

## ViewModel

- `extends ChangeNotifier`; phụ thuộc (repository/use case interface) nhận qua constructor, giữ `final _private`.
- State lộ ra bằng getter; danh sách trả về bản không sửa được.
- Lắng nghe các repository mình đọc → `notifyListeners()`; gỡ trong `dispose()`.
- Không import `material`, không giữ `BuildContext`, không điều hướng. Trả về kết quả để View tự điều hướng.
- Hành động đồng bộ → hàm thường. Hành động bất đồng bộ cần trạng thái chạy/lỗi → `Command`.

```dart
class CartViewModel extends ChangeNotifier {
  CartViewModel({required CartRepository cart, required CatalogRepository catalog})
    : _cart = cart,
      _catalog = catalog {
    _cart.addListener(notifyListeners);
  }

  final CartRepository _cart;
  final CatalogRepository _catalog;

  List<Product> get items => List.unmodifiable(_cart.items(_catalog.products));

  void remove(Product p) => _cart.remove(p.id);

  @override
  void dispose() {
    _cart.removeListener(notifyListeners);
    super.dispose();
  }
}
```

## Command (`utils/command.dart`)

```dart
late final Command1<void, Order> checkout = Command1(_checkout);   // trong ViewModel
Future<Result<void>> _checkout(Order o) => _orders.submit(o);

// View
ListenableBuilder(
  listenable: viewModel.checkout,
  builder: (context, _) => PrimaryButton(
    label: t.cartCheckout,
    loading: viewModel.checkout.running,
    onPressed: () => viewModel.checkout.execute(order),
  ),
);
```
Kết quả lỗi: View nghe `checkout` và hiện thông báo khi `checkout.error`, rồi `checkout.clearResult()`.

## View (màn)

- `const XScreen({super.key, required this.viewModel})`; rebuild bằng `ListenableBuilder(listenable: viewModel, …)`
  bọc **đúng phần** cần đổi.
- Chỉ chứa: hiện/ẩn theo cờ, animation, bố cục theo kích thước màn, điều hướng đơn giản (`context.push(Routes…)`).
- Widget con nhận dữ liệu + callback bằng **tham số**; không tự tìm ViewModel/repository.
- `StatefulWidget` chỉ cho state thuần UI (controller, animation, ô đang chọn tạm thời).

## Tạo ViewModel trong route

```dart
GoRoute(
  path: Routes.cart,
  builder: (_, s) => ViewModelHost(
    create: (c) => CartViewModel(cart: c.read(), catalog: c.read()),
    builder: (_, vm) => CartScreen(viewModel: vm),
  ),
),
```
`ViewModelHost` (`ui/core/widgets/view_model_host.dart`) tạo ViewModel **một lần** và `dispose()` khi rời màn.
Hàm dựng màn kèm ViewModel đặt ở `routing/<tính năng>_routes.dart` (vd `cartScreen()`) — router và test gọi cùng hàm.
Đường dẫn là hằng/hàm trong `routing/routes.dart`, không viết chuỗi `'/…'` trong màn.

## Quy tắc giao diện

- Màu `AppColors`, chữ `AppFonts`/`AppText`, khoảng cách `AppSpace`, kích thước `AppSize` — không viết số cứng.
  Màu mới chưa có token → thêm token (hoặc báo bên thiết kế), không viết `Color(0x…)` tại chỗ.
- Chữ hiển thị qua `AppLocalizations`; chuỗi mới chưa có trong thiết kế → `lib/l10n/app_vi.arb` tiền tố `dev`.
- Vùng chạm ≥ 44. Phong cách riêng của dự án (góc, viền, bóng, ripple…): ghi ở `CHANGELOG.md` của bộ chuẩn này.

## Hiệu năng (Flutter performance best practices)

- `const` mọi chỗ được.
- Tách UI dùng lại thành **lớp widget**, không phải hàm trả `Widget`.
- `build()` không làm việc nặng (lọc, sắp xếp, parse) → làm ở ViewModel, lưu kết quả.
- Danh sách dài: `ListView.builder` / `SliverList.builder`.
- Tránh `Opacity` trong animation (dùng `AnimatedOpacity`/`FadeTransition`); tránh `saveLayer`, clip không cần thiết.
- Phần tĩnh của `AnimatedBuilder` truyền qua `child`.
- `ListenableBuilder` bọc nhỏ nhất có thể; không bọc cả màn khi chỉ một ô đổi.
