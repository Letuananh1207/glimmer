# Phiếu màn thiết bị: cửa sổ Ảnh lấy ảnh từ điện thoại

- Trạng thái: đã áp (P-2026-11-28.27)
- Đã vẽ: P-2026-11-28.27
- Ngày: 2026-11-27 · Nguồn: yêu cầu người dùng, kế hoạch `app/docs/tasks/2026-11-27-kho-anh-tren-app.md` (bước 9)

## Dán vào canvas

**Kênh / màn:** `Photo` (cửa sổ XP "Ảnh", §17 XP-Photo / XP-Photo-Empty).

**Cần:** Kho ảnh giờ nằm trên điện thoại (app là bộ nhớ). Mỗi bước trình chiếu thiết bị **xin ảnh kế tiếp từ app** qua
mạng nhà (mất ~0,3–1 s); khi điện thoại vắng nó chiếu **8 ảnh đã giữ** (bộ đệm) và 60 s sau thử lại. Người nhìn màn
cần biết: ảnh thứ mấy trong bao nhiêu, và (nếu thiết kế thấy cần) đang chiếu từ điện thoại hay chỉ từ ảnh đã giữ.
Theo XP thật: trình chiếu ảnh của Windows XP (*Windows Picture and Fax Viewer* / thư mục ảnh qua mạng).

**Trạng thái phải vẽ:**
1. Đang hiện ảnh từ điện thoại — meta `3/40` (thứ tự trong kho).
2. Đang xin ảnh kế tiếp (lúc chuyển ảnh, ≤ 3 s) — giữ ảnh cũ? hộp tải XP-Load? con trỏ chờ?
3. Điện thoại vắng — chiếu bộ đệm, meta `3/8`; có ghi chú nhỏ không (thanh trạng thái XP?).
4. Kho rỗng và bộ đệm rỗng → như XP-Photo-Empty (chữ có thể đổi: thêm ảnh từ app glimmer).

**Luật phải theo:** No animated transitions (chỉ cắt ngay); không vẽ ngoài cửa sổ; tick() không xoá màn; vẽ lại dưới con
trỏ không xin lại ảnh (đã có file tạm); ảnh 188×188 tại (26, 24) như hiện nay.

**Dữ liệu từ firmware:** `Photos::source()` — `state` none / online / offline, `remote` (ảnh đang hiện từ app),
`index`, `count`; bộ đệm `Photos::total()` / `current()`.

**Chữ:** meta tiêu đề `3/40` (đã có kiểu `2/5`); ghi chú vắng điện thoại (khe ≈ thanh trạng thái XP, đo bằng
`tools/vlwpreview.py`); chữ trống: "Gửi ảnh từ app glimmer" (đã có).

**Dùng lại:** `XP::window`, `XP::titleMeta`, `XP::loading` / `loadingStep` (hộp tải về), con trỏ chờ, thanh trạng thái XP.

**Gợi ý (không bắt buộc):** giữ ảnh cũ trên màn cho tới khi ảnh mới về (không màn trống), con trỏ chờ trong lúc xin;
khi vắng điện thoại thêm thanh trạng thái `Ảnh đã lưu trên máy · 3/8`.

**Máy đang có:** firmware đã xin ảnh từ app (bước 1–2 của kế hoạch): ảnh mới vẽ đè ngay khi về, meta `index/count`,
vắng thì bộ đệm `i/n`; chưa có ghi chú / trạng thái đang xin.
