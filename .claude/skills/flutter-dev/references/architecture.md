# Kiến trúc — lớp, thư mục, phụ thuộc

MVVM theo hướng dẫn kiến trúc chính thức của Flutter (docs.flutter.dev/app-architecture), dữ liệu offline-first.

```
View ⇄ ViewModel → (UseCase) → Repository (interface) → Service
                                   └ …Local (bây giờ) / …Synced (khi có backend)
Dữ liệu đi lên, sự kiện đi xuống. Máy là nguồn sự thật.
```

## Thư mục

```
lib/
├── main.dart              khởi tạo, bắt lỗi toàn cục, MultiProvider, runApp
├── config/                dependencies.dart (nơi DUY NHẤT chọn bản cài đặt …Local/…Synced, tạo instance)
├── routing/               router.dart (GoRouter, redirect, tạo ViewModel) · routes.dart (hằng/hàm đường dẫn)
├── utils/                 result.dart, command.dart (+ clock.dart, json.dart khi cần)
├── domain/
│   ├── models/            model bất biến + toJson/fromJson
│   ├── rules/             quy tắc thuần, không IO
│   └── use_cases/         thao tác chạm ≥ 2 repository
├── data/
│   ├── services/          bọc nguồn ngoài (DB, HTTP, SDK), không giữ state
│   ├── repositories/<y>/  y_repository.dart (interface) + y_repository_local.dart
│   ├── migrations/        khoá lưu; di trú dữ liệu khi đã phát hành
│   └── models/            API model (chỉ khi JSON backend khác domain model)
├── ui/
│   ├── core/themes/       app_colors.dart, app_text.dart (AppFonts, AppSpace, AppSize)
│   ├── core/widgets/      widget dùng ở ≥ 2 tính năng
│   └── <tính năng>/       view_models/<màn>_view_model.dart · widgets/<màn>_screen.dart + phần con
└── l10n/                  app_vi.arb + file sinh
test/                      soi gương lib/
testing/fakes/             bản giả dùng chung
docs/backend/              hợp đồng dữ liệu với backend
```

Một tính năng có thể nhiều màn; **mỗi màn đúng một ViewModel**. Danh sách tính năng của dự án: xem Bản đồ tính năng
trong `.claude/skills/lead/SKILL.md`.

## Ai được import ai

| Từ ↓                     | Được import                                                                                              |
| ------------------------ | -------------------------------------------------------------------------------------------------------- |
| View (`ui/<f>/widgets`)  | `ui/core`, view + ViewModel **của chính `<f>`**, `domain/models`, `utils`, `l10n`, `routing/routes.dart` |
| `ui/core`                | `ui/core`, `domain/models`, `utils`, `l10n`, `routing/routes.dart`                                       |
| ViewModel                | `domain/*`, repository (interface), `utils`                                                              |
| UseCase                  | `domain/models`, `domain/rules`, use case khác, repository (interface), `utils`                          |
| Repository               | `domain/models`, `domain/rules`, service, `data/models`, `data/migrations`, `utils`. **Không** repository khác |
| Service                  | `data/models`, `utils`. **Không** service khác                                                           |
| `domain/rules`           | `domain/models`, `utils`                                                                                 |
| `domain/models`, `utils` | chỉ cùng lớp                                                                                             |
| `routing/router.dart`, `config/`, `main.dart` | mọi lớp                                                             |

Gói ngoài: `flutter/material`, `provider`, `go_router` chỉ ở UI/routing/config; gói lưu trữ, mạng, analytics,
thanh toán chỉ ở `data/services` (danh sách máy kiểm: `_packageOwners` trong `tool/check.dart`).
`flutter/foundation.dart` (ChangeNotifier) dùng được ở mọi lớp.

Hệ quả:
- Widget **không** tự tìm phụ thuộc trong `context`; chỉ `routing/` và `config/` dùng `context.read()`.
- Hai tính năng cần cùng widget → chuyển widget vào `ui/core/widgets/`.
- Logic cần ≥ 2 repository → UseCase (hoặc ViewModel nếu chỉ một màn dùng).

## Đặt tên

| Loại        | File                                | Lớp                         |
| ----------- | ----------------------------------- | --------------------------- |
| Màn         | `home_screen.dart`                  | `HomeScreen`                |
| ViewModel   | `home_view_model.dart`              | `HomeViewModel`             |
| Repository  | `progress_repository.dart`          | `ProgressRepository`        |
| Bản cài đặt | `progress_repository_local.dart`    | `ProgressRepositoryLocal`   |
| Service     | `local_database_service.dart`       | `LocalDatabaseService`      |
| UseCase     | `check_in_use_case.dart`            | `CheckInUseCase`            |
| Bản giả     | `fake_local_database_service.dart`  | `FakeLocalDatabaseService`  |

## Kích thước

File ≤ ~400 dòng; `build()` đọc được trên một màn hình. Vượt → tách widget con thành lớp riêng (file riêng nếu
dùng lại hoặc file vẫn dài).
