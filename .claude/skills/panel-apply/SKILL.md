---
name: panel-apply
description: Người áp thiết kế màn thiết bị glimmer vào firmware (thiết kế trước, code sau) — soạn phiếu khi màn chưa được vẽ; lấy bản mới trong design/panel/ (CHANGELOG mã P-…), chia từng mục theo loại, sửa src/channels/ đúng kỷ luật vẽ lại từng phần, cập nhật tools/screens.py, build, so ảnh với thiết kế, ghi tiến độ, và nạp lên máy khi được bảo. Dùng khi người dùng gõ /panel-apply, hoặc nói "thiết kế màn thiết bị vừa cập nhật", "áp thiết kế lên máy", "màn trên máy lệch thiết kế", "cần vẽ kênh …".
argument-hint: "[tiep | <mã mục, vd .3> | kiem <Màn> | phieu <yêu cầu>]"
---

# /panel-apply: áp thiết kế vào firmware (phiên VS Code)

Lệnh: $ARGUMENTS

Thiết kế ở `design/panel/`, do phiên thiết kế (`/panel-design`, ngoài VS Code) đẩy lên: **không sửa tay**, không sửa
canvas. Code: `src/` theo `CLAUDE.md` gốc (đọc mục Channels & PARTIAL REDRAW DISCIPLINE, VLW fonts, Vietnamese UI trước
khi sửa). Tiến độ: `.panel_design_sync.json` ở gốc repo — `{"appliedVersion": "P-…"}` (mục CHANGELOG mới nhất đã áp).

| Lệnh | Làm gì |
|---|---|
| `/panel-apply` | Lấy bản mới, chia loại các mục chưa áp, trình kế hoạch, làm (mục 1–3). |
| `/panel-apply tiep` | Làm tiếp từ mục đầu tiên mới hơn `appliedVersion`, không pull lại. |
| `/panel-apply <mã>` | Chỉ áp một mục (vd `.3` = `P-<ngày>.3`). Mục cũ hơn còn chưa áp thì hỏi trước. |
| `/panel-apply kiem <Màn>` | So màn firmware với thiết kế, liệt kê chỗ lệch, **không sửa** (mục 4). |
| `/panel-apply phieu <yêu cầu>` | Soạn phiếu yêu cầu thiết kế, **không sửa code** (mục 5). |

| Thứ | Ở đâu |
|---|---|
| canvas | https://claude.ai/artifact/Kkt5gUfTSSTjxKBZ6mPuZA |
| nhật ký (`## P-… — …`) · đặc tả · token | `design/panel/CHANGELOG.md` · `docs/screen_specs.md` · `tokens/panel_tokens.json` |
| ảnh · số đo chính xác | `design/panel/screens/@2x/<Màn>*.png` · `design/panel/source/<Màn>.dc.html` |
| phiếu | `docs/phieu_panel/<ngày>-<tên>.md` |
| code màn | `src/channels/ch_<kênh>.cpp`, `chrome.{h,cpp}` (status bar, thẻ credential), `src/core/display.cpp` (Clawd, màn hệ thống), `theme.h`, `layout.h` |
| xem trước không cần nạp | `python tools/screens.py out.png [số màn…]` (vẽ tay theo code — **sửa layout thì sửa cả file này**), `tools/vlwpreview.py` (đo chữ) |

**Thiết kế trước, code sau.** Màn mà `design/panel/` chưa có → **không tự vẽ tạm**: soạn phiếu (mục 5), chờ bản chốt.
Phần không dính giao diện (dữ liệu, API, scheduler) làm trước được nếu người dùng muốn.

## 1. Lấy bản mới

1. `git status`: có thay đổi chưa commit chạm `src/`, `data/`, `tools/screens.py`, `.panel_design_sync.json` → dừng,
   hỏi. Rồi `git pull`.
2. Mục cần làm = các mục `## P-… — …` trong `design/panel/CHANGELOG.md` mới hơn `appliedVersion`. Không có → báo
   "Thiết kế màn thiết bị không có gì mới", kèm phiếu `chờ thiết kế` trong `docs/phieu_panel/`, và dừng.
3. `appliedVersion` trống (lần đầu) và mục duy nhất là "Bản đầu: vẽ lại màn hiện có" → không phải sửa code: chạy
   `kiem` (mục 4) cho từng màn để ghi chỗ bản vẽ lại lệch máy, báo người dùng chọn theo bên nào, rồi ghi `appliedVersion`.

## 2. Chia loại, khoanh phạm vi, trình kế hoạch

Với từng mục (cũ → mới), chỉ đọc phần **Việc cần làm trong code** và danh sách file của mục:

| Loại | Dấu hiệu | Cách làm |
|---|---|---|
| **màu** | token màu mới / đổi | `theme.h` (RGB565 = `(R>>3)<<11 \| (G>>2)<<5 \| B>>3`, ghi hex gốc trong chú thích) + bảng màu đầu `tools/screens.py`. |
| **font** | "Cần firmware: font …" | `/regenerate-fonts`; kiểm FS 1 MB; nạp filesystem **xoá config** trừ khi làm theo "bake the config in" (`CLAUDE.md` mục Flashing) → nói rõ với người dùng trước. |
| **bố cục** | tọa độ, khối, chữ | Sửa `draw()` + `paintX()` của kênh (mục 3). |
| **hành vi** | "Đổi luật", thời gian giữ thẻ, ưu tiên, dim/tối, skill | Đối chiếu `CLAUDE.md` gốc **trước**; khác luật đã ghi → dừng, hỏi người dùng chốt; chốt → sửa `CLAUDE.md` + test `test/` (pio native) rồi code. |
| **dữ liệu** | "Cần firmware: dữ liệu …" | API / parse / scheduler (`src/data/`); giữ cổng heap (`kTlsFloor`), parse có filter. Setting mới → bốn file (`CLAUDE.md` mục Settings round-trip). |

- **Sổ lỗi** firmware nếu có (`docs/loi.md`, phần Đang mở) theo kênh của mục → báo cùng kế hoạch.
- **Duyệt**: chỉ màu / chữ hoặc bố cục nhỏ (≤ 2 file, không font mới, không dữ liệu mới) → báo một dòng mỗi mục rồi làm.
  Còn lại → bảng `mã · loại · file sẽ sửa · cần quyết định`, **dừng chờ duyệt**.

## 3. Áp từng mục

Mỗi lần **một mục**, cũ → mới:

1. Đọc mục của màn trong `screen_specs.md` (không đọc cả file), ảnh `@2x`; tọa độ chính xác từ
   `design/panel/source/<Màn>.dc.html` (grep `top:` / `left:` của khối). Ảnh ≠ đặc tả ≠ HTML → theo **đặc tả** (có số
   đo), ghi vào báo cáo.
2. Sửa theo kỷ luật màn:
   - `draw()` vẽ lại toàn màn, seed cache; `tick()` 5 Hz **không bao giờ** `Display::clear()` / `fillScreen()` — chỉ
     `paintX()` xoá đúng dải của nó khi giá trị đổi (cache file-static, sentinel `-1` / `-2.f`). Mẫu: `ch_clock.cpp`,
     `ch_home.cpp`.
   - Không vẽ ngoài y 24–219 (trừ status bar qua `chrome`, vạch chỉ báo do `main.cpp`). Không thêm hiệu ứng chuyển.
   - Chữ tiếng Việt: `Utf8::copy` / `Utf8::prevChar` khi cắt, `Utf8::upper` khi viết hoa; literal trong flash
     (`PSTR` / `F()` / `snprintf_P`). `Display::useFont("JBMono-12B")` — thiếu file là im lặng dùng font cũ.
   - Không cấp phát lớn (không sprite toàn màn; heap ~25 KB, TLS cần 20 KB liền).
3. Cập nhật `tools/screens.py` cho khớp code vừa sửa (nó vẽ tay theo code). Render màn đó:
   `python tools/screens.py <scratchpad>/m.png <số>` → so với ảnh `@2x` của thiết kế (mở cả hai bằng Read). Lệch → sửa.
   Nhãn mới: đo bằng `tools/vlwpreview.py`, vượt khe (status ≈ 88 px, meta ≈ 72 px) → báo, không tự đổi chữ.
4. Kiểm: `pio run -e nodemcuv2` (RAM tĩnh không tăng bất thường — so dòng `RAM:` trước / sau), `pio test -e native`.
5. **Ghi `appliedVersion` ngay** (`.panel_design_sync.json`), rồi sang mục kế. Dừng giữa chừng → `/panel-apply tiep`.
6. Mục đáp một phiếu → phiếu ghi `đã áp (<mã>)`; đáp một phần → ghi phần thiếu, giữ `chờ thiết kế`.

Cuối: báo mục đã áp (mã · một dòng · file), việc chờ quyết định, ảnh so sánh (đường dẫn đầy đủ), và **Xem trên máy**:
kênh nào cần nhìn trên thiết bị thật. **Nạp lên máy chỉ khi người dùng bảo**: chỉ firmware → `curl -F
"firmware=@.pio/build/nodemcuv2/firmware.bin" http://<ip>/update`; có đổi `data/` → luồng "bake the config in" trong
`CLAUDE.md`. Sau khi nạp, nhắc rút điện cắm lại một lần (khởi động lại bằng phần mềm để lại heap thấp). Không commit khi
chưa được bảo.

## 4. Kiểm một màn (`kiem <Màn>`)

1. Thiết kế: ảnh `design/panel/screens/@2x/<Màn>*.png`, mục `screen_specs.md`, `source/<Màn>.dc.html`. Máy:
   `python tools/screens.py` (màn đó) + `src/channels/ch_<kênh>.cpp`.
2. Đối chiếu từng khối: có / thiếu / thừa, tọa độ, font, màu, chữ, trạng thái (đang tải, số liệu, STALE, lỗi, credential).
3. Báo bảng `khối · thiết kế · firmware · nguồn (file:dòng)`, chia **firmware sai**, **thiết kế trái giới hạn / luật**
   (gửi lại thiết kế), **không chắc** (xem trên máy). Không sửa gì.

## 5. Phiếu yêu cầu thiết kế (`phieu <yêu cầu>`)

Gọi trực tiếp, hoặc khi một việc firmware cần màn mà `design/panel/` chưa có. Không đọc code sâu, không sửa code.

1. Gom bối cảnh ít: màn hiện có (ảnh `@2x`, mục đặc tả, hoặc `tools/screens.py`), luật liên quan trong `CLAUDE.md`, dữ
   liệu firmware có sẵn (`/api/state`).
2. Mơ hồ tới mức hai cách vẽ khác hẳn → hỏi tối đa 2 câu. Phiếu nói **cần gì**, không nói vẽ thế nào.
3. Ghi `docs/phieu_panel/<YYYY-MM-DD>-<tên-không-dấu>.md` theo mẫu, trạng thái `chờ thiết kế`.
4. Báo đường dẫn + **nguyên khối "Dán vào canvas"** trong một khối code. Phiếu phải **commit và đẩy** thì phiên thiết kế
   mới thấy: hỏi rồi commit riêng `docs: phiếu màn thiết bị <tên>`. Nhắc: bên ngoài gõ `/panel-design phieu` → vẽ → chốt →
   trong VS Code `/panel-apply`.

### Mẫu phiếu

```markdown
# Phiếu màn thiết bị: <tên việc>

- Trạng thái: chờ thiết kế | đã áp (<mã P-…>) | bỏ (<lý do>)
- Ngày: <YYYY-MM-DD> · Nguồn: <yêu cầu người dùng | kế hoạch … | lỗi …>

## Dán vào canvas

**Kênh / màn:** <tên trong kChannels[], hoặc "kênh mới">
**Cần:** <người nhìn màn này biết được gì, 1–3 câu>
**Trạng thái phải vẽ:** <đang tải, có số liệu, STALE, lỗi, credential hỏng, ban đêm, …>
**Luật phải theo:** <trích ngắn từ CLAUDE.md>
**Dữ liệu từ firmware:** <trường có sẵn / cần thêm>
**Chữ:** <câu chữ cần có, khe dự kiến>
**Dùng lại:** <status bar, pixelBar, Clawd, thẻ credential, màu kênh>
**Gợi ý (không bắt buộc):** …
**Máy đang có:** <mô tả, hoặc "chưa có">
```
