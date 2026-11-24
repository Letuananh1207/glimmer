# glimmer app — hướng dẫn cho Claude

App Android **glimmer** (Flutter) đi kèm màn hình glimmer (GeekMagic SmallTV-Ultra chạy firmware ở gốc repo): cài
Wi-Fi cho thiết bị, xem mức dùng Claude và bảng project, chỉnh cài đặt, cập nhật firmware, sao lưu cấu hình. Chức năng
và API thiết bị dùng tới: `README.md`. Giao diện và chữ hiển thị bằng tiếng Việt; trả lời người dùng bằng tiếng Việt.

**File này nằm ở `app/`.** Mọi lệnh `dart` / `flutter` (kể cả `tool/…`) chạy trong `app/`; đường dẫn `lib/`, `test/`,
`testing/`, `tool/`, `docs/` trong các skill tính từ `app/`. Skill ở `../.claude/skills/`; script của `/lead` gọi
bằng `dart ../.claude/skills/lead/scripts/impact.dart`. Hợp đồng HTTP với firmware (`/api/*`, `/push`, `/update`)
do firmware quyết định — đổi API thì đọc `../CLAUDE.md` và `../src/core/web.cpp`.

## Thiết kế: `design/` (gốc repo) là nguồn sự thật

Giao diện app vẽ trên canvas "glimmer – giao diện app" (https://claude.ai/artifact/WzLqGhKvD1MYxqaiRkzq1r), chốt thì
xuất sang `../design/` và đẩy lên GitHub. **Không sửa tay `design/`** — lần chốt sau sẽ ghi đè.

**Hai phiên, hai vai.** Phiên **thiết kế** (Claude ngoài VS Code: claude.ai/code, trình duyệt, app máy tính) vẽ canvas
cùng người dùng, chốt thì ghi `design/` — skill `ui-design`; phiên đó không sửa `app/lib`, `app/test`, `app/tool`,
`app/assets`. Phiên **code** (VS Code) không sửa `design/`, áp thiết kế bằng `/ui-apply`. Không rõ mình là phiên nào → hỏi.

| File | Dùng cho |
| --- | --- |
| `design/CHANGELOG.md` | Thiết kế đổi gì, ở màn/widget nào. **Đọc đầu tiên khi thiết kế cập nhật** |
| `design/screens/@3x/*.png` | Ảnh chuẩn từng màn |
| `design/docs/screen_specs.md` · `components.md` · `navigation.json` | Đặc tả màn · widget dùng lại · route, luồng bấm |
| `design/tokens/design_tokens.json` | Màu, font, cỡ chữ, khoảng cách |
| `design/l10n/app_vi.arb` | Chữ hiển thị theo thiết kế |
| `design/icons/*.svg` · `design/data/*.json` | Icon · dữ liệu nội dung |
| `design/source/*.dc.html` | File canvas gốc (tra số đo chính xác) |

**Thiết kế trước, code sau.** Giao diện `design/` chưa có → **không dựng tạm**: `/ui-apply phieu <yêu cầu>` soạn phiếu
(`docs/phieu_thiet_ke/`, đẩy lên GitHub) cho phiên thiết kế (`/ui-design phieu`); việc giao diện đợi bản chốt. Thiết
kế cập nhật → `/ui-apply` (áp từng mục CHANGELOG mới hơn `appliedVersion`, `/ui-apply tiep` làm tiếp);
`/ui-apply kiem <Màn>` so một màn với thiết kế, không sửa.

## Quy tắc khi viết code

**Mọi thay đổi code Dart (`lib/`, `test/`, `testing/`) theo bộ chuẩn `.claude/skills/flutter-dev/`** (kiến trúc MVVM,
quy tắc lớp, mẫu code, cách kiểm tra). `dart tool/check.dart` chặn khi vi phạm quy tắc lớp; `tool/guard.dart`
(check `--changed` + `dart analyze` file đổi) tự chạy ở hook Stop (`../.claude/settings.json`) và git pre-commit
(`core.hooksPath = app/tool/git_hooks`) — bị chặn thì sửa lỗi, không lách.

**Code cũ chưa theo chuẩn** (`lib/api/`, `lib/services/`, `lib/app_controller.dart`, `lib/ui/*.dart`): check báo
`E-ngoai`/`E-lop`, nên sửa một file cũ là guard chặn. Chuyển dần sang cấu trúc lớp (`lib/data/services/`,
`lib/data/repositories/`, `lib/ui/<tính năng>/{widgets,view_models}/`, `lib/ui/core/themes/`) — file nào đụng tới thì
chuyển file đó.

- Không viết cứng màu, cỡ chữ, khoảng cách: dùng `AppColors`, `AppFonts`, `AppSpace`, `AppSize` (bảng màu giống
  firmware `../src/core/theme.h`).
- Không viết cứng chữ hiển thị: dùng `AppLocalizations`. Chuỗi mới chưa có trong thiết kế → thêm vào
  `lib/l10n/app_vi.arb` với tiền tố `dev` (ví dụ `devSearchHint`). Chuỗi `dev` chép từ câu chữ viết thẳng trong HTML
  thiết kế → metadata `"x-thiet-ke": "source/<Màn>.dc.html"` (và `"x-khoa-thiet-ke": "<khoá>"` nếu chờ khoá cụ thể);
  `sync_design.dart` báo khi câu đổi hoặc thiết kế đã có khoá.
- Tên widget/màn theo `design/docs/components.md` và `screen_specs.md`.
- Widget dùng lại ở `lib/ui/core/widgets/`, màn ở `lib/ui/<tính năng>/widgets/` (ViewModel ở `…/view_models/`).
- Vùng chạm ≥ 44.
- **Quy tắc nghiệp vụ đã chốt với người dùng: `docs/testing/quy_tac.md`** (mã `R-…`). Đổi hành vi nghiệp vụ → sửa
  quy tắc ở đó trước, test ghi mã (`test/rules/`), `dart tool/rule_trace.dart` không được thiếu.
- Đổi model / repository dữ liệu người dùng → cập nhật `docs/backend/` cùng commit.
- Test với thiết bị thật: `GLIMMER_LIVE=http://<ip> flutter test test/device_live_test.dart`.

## File sinh tự động — không sửa tay

- `lib/ui/core/themes/app_colors.dart`, `lib/l10n/app_vi.arb` (gộp: chuỗi thiết kế thắng, chuỗi riêng của code được
  giữ), `assets/icons/*.svg`, `assets/data/*.json`, `.design_sync.json` (`appliedVersion` = bản CHANGELOG đã áp) —
  chỉ cập nhật bằng `dart run tool/sync_design.dart`. `lib/ui/core/themes/app_text.dart` (`AppFonts`, `AppSpace`,
  `AppSize`) viết tay — script báo khi token chữ/khoảng cách đổi.
- `lib/l10n/app_localizations*.dart` (`flutter gen-l10n`)
- `*.g.dart` (`dart run build_runner build`)

## Trợ giúp

`/guide` liệt kê mọi lệnh và luồng làm việc; `/guide <lệnh>` xem chi tiết; `/guide <việc muốn làm>` hỏi nên dùng lệnh nào.

## Khi có yêu cầu thêm/sửa/xóa tính năng

Làm theo `/lead <yêu cầu>` (`.claude/skills/lead/`): khoanh phạm vi bằng `scripts/impact.dart`, chia nhiệm vụ, ghi kế
hoạch ở `docs/tasks/`.

## Khi có lỗi

Dùng `/loi <mô tả>` để ghi lỗi vào `docs/loi.md` (mã `L-…`), `/loi` để xem lỗi đang mở, `/loi sua [L-…]` để sửa
(test đỏ trước, rồi sửa, rồi chờ thử máy). Người dùng báo lỗi trong chat mà không gõ `/loi` thì vẫn ghi vào sổ.
