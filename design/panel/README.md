# Thiết kế màn thiết bị glimmer (240×240)

Thiết kế của màn ST7789 240×240 trên GeekMagic SmallTV-Ultra. Thiết kế đi trước, code đi sau:

1. Vẽ trên canvas **glimmer – màn thiết bị** — https://claude.ai/artifact/Kkt5gUfTSSTjxKBZ6mPuZA — bằng `/panel-design`
   (Claude ngoài VS Code).
2. Khi chốt, phiên thiết kế xuất vào thư mục này, ghi một mục `P-YYYY-MM-DD.N` trong `CHANGELOG.md` và đẩy lên `main`.
3. Phía firmware chạy `/panel-apply` để áp vào `src/channels/`, build và nạp; tiến độ ghi ở `.panel_design_sync.json`.

Không sửa tay các file ở đây. Thiết kế của app Android nằm ở `design/` phần còn lại.

## Nội dung

| Đường dẫn | Là gì |
|---|---|
| `CHANGELOG.md` | Nhật ký thay đổi, mục mới nhất ở trên, kèm "Việc cần làm trong code". |
| `docs/screen_specs.md` | Đặc tả từng màn: tọa độ px, font VLW, màu token, datum căn chữ, độ rộng chữ đo bằng font thật, khi nào vẽ lại. |
| `tokens/panel_tokens.json` | Vùng, màu (hex + RGB565), font, khe chữ, thành phần dùng chung. Phía code chép tay sang `theme.h`. |
| `source/<Màn>.dc.html` | Nguồn artboard của canvas (nguyên văn). `Main.dc.html` là khung mẫu, `Clawd.dc.html` là linh vật dùng chung. |
| `screens/@2x/<Màn><TrạngThái>.png` | Ảnh 480×480 (phóng ×2, không làm mịn). |

## Ảnh và canvas khác nhau ở đâu

Canvas dùng Google Fonts `JetBrains Mono` / `VT323` cùng cỡ px, nên chữ có thể lệch 1–2 px. Ảnh trong
`screens/@2x/` được vẽ bằng **font VLW thật** trong `data/fonts/` và đúng tọa độ firmware, nên giống máy hơn. Khi hai
bên lệch nhau, **tin ảnh và đặc tả**.

## Giới hạn phần cứng (tóm tắt)

- **Khung:** 1 px canvas = 1 px panel. Status bar y 0–21, gạch nhấn y 22, nội dung y 24–219, vạch chỉ báo y 230.
- **Màu:** chỉ dùng bảng token, mỗi màn một màu nhấn. Không gradient, không trong suốt, không bóng (RGB565).
- **Chữ:** chỉ JBMono 11 / 13 / 12 đậm / 16 đậm và VT323 32 / 44 / 86. Không dùng `…` hay emoji.
- **Chuyển động:** không có hiệu ứng chuyển màn; trong màn chỉ đổi giá trị (5 lần/giây).
- **Đọc từ xa:** không có cảm ứng hay nút bấm, màn để nhìn từ khoảng 1 m.
