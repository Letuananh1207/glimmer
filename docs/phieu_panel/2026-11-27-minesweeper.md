# Phiếu màn thiết bị: Dò mìn (Minesweeper)

- Trạng thái: đã áp (P-2026-11-27.25) — firmware + app (R-DK-22, R-DK-23)
- Ngày: 2026-11-27 · Nguồn: lộ trình `app/docs/tasks/2026-11-27-chuong-trinh-xp-con-thieu.md` (bạn đồng ý 2026-11-27), mục 1
- Đã vẽ: P-2026-11-27.25

## Dán vào canvas

**Kênh / màn:** kênh mới `Mines` — cửa sổ XP "Dò mìn" (skill mới **Giải trí** `fun`, đang "sắp có" trong app), biểu
tượng desktop + mục Start (cột trái và Tất cả chương trình).

**Cần:** Chơi Dò mìn như Minesweeper của Windows XP bằng chuột của app: click trái mở ô, click phải cắm / gỡ cờ, click
mặt cười chơi ván mới. Người nhìn biết còn bao nhiêu mìn, đã chơi bao lâu, thắng hay thua.

**Trạng thái phải vẽ (theo XP thật):**
- Cửa sổ XP (thanh tiêu đề "Dò mìn", biểu tượng mìn), dưới tiêu đề có thể có thanh menu "Trò chơi  Trợ giúp" (XP có —
  thiết kế quyết giữ hay bỏ vì chật).
- Khung trò chơi xám nổi kiểu XP: bảng đếm trên (đèn LED đỏ 7 đoạn trên nền đen: **số mìn còn lại** bên trái, **giây**
  bên phải, tối đa 999), **nút mặt cười** ở giữa: 🙂 thường, 😮 khi đang nhấn ô, 😎 thắng, 😵 thua.
- Bảng **9 × 9, 10 mìn** (Beginner của XP): ô chưa mở (xám nổi 3D), ô đã mở (phẳng, viền mảnh), số 1–8 đúng màu XP
  (1 xanh dương, 2 xanh lá, 3 đỏ, 4 xanh đậm, 5 nâu đỏ, 6 xanh mòng két, 7 đen, 8 xám), cờ đỏ, mìn, mìn đã nổ nền đỏ,
  cờ sai (mìn gạch chéo) khi thua.
- Ô đang nhấn (chuột trái đang giữ trên ô chưa mở → ô lõm), ô dưới con trỏ (XP không sáng — giữ như XP).
- Thắng: mặt kính, mọi mìn còn lại tự cắm cờ, đếm mìn về 0. Thua: mìn hiện hết, mìn vừa click nền đỏ.
- Ô cỡ đủ cho con trỏ trúng (XP 16 px; 9 × 16 = 144 vừa thân cửa sổ 220 px).

**Luật phải theo:**
- Như XP thật (người dùng yêu cầu 2026-11-26): ô đầu tiên click **không bao giờ là mìn**; ô 0 tự mở lan ô kề; đồng hồ
  bắt đầu ở click đầu, dừng khi thắng / thua; cờ không mở được bằng click trái.
- Partial redraw: mở một ô chỉ vẽ lại ô đó (và vùng lan); đồng hồ vẽ lại mỗi giây chỉ ô LED; không vẽ lại cả bảng.
- An toàn khi vẽ lại ô dưới con trỏ (`CLAUDE.md` mục Mouse): `draw()` vẽ đúng ván đang chơi, không reset.
- App là bộ xử lý: app tính click trúng ô nào; thiết bị chỉ vẽ.

**Dữ liệu từ firmware:** chưa có — cần bảng ván (81 ô: đã mở / cờ / số / mìn), giây, trạng thái ván. Nơi giữ luật
chơi (app hay firmware) là việc phía code, không ảnh hưởng hình.

**Chữ:** "Dò mìn", "Trò chơi", "Trợ giúp", (nếu có) "Ván mới". Đo theo font JBMono đã đóng gói; LED dùng VT323 hoặc vẽ
7 đoạn bằng hình.

**Dùng lại:** `XP::window`, màu viền nổi / lõm của nút XP (`BTN_*`), biểu tượng 32 px cho desktop như Ảnh / Codex.

**Máy đang có:** chưa có.
