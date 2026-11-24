---
name: ui-apply
description: Người áp thiết kế của app glimmer (thiết kế trước, code sau) — soạn phiếu yêu cầu thiết kế khi giao diện chưa được vẽ; lấy bản thiết kế mới trong design/ (CHANGELOG), chia từng mục theo loại, đối chiếu sổ quy tắc và sổ lỗi, sửa code app/ cho khớp từng mục một, ghi tiến độ để phiên sau làm tiếp, và so màn trong app với ảnh/đặc tả thiết kế. Dùng khi người dùng gõ /ui-apply, hoặc nói "thiết kế vừa cập nhật", "áp thiết kế mới", "màn này lệch thiết kế", "cần vẽ màn …".
argument-hint: "[tiep | <mã mục, vd .12> | kiem <Màn> | phieu <yêu cầu>]"
---

# /ui-apply: áp thiết kế vào app (phiên VS Code)

Lệnh: $ARGUMENTS

Thiết kế ở `design/` (gốc repo), do phiên thiết kế (`/ui-design`, ngoài VS Code) đẩy lên: **không sửa tay**, không sửa
canvas trong lúc `/ui-apply`. Code ở `app/` theo `.claude/skills/flutter-dev/`; mọi lệnh `dart` / `flutter` chạy trong
`app/`. Tiến độ: `app/.design_sync.json` — `syncedVersion` (đã chạy `sync_design.dart`), `appliedVersion` (mục CHANGELOG
mới nhất đã áp vào code).

| Lệnh | Làm gì |
|---|---|
| `/ui-apply` | Lấy bản mới, chia loại các mục chưa áp, trình kế hoạch, làm (mục 1–3). |
| `/ui-apply tiep` | Làm tiếp từ mục đầu tiên mới hơn `appliedVersion` (mục 3), không pull lại. |
| `/ui-apply <mã>` | Chỉ áp một mục (vd `.12` = `<ngày>.12`). Mục cũ hơn còn chưa áp thì hỏi trước. |
| `/ui-apply kiem <Màn>` | So màn trong app với thiết kế, liệt kê chỗ lệch, **không sửa** (mục 4). |
| `/ui-apply phieu <yêu cầu>` | Soạn phiếu yêu cầu thiết kế, **không sửa code** (mục 5). |

| Thứ | Ở đâu |
|---|---|
| canvas | https://claude.ai/artifact/WzLqGhKvD1MYxqaiRkzq1r |
| nhật ký thiết kế (`## <mã> — …`) | `design/CHANGELOG.md` |
| đặc tả màn / widget / luồng | `design/docs/screen_specs.md` (đúng mục `## <số>. <Màn>`), `components.md`, `navigation.json` |
| token · chuỗi | `design/tokens/design_tokens.json` · `design/l10n/app_vi.arb` |
| ảnh màn · số đo chính xác | `design/screens/@3x/<Màn>*.png` · `design/source/<Màn>.dc.html` |
| phiếu | `app/docs/phieu_thiet_ke/<ngày>-<tên>.md` |
| file sinh (không sửa tay) | `app/lib/ui/core/themes/app_colors.dart`, `app/lib/l10n/app_vi.arb` (gộp), `app/assets/icons/*.svg`, `app/assets/data/*.json` — `dart run tool/sync_design.dart` |

**Thiết kế trước, code sau.** Giao diện mà `design/` chưa có → **không dựng tạm trong code**: soạn phiếu (mục 5), chờ
bản chốt. Phần không dính giao diện (luật, dữ liệu, repository, gọi API thiết bị) làm trước được nếu người dùng muốn.

## 0. Lần áp đầu tiên (`appliedVersion` trống)

`design/` chưa có → báo "Chưa có bản thiết kế nào — phiên thiết kế vẽ lại app hiện có rồi chốt lần đầu", kèm dòng
canvas, và dừng. Có bản đầu → ngoài các mục CHANGELOG, dựng nền một lần (trình kế hoạch, chờ duyệt):

1. `dart run tool/sync_design.dart` → `app_colors.dart`, `lib/l10n/app_vi.arb`.
2. Viết tay `lib/ui/core/themes/app_text.dart` (`AppFonts`, `AppSpace`, `AppSize`) theo `font` / `type` / `space` /
   `size` / `radius` / `border` của token; font JetBrains Mono đã đóng gói ở `assets/fonts/`.
3. l10n: `flutter pub add flutter_localizations --sdk=flutter` + `intl`, `flutter: generate: true`, `l10n.yaml`
   (`arb-dir: lib/l10n`, `template-arb-file: app_vi.arb`, `output-localization-file: app_localizations.dart`), nối
   `localizationsDelegates` / `supportedLocales` ở `MaterialApp`, `flutter gen-l10n`.
4. `ThemeData` chuyển sang `lib/ui/core/themes/app_theme.dart` dùng `AppColors`; `lib/ui/theme.dart` (bảng `G`) bỏ dần
   khi các màn chuyển xong.

Code cũ chưa theo MVVM (`app/CLAUDE.md`): áp thiết kế vào màn cũ = **chuyển màn đó sang cấu trúc lớp luôn** (màn
`lib/ui/<tính năng>/widgets/`, ViewModel `…/view_models/`, gọi thiết bị qua repository → service), vì guard chặn sửa
file cũ. Màn lớn → kế hoạch `docs/tasks/` theo mẫu `/lead`.

## 1. Lấy bản mới

1. `git status`: có thay đổi chưa commit chạm `app/lib/`, `app/assets/`, `app/.design_sync.json` → dừng, hỏi. Rồi `git pull`.
2. Mục cần làm = các mục `## <mã> — …` trong `design/CHANGELOG.md` mới hơn `appliedVersion`. Không có → báo "Thiết kế
   không có gì mới", kèm phiếu `chờ thiết kế` trong `app/docs/phieu_thiet_ke/` (nhắc: chốt trên canvas rồi đẩy lên
   git), và dừng.
3. File đổi thật: `git log --oneline -- design/` (commit `design <mã>: …`), `git show --stat <commit>`.
4. `syncedVersion` cũ hơn mục mới nhất → `dart run tool/sync_design.dart`, đọc phần **Cần chú ý**; chuỗi đổi thì
   `flutter gen-l10n`.

## 2. Chia loại, khoanh phạm vi, trình kế hoạch

Với từng mục (cũ → mới), chỉ đọc phần **Việc cần làm trong code** và danh sách file `design/` của mục:

| Loại | Dấu hiệu | Cách làm |
|---|---|---|
| **token/chuỗi** | chỉ màu, chuỗi, icon, dữ liệu nội dung; script đã đồng bộ | Không sửa code (trừ token chữ/khoảng cách → `app_text.dart` tay; chuỗi bị bỏ → gỡ chỗ dùng). |
| **giao diện** | đổi màn/widget, số đo, bố cục | Sửa màn/widget (mục 3). |
| **luồng/luật** | `navigation.json`, route, điều kiện hiện/ẩn, hành vi bấm | Đối chiếu `docs/testing/quy_tac.md` **trước** (dưới). |
| **dữ liệu / thiết bị** | dữ liệu mới, dòng `- Cần firmware: …` | Model + repository; API thiết bị chưa có → báo người dùng: việc của firmware (`src/core/web.cpp`), làm trước hay đợi. |

- **Khoanh file**: tên màn/widget → `dart ../.claude/skills/lead/scripts/impact.dart <từ khoá>` (Bản đồ tính năng của
  `/lead`); grep tên widget trong `lib/` trước khi mở file.
- **Sổ quy tắc** (mục luồng/luật, giao diện có đổi hành vi, mọi dòng `- Đổi luật: …` — dòng này luôn phải hỏi):
  khớp → làm. Thiết kế đổi luật mà sổ chưa có → **dừng, hỏi** người dùng chốt không; chốt → sửa `quy_tac.md` trước,
  test đỏ, rồi code. Thiết kế trái luật đã chốt → **không làm theo thiết kế**; ghi `docs/testing/gui_thiet_ke_<ngày>.md`
  (bảng "Thiết kế ghi khác app"), cột App của quy tắc ghi `tk`.
- **Sổ lỗi**: grep `docs/loi.md` phần **Đang mở** theo màn của mục → báo cùng kế hoạch. Áp xong sinh lỗi mới → `/loi`.
- **Duyệt**: chỉ token/chuỗi hoặc giao diện nhỏ (≤ 2 file, không màn mới, không màn cũ phải chuyển cấu trúc) → báo
  một dòng mỗi mục rồi làm. Còn lại → bảng `mã · loại · file sẽ sửa · cần quyết định`, **dừng chờ duyệt**. Mục lớn →
  kế hoạch `docs/tasks/<ngày>-thiet-ke-<mã>.md` theo mẫu `/lead`.

## 3. Áp từng mục

Mỗi lần **một mục**, cũ → mới:

1. Đọc mục của màn trong `screen_specs.md` (không đọc cả file), `components.md`, ảnh `@3x`; số đo chính xác từ
   `design/source/<Màn>.dc.html` (grep theo khối / prop).
2. Sửa theo `flutter-dev`: màn mới `<x>_screen.dart` + `<x>_view_model.dart`, nối route (mẫu `references/ui_layer.md`);
   widget dùng chung `lib/ui/core/widgets/`. Số trong thiết kế không có token → token gần nhất của `AppSpace` / `AppSize`;
   khác hẳn → hằng có tên trong widget. Giữ nguyên phần mục không nhắc tới. Ảnh ≠ đặc tả ≠ HTML → theo HTML, ghi vào báo cáo.
3. Test: logic mới (ViewModel / use case / rules) → unit test; đổi luật → test mang mã `R-…`; giao diện có trạng thái
   → `testWidgets`. Không golden test.
4. Kiểm: `dart tool/check.dart --changed`, `flutter analyze`, `flutter test -r failures-only test/<phần>`; đổi luật thêm
   `dart tool/rule_trace.dart`.
5. **Ghi `appliedVersion` = mã mục vừa xong ngay** (`app/.design_sync.json`), rồi sang mục kế. Dừng giữa chừng → `/ui-apply tiep`.
6. Mục đáp một phiếu (dòng `- Phiếu: …`, hoặc cùng màn / cùng việc với phiếu `chờ thiết kế`) → phiếu ghi
   `đã áp (<mã>)`; phiếu có nối kế hoạch `/lead` hay lỗi `/loi` → mở lại việc đó. Chỉ đáp một phần → ghi phần thiếu vào
   phiếu, giữ `chờ thiết kế`.

Cuối: `flutter test -r failures-only`. Báo: mục đã áp (mã · một dòng · file), mục gửi lại thiết kế, việc chờ quyết
định, và **Xem trên máy**: các màn cần mở trên điện thoại (nối thiết bị thật nếu màn cần dữ liệu thiết bị) để so với
ảnh `@3x`. Không commit khi chưa được bảo.

## 4. Kiểm một màn (`kiem <Màn>`)

1. Tìm màn: ảnh `design/screens/@3x/<Màn>*.png`, mục `screen_specs.md`, `source/<Màn>.dc.html`; code qua Bản đồ tính năng.
2. Đối chiếu từng khối: có / thiếu / thừa, thứ tự, số đo, token màu/chữ, chuỗi, trạng thái (đang tìm, đang tải, lỗi,
   rỗng), hành vi bấm (`navigation.json`).
3. Báo bảng `khối · thiết kế · app · nguồn (file:dòng)`, chia **app sai** (sửa bằng `/ui-apply` hoặc `/loi`), **thiết
   kế ghi khác luật đã chốt** (gửi thiết kế), **không chắc** (xem trên máy). Không sửa gì. Màn chưa có trên canvas →
   "chưa có trên canvas, theo code" + đề xuất phiếu.

## 5. Phiếu yêu cầu thiết kế (`phieu <yêu cầu>`)

Gọi trực tiếp, hoặc từ `/lead` / `/loi` khi việc cần giao diện mà `design/` chưa có. Không đọc code sâu, không sửa code.

1. Gom bối cảnh, đọc ít: màn hiện có (ảnh `@3x`, mục `screen_specs.md`, widget dùng lại được), luật `R-…` liên quan,
   chuỗi đã có, dữ liệu thiết bị trả về được (`README.md` mục API), đồ đang dựng tạm (nếu có).
2. Mơ hồ tới mức hai cách vẽ khác hẳn → hỏi tối đa 2 câu. Phiếu nói **cần gì**, không nói vẽ thế nào (ý tưởng ghi là gợi ý).
3. Ghi `docs/phieu_thiet_ke/<YYYY-MM-DD>-<tên-không-dấu>.md` theo mẫu, trạng thái `chờ thiết kế`. Có kế hoạch `/lead`
   hoặc lỗi `/loi` sinh ra phiếu → ghi tên phiếu vào đó, và tên việc đó vào phiếu.
4. Báo: đường dẫn phiếu + **nguyên khối "Dán vào canvas"** trong một khối code. Phiếu phải **commit và đẩy lên GitHub**
   thì phiên thiết kế mới thấy: hỏi rồi commit riêng `docs: phiếu thiết kế <tên>`. Nhắc: bên ngoài gõ
   `/ui-design phieu` (hoặc dán khối) → vẽ → chốt → trong VS Code `/ui-apply`.

### Mẫu phiếu

```markdown
# Phiếu thiết kế: <tên việc>

- Trạng thái: chờ thiết kế | đã áp (<mã CHANGELOG>) | bỏ (<lý do>)
- Ngày: <YYYY-MM-DD> · Nguồn: <yêu cầu người dùng | kế hoạch docs/tasks/… | lỗi L-…>

## Dán vào canvas

**Màn / widget:** <tên theo components.md / screen_specs.md, hoặc "màn mới">
**Cần:** <việc người dùng làm được trên màn này, 1–3 câu>
**Trạng thái phải vẽ:** <mặc định, đang tìm thiết bị, đang tải, lỗi, rỗng, …>
**Luật phải theo:** <R-…: nguyên văn ngắn>
**Dữ liệu từ thiết bị:** <trường API có sẵn / cần firmware thêm>
**Chuỗi:** <khoá có sẵn dùng lại được / câu chữ mới cần đặt khoá>
**Dùng lại:** <widget, token, icon có sẵn>
**Gợi ý (không bắt buộc):** …
**App đang có (dựng tạm):** <mô tả, hoặc "chưa có">

## Ghi chú phía code
- Chặn việc: <nhiệm vụ / lỗi đang chờ phiếu này>
```
