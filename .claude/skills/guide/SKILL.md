---
name: guide
description: Trợ giúp về các skill / lệnh của dự án này — bảng tổng các lệnh, chi tiết một lệnh, và "việc này dùng lệnh nào". Dùng khi người dùng gõ /guide, hoặc hỏi "có những lệnh gì", "dùng lệnh nào để…", "luồng làm việc thế nào", "skill X làm gì".
argument-hint: "[<tên skill> | <việc muốn làm>]"
---

# /guide: trợ giúp

Câu hỏi: $ARGUMENTS

Chỉ đọc, không sửa gì. Trả lời tiếng Việt, ngắn. **Luôn đọc thật** các skill đang có, không trả lời theo trí nhớ:
mỗi `.claude/skills/*/SKILL.md` chỉ đọc phần frontmatter (`name`, `description`, `argument-hint`) và bảng lệnh đầu file
(grep `^| \`/`); thêm `.claude/commands/*.md` (nếu có) và mục quy trình trong `CLAUDE.md`.

## Không có tham số → bảng tổng

1. Một dòng: dự án này là gì (lấy từ đầu `CLAUDE.md`).
2. Bảng `Lệnh · Làm gì (một dòng) · Gõ tay / tự gọi` — skill không gõ tay (bộ chuẩn `flutter-dev`) vẫn liệt kê.
3. **Luồng thường dùng** — chỉ những luồng mà mọi skill trong đó **đều có** trong dự án:
   - Tính năng mới: `/lead <yêu cầu>` → duyệt kế hoạch → làm → `/lead tiep` nếu dừng giữa chừng.
   - Lỗi: `/loi <mô tả>` (ghi) → `/loi sua` → thử máy → `/loi xong L-…` hoặc `/loi mo L-…`.
   - Thiết kế app: (ngoài VS Code) `/ui-design <yêu cầu>` → `chốt` → (VS Code) `/ui-apply`.
   - Thiết kế màn thiết bị: (ngoài VS Code) `/panel-design <yêu cầu>` → `chốt` → (VS Code) `/panel-apply` → nạp máy.
   - Chốt chặn tự động: hook Stop + git pre-commit chạy `dart tool/guard.dart` (quy tắc lớp + lỗi biên dịch).
4. Dòng cuối: "Chi tiết một lệnh: `/guide <tên>` · Hỏi việc: `/guide <việc muốn làm>`".

## Tham số là tên skill (`/guide loi`, `/guide lead`…)

Đọc **cả** `SKILL.md` của skill đó. Báo: làm gì (2 câu), bảng lệnh con (`lệnh · làm gì`), file nó ghi (sổ, kế
hoạch…), skill nó gọi / được gọi từ đâu, và một ví dụ gõ thật. Không có skill tên đó → liệt kê tên gần giống.

## Tham số là việc muốn làm (`/guide muốn thêm màn đăng nhập`, `/guide app bị kẹt khi…`)

Chọn **một** lệnh phù hợp nhất, giải thích một câu vì sao, rồi ghi đúng câu lệnh nên gõ, vd
`/loi bấm Lưu không có phản hồi`. Không chắc giữa hai lệnh → nêu cả hai, mỗi cái một dòng khi nào dùng. Không tự
chạy lệnh đó.
