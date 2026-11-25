# Phiếu thiết kế: Skill bật/tắt nhiều + màn chính theo tab dock

- Trạng thái: chờ thiết kế
- Đã vẽ: 2026-11-25.3
- Ngày: 2026-11-25 · Nguồn: yêu cầu người dùng (app theo ý tưởng dock của màn thiết bị, P-2026-11-25.3)

## Dán vào canvas

**Màn / widget:** màn Skill (`SkillsScreen`, `screen_specs.md` §6) + tab 1 của thanh điều hướng dưới (màn chính,
hiện là Tổng quan của skill Agent).

**Cần:** Màn thiết bị không còn "mỗi lúc một skill": giờ nó có **dock dọc** bên trái, mỗi tab là một skill, các tab
**cùng xoay vòng** (ảnh `design/panel/screens/@2x/*Dock.png`, đặc tả `design/panel/docs/screen_specs.md` §15). App
phải theo cùng ý tưởng:
1. **Màn Skill:** người dùng **bật / tắt từng skill**; skill bật = một tab trên dock thiết bị và vào vòng xoay. Thấy
   ngay skill nào đang bật, skill nào sắp có.
2. **Màn chính (tab 1):** chia theo các tab dock giống màn thiết bị — Claude (mức dùng Claude/Codex, project, thẻ
   duyệt — nội dung Tổng quan hiện nay), Thời tiết, Đồng hồ; sau này Tin nhắn… Người dùng chuyển qua lại giữa các
   tab trong app; tab có việc chờ (agent chờ duyệt) có huy hiệu số như dock thiết bị.

**Trạng thái phải vẽ:**
- Màn Skill: skill đang bật / đang tắt / sắp có; đang gửi thiết bị (chờ nhận); gửi lỗi (thử lại); tắt skill cuối cùng
  (phải còn ít nhất một tab? — thiết kế quyết, ghi rõ); firmware cũ (chỉ Agent, không đổi được).
- Màn chính: tab Claude (có số liệu, đang tải, chưa có khoá, có agent chờ → huy hiệu), tab Thời tiết (có số liệu,
  chưa cài vị trí), tab Đồng hồ; chỉ một skill bật (thanh tab có cần hiện không?).
- Tab dock của skill bị tắt thì biến mất khỏi màn chính.

**Luật phải theo (đổi luật — phía code chốt khi áp):**
- R-SK-1 cũ "mỗi lúc đúng một skill" → **nhiều skill bật cùng lúc**, mặc định chỉ Agent.
- R-SK-2 cũ "thiết bị chỉ xoay kênh của skill đó" → thiết bị xoay mọi tab đang bật (dock tab = skill).
- R-SK-3 giữ: thẻ duyệt / chờ trả lời chen ngang ở mọi skill; trên dock là huy hiệu vàng ở tab Claude.
- R-SK-4, R-SK-5 giữ (firmware cũ → chỉ Agent; thiết bị đổi từ web → app theo thiết bị).
- Thời tiết, Đồng hồ hiện là kênh hệ thống của thiết bị (luôn có) — thiết kế cho biết chúng có tắt được như skill
  không; nếu có thì phía firmware phải đổi theo.

**Dữ liệu từ thiết bị:** hiện có `GET /api/state` → `skill` (một id), `skills` (danh sách thiết bị có); đổi bằng
`POST /api/settings {"skill": "<id>"}`. **Cần thêm ở firmware** (làm khi áp): setting dạng danh sách skill đang bật.
Huy hiệu agent chờ: app đã có danh sách thẻ (`GET /push`). Tab dock của thiết bị: Claude, Thời tiết, Đồng hồ
(Tin nhắn chờ gói chat).

**Chuỗi:** có sẵn `navSkills`, `skill…Name/Desc`, `skills…`, `commonRetry`. Cần mới: bật / tắt, "đang bật", tên
tab Thời tiết / Đồng hồ trong app, câu giới thiệu màn Skill (bỏ "Mỗi lúc một skill").

**Dùng lại:** `SkillTile`, thanh báo trạng thái, thanh điều hướng dưới, Clawd, màu nhấn `skillAgent…`; icon và màu
tab nên khớp dock thiết bị (token `component.dock` trong `design/panel/tokens/panel_tokens.json`).

**Gợi ý (không bắt buộc):** ô skill có công tắc; màn chính có thanh tab ngang (hoặc dọc như dock) ở trên, huy hiệu
số vàng giống dock; tab Thời tiết / Đồng hồ là bản thu gọn của kênh Weather / Clock trên thiết bị.

**App đang có:** màn Skill lưới 2 cột chọn một skill (bản `2026-11-25.2`); tab 1 = Tổng quan của Agent.

## Ghi chú phía code
- Khi áp: sửa `docs/testing/quy_tac.md` R-SK-1/2 trước, rồi test, `SkillRepository` / `SwitchSkillUseCase` thành
  danh sách; firmware thêm setting danh sách skill (bốn file, `CLAUDE.md` gốc mục Settings round-trip).
