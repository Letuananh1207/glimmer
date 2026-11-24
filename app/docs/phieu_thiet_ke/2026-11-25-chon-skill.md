# Phiếu thiết kế: Chọn skill + điều hướng theo skill

- Trạng thái: đã áp (2026-11-25.2)
- Đã vẽ: 2026-11-25.2
- Ngày: 2026-11-25 · Nguồn: kế hoạch `docs/tasks/2026-11-25-he-sinh-thai-skill.md` (nhiệm vụ 8)

## Dán vào canvas

**Màn / widget:** màn mới "Chọn skill" + đổi khung điều hướng hiện có (thanh 3 tab Tổng quan · Cài đặt · Thiết bị,
`components.md` "Thanh điều hướng dưới").

**Cần:** App thành một hệ sinh thái nhiều skill (gói chức năng): Agent (Claude / Codex — chính là 5 màn hiện có),
sau này Nhạc, Mạng xã hội, Giải trí… Người dùng (1) thấy các skill, biết skill nào đang chiếm màn thiết bị,
(2) chọn skill khác và thấy màn thiết bị đổi theo, (3) dùng các màn của skill đang chọn. Phần dùng chung mọi skill
(kết nối, Wi-Fi, firmware, sao lưu, độ sáng, ban đêm) vẫn phải tìm được.

**Trạng thái phải vẽ:**
- Danh sách skill: skill đang dùng (nổi bật), skill chọn được, skill "sắp có" (chưa có gói — Nhạc, Mạng xã hội,
  Giải trí: hiện hay ẩn là quyết định của thiết kế).
- Đang đổi skill (chờ thiết bị nhận), đổi lỗi (thiết bị không trả lời).
- Thiết bị firmware cũ không hỗ trợ skill: chỉ Agent, không đổi được, gợi ý cập nhật firmware.
- Khung điều hướng khi skill Agent đang dùng (5 màn hiện có nằm ở đâu: màn của Agent vs màn dùng chung).

**Luật phải theo:**
- R-SK-1: Mỗi lúc đúng một skill đang dùng; mặc định Agent.
- R-SK-2: Đổi skill trên app → thiết bị chỉ xoay kênh của skill đó + kênh hệ thống (Đồng hồ, Thời tiết, Dự báo,
  Thông tin, Ban đêm).
- R-SK-3: Thẻ cần duyệt / chờ trả lời của agent vẫn chen ngang ở mọi skill.
- R-SK-4: Firmware cũ (không báo skill) → chỉ Agent, không cho đổi.
- R-SK-5: Skill đổi từ trang web thiết bị → app theo thiết bị.

**Dữ liệu từ thiết bị:** có sẵn (firmware mới) — `GET /api/state`: `skill` (đang dùng, vd `"agent"`), `skills`
(danh sách thiết bị có); đổi bằng `POST /api/settings {"skill": "<id>"}`. Firmware cũ không có hai trường này.
Mỗi skill chưa có icon / mô tả từ thiết bị — tên, icon, mô tả do thiết kế đặt.

**Chuỗi:** chưa có khoá nào cho skill. Có sẵn: `navDashboard`, `navSettings`, `navDevice`, `commonRetry`,
`devErrSkillUnsupported` ("Thiết bị chưa hỗ trợ skill này — cập nhật firmware."). Cần khoá mới: tên + mô tả từng
skill, tiêu đề màn chọn skill, nhãn "đang dùng", "sắp có", trạng thái đang đổi.

**Dùng lại:** thẻ (Card), dòng danh sách (ListTile), nút chính / nút viền, Clawd (linh vật của skill Agent), token
màu hiện có; thanh điều hướng dưới.

**Gợi ý (không bắt buộc):** skill như "ứng dụng" trong app — một màn lưới / danh sách skill; mỗi skill có màu
nhấn riêng (Agent = `clawd`) để màn thiết bị và app cùng tông; tab đầu của thanh dưới đổi theo skill, Cài đặt /
Thiết bị dùng chung.

**App đang có (dựng tạm):** chưa có. Phần dữ liệu đã làm: danh mục skill, skill đang dùng (lưu máy), đổi skill gửi
thiết bị (`SwitchSkillUseCase`).

## Ghi chú phía code
- Chặn việc: nhiệm vụ 8 của `docs/tasks/2026-11-25-he-sinh-thai-skill.md` (UI chọn skill + route theo skill).
