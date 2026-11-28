# Phiếu thiết kế: hàng skill Giải trí (Dò mìn) trên màn Skill

- Trạng thái: chờ thiết kế
- Ngày: 2026-11-27 · Nguồn: áp panel P-2026-11-27.25 (Dò mìn) — skill Giải trí `fun` thành gói thật

## Dán vào canvas

**Màn / widget:** `SkillsScreen` (screen_specs §6) — `SkillRow` của Giải trí (trước đây chỉ là chip "Sắp có").

**Cần:** Giải trí nay bật / tắt được như Ảnh, Thời tiết, Đồng hồ: bật thì thiết bị có chương trình Dò mìn (biểu
tượng desktop, Start). Hàng cần biểu tượng dock dạng pixel như các skill khác và câu mô tả.

**Trạng thái phải vẽ:** tắt (mặc định), bật, đang gửi, firmware cũ ("Cần firmware mới"), skill cuối cùng còn bật.

**Luật phải theo:** R-SK-1 (Giải trí mặc định tắt, thứ tự dock sau Đồng hồ), R-SK-2, R-SK-4, R-DK-23.

**Dữ liệu từ thiết bị:** `skills` trong `/api/state` có `fun` khi firmware có Dò mìn (đã có).

**Chuỗi:** `skillFunName` "Giải trí", `skillFunDesc` "Nội dung vui cho màn hình." (có sẵn — xem lại câu cho đúng Dò mìn).

**Dùng lại:** màu `skillFun` / `skillFunTint`, `SkillRow`, `SkillSwitch`; gợi ý icon dock: quả mìn pixel 16 như icon
Start của thiết bị (panel P-.25).

**App đang có (dựng tạm):** hàng dùng icon tay cầm Material của chip "Sắp có" (`Icons.videogame_asset`) thay icon dock.

## Ghi chú phía code
- `lib/ui/core/skill_style.dart` `dockIcon` lùi về icon chip khi skill chưa có icon pixel.
