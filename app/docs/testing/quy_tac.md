# Quy tắc nghiệp vụ đã xác nhận

Nguồn sự thật cho test: mỗi test ghi mã quy tắc nó kiểm (`R-…`). Sửa quy tắc → sửa file này trước, rồi test, rồi code.
`dart tool/rule_trace.dart` đọc các dòng bảng `| R-<VÙNG>-<số> | … | App |` ở đây.

Cột **App**: `ok` = code đã chạy đúng · `sửa` = code phải đổi theo quy tắc (test viết trước, đỏ tới khi sửa) ·
`tk` = code đúng, chỉ thiết kế ghi sai · thêm "miễn test (<lý do>)" khi không kiểm được bằng test.

"Ngày" luôn là ngày lịch theo giờ máy người dùng, sang ngày mới lúc 00:00.

Các quy tắc dưới đây ghi lại hành vi app đang có lúc chuyển sang MVVM (2026-11-25, kế hoạch
`docs/tasks/2026-11-25-thiet-ke-2026-11-25.1.md`), để lần chuyển không làm lệch.

## 1. Kết nối thiết bị

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-KN-1 | Tìm thiết bị theo thứ tự: địa chỉ lần trước → NSD (`_http._tcp` tên glimmer*) → `glimmer.local` → AP cài đặt `192.168.4.1`. Địa chỉ trả lời được lưu lại, trừ AP cài đặt. | Lần trước 10.0.0.9 không trả lời, NSD thấy 10.0.0.5 → thử 10.0.0.5 | ok |
| R-KN-2 | Đã kết nối thì tự làm mới mỗi 5 s, chỉ khi app đang mở; mở lại app → làm mới ngay. | App xuống nền → ngừng hỏi thiết bị | ok |
| R-KN-3 | Chưa kết nối → màn Kết nối; kết nối được → khung 4 tab, mở ở tab 1 (Điều khiển, từ thiết kế 2026-11-26.5; Số liệu là màn phụ đẩy từ đó). "Kết nối thiết bị khác" quên thiết bị → về Kết nối. | Bấm "Kết nối thiết bị khác" → màn Kết nối | ok |
| R-KN-4 | Thiết bị có API token mà app chưa có → vẫn hiện trạng thái, thẻ để trống, báo cần nhập token trong Cài đặt. | `/push` trả 401 → "Thiết bị có API token — …" | ok |

## 2. Mức dùng Claude (Tổng quan)

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-DUNG-1 | Màu % đã dùng theo % còn lại: còn ≤ 20 → coral, ≤ 50 → amber, còn lại → mint; chưa biết → muted, hiện `--`. | 38 → mint, 60 → amber, 92 → coral | ok |
| R-DUNG-2 | Dòng phụ thẻ mức dùng, ưu tiên: chưa có khóa (amber) > khóa lỗi `expired`/`rejected` (coral) > bị chặn `blocked` (amber) > số liệu cũ "số liệu cũ (X trước)" (amber) > "X trước" (chỉ khi đã tải được và đồng hồ thiết bị đã đồng bộ) > trống. | cred `blocked`, stale → "claude.ai đang chặn…" | ok |
| R-DUNG-3 | Thời gian ngắn, chữ đơn vị tiếng Anh như màn thiết bị: đếm ngược `4d 3h` / `2h 14m` / `12m`, đã tới → `ngay`, chưa biết → không hiện "đặt lại sau"; đã qua `45s` / `12m` / `3h` (< 48 h) / `2d`. | reset sau 2 h 14 phút → "đặt lại sau 2h 14m" | ok |
| R-DUNG-4 | Số liệu cũ → cả hai số và thanh % chuyển màu muted. | stale → 66% muted | ok |

## 3. Bảng project

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-PRJ-1 | Chỉ hiện project `shown`, xếp approval → input → error → working → done. Dòng phụ: nhãn trạng thái · chi tiết · tên agent nếu không phải claude. | [done A, approval B] → B, A | ok |
| R-PRJ-2 | Clawd ở Tổng quan: bảng trống → ngủ; có approval → mắt to; có error → buồn; có working/input → mắt mở; còn lại → vui. Có working → Clawd bước. | [done, error] → buồn | ok |

## 4. Cài đặt

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-CD-1 | Chỉ gửi khóa đã đổi; đổi về đúng giá trị cũ → không còn tính là đổi. Nút "Lưu (n)" + "Bỏ thay đổi" chỉ hiện khi có thay đổi; lưu xong tải lại. | Độ sáng 60 → 80 → 60: không có thay đổi | ok |
| R-CD-2 | Khóa bí mật (khóa Claude, API token) thiết bị trả về dạng ẩn; dòng hiện "đã đặt" / "chưa đặt", "sẽ đổi khi lưu" khi người dùng vừa nhập; chỉ gửi khi người dùng nhập giá trị mới. | claudeKey `***` → "đã đặt" | ok |
| R-CD-3 | Giờ Từ/Đến chỉ hiện khi chế độ ban đêm ≠ Không; độ sáng ban đêm chỉ khi chế độ = Giảm sáng. | Chế độ Đồng hồ → có Từ/Đến, không có độ sáng ban đêm | ok |

## 5. Thiết bị (cập nhật, sao lưu)

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-TB-1 | Có bản mới khi bản phát hành `latest` mới hơn lúc build của thiết bị quá 30 phút. | build 10:00, phát hành 10:20 → đã cập nhật | ok |
| R-TB-2 | Tệp khôi phục phải là config.json của glimmer (có `wifi_ssid`), không thì báo tệp không hợp lệ và không gửi gì. | `{"a":1}` → "Tệp không hợp lệ" | ok |
| R-TB-3 | Cập nhật đầy đủ: sao lưu cấu hình (không đọc được → dừng), tải firmware + hệ thống tệp, nạp firmware, chờ thiết bị trả lời (không → dừng), nạp hệ thống tệp, chờ 20 s rồi khôi phục cấu hình (thẳng hoặc qua glimmer-setup). | Thiết bị không trả lời sau firmware → dừng, chưa nạp hệ thống tệp | ok |
| R-TB-4 | Khi đang chạy một việc dài (nạp, khôi phục, khởi động lại), mọi dòng thao tác bị tắt và thẻ tiến trình hiện ở đầu màn. | Đang nạp firmware → "Khởi động lại" tắt | ok |

## 6. Cài Wi-Fi cho thiết bị

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-WF-1 | Gửi Wi-Fi mới thẳng cho thiết bị chỉ khi đang kết nối, thiết bị không ở chế độ cài đặt và trả lời ngay lúc đó; còn lại vào Wi-Fi glimmer-setup (cần quyền vị trí) rồi gửi qua đó. | Thiết bị đã rời mạng → đi qua glimmer-setup | ok |
| R-WF-2 | Lệnh có khởi động lại (lưu Wi-Fi, khôi phục cấu hình, khởi động lại) mà thiết bị không kịp trả lời vẫn tính là thành công; lỗi HTTP vẫn là lỗi. | Gửi Wi-Fi, mất kết nối → bước tiếp | ok |
| R-WF-3 | Gửi xong: rời glimmer-setup, tìm lại thiết bị trên mạng mới; không thấy → "Chưa thấy thiết bị trên …". Tên Wi-Fi điền sẵn bằng mạng điện thoại đang dùng (trừ glimmer-setup). | Không thấy sau ~4 phút → lỗi | ok |

## 7. Skill (gói chức năng)

Một skill = các màn của nó trong app + một tab trên dock thiết bị (bộ kênh của nó). Kế hoạch
`docs/tasks/2026-11-25-he-sinh-thai-skill.md`; từ thiết kế 2026-11-25.3 (`docs/tasks/2026-11-25-thiet-ke-2026-11-25.3.md`)
skill là danh sách bật / tắt: Agent, Thời tiết (Weather + Forecast), Đồng hồ (Clock); từ thiết kế 2026-11-25.4
(`docs/tasks/2026-11-25-thiet-ke-2026-11-25.4.md`) thêm Ảnh (Photo) — thứ tự dock Agent, Ảnh, Thời tiết, Đồng hồ.
Kênh hệ thống (Thông báo, Ban đêm, Thông tin) hiện ở mọi skill.

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-SK-1 | Nhiều skill bật cùng lúc, ít nhất một; mặc định Agent + Thời tiết + Đồng hồ (Ảnh mặc định tắt). Không tắt được skill bật cuối cùng. Danh sách lưu trên máy bỏ id không còn trong danh mục, rỗng → mặc định. | Mới cài app → Agent, Thời tiết, Đồng hồ bật; chỉ còn Agent → công tắc Agent khoá | ok |
| R-SK-2 | Bật / tắt trên app → gửi thiết bị danh sách skill bật (`skillsOn` trong `/api/settings`, theo thứ tự dock), thiết bị nhận rồi mới lưu máy; skill thiết bị đang bật mà app chưa có gói (vd `music`) gửi kèm, giữ nguyên; mỗi skill bật có nút trên thanh tác vụ và các chương trình của nó trong Tất cả chương trình (thiết bị không tự xoay, từ thiết kế 2026-11-26.6). | Tắt Thời tiết → gửi `[agent, clock]`; Tất cả chương trình bỏ Thời tiết, Dự báo | ok |
| R-SK-3 | Thẻ cần duyệt / chờ trả lời vẫn chen ngang ở mọi skill. | Skill Nhạc, Claude Code xin duyệt → thẻ amber hiện | ok · miễn test (luật firmware: kênh Attention là kênh hệ thống, `test/test_logic` `test_skill_filter_and_default`) |
| R-SK-4 | Thiết bị không báo danh sách skill bật (`skills_on`, firmware cũ) → app chỉ có skill Agent, không cho bật / tắt, không gửi gì. | Firmware 0.22 → Agent ổ khoá, Thời tiết / Đồng hồ "Luôn có" | ok |
| R-SK-5 | Danh sách skill bật trên thiết bị khác danh sách app lưu (đổi từ trang web thiết bị) → app theo thiết bị và lưu lại. | Web tắt Đồng hồ, app lưu cả ba → app thành Agent, Thời tiết | ok |
| R-SK-6 | Tab Ảnh trên Số liệu chỉ có khi skill Ảnh bật; quản lý ảnh khi skill tắt = bật skill trước (màn Skill gợi ý "N ảnh đã có trên thiết bị. Bật để xoay." khi thiết bị đã có ảnh). Firmware chưa có ảnh (`/api/state` không có `photos`) → dòng Ảnh "Cần firmware mới" + nút Cập nhật, không bật được. | Ảnh tắt, thiết bị có 5 ảnh → mô tả mint "5 ảnh đã có…"; bật Ảnh → tab Ảnh thứ 2 | ok |

## 8. Điều khiển thiết bị (tab 1)

Từ thiết kế 2026-11-26.5 (`docs/tasks/2026-11-26-thiet-ke-2026-11-26.5.md`): tab 1 là remote của thiết bị — ô màn vẽ
lại màn thiết bị, nút kênh trước / sau, dừng xoay, nhảy tới skill, độ sáng, tắt màn, chế độ đêm. Người dùng chốt
2026-11-26.

Từ thiết kế 2026-11-26.6 (`docs/tasks/2026-11-26-thiet-ke-2026-11-26.6.md`, người dùng chốt 2026-11-26): mô hình Windows
XP — app là máy tính, thiết bị là màn hình; ô màn chạm được như chuột, **thiết bị không tự xoay**; bỏ nút kênh trước /
sau, dừng xoay, hàng tab. Chạm được app đổi ra lệnh firmware đã có (`/api/channel {name}`).

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-DK-1 | Bấm nút điều khiển → ô màn đổi ngay theo lệnh (lạc quan) + chip "Đang gửi…", rồi gửi lệnh. Thiết bị trả kênh / trạng thái khác điều app chờ, hoặc không trả lời → ô màn về theo thiết bị và báo (thanh báo có Thử lại do người dùng bấm); app không tự gửi lại. | Bấm Thời tiết, thiết bị trả `active: Claude` → ô màn về Claude, báo "Thiết bị không nhận lệnh"; không có lệnh thứ hai | ok |
| R-DK-2 | "Bỏ thẻ khỏi màn" chỉ gỡ thẻ đó khỏi màn thiết bị (`/push/clear {id}`); app không duyệt / trả lời hộ agent, không có nút duyệt. | Thẻ Bash cần duyệt giữ màn → bấm Bỏ thẻ → gửi `{id}` của thẻ, không gửi gì cho agent | ok |
| R-DK-3 | Lệnh firmware chưa có (biết từ `/api/state`: không có `paused` → chạm màn, bỏ một thẻ; không có `screen_on` → tắt màn) → nút khoá (mờ + ổ khoá) + thanh báo gợi ý cập nhật firmware; bấm không gửi gì. | Firmware 0.24 không báo `screen_on` → Tắt màn khoá, bấm không có `POST` | ok |
| R-DK-4 | ~~Dừng xoay là tạm~~ — bỏ từ thiết kế 2026-11-26.6: thiết bị không tự xoay; mở tab Điều khiển mà `autoRotate` còn bật → app gửi `{autoRotate: false}` một lần. | Cài đặt thiết bị `autoRotate: true` → đúng một `POST /api/settings {autoRotate: false}` | miễn test (luật bỏ; việc tắt xoay kiểm ở R-DK-7) |
| R-DK-5 | Độ sáng chỉ gửi khi thả tay (`brightness` qua `/api/settings`, như Cài đặt); đang kéo chỉ đổi trên app. | Kéo 50 → 80 rồi thả → đúng một lệnh `brightness: 80` | ok |
| R-DK-6 | Ô màn vẽ theo `/api/state`; mở app / về tab 1 (cả khi quay lại từ Số liệu) thì đọc lại trạng thái ngay. | Mở tab Điều khiển → `GET /api/state` ngay, không đợi lượt 5 s | ok |
| R-DK-7 | Mới mở app → không cửa sổ nào, thanh tác vụ trống, màn là desktop: thiết bị đang hiện một chương trình thì app gửi `{name: Home}` một lần (từ thiết kế 2026-11-26.7). App giữ danh sách cửa sổ đang mở (thứ tự mở) + cửa sổ trên cùng + cửa sổ thu nhỏ; mở chương trình (biểu tượng, Start, Tất cả chương trình, nút thanh tác vụ) → cửa sổ lên trên cùng, gửi `/api/channel {name}`. Thiết bị đổi sang một chương trình khác mà app không mở → app theo thiết bị (thêm cửa sổ đó); thẻ agent, ban đêm, desktop không đổi danh sách. Thiết bị không tự xoay: `autoRotate` bật → gửi `false` một lần. Danh sách cửa sổ gửi xuống thiết bị (`POST /api/windows {open, top, min, sel}`, panel P-2026-11-26.14) mỗi khi đổi, firmware có `windows` trong `/api/state`; thanh tác vụ trên máy vẽ theo nó. | Mở app khi thiết bị hiện Claude → gửi `Home`, thanh trống; mở Claude rồi Thời tiết → [Claude, Thời tiết], trên cùng Thời tiết | ok |
| R-DK-8 | `_` thu nhỏ: thiết bị về desktop (`Home`), cửa sổ vẫn có nút trên thanh tác vụ. `×` tắt app: bỏ khỏi danh sách, thiết bị về cửa sổ trước đó chưa thu nhỏ, hết → desktop. Thanh tác vụ = đúng danh sách cửa sổ đang mở theo thứ tự mở (tối đa 4 nút, nhiều hơn → 4 cửa sổ mở gần nhất), nút lõm = cửa sổ trên cùng (từ thiết kế 2026-11-26.7); bấm nút của cửa sổ đang hiện → thu nhỏ (như XP), nút khác → cửa sổ đó lên trên cùng. `□` không gửi gì (cửa sổ trên máy luôn đầy màn, nút vẽ mờ); giữ = chuột phải (R-DK-11). Bấm nút cửa sổ không đổi chỗ nút (như XP); `×` → cửa sổ được dùng gần nhất trước đó chưa thu nhỏ. Vùng trúng nút nhỏ nới 44 × 44 dp quanh tâm. | Mở Claude, Thời tiết; `×` trên Thời tiết → gửi `{name: Claude}`, danh sách [Claude] | ok |
| R-DK-9 | Chương trình theo skill bật: Agent → Claude, Codex, AI, Xu hướng, Agents (kênh có cờ `show*` bật khi biết cài đặt); Ảnh, Thời tiết (+ Dự báo), Đồng hồ; hệ thống Thông tin (khi `showInfo`). Tắt skill → chương trình của nó bỏ khỏi Start / Tất cả chương trình và cửa sổ của nó bỏ khỏi danh sách. Desktop có biểu tượng cho từng chương trình của skill bật (panel P-2026-11-26.14); skill vừa bật → biểu tượng đầu của nó ở trạng thái chọn (gửi `sel`), mở cửa sổ khác hoặc chạm chỗ trống → bỏ chọn. | Tắt Đồng hồ → Tất cả chương trình không còn Đồng hồ; cửa sổ Đồng hồ đang mở bị bỏ; bật Ảnh → biểu tượng Ảnh đang chọn | ok |
| R-DK-10 | Firmware chưa nhận chạm (R-DK-3: không có `paused`) → chạm trên ô màn không gửi gì, thanh báo "Firmware chưa nhận chạm" + Cập nhật firmware; Start vẫn mở được chương trình. | Firmware 0.24 → chạm `×` không có `POST`; Start → Thời tiết vẫn gửi `{name: Weather}` | ok |
| R-DK-11 | Giữ ≥ 500 ms trên ô màn = chuột phải: nút thanh tác vụ → menu cửa sổ đó (mọc từ nút); thanh tiêu đề → menu cửa sổ tại điểm giữ; chỗ trống desktop → menu desktop. App gửi `POST /api/menu {kind, x, y, minimized}` (thiết bị vẽ), chạm trong menu app tự chọn mục: Thu nhỏ / Khôi phục / Đóng / Thuộc tính (→ Thông tin) / Làm mới gửi lệnh tương ứng; mục mờ không làm gì; chạm ngoài → đóng menu (`kind: none`). Firmware không có `windows` → giữ không làm gì. | Giữ nút Claude → menu tại (71, 100); chạm Thu nhỏ → `{name: Home}`, menu đóng | ok |
