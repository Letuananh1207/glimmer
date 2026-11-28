# Thiết kế app glimmer

Thiết kế giao diện app Android (`app/`), làm trước code. Vẽ trên canvas "glimmer – giao diện app"
(https://claude.ai/artifact/WzLqGhKvD1MYxqaiRkzq1r) bằng `/ui-design`, xuất vào đây khi chốt; phía code áp bằng `/ui-apply`.
**Không sửa tay thư mục này** từ phía code — mọi thay đổi đi qua canvas.

| Đường dẫn | Nội dung |
|---|---|
| `CHANGELOG.md` | Các lần chốt (mã `YYYY-MM-DD.N`), việc cần làm trong code |
| `tokens/design_tokens.json` | Màu, font, cỡ chữ, khoảng cách, kích thước, bo góc |
| `l10n/app_vi.arb` | Mọi chuỗi giao diện (tiếng Việt) |
| `docs/screen_specs.md` | Đặc tả từng màn, số đo, trạng thái |
| `docs/components.md` | Widget dùng chung |
| `docs/navigation.json` | Màn, trạng thái, luồng chuyển |
| `screens/@3x/` | Ảnh 1170 px rộng của mọi trạng thái (màn dài cao hơn 2532) |
| `images/` | Ảnh dùng trong thiết kế (vd ảnh màn thiết bị); `source/*.dc.html` trỏ tới bản tải lên canvas `/_blob/…` cùng nội dung |
| `source/` | Bản gốc `.dc.html` chép nguyên từ canvas; `<Màn>.dc.html` có prop `state`, các file `<Màn><TrạngThái>.dc.html` chỉ nhúng lại |

Khung 390 × 844 dp. Bảng màu theo màn hình thiết bị (`src/core/theme.h`), chữ JetBrains Mono, linh vật Clawd.
