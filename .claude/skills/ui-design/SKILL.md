---
name: ui-design
description: Phiên THIẾT KẾ giao diện app Android glimmer (Claude ngoài VS Code — claude.ai/code, trình duyệt hoặc app máy tính). Trò chuyện với người dùng để vẽ / sửa màn trên canvas, nhận phiếu yêu cầu từ phía code, giữ đúng luật nghiệp vụ, và khi người dùng "chốt" thì xuất sang design/ (source, ảnh, đặc tả, token, chuỗi, CHANGELOG) rồi đẩy lên GitHub. Dùng khi người dùng gõ /ui-design, dán một phiếu "Dán vào canvas", hoặc nói "vẽ", "sửa giao diện", "thiết kế màn", "đổi bố cục", "chốt thiết kế". Không dùng cho màn hình 240×240 của thiết bị (firmware).
argument-hint: "[<yêu cầu> | <phiếu dán vào> | phieu | chot | xem]"
---

# /ui-design: phiên thiết kế app glimmer

Lệnh: $ARGUMENTS

Vai trò: người thiết kế. Repo glimmer có firmware ở gốc và app Flutter ở `app/`; **thiết kế của app ở `design/` (gốc
repo)**. Phiên này **chỉ** ghi `design/` (và trạng thái phiếu trong `app/docs/phieu_thiet_ke/`). **Không sửa** `app/lib/`,
`app/test/`, `app/tool/`, `app/assets/`, `.claude/`, firmware (`src/`, `data/`), sổ quy tắc. Việc cần code làm thì ghi
vào CHANGELOG; phía code (VS Code, `/ui-apply`) áp vào app. Câu "không sửa tay `design/`" trong `app/CLAUDE.md` là luật
cho phía code; phiên này **là** nơi viết `design/`.

**Canvas**: "glimmer – giao diện app" https://claude.ai/artifact/WzLqGhKvD1MYxqaiRkzq1r (loại Design). Sửa bằng công
cụ Artifact theo hướng dẫn của chính loại Design (đọc `SKILL.md` của canvas trước lần sửa đầu: `read` path `SKILL.md`).
Chỉ ghi dưới `project/`. Không tạo canvas mới. Khung màn 390 × 844, đơn vị = dp.

**Mọi lần báo cho người dùng** mở đầu bằng dòng:
`Canvas: glimmer – giao diện app — https://claude.ai/artifact/WzLqGhKvD1MYxqaiRkzq1r` (đang sửa một màn thì thêm
`· màn <Tên> (project/<Màn>.dc.html)`). Không đọc được canvas (thiếu quyền, lỗi) → nói rõ ngay, không đoán từ `design/`.

| Lệnh | Làm gì |
|---|---|
| `/ui-design <yêu cầu>` hoặc `<phiếu>` | Vẽ / sửa trên canvas, trò chuyện tới khi người dùng chốt (mục 1–2). |
| `/ui-design phieu` | Liệt kê phiếu `chờ thiết kế` trong `app/docs/phieu_thiet_ke/`, chọn một để làm. |
| `/ui-design chot` (hoặc người dùng nói "chốt") | Xuất sang `design/`, commit, đẩy lên GitHub (mục 3). |
| `/ui-design xem` | Đọc `project/canvas.json` + danh sách file canvas (`list` scope `files`), so với `design/source/` bằng **kích thước + mã băm** (không đọc nội dung): link canvas, số artboard, màn khác / chỉ có ở một bên (đã sửa mà chưa chốt). Chỉ báo. |

## 0. Lần đầu: canvas trống, `design/` chưa có

App đã có sẵn 5 màn dựng trước khi có luồng thiết kế. Việc đầu tiên là **vẽ lại hiện trạng** lên canvas để có nền
chung, rồi mới sửa:

1. Đọc `app/README.md` (chức năng từng màn) và code giao diện `app/lib/ui/*.dart` — chỉ để lấy bố cục, chữ, màu:
   `theme.dart` (bảng màu `G`, giống firmware `src/core/theme.h`; font JetBrains Mono), `connect_screen.dart` (Kết nối),
   `dashboard_screen.dart` (Tổng quan), `settings_screen.dart` (Cài đặt), `device_screen.dart` (Thiết bị),
   `wifi_setup_screen.dart` (Cài Wi-Fi), `clawd.dart` (linh vật Clawd đổi biểu cảm).
2. Vẽ mỗi màn một artboard `project/<Màn>.dc.html` (tên tiếng Anh, PascalCase: `Connect`, `Dashboard`, `Settings`,
   `Device`, `WifiSetup`), đủ trạng thái chính (đang tìm / không thấy thiết bị, đang tải, lỗi, rỗng).
3. Cho người dùng xem, sửa tới khi ưng, rồi **chốt lần đầu** (mục 3) — tạo khung `design/`:
   `README.md`, `CHANGELOG.md` (phần đầu như mẫu ở mục 3 + mục `## <mã> — Bản đầu: vẽ lại app hiện có`),
   `tokens/design_tokens.json`, `l10n/app_vi.arb`, `docs/screen_specs.md`, `docs/components.md`, `docs/navigation.json`,
   `screens/@3x/`, `source/`.

**`design_tokens.json`** (phía code sinh `AppColors` từ `color`; các khoá khác chép tay sang `app_text.dart`):

```json
{
  "meta": { "name": "glimmer", "frame": { "width": 390, "height": 844, "unit": "dp" } },
  "color": { "bg": { "value": "#0E0D12", "use": "Nền mọi màn" } },
  "font":  { "mono": { "family": "JetBrains Mono", "weights": [400, 700], "use": "Mọi chữ" } },
  "type":  { "title": { "font": "mono", "size": 20, "weight": 700, "use": "Tiêu đề màn" } },
  "space": { "xs": 4, "s": 8, "m": 12, "l": 16, "xl": 24 },
  "size":  { "tapMin": 44 },
  "radius": { "card": 14 },
  "border": { "hairline": 1 }
}
```

Tên màu camelCase, giá trị `#RRGGBB`, `#AARRGGBB` hoặc `rgba(r, g, b, a)`. Màu trùng nghĩa với màn hình thiết bị giữ
đúng mã của `src/core/theme.h` (người dùng nhìn hai thứ cạnh nhau).

## 1. Giữ canvas và `design/` nhẹ (mọi lượt)

- **Không nhúng base64** (ảnh, font, âm) vào `.dc.html`: tài nguyên → tài nguyên của canvas / file riêng, nhiều màn
  dùng chung một file. Trước khi chốt: `grep -c 'base64,'` của màn đã sửa không tăng; `.dc.html` > 300 KB → báo.
- **Không đọc nguyên trang lớn** vào ngữ cảnh: `read` canvas lưu file cục bộ → `grep -n` tìm đoạn, `sed -n 'a,bp'` đọc
  đúng đoạn. File lớn của `design/` (`CHANGELOG.md`, `screen_specs.md`) → grep tìm chỗ, chèn bằng script.

## 2. Trước khi vẽ, và khi vẽ

- `git pull` (bản `design/` và phiếu mới nhất).
- Yêu cầu từ phiếu → đọc `app/docs/phieu_thiet_ke/<…>.md`: phiếu nói **cần gì**, phiên này quyết định vẽ thế nào.
- Đọc đúng chỗ: mục của màn trong `design/docs/screen_specs.md` (grep `## <số>. <Màn>`), widget dùng lại trong
  `design/docs/components.md`, token `design/tokens/design_tokens.json`, chuỗi `design/l10n/app_vi.arb`.
- **Luật nghiệp vụ**: `app/docs/testing/quy_tac.md` (mã `R-…`, người dùng đã chốt). Vẽ theo luật. Ý tưởng trái luật →
  nói ngay: đổi luật (ghi dòng "Đổi luật" trong CHANGELOG để phía code chốt) hay đổi ý tưởng. Danh sách thiết kế đang
  ghi khác app: `app/docs/testing/gui_thiet_ke_*.md` — sửa được thì sửa luôn.
- **Giới hạn của thiết bị** là luật cứng: dữ liệu nào app hiện được phụ thuộc API firmware (`app/README.md` mục "API
  thiết bị dùng tới", chi tiết `CLAUDE.md` gốc). Vẽ thứ firmware chưa trả về → ghi rõ trong CHANGELOG là cần đổi firmware.
- Phong cách hiện có: nền tối theo bảng màu thiết bị, chữ JetBrains Mono, linh vật Clawd, giao diện tiếng Việt,
  vùng chạm ≥ 44. Đổi phong cách là quyết định của người dùng.
- Sửa đúng artboard của màn, chỉ phần được yêu cầu. Trạng thái mới = prop trong `data-props` hoặc artboard riêng.
  Mỗi lượt: sửa → một dòng đã đổi gì → người dùng xem trên canvas. Chưa chắc → 2–3 phương án.
- Chuỗi mới: đặt khoá l10n camelCase theo tiền tố màn (`dashboard…`, `settings…`) ngay khi vẽ, ghi lại để lúc chốt.
- Chưa chốt thì **không** ghi `design/`, không commit.

## 3. Chốt: xuất sang `design/` và đẩy lên GitHub

Làm đủ, theo thứ tự:

1. **Mã phiên bản** `YYYY-MM-DD.N`: ngày hôm nay, `N` = số của mục trên cùng + 1 (liên tục, không về 1 mỗi ngày):
   `grep -m1 -oE '^## [0-9-]+\.[0-9]+' design/CHANGELOG.md`. Bản đầu: `.1`. Nhiều thay đổi tách biệt → mỗi cái một mã.
2. **Source**: chép `project/<Màn>.dc.html` của canvas sang `design/source/<Màn>.dc.html` (nguyên văn). Icon SVG →
   `design/icons/*.svg` (màu `currentColor`); dữ liệu nội dung → `design/data/*.json`.
3. **Ảnh** `design/screens/@3x/<Màn><TrạngThái>.png` (1170 × 2532) cho mọi trạng thái đổi / mới, chụp bằng trình duyệt
   không giao diện. Không chụp được → giữ ảnh cũ, ghi "ảnh chưa cập nhật" trong mục CHANGELOG, báo người dùng.
4. **Đặc tả**: `design/docs/screen_specs.md` — dòng `> **<mã> — <tiêu đề>:** …` lên **đầu** mục của màn (số đo, khoá
   chuỗi, prop, ảnh); màn mới → mục `## <số>. <Tên> — \`<TênScreen>\` (<ảnh>.png)`. Widget mới / đổi →
   `design/docs/components.md`. Luồng, route, luật màn → `design/docs/navigation.json`.
5. **Chuỗi** → `design/l10n/app_vi.arb` (`"@@locale": "vi"`, mỗi khoá kèm `@khoá` mô tả, tham số). Token đổi →
   `design/tokens/design_tokens.json`.
6. **CHANGELOG**: mục mới **trên cùng** (dưới `---` của phần đầu), theo mẫu dưới; viết ra file tạm rồi chèn bằng script.
7. **Commit và đẩy**: chỉ file trong `design/` (và dòng `- Đã vẽ: <mã>` trong phiếu đáp ứng; phiếu giữ `chờ thiết kế`,
   phía code đóng). Thông điệp `design <mã>: <tóm tắt>`, thân 1–3 dòng. Đẩy lên `main`; bị từ chối → `git pull --rebase`
   rồi đẩy lại; xung đột trong `design/` → hỏi.
8. Báo: mã, tóm tắt, và "trong VS Code chạy `/ui-apply`".

### Phần đầu `design/CHANGELOG.md` (bản đầu)

```markdown
# Nhật ký thay đổi thiết kế — app glimmer

Mỗi mục có mã `YYYY-MM-DD.N` (N tăng liên tục). Mục mới nhất ở trên cùng. "Việc cần làm trong code" chỉ ghi tên màn /
widget và việc cần làm — không ghi đường dẫn file hay cách code. Phía code ghi mục đã áp ở `app/.design_sync.json`.

---
```

### Mẫu mục CHANGELOG

```markdown
## <mã> — <tiêu đề nói bằng lời người dùng>

- **<Khu vực> · `<TênWidget/TênScreen>`** (`source/<Màn>.dc.html`, `screen_specs.md` §<số>; ảnh `<Ảnh>.png`):
  - <thay đổi, có số đo, khoá chuỗi, prop>
  - <hiện app đang làm gì khác, nếu biết>
- Phiếu: `app/docs/phieu_thiet_ke/<…>.md` (bỏ dòng nếu không từ phiếu)
- Đổi luật: <R-… và luật mới đề xuất — phía code phải chốt trước khi làm> (bỏ dòng nếu không)
- Cần firmware: <dữ liệu / API mới thiết bị phải trả về> (bỏ dòng nếu không)

**Việc cần làm trong code:**
- `<TênScreen/TênWidget>`: <cần làm gì, nói theo hành vi và số đo>.
```
