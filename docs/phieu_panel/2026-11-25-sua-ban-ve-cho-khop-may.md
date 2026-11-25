# Phiếu màn thiết bị: sửa bản vẽ đầu cho khớp máy + Việt hoá đơn vị thời gian

- Trạng thái: chờ thiết kế
- Ngày: 2026-11-25 · Nguồn: `/panel-apply` kiểm bản đầu `P-2026-11-25.1` (40 màn)

## Dán vào canvas

**Kênh / màn:** nhiều màn — vạch chỉ báo (mọi kênh), Agents, Setup, Home, AI-Loading, Codex, AI, Trend, Clock, Night, Info, Weather-Loading.
**Cần:** bản vẽ đầu ghi "không đổi so với máy" nhưng có vài chỗ vẽ khác máy; sửa cho đúng máy. Đồng thời người dùng đã chốt **Việt hoá mọi đơn vị / chữ tiếng Anh còn trên màn** — bản vẽ là nơi quyết định dạng chữ, firmware làm theo sau.

Sửa cho khớp máy (máy đúng, bản vẽ sai):
1. **Vạch chỉ báo y 230, mọi màn có xoay vòng**: phần chưa chạy tô `PANEL` `#1F1A28` hết 240 px (bản vẽ để đen). Mặt Night: nền đen, khớp.
2. **Màu vạch chỉ báo**: kênh Setup và Agents là `MUTED` (bản vẽ `AMBER`). Agents khi có mục chờ duyệt: vạch `AMBER` liền 240 px (chờ câu hỏi: `SKY` liền) — vẽ thêm trạng thái này nếu muốn thể hiện.
3. **Home**: 3 chấm đang tải ở x 206 / 215 / 224 (bản vẽ x 196).
4. **AI-Loading**: cột phải CL / CX hiện `ngay` (đồng hồ đã đồng bộ) hoặc `--` (chưa), không phải đếm ngược.

Việt hoá (máy đang chữ Anh — vẽ dạng tiếng Việt cuối cùng, đo vừa khe, firmware sửa theo):
5. **Thời lượng ngắn** (meta `CŨ 18M`, `CÒN 2 · 3D`, `ĐẶT LẠI 2H`, `HẾT SAU 5H`, chân trang Home `CLAUDE CÒN 2D`): luật `CLAUDE.md` là `P` phút · `G` giờ · `NG` ngày. Bản vẽ đã dùng `3NG`, `2G` ở vài chỗ — làm cho **đồng bộ mọi màn**.
6. **Đếm ngược** (Codex, AI, Claude cột phải: `3d`, `2h 14m`, `14m`): chọn dạng tiếng Việt (vd `3NG`, `2G 14P`, `14P`) và đo vừa khe.
7. **Giờ 12 tiếng**: `AM`/`PM` → `SA`/`CH` ở Clock, Night (sau ngày), chân trang Home (gợi ý mưa).
8. **Trend**: nhãn thứ `TH FR SA SU MO TU WE` → `T2…T7`, `CN` (cùng kiểu nhãn đỉnh đã dùng trong màn).
9. **Info**: `312m`, `1m trước`, `sau 4m` → đơn vị `P`.
10. **Weather-Loading / lỗi**: máy hiện chuỗi lỗi tiếng Anh (`HTTP 500`, `JSON …`, `no current`, `http begin`) — vẽ trạng thái lỗi với chữ tiếng Việt.

**Trạng thái phải vẽ:** các trạng thái hiện có của các màn trên; thêm Weather lỗi, Agents có mục chờ (tuỳ chọn).
**Luật phải theo:** `CLAUDE.md` — Vietnamese UI (đơn vị `P`/`G`/`NG`, `SA`/`CH`), đo nhãn với khe (status ≈ 88 px, meta ≈ 72 px).
**Dữ liệu từ firmware:** có sẵn, chỉ đổi chữ.
**Dùng lại:** mọi thứ hiện có.
**Máy đang có:** như mô tả ở từng dòng.

## Ghi chú phía code
- Sau khi chốt: Việt hoá `TimeUtil::shortDuration`, `Api::formatCountdown`, `ClockFmt::ampm`, nhãn thứ `ch_trend.cpp`, đơn vị `ch_info.cpp`, chuỗi lỗi `weather.cpp`; cập nhật host test (`test/`) và `tools/screens.py`.
