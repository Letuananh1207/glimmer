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
| R-WF-4 | Quét mã QR trên màn cài đặt của thiết bị (chuẩn Wi-Fi `WIFI:…;S:glimmer-setup…;;`, không mật khẩu) → nhận tên AP từ mã rồi đi theo R-WF-1 qua AP đó; mã khác (Wi-Fi khác, có mật khẩu, không phải Wi-Fi) → báo "không phải mã glimmer", không làm gì. Tên Wi-Fi gửi đi là mạng điện thoại đang dùng (như R-WF-3). | Quét `WIFI:T:nopass;S:glimmer-setup;;` → vào glimmer-setup; quét mã quán cà phê → từ chối | sửa |
| R-WF-5 | App nhớ mật khẩu Wi-Fi theo tên mạng, trong kho bảo mật của máy, chỉ khi thiết bị đã hiện lại trên mạng đó (gửi sai không nhớ). Quét QR mà mạng điện thoại đã có mật khẩu nhớ → gửi luôn, không hỏi; chưa có → chỉ hỏi mật khẩu. Mật khẩu nhớ mà gửi xong thiết bị không hiện lại → quên nó, lần sau hỏi lại. Gửi tay cũng nhớ; quên được mật khẩu đã nhớ. | Lần 2 quét ở nhà → gửi ngay không hỏi | sửa |

## 7. Skill (gói chức năng)

Một skill = các màn của nó trong app + một tab trên dock thiết bị (bộ kênh của nó). Kế hoạch
`docs/tasks/2026-11-25-he-sinh-thai-skill.md`; từ thiết kế 2026-11-25.3 (`docs/tasks/2026-11-25-thiet-ke-2026-11-25.3.md`)
skill là danh sách bật / tắt: Agent, Thời tiết (Weather + Forecast), Đồng hồ (Clock); từ thiết kế 2026-11-25.4
(`docs/tasks/2026-11-25-thiet-ke-2026-11-25.4.md`) thêm Ảnh (Photo) — thứ tự dock Agent, Ảnh, Thời tiết, Đồng hồ.
Kênh hệ thống (Thông báo, Ban đêm, Thông tin) hiện ở mọi skill.

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-SK-1 | Nhiều skill bật cùng lúc, ít nhất một; mặc định Agent + Thời tiết + Đồng hồ (Ảnh, Giải trí mặc định tắt; Giải trí = Dò mìn, có gói từ 2026-11-27). Không tắt được skill bật cuối cùng. Danh sách lưu trên máy bỏ id không còn trong danh mục, rỗng → mặc định. | Mới cài app → Agent, Thời tiết, Đồng hồ bật; chỉ còn Agent → công tắc Agent khoá | ok |
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
| R-DK-3 | Lệnh firmware chưa có (biết từ `/api/state`: không có `paused` → bỏ một thẻ) → nút khoá (mờ + ổ khoá) + thanh báo gợi ý cập nhật firmware; bấm không gửi gì. Nút "Tắt màn" bỏ khỏi app (thiết kế 2026-11-27.10, bạn chốt 2026-11-27): tắt = nút nguồn (R-DK-20). | Firmware 0.24 không báo `paused` → Bỏ thẻ khoá, bấm không có `POST` | ok |
| R-DK-4 | ~~Dừng xoay là tạm~~ — bỏ từ thiết kế 2026-11-26.6: thiết bị không tự xoay; mở tab Điều khiển mà `autoRotate` còn bật → app gửi `{autoRotate: false}` một lần. | Cài đặt thiết bị `autoRotate: true` → đúng một `POST /api/settings {autoRotate: false}` | miễn test (luật bỏ; việc tắt xoay kiểm ở R-DK-7) |
| R-DK-5 | Độ sáng chỉ gửi khi thả tay (`brightness` qua `/api/settings`, như Cài đặt); đang kéo chỉ đổi trên app. | Kéo 50 → 80 rồi thả → đúng một lệnh `brightness: 80` | ok |
| R-DK-6 | Ô màn vẽ theo `/api/state`; mở app / về tab 1 (cả khi quay lại từ Số liệu) thì đọc lại trạng thái ngay. | Mở tab Điều khiển → `GET /api/state` ngay, không đợi lượt 5 s | ok |
| R-DK-7 | Mới mở app → không cửa sổ nào, thanh tác vụ trống, màn là desktop: thiết bị đang hiện một chương trình thì app gửi `{name: Home}` một lần (từ thiết kế 2026-11-26.7). "Mới mở app" = lần chạy app mới; sang tab khác rồi quay lại tab Điều khiển trong cùng lần chạy → giữ nguyên danh sách cửa sổ, không gửi `Home` (L-7, bạn báo 2026-11-27). App giữ danh sách cửa sổ đang mở (thứ tự mở) + cửa sổ trên cùng + cửa sổ thu nhỏ; mở chương trình (biểu tượng, Start, Tất cả chương trình, nút thanh tác vụ) → cửa sổ lên trên cùng, gửi `/api/channel {name}`. Thiết bị đổi sang một chương trình khác mà app không mở → app theo thiết bị (thêm cửa sổ đó); thẻ agent, ban đêm, desktop không đổi danh sách. Thiết bị không tự xoay: `autoRotate` bật → gửi `false` một lần. Danh sách cửa sổ gửi xuống thiết bị (`POST /api/windows {open, top, min, sel}`, panel P-2026-11-26.14) mỗi khi đổi, firmware có `windows` trong `/api/state`; thanh tác vụ trên máy vẽ theo nó. | Mở app khi thiết bị hiện Claude → gửi `Home`, thanh trống; mở Claude rồi Thời tiết → [Claude, Thời tiết], trên cùng Thời tiết | ok |
| R-DK-8 | `_` thu nhỏ: thiết bị về desktop (`Home`), cửa sổ vẫn có nút trên thanh tác vụ. `×` tắt app: bỏ khỏi danh sách, thiết bị về cửa sổ trước đó chưa thu nhỏ, hết → desktop. Thanh tác vụ = đúng danh sách cửa sổ đang mở theo thứ tự mở (tối đa 4 nút, nhiều hơn → 4 cửa sổ mở gần nhất), nút lõm = cửa sổ trên cùng (từ thiết kế 2026-11-26.7); bấm nút của cửa sổ đang hiện → thu nhỏ (như XP), nút khác → cửa sổ đó lên trên cùng. `□` không gửi gì (cửa sổ trên máy luôn đầy màn, nút vẽ mờ); giữ = chuột phải (R-DK-11). Bấm nút cửa sổ không đổi chỗ nút (như XP); `×` → cửa sổ được dùng gần nhất trước đó chưa thu nhỏ. Vùng trúng nút nhỏ nới 44 × 44 dp quanh tâm. | Mở Claude, Thời tiết; `×` trên Thời tiết → gửi `{name: Claude}`, danh sách [Claude] | ok |
| R-DK-9 | Chương trình theo skill bật: Agent → Claude, Codex, AI, Xu hướng, Agents (kênh có cờ `show*` bật khi biết cài đặt); Ảnh, Thời tiết (+ Dự báo), Đồng hồ; hệ thống Thông tin (khi `showInfo`). Tắt skill → chương trình của nó bỏ khỏi Start trên thiết bị (do firmware vẽ theo skill) và cửa sổ của nó bỏ khỏi danh sách. Desktop có biểu tượng cho từng chương trình của skill bật (panel P-2026-11-26.14); skill vừa bật → biểu tượng đầu của nó ở trạng thái chọn (gửi `sel`), mở cửa sổ khác hoặc chạm chỗ trống → bỏ chọn. | Tắt Đồng hồ → Tất cả chương trình không còn Đồng hồ; cửa sổ Đồng hồ đang mở bị bỏ; bật Ảnh → biểu tượng Ảnh đang chọn | ok |
| R-DK-10 | ~~Firmware chưa nhận chạm (R-DK-3: không có `paused`) → chạm trên ô màn không gửi gì, thanh báo "Firmware chưa nhận chạm" + Cập nhật firmware; Start vẫn mở được chương trình.~~ — thay bằng R-DK-21 (2026-11-27: bỏ ô màn, app là chuột). | Firmware 0.24 → chạm `×` không có `POST`; Start → Thời tiết vẫn gửi `{name: Weather}` | miễn test (luật bỏ; thay bằng R-DK-21) |
| R-DK-11 | Giữ ≥ 500 ms trên ô màn = chuột phải: nút thanh tác vụ → menu cửa sổ đó (mọc từ nút); thanh tiêu đề → menu cửa sổ tại điểm giữ; chỗ trống desktop → menu desktop. App gửi `POST /api/menu {kind, x, y, minimized}` (thiết bị vẽ), chạm trong menu app tự chọn mục: Thu nhỏ / Khôi phục / Đóng / Thuộc tính (→ Thông tin) / Làm mới gửi lệnh tương ứng; mục mờ không làm gì; chạm ngoài → đóng menu (`kind: none`). Firmware không có `windows` → giữ không làm gì. | Giữ nút Claude → menu tại (71, 100); chạm Thu nhỏ → `{name: Home}`, menu đóng | ok |
| R-DK-12 | App đang hiện trên màn điện thoại (foreground) → điện thoại không tự tắt màn; app ra nền / thoát → điện thoại tắt màn theo cài đặt máy như thường. Chỉ giữ sáng màn điện thoại, không đổi gì trên thiết bị glimmer. | Mở app, để yên 5 phút → màn điện thoại vẫn sáng; bấm Home → máy tắt màn theo hẹn giờ | ok · miễn test (cờ Android `FLAG_KEEP_SCREEN_ON` trong `MainActivity`, thử máy thật) |
| R-DK-13 | Khay thời tiết (panel P-2026-11-26.15; bỏ bong bóng từ P-2026-11-26.21, bạn chốt 2026-11-27): firmware báo `balloon` và skill Thời tiết bật → ô màn vẽ khay từ x 176 có biểu tượng thời tiết, thanh tác vụ tối đa 3 nút. **Không còn bong bóng** (thiết bị luôn báo `balloon: false`). Chạm biểu tượng khay ở bất kỳ màn nào → mở cửa sổ Thời tiết, tab Hiện tại (`/api/channel {name: Weather}`); không gửi `/api/balloon`. Firmware cũ (không có `balloon`): khay x 196, 4 nút, không có biểu tượng khay. | Desktop hoặc cửa sổ Đồng hồ, chạm mặt trời ở khay → `{name: Weather}` | ok |
| R-DK-14 | Cửa sổ XP thật (panel P-2026-11-26.17, bạn chốt 2026-11-26), firmware có `weatherPlace` trong `/api/settings`: Dự báo là tab "Dự báo" của cửa sổ Thời tiết — một cửa sổ, một nút thanh tác vụ (nút Thời tiết lõm cả khi đang ở tab Dự báo), Start / Tất cả chương trình không còn mục Dự báo riêng; chạm tab "Hiện tại" / "Dự báo" (y 26–41) → `{name: Weather}` / `{name: Forecast}`, tab đang hiện không gửi gì; mở lại cửa sổ Thời tiết (nút, Start, bong bóng) → về tab dùng lần cuối. Như XP: chạm đồng hồ khay → mở Đồng hồ; chạm thân bong bóng thời tiết (trừ ×) → mở Thời tiết. Desktop một cột: Claude, Codex, Ảnh, Thùng rác — không biểu tượng Thời tiết / Đồng hồ. Firmware cũ (không có `weatherPlace`): như R-DK-8/9/13. | Đang ở Dự báo, chạm tab Hiện tại → `{name: Weather}`, danh sách cửa sổ chỉ có Weather; chạm 14:32 ở khay → `{name: Clock}` | ok |
| R-DK-15 | Start menu trên thiết bị (panel P-2026-11-26.20; thiết kế 2026-11-27.10, bạn chốt 2026-11-27: **app không còn sheet Start / Tất cả chương trình**). Phím Windows hoặc click nút start (x 0–67 thanh tác vụ) → `POST /api/menu {kind: start, all: false}` (thiết bị vẽ Start, nút start lún); lần nữa / Esc / click ngoài Start → `{kind: none}`. Chọn mục: R-DK-22. Menu chuột phải đang mở thì nhường cho Start. Firmware không có `windows` → không gửi gì. | Phím Windows → `{kind: start, all: false}`; Esc → `{kind: none}` | ok |
| R-DK-16 | Ngày và Giờ chạm được như XP (panel P-2026-11-26.22, bạn chốt 2026-11-27): firmware có `clock` trong `/api/state` → chạm trên cửa sổ Đồng hồ đổi ngay ô màn và gửi `POST /api/clock {tab, year, month, day, list, top}`: tab (Ngày và giờ / Múi giờ / Internet), ô tháng mở / đóng danh sách tháng, chọn tháng, ▲▼ năm, chạm ngày (chỉ để xem), ô múi giờ mở danh sách, chọn múi → `tzMinutes` qua `/api/settings`, ▲▼ thanh cuộn, chạm ngoài danh sách → đóng; `Cập nhật ngay` → `{…, sync: true}`. Giờ chỉ đọc. Mở lại cửa sổ Đồng hồ từ màn khác → về hôm nay, tab Ngày và giờ. Firmware không có `clock` → chạm trên cửa sổ không gửi gì. | Chạm ô tháng → danh sách tháng; chọn Thg 3 → `{month: 3, list: none}`; tab Múi giờ chọn Tokyo → `tzMinutes: 540` | ok |

Từ kế hoạch `docs/tasks/2026-11-27-app-la-chuot-ban-phim-nguon.md` (bạn duyệt 2026-11-27): **app là phần cứng máy tính
— chuột, bàn phím, nút nguồn, bộ xử lý; thiết bị là màn hình.** Bỏ ô màn chạm được trên app: người dùng nhìn màn thật.
Mọi chỗ R-DK-7…16 nói "chạm (giữ) trên ô màn tại (x, y)" nay là "click trái (phải) khi con trỏ ở (x, y)"; luật trúng
đích và lệnh gửi đi không đổi.

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-DK-17 | Con trỏ do app giữ: toạ độ px thiết bị, kẹp trong 0…239 × 0…239, mới mở app → giữa màn (120, 120). Rê trên bàn rê → con trỏ đi theo quãng rê nhân hệ số tốc độ (rê nhanh đi xa hơn — gia tốc như chuột). App gửi vị trí + hình con trỏ xuống thiết bị qua UDP (cổng thiết bị báo trong `/api/state` `cursor`), tối đa ~30 gói/giây, chỉ khi đổi; mất gói thì gói sau sửa, không gửi lại. Hình con trỏ theo thứ dưới nó: bàn tay trên thứ bấm được (biểu tượng, nút, mục menu, tab, nút thanh tác vụ), đồng hồ cát khi cửa sổ đang mở (chờ thiết bị), còn lại mũi tên. | Con trỏ (230, 100), rê sang phải 40 → (239, 100); rê lên nút × của cửa sổ → hình bàn tay | ok |
| R-DK-18 | Click trái (chạm nhẹ trên bàn rê hoặc nút trái) = chạm cũ tại vị trí con trỏ (R-DK-7…16: `touchTargetAt`). Click phải (nút phải) = giữ cũ tại vị trí con trỏ (R-DK-11: `holdMenuAt`). Menu đang mở: con trỏ đứng trên một mục → mục đó sáng trên thiết bị (`/api/menu {…, hover}`), click trái chọn mục. Không kéo thả (cửa sổ luôn đầy màn). Mỗi click / phím / nút chuột rung nhẹ (bạn chốt 2026-11-27). | Con trỏ trên nút Claude ở thanh tác vụ, click phải → `/api/menu {kind: window…}`; rê xuống "Đóng" → `hover` = Đóng; click → đóng cửa sổ | ok |
| R-DK-19 | Bàn phím điều khiển (gõ chữ làm sau): **Windows** mở / đóng Start (R-DK-15); **Alt+Tab** → cửa sổ kế tiếp trong danh sách mở lên trên cùng (vòng, cả cửa sổ thu nhỏ); **Alt+F4** → đóng cửa sổ trên cùng (như `×`, R-DK-8), đang ở desktop thì không làm gì; **mũi tên** → menu đang mở: mục sáng lên / xuống (bỏ mục mờ), desktop: biểu tượng chọn lên / xuống (`sel`); **Enter** → mở / chọn thứ đang chọn hoặc đang sáng; **Esc** → đóng menu / Start đang mở, không có thì không làm gì; **Tab** → như mũi tên xuống. Phím đi qua đúng các lệnh của R-DK-7…16. Mỗi click / phím / nút chuột rung nhẹ (bạn chốt 2026-11-27). | Desktop chọn Claude, ↓ → `sel` Codex; Enter → mở Codex; Alt+F4 → đóng Codex, về desktop | ok |
| R-DK-20 | Nút nguồn: đang bật, bấm → `POST /api/power {on: false}`: thiết bị hiện màn "đang tắt máy" rồi tắt đèn màn hình, vẫn chạy (nhận lệnh, thẻ agent khẩn vẫn đánh thức như tắt màn — `chAttentionWakesScreen`); con trỏ ẩn, bàn rê / phím không gửi gì. Đang tắt, bấm → `{on: true}`: màn khởi động rồi về desktop, danh sách cửa sổ trống (như mới mở app, R-DK-7). Trạng thái nguồn đọc từ `/api/state` `power`. | Bấm nguồn khi đang mở Claude → `{on: false}`; rê bàn rê → không gói UDP nào; bấm lại → `{on: true}`, thanh tác vụ trống | ok |
| R-DK-21 | Firmware chưa có chuột (`/api/state` không có `cursor`) → màn Điều khiển khoá bàn rê, phím, nguồn (mờ + ổ khoá) + thanh báo gợi ý cập nhật firmware; không gửi gì. Thay R-DK-10 (không còn ô màn để lùi về chạm). | Firmware 0.30 không báo `cursor` → rê / bấm không có gói UDP, không `POST` | ok |
| R-DK-22 | Click trái khi Start mở trên thiết bị (bố cục `src/channels/xp_start.cpp`; panel P-2026-11-27.25, bạn chốt 2026-11-27): cột trái — Claude (y 36–63), Codex (64–91) khi skill Agent bật, rồi **3 chương trình mở gần nhất** do thiết bị báo (`/api/state` `start_recent`, mới nhất trên; chỉ chương trình đã cài; thiếu bù theo Ảnh, Thời tiết, Đồng hồ, Dò mìn, AI hôm nay, Xu hướng, Agents), hàng 20 từ y 99 (38 khi Agent tắt) → mở chương trình đó (R-DK-7), Start đóng; "Tất cả chương trình" (y 167–186) → `{kind: start, all: true}` (lần nữa → `all: false`). Menu con = **mọi chương trình đã cài** (Claude, Codex, AI hôm nay, Xu hướng, Agents khi `showAgents`, Ảnh, Thời tiết, Đồng hồ, Dò mìn), vạch, Thêm / gỡ; khung (144, top, 96 × (4 + 20n + 7 + 20)), top = 62, cao quá thì dời lên cho đáy ≤ 213; hàng 20 từ top + 2. Cột phải (x 153–238): Desktop (y 37–58) → thu nhỏ hết; Số liệu (59–82) / Cài đặt (88–108) / Thêm / gỡ (109–129) / Thiết bị (130–150) → mở màn đó trên điện thoại. Dải dưới (y 190–213): Khởi động lại (x 0–110) → hỏi lại rồi khởi động lại; Tắt máy (x 160–239) → nút nguồn tắt (R-DK-20). Click ngoài Start → Start đóng. | Đủ skill + `showAgents`, Start mở, Tất cả chương trình → menu con (144, 2, 96×211); click (190, 170) → Dò mìn | ok |
| R-DK-23 | Dò mìn (skill Giải trí `fun`, panel P-2026-11-27.25, bạn chốt 2026-11-27: **app giữ ván**): bảng 9×9, 10 mìn như Minesweeper XP mức Beginner. Click trái ô chưa mở (không cờ) → mở; **click đầu tiên của ván không bao giờ trúng mìn** (mìn đặt sau click đầu, tránh ô đó); ô 0 tự mở lan ô kề (không mở ô cắm cờ); trúng mìn → thua: hiện mọi mìn chưa cắm cờ, mìn vừa click nổ (đỏ), cờ cắm sai hiện gạch chéo, mặt chết; mở hết ô không mìn → thắng: mọi mìn tự cắm cờ, đếm mìn 000, mặt kính. Click phải ô chưa mở → cắm cờ / gỡ cờ (không dấu `?`); click trái lên cờ không làm gì. Đếm mìn = 10 − số cờ (âm được). Đồng hồ chạy từ click đầu, dừng khi thắng / thua, tối đa 999. Ván xong → bảng không nhận click, chỉ mặt cười. Click mặt cười (107–132, 29–54) → ván mới. Mỗi thay đổi gửi cả bảng `POST /api/mines {board, face, left, secs, run}` (thiết bị vẽ, tự chạy giây). Không chord. Firmware không có `mines` trong `/api/state` → chương trình không có. | Click đầu (4, 4) → không mìn, lan mở; click phải (0, 0) → cờ, đếm 009; trúng mìn → `face: dead`, `run: false` | ok |

## 9. Vị trí thời tiết

Từ thiết kế 2026-11-26.9 (`docs/tasks/2026-11-27-thiet-ke-2026-11-26.9.md`, bạn đồng ý áp 2026-11-27): đặt vị trí thời
tiết của thiết bị từ điện thoại. Vị trí chỉ nằm trên thiết bị (`weatherLat`, `weatherLon`, `weatherPlace` của
`/api/settings`), app không lưu.

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-VT-1 | App chỉ lấy vị trí điện thoại khi bấm "Dùng vị trí hiện tại": hỏi quyền (hộp thoại hệ thống) rồi lấy một lần; từ chối → thanh báo (bị từ chối hẳn thì có nút mở cài đặt điện thoại), định vị tắt → thanh báo + nút bật định vị, không lấy được → thanh báo + Thử lại. Lấy được → bảng xác nhận, tên = tên nơi điện thoại tra được (không có thì để trống). | Mở màn → không hỏi quyền, không lấy vị trí; bấm nút, định vị tắt → "Định vị đang tắt" | ok |
| R-VT-2 | Tìm thành phố qua Open-Meteo (`language=vi`, tối đa 10 kết quả) 400 ms sau phím cuối, từ 2 ký tự; dưới 2 ký tự → không tìm, xoá kết quả; một lần tìm mới bỏ kết quả của lần cũ. | Gõ "Đ" → không gửi gì; gõ "Đà" rồi dừng → một lần tìm | ok |
| R-VT-3 | Tên hiện trên thiết bị tối đa 16 ký tự (chữ, không phải byte), bỏ khoảng trắng đầu / cuối. "Đặt cho thiết bị" gửi `{weatherLat, weatherLon, weatherPlace}`; "Sửa tên" chỉ gửi `weatherPlace`. Thiết bị nhận → thẻ cập nhật + thông báo nhỏ 3 s; không nhận → bảng giữ mở, "Thiết bị không nhận", vị trí trên thiết bị giữ nguyên. | Tên "Thành phố Hồ Chí Minh" → gửi "Thành phố Hồ Chí" | ok |
| R-VT-4 | Firmware không có khoá `weatherPlace` trong `/api/settings` → chỉ gửi `weatherLat` / `weatherLon`; thẻ hiện toạ độ + ghi chú cập nhật firmware; bảng không có ô tên. | Firmware cũ, chọn Đà Nẵng → `{weatherLat: 16.07, weatherLon: 108.22}` | ok |
| R-VT-5 | "Xoá vị trí" hỏi trước; đồng ý → gửi `weatherLat` 0, `weatherLon` 0, `weatherPlace` "" (firmware cũ: không gửi tên); thiết bị coi 0, 0 là chưa đặt → thẻ "chưa đặt". | Xoá Hà Nội → `{weatherLat: 0, weatherLon: 0, weatherPlace: ""}` | ok |

## 10. Kho ảnh (app là bộ nhớ, thiết bị trỏ vào lấy)

Bạn chốt 2026-11-27 (kế hoạch `docs/tasks/2026-11-27-kho-anh-tren-app.md`): app điện thoại là bộ nhớ + bộ xử lý, thiết
bị là màn hình. Thiết bị xin, app trả; thiết bị giữ bản đệm nhỏ do app chọn; hình nền giữ như cũ.

| Mã | Quy tắc | Ví dụ | App |
| --- | --- | --- | --- |
| R-AK-1 | Mọi ảnh người dùng thêm (đã cắt 188×188, ≤ 40 KB) nằm trong **kho trên điện thoại** (`library/<mã>.jpg` + `library.json`), không giới hạn số ảnh; mã tăng dần, không dùng lại. Xoá một ảnh ở tab Ảnh = xoá khỏi kho. | Gửi ảnh thứ 12 → kho có 12 ảnh | ok |
| R-AK-2 | Thiết bị xin "ảnh sau mã X"; app trả ảnh kế tiếp theo thứ tự thêm (cũ trước), hết thì vòng lại đầu; X = 0 → ảnh đầu; X đã bị xoá → ảnh có mã lớn hơn kế tiếp. Kèm số thứ tự (từ 1) và tổng số ảnh. Kho rỗng → không có ảnh (204). | Kho [3, 5, 9]: sau 5 → 9 (3/3); sau 9 → 3 (1/3); sau 4 (đã xoá) → 5 | ok |
| R-AK-3 | Bộ đệm trên thiết bị = **8 ảnh mới nhất** của kho (app tự chọn, không có nút ghim): ảnh rời khỏi 8 mới nhất thì xoá khỏi thiết bị, ảnh mới nhất còn thiếu thì tải lên (mới trước; thiết bị đầy / hết chỗ thì dừng). Ảnh trên thiết bị không do kho gửi (trang web, máy khác) không bao giờ bị xoá. | Kho 9 ảnh, thiết bị giữ 8 → thêm ảnh 10: xoá bản của ảnh cũ nhất trong 8, tải ảnh 10 | ok |
| R-AK-4 | Kho được phục vụ trong mạng nhà (HTTP thường, cổng 8787, bận thì cổng khác) khi app đang mở và 2 phút sau khi app ra nền; đường dẫn có khoá ngẫu nhiên mỗi lần chạy app. Mở app / quay lại app / nối thiết bị → gửi thiết bị `{host, port, key}` (`POST /api/photos/source`), host = địa chỉ điện thoại cùng mạng với thiết bị. App vắng → thiết bị chiếu bộ đệm, 60 s sau xin lại. | Thiết bị 192.168.1.50, điện thoại 192.168.1.20 → `{host: 192.168.1.20, port: 8787, key: …}` | ok |
| R-AK-5 | Firmware chưa có `photo_source` trong `/api/state` → không gửi nguồn, không đồng bộ bộ đệm; gửi ảnh như cũ (thẳng xuống thiết bị) và vẫn thêm vào kho. | Firmware 0.24 → gửi ảnh = `POST /api/photos` như trước | ok |
