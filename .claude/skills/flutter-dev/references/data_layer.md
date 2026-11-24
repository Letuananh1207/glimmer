# Lớp data — service, repository, lưu trữ, backend

## Service — bọc nguồn ngoài

- `abstract class` + bản thật; bản giả ở `testing/fakes/`. **Không giữ state**, không logic nghiệp vụ.
- Một service một nguồn (DB máy, asset, HTTP API, analytics, thanh toán, đăng nhập…). Service không import service
  khác (bản thật để cùng file với interface, hoặc thư mục riêng `services/<tên>/`).
- Service mạng nên có bản `Unconfigured…` khi build thiếu cấu hình (khoá API) — app vẫn chạy offline.
- Thao tác có thể lỗi trả `Future<Result<T>>`; bắt `on Exception catch (e)` → `Result.error(e)`.

## Repository — nguồn sự thật của một loại dữ liệu

- Dữ liệu backend có thể chạm (người dùng, nội dung) → **interface** `XRepository` + `XRepositoryLocal`.
  Chỉ đọc asset riêng của app → lớp cụ thể là đủ.
- Repository **không biết nhau**. Cần dữ liệu của repository khác → đưa lên UseCase/ViewModel.
- Không singleton, không cache tĩnh: cache là trường của repository; một instance tạo ở `config/dependencies.dart`.

### Dữ liệu người dùng: offline-first

- `ChangeNotifier`, nạp vào bộ nhớ lúc khởi động, **getter đồng bộ**.
- Hàm sửa: đổi bộ nhớ → ghi máy → `notifyListeners()`. Không đổi gì thì không ghi, không báo.

```dart
abstract class CartRepository extends ChangeNotifier {
  List<String> get ids;
  void add(String id);
  void remove(String id);
}

class CartRepositoryLocal extends CartRepository {
  CartRepositoryLocal(this._db, List<String> saved) : _ids = [...saved];

  final KeyValueService _db;
  final List<String> _ids;

  @override
  List<String> get ids => List.unmodifiable(_ids);

  @override
  void add(String id) {
    if (_ids.contains(id)) return;
    _ids.add(id);
    _save();
  }

  @override
  void remove(String id) {
    if (_ids.remove(id)) _save();
  }

  void _save() {
    unawaited(_db.write(StorageKeys.cart, _ids)); // không chờ — bộ nhớ là nguồn sự thật
    notifyListeners();
  }
}
```

### Định dạng lưu

- Dữ liệu lớn dần → mỗi phần tử một dòng/bản ghi; nhóm nhỏ → một bản ghi JSON. Tên khoá ở
  `data/migrations/storage_keys.dart`. Đọc JSON an toàn: sai kiểu thì về mặc định, không ném.
- Tên trường **không đổi tuỳ tiện** (xem Di trú) và khớp `docs/backend/` (nếu có).
- Ngày theo lịch người dùng lưu `"yyyy-MM-dd"` theo **giờ máy**; mốc thời điểm lưu ISO-8601 **UTC**.
  Giá trị có tập cố định lưu **mã** (`enum.name`), không lưu nhãn hiển thị.
- Đọc dữ liệu hỏng: bỏ qua phần hỏng, ghi log, **không** chặn app.

### Di trú

- **Chưa phát hành: không viết di trú.** Đổi định dạng thì sửa thẳng; máy dev xoá dữ liệu app rồi chạy lại.
- **Từ bản phát hành đầu tiên:** đổi bảng / định dạng → tăng phiên bản + bước di trú đọc được bản cũ. Mỗi bước di trú
  **bắt buộc** có test với dữ liệu mẫu của bản cũ (`test/data/migrations/`), giữ mãi.

## Nội dung tĩnh

Danh sách, nội dung, cấu hình hiển thị → nạp từ `assets/data/*.json` qua repository (vd `CatalogRepository`) lúc
khởi động. Không viết cứng trong code.

## Chuẩn bị backend

- Chỉ `config/dependencies.dart` biết tên bản cài đặt. Thêm backend = thêm `…Synced` (hoặc outbox + đồng bộ nền) +
  service mạng + đổi ở đó.
- JSON backend khác định dạng máy → API model ở `data/models/`, repository chuyển đổi; domain model không đổi.
- Đổi trường dữ liệu người dùng → cập nhật `docs/backend/` **cùng commit** (`tool/check.dart` nhắc bằng W-backend).
- Không tự đặt endpoint; hợp đồng API chỉ ghi khi hai bên đã chốt.
