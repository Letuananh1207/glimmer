---
name: loi
description: Sổ lỗi của glimmer. Ghi lỗi người dùng báo vào docs/loi.md (mã L-…), liệt kê lỗi đang mở, và sửa từng lỗi theo quy trình tái hiện bằng test đỏ → sửa → chờ thử máy thật. Dùng khi người dùng gõ /loi, hoặc báo lỗi ("bị lỗi", "không chạy", "sai", "kẹt", "mất dữ liệu") — kể cả khi chưa muốn sửa ngay.
argument-hint: "[<mô tả lỗi> | sua [L-…] | xong L-… | mo L-…]"
---

# /loi: sổ lỗi

Lệnh: $ARGUMENTS

Sổ: `docs/loi.md`. Một lỗi = một mục `### L-<số> · <tóm tắt>`, số tăng dần, không dùng lại. Trạng thái (dòng
`- Trạng thái:`): `mới` → `đang sửa` → `chờ thử máy` → `xong` · hoặc `không sửa (<lý do>)`.

| Lệnh | Làm gì |
|---|---|
| `/loi` | Liệt kê lỗi chưa `xong`, xếp: `chặn dùng` → `khó chịu` → `nhỏ`, cùng mức thì mã nhỏ trước. Không sửa gì. |
| `/loi <mô tả>` | **Chỉ ghi**, không sửa (mục 1). |
| `/loi sua [L-…]` | Sửa lỗi đó; không có mã thì lấy lỗi đứng đầu danh sách mở (mục 2). |
| `/loi xong L-…` | Người dùng đã thử máy thật, đạt → `xong`, chuyển mục xuống **Đã xong**. |
| `/loi mo L-…` | Thử máy vẫn lỗi → mở lại về `mới`, chuyển lên **Đang mở**, ghi thêm lần thử vào **Lịch sử**. |

Người dùng báo lỗi trong chat mà không gõ `/loi`: hỏi "Ghi vào sổ lỗi rồi sửa luôn, hay chỉ ghi?" (một câu), rồi
làm theo mục 1 (+ mục 2).

## 1. Ghi lỗi

1. Đọc `docs/loi.md`: lỗi này đã có chưa (cùng hiện tượng, cùng màn)? Có rồi và đang mở → thêm vào **Lịch sử**
   của mục đó, không tạo mã mới. Có rồi mà `xong` → `mo` lại (tái phát), ghi rõ.
2. Cần đủ 4 thứ; thiếu thì hỏi **một lần**, gộp các câu (tối đa 3), không đoán:
   - Hiện tượng (lời người dùng, giữ nguyên văn).
   - Các bước (màn nào, dữ liệu nào, đã đăng nhập hay chưa, theo thứ tự). Lỗi dính ngày giờ → hỏi thêm: xảy ra hôm
     nào, có qua 00:00 hay đổi giờ máy không.
   - Mong đợi / thực tế.
   - Bằng chứng: ảnh màn hình, máy (Android/iOS, hãng), dòng log — có thì ghi, không có thì ghi "chưa có".
3. Tự điền (không hỏi): **Phần** (theo Bản đồ tính năng của `/lead`), **Quy tắc** `R-…` liên quan (tra
   `docs/testing/quy_tac.md`, không có thì "chưa có"), **Mức độ** (`chặn dùng`: không dùng tiếp được, văng app,
   mất dữ liệu, không đăng nhập / đồng bộ được; `khó chịu`: tính sai, báo sai, phải thao tác lại; `nhỏ`: chữ,
   giao diện lệch, âm thanh) — ghi lý do một dòng, người dùng sửa được.
4. Ghi mục theo **Mẫu** dưới vào **Đang mở**, trạng thái `mới`. Không đọc code sâu, không sửa gì. Báo lại: mã,
   tóm tắt, mức độ, và một dòng "sửa bằng `/loi sua L-…`".

## 2. Sửa lỗi

Trạng thái → `đang sửa`. Làm theo thứ tự, ghi kết quả từng bước vào mục **Sửa** của lỗi:

1. **Tìm nguyên nhân**: khoanh file bằng `dart .claude/skills/lead/scripts/impact.dart <từ khoá>`, rồi đọc đúng đoạn
   cần. Ghi nguyên nhân bằng lời thường. Nguyên nhân nằm ở file sinh tự động (danh sách ở `CLAUDE.md`) → **không sửa
   tay**, sửa nguồn sinh ra nó.
2. **Hành vi đúng là gì?** Quy tắc `R-…` đã nói rõ → theo quy tắc. Quy tắc sai / thiếu, hoặc phải chọn giữa nhiều
   cách → dừng, trình lựa chọn (đề xuất một), chờ người dùng. Đổi hành vi nghiệp vụ → sửa `docs/testing/quy_tac.md`
   trước (ghi "Bạn chốt <ngày>").
3. **Tái hiện bằng test đỏ**, chọn tầng rẻ nhất mà đúng với lỗi (cách viết: `flutter-dev/references/testing.md`):
   - Logic (repository / use case / rules) → `test/rules/<vùng>_test.dart` hoặc test gương, đồng hồ giả.
   - Màn / điều hướng → `testWidgets`; luồng nhiều màn → `test/flows/`.
   - Tên test **bắt đầu bằng mã quy tắc** rồi tới mã lỗi: `'R-GIO-2 (L-3): thêm trùng → giỏ không đổi'`;
     chưa có quy tắc thì `'(L-3): …'`. Chạy, **phải đỏ** đúng như hiện tượng.
   - Không dựng được (font, kết xuất, âm thanh, thông báo, mạng thật) → ghi lý do, sang bước 4 nhưng báo rõ
     "chưa khoá được bằng test".
4. **Sửa code** theo `flutter-dev`, nhỏ nhất đủ làm test xanh. Việc lớn (≥ 3 file ngoài phần lỗi, đổi giao diện,
   đổi dữ liệu người dùng đã lưu, đổi server) → chuyển sang `/lead` với mô tả lỗi, ghi tên kế hoạch `docs/tasks/…`
   vào mục lỗi. Sửa lỗi cần giao diện mà `design/` chưa vẽ (lỗi do thiếu trạng thái, thiếu màn) → `/ui-apply phieu`,
   lỗi chờ phiếu; giao diện lệch thiết kế đã chốt → sửa theo `design/` như lỗi thường.
5. **Kiểm**: `dart tool/check.dart --changed`, `flutter analyze`, `flutter test -r failures-only test/<phần>`,
   `dart tool/rule_trace.dart`.
6. Trạng thái → `chờ thử máy` (hoặc `xong` nếu lỗi kiểm trọn được bằng test, không dính font, âm thanh, thông báo,
   server hay máy cụ thể). Ghi **Thử máy**: các bước ngắn nhất để người dùng xác nhận + thứ cần chụp/gửi nếu còn lỗi.
7. Báo lại: nguyên nhân, đã sửa gì, test nào khoá, các bước thử máy. Không commit khi chưa được bảo; được bảo thì
   commit `fix: … (L-…)`, ghi mã commit vào mục lỗi.

## Mẫu

```markdown
### L-<số> · <tóm tắt một dòng>

- Trạng thái: mới · Mức độ: khó chịu (<lý do>) · Phần: <tính năng> · Quy tắc: R-…
- Báo: <ngày> — "<nguyên văn người dùng>"
- Các bước: 1. … 2. …
- Mong đợi / thực tế: … / …
- Bằng chứng: <ảnh màn hình / máy / log / chưa có>

**Sửa**
- Nguyên nhân: …
- Test: `test/…` — `'R-… (L-<số>): …'`
- Code: `lib/…`
- Thử máy: …
- Commit: …

**Lịch sử**
- <ngày>: …
```
