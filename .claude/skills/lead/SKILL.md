---
name: lead
description: Trưởng nhóm của glimmer — nhận một yêu cầu thêm/sửa/xóa/cập nhật tính năng bằng lời, xác định phạm vi ảnh hưởng với ít token nhất (import thật + đồ thị understand-anything nếu có), chia thành nhiệm vụ, ghi kế hoạch vào docs/tasks/, rồi thực hiện. Dùng khi người dùng gõ /lead <yêu cầu>.
argument-hint: "<yêu cầu bằng lời> | tiep"
---

# /lead — từ yêu cầu đến nhiệm vụ

Yêu cầu: **$ARGUMENTS**

Vai trò: trưởng nhóm. Việc chính là **khoanh đúng phạm vi trước khi đọc code**, để không đọc thừa, không sửa thừa.
Code viết theo `.claude/skills/flutter-dev/` (đọc khi bắt tay vào làm, không phải lúc lập kế hoạch).

## 1. Hiểu yêu cầu — chưa đọc code

- Phân loại: **thêm** / **sửa hành vi** / **xóa** / **chỉ giao diện** / **sửa lỗi** / **dữ liệu-nội dung**.
- Dịch yêu cầu sang tên trong code bằng bảng **Bản đồ tính năng** ở cuối file.
- Yêu cầu mơ hồ đến mức hai cách hiểu cho ra hai kế hoạch khác nhau thì hỏi **tối đa 2 câu** (AskUserQuestion) rồi
  mới đi tiếp. Chi tiết nhỏ thì tự chọn cách hợp lý và ghi vào mục "Giả định" của kế hoạch.
- Rẽ nhánh sớm:
  - Yêu cầu là báo một lỗi cụ thể → dùng `/loi` (ghi sổ `docs/loi.md`, test đỏ trước). `/lead` chỉ nhận lỗi khi
    `/loi` chuyển sang vì việc sửa lớn.
  - Cần đổi file sinh tự động (danh sách ở `CLAUDE.md`) → **không sửa tay**; ghi vào kế hoạch là việc của công cụ sinh.
  - **Thiết kế trước, code sau**: việc cần giao diện mà `design/` (gốc repo) chưa vẽ → **không dựng tạm**; gọi
    `/ui-apply phieu <việc>` soạn phiếu, nhiệm vụ giao diện ghi cờ `chờ thiết kế: <phiếu>`; phần không dính giao diện
    (luật, dữ liệu, repository, API thiết bị) làm trước được. Giao diện đã có trong `design/` → làm theo đặc tả + ảnh.

## 2. Khoanh phạm vi — từ rẻ đến đắt, đủ thì dừng

1. **Script dò ảnh hưởng** (một lệnh, đầu ra gọn):
   ```
   dart .claude/skills/lead/scripts/impact.dart <từ khoá|đoạn đường dẫn>... [--depth N]
   ```
   Điểm khởi đầu = file có đường dẫn khớp từ khoá (+ node đồ thị understand-anything nếu có `.ua/`). Rồi lan ngược
   theo import/export/part trong `lib/`, `test/`, `testing/` — luôn mới vì đọc code hiện tại. In 3 nhóm: file khởi
   đầu, file dùng chúng (theo tầng), test liên quan.
   - File khởi đầu là model/repository dùng chung thì để `--depth 1`, tránh danh sách phình to.
2. **Grep có mục tiêu** để tìm chỗ dùng một hàm hay khoá l10n cụ thể.
3. **Read** chỉ những file trong nhóm "sẽ sửa", và chỉ đoạn cần (offset/limit).

Không dùng subagent để dò, trừ khi yêu cầu chạm từ 3 tính năng trở lên cùng lúc. Khi đó giao cho agent `Explore`
mỗi agent một tính năng, kèm sẵn kết quả của script.

Kết quả bước này là ba nhóm file:
- **Sẽ sửa**: kèm lý do một dòng.
- **Cần kiểm tra**: file dùng phần sẽ sửa; nếu chữ ký hoặc hành vi đổi thì có thể phải sửa theo.
- **Không đụng**: chỉ ghi khi người dùng có thể nghĩ là có đụng (ví dụ: "không đổi dữ liệu đã lưu").

## 3. Chia nhiệm vụ

Mỗi nhiệm vụ là một đơn vị làm và kiểm tra được độc lập, xếp theo thứ tự lớp: model/rules → repository → use case →
ViewModel → widget/màn → routing → l10n → test. Mỗi nhiệm vụ gồm:
- **Mục tiêu** (một câu), **file**, **lớp** (để biết đọc `references/` nào của flutter-dev).
- **Chuỗi mới**: khoá `dev…` trong `lib/l10n/app_vi.arb`.
- **Test**: thêm hoặc sửa ở đường dẫn gương trong `test/`. Logic mới ở ViewModel, use case hay rules thì bắt buộc có test.
- **Xong khi**: tiêu chí kiểm được.

Cờ cảnh báo, ghi ra nếu có:
- Đổi model hoặc repository **dữ liệu người dùng** → cập nhật `docs/backend/` cùng lúc. App chưa phát hành:
  sửa thẳng, **không viết code di trú**.
- Đổi hành vi nghiệp vụ → sửa `docs/testing/quy_tac.md` trước (mã `R-…`).
- Xóa tính năng → liệt kê cả chuỗi l10n, asset, route, test sẽ thành rác.

## 4. Ghi kế hoạch

Ghi vào `docs/tasks/<YYYY-MM-DD>-<tên-ngắn-không-dấu>.md` theo mẫu:

```markdown
# <Tên việc>

- Yêu cầu: <nguyên văn>
- Loại: <thêm|sửa|xóa|giao diện|lỗi|dữ liệu> · Cỡ: <nhỏ|vừa|lớn>
- Trạng thái: chờ duyệt | đang làm | xong

## Phạm vi
**Sẽ sửa** — `đường/dẫn.dart`: lý do
**Cần kiểm tra** — …
**Không đụng** — …

## Giả định / cần quyết định
- …

## Nhiệm vụ
- [ ] 1. <mục tiêu> — `file` (lớp) · test: `…` · xong khi: …
- [ ] 2. …

## Kiểm tra cuối
dart tool/check.dart --changed · flutter analyze · flutter test -r failures-only <các test liên quan>
```

## 5. Duyệt rồi làm

- **Cỡ nhỏ** (≤ 2 file sửa, không đổi dữ liệu lưu, không xóa, không có mục "cần quyết định"): ghi kế hoạch, báo một
  dòng rồi **làm luôn**.
- **Cỡ vừa/lớn**: trình tóm tắt trong chat (phạm vi + danh sách nhiệm vụ + câu hỏi nếu có), **dừng chờ duyệt**.
- Khi làm: đánh dấu `[x]` từng nhiệm vụ trong file kế hoạch ngay khi xong, để phiên sau có thể tiếp tục.
  Gặp điều ngoài phạm vi đã khoanh thì dừng, báo lại, cập nhật kế hoạch; không tự mở rộng.
- Kết thúc: chạy phần "Kiểm tra cuối", đổi trạng thái thành `xong`, báo bằng tiếng Việt: đã sửa gì, kết quả kiểm
  tra, việc còn chờ người dùng quyết định.
- Không commit hay push trừ khi người dùng yêu cầu.

`/lead tiep` (hoặc `/lead` không có tham số): mở file mới nhất trong `docs/tasks/` có trạng thái chưa `xong` và làm
tiếp từ nhiệm vụ chưa đánh dấu.

## Bản đồ tính năng (tiếng Việt → code)

| Người dùng nói                   | Từ khoá cho script / thư mục                         |
| -------------------------------- | ---------------------------------------------------- |
| Điều hướng, route                | `routing`, `router`, `routes`, `screens` (`lib/routing/`) |
| Tìm / kết nối thiết bị, IP, token | `connect`, `device_repository`, `discovery_service`, `local_store_service` |
| Tổng quan, mức dùng, bảng project, thẻ | `dashboard`, `usage_rules`, `board_rules`, `device_state`, `clawd` |
| Cài đặt (độ sáng, ban đêm, agent…) | `settings`, `device_repository`                  |
| Thiết bị, firmware, sao lưu/khôi phục | `device`, `release_repository`, `backup_repository`, `update_rules` |
| Cài / đổi Wi-Fi, glimmer-setup   | `wifi_setup`, `wifi_service`, `device_repository`    |
| Trạng thái chung của app (thiết bị, polling) | `device_repository`, `polling_lifecycle`  |
| Màu, font, giao diện chung       | `themes`, `app_text`, `status_colors`, `labels`      |
| Quy tắc nghiệp vụ, test quy tắc  | `docs/testing/quy_tac.md` (mã `R-…`), `lib/domain/rules/`, test ghi mã trong `test/` |

Thêm tính năng hoặc thư mục mới → bổ sung một dòng vào bảng này cùng lúc.
