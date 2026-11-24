# Hệ sinh thái skill — khung + Claude/Agent là skill đầu

- Yêu cầu: "bây giờ tầm nhìn của tôi là ứng dụng app flutter sẽ là 1 hệ sinh thái các nhiều skill chức năng, sẽ có
  gói kỹ năng để chuyên dành cho các chức năng mạng xã hội, gói dành cho nhạc, giải trí ... và flutter này sẽ đóng
  thành 1 kỹ năng riêng, giao diện của phía phần cứng cũng sẽ tương ứng với skill đang sử dụng"
- Đã chốt (2026-11-25): **một skill chiếm màn** thiết bị tại một thời điểm; bước đầu = **khung skill + gói 5 màn
  hiện có thành skill "Agent"**, chưa làm gói mới (Nhạc, Mạng xã hội, Giải trí là các kế hoạch sau).
- Loại: thêm · Cỡ: lớn
- Trạng thái: đang làm (còn nhiệm vụ 8 — chờ thiết kế)

## Hiểu đúng "skill" ở đây

Một **skill** = một gói chức năng đóng sẵn trong app (không tải code về lúc chạy — Flutter/Play Store không cho) gồm:
các màn của nó trong app + **bộ kênh** của nó trên màn 240×240. Người dùng chọn skill đang dùng trên app → app báo
thiết bị → thiết bị chỉ xoay các kênh của skill đó. Skill đầu tiên là **Agent** (Claude/Codex): đúng những gì app và
thiết bị đang làm hôm nay, nên ai không đổi gì sẽ không thấy khác.

## Phạm vi

**Sẽ sửa — app**
- `lib/domain/models/skill.dart` (mới): `Skill` (id, có trên thiết bị chưa…), danh mục skill.
- `lib/domain/rules/skill_rules.dart` (mới): skill mặc định, chọn skill hợp lệ, thiết bị cũ không hỗ trợ.
- `lib/domain/models/device_state.dart`: đọc trường `skill` (và danh sách skill thiết bị có) từ `/api/state`.
- `lib/data/repositories/skill/skill_repository.dart` (+ `_local.dart`, mới): skill đang dùng, lưu máy.
- `lib/data/services/local_store_service.dart`: khoá `active_skill`.
- `lib/domain/use_cases/switch_skill_use_case.dart` (mới): đổi skill = lưu máy + `POST /api/settings {skill}`
  (chạm 2 repository → use case).
- `lib/config/dependencies.dart`, `lib/routing/{router,routes,screens}.dart`: route theo skill — **chờ thiết kế**.
- Màn chọn skill + khung điều hướng theo skill — **chờ thiết kế** (phiếu dưới).
- `docs/testing/quy_tac.md`: vùng mới `R-SK-…`. `docs/backend/README.md`: khoá `active_skill`.

**Sẽ sửa — firmware** (cùng repo, `../src/`; cần bạn chốt làm luôn hay để sau)
- `src/channels/channel.h`: `Channel` thêm `skill` (`"agent"`, hoặc `nullptr` = kênh hệ thống, hiện ở mọi skill).
- `src/main.cpp`: `kChannels[]` gắn skill; `recomputeActive()` chỉ lấy kênh của skill đang dùng + kênh hệ thống.
- Settings round-trip 4 file (`../CLAUDE.md` mục Settings): `storage.h`, `storage.cpp` (`skill`, mặc định
  `"agent"`), `web.cpp` (`handleApiGetSettings`/`applyIfPresent`, `/api/state` thêm `skill` + `skills`),
  `data/web/index.html`.
- `docs/AGENTS-GLIMMER.md` nếu MCP/agent cần biết skill.
- Host test `pio test -e native` cho bộ lọc kênh theo skill.

**Cần kiểm tra** — `device_repository_local.dart` (parse state), `dashboard_*`, `device_*` (đọc `DeviceState`),
`test/ui/screens_test.dart` (router), `testing/fakes/fake_services.dart`.

**Không đụng** — dữ liệu đã lưu (`device_url`, `token`, `repo` giữ nguyên, chỉ thêm khoá); hàng đợi thẻ duyệt
(approval/question vẫn chen ngang mọi skill); 5 màn hiện có (chỉ đổi chỗ treo route khi có thiết kế).

## Giả định / cần quyết định
- **Đã chốt:** Clock / Weather / Forecast / Info là kênh hệ thống. Đề xuất cũ: là kênh **hệ thống** (hiện ở mọi skill, như
  Attention/Night/Setup), để skill Nhạc sau này vẫn có đồng hồ. Cách khác: skill riêng "Đồng hồ & thời tiết", hoặc
  thuộc skill Agent. → **cần duyệt**.
- **Đã chốt: firmware làm cùng đợt.** App làm được phần dữ liệu trước; nút đổi skill chỉ có tác dụng khi firmware
  hiểu `skill`. Đề xuất: làm cùng đợt (firmware nhỏ: 1 trường settings + bộ lọc kênh). → **cần duyệt**.
- Thiết bị firmware cũ (không trả `skill`) → app coi như chỉ có skill Agent, ẩn/tắt việc đổi skill (R-SK-4).
- Chỉ một skill (Agent) có thật trong đợt này; Nhạc / Mạng xã hội / Giải trí hiện trong danh mục hay chưa là việc
  của thiết kế ("sắp có" hay ẩn).
- Không đổi tên thư mục `ui/dashboard`… thành `ui/agent_…` lúc này; đổi khi thiết kế chốt khung điều hướng.

## Quy tắc mới (ghi `quy_tac.md` trước, cột App `sửa`)
- R-SK-1: Mỗi lúc đúng một skill đang dùng; mặc định `agent`.
- R-SK-2: Đổi skill trên app → lưu máy và gửi thiết bị; thiết bị chỉ xoay kênh của skill đó + kênh hệ thống.
- R-SK-3: Thẻ cần duyệt / chờ trả lời vẫn chen ngang ở mọi skill (giữ luật hàng đợi hiện có).
- R-SK-4: Thiết bị không báo `skill` (firmware cũ) → chỉ skill Agent, không cho đổi.
- R-SK-5: Skill trên thiết bị khác skill app lưu (đổi từ trang web thiết bị) → app theo thiết bị.

## Nhiệm vụ
- [x] 1. Quy tắc R-SK-1..5 vào `docs/testing/quy_tac.md` — xong khi: bạn duyệt nội dung.
- [x] 2. Phiếu thiết kế "Chọn skill + điều hướng theo skill" (`/ui-apply phieu`) — `docs/phieu_thiet_ke/` ·
  xong khi: phiếu được commit + đẩy lên cho phiên thiết kế.
- [x] 3. Model + quy tắc skill — `domain/models/skill.dart`, `domain/rules/skill_rules.dart` (domain) · test:
  `test/domain/rules/skill_rules_test.dart` (R-SK-1, R-SK-4, R-SK-5) · xong khi: test xanh.
- [x] 4. `DeviceState` đọc `skill` / `skills` — (models) · test: `device_state_test.dart` (thiếu trường → rỗng).
- [x] 5. `SkillRepository` + khoá `active_skill` — (repository, service) · test:
  `test/data/repositories/skill_repository_local_test.dart` · `docs/backend/README.md`.
- [x] 6. `SwitchSkillUseCase` — (use case) · test: lưu + gửi `{skill}`; thiết bị cũ → không gửi (R-SK-2, R-SK-4).
- [x] 7. Firmware: `Channel.skill`, bộ lọc trong `recomputeActive`, settings `skill` (4 file), `/api/state`
  `skill`/`skills` · test: `pio test -e native` · xong khi: `pio run -e nodemcuv2` build được, đổi `skill` qua
  `/api/settings` thì vòng kênh đổi trong 1 slide. *(chờ duyệt có làm đợt này)*
- [ ] 8. UI chọn skill + khung theo skill + route — `ui/skills/…`, `routing/` · *chờ thiết kế:
  `docs/phieu_thiet_ke/2026-11-25-chon-skill.md`*. Khi làm: gọi `SwitchSkillUseCase.syncFromDevice()` mỗi lần
  trạng thái thiết bị đổi (R-SK-5).
- [x] 9. Bản đồ tính năng `/lead` thêm dòng "Skill, gói chức năng".

## Kiểm tra cuối
dart tool/check.dart --changed · flutter analyze · flutter test -r failures-only test/domain test/data ·
dart tool/rule_trace.dart · (firmware) pio test -e native · pio run -e nodemcuv2
