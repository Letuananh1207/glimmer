# Phiếu thiết kế: Bàn phím điều khiển — các phím XP còn thiếu cho chương trình mới

- Trạng thái: chờ thiết kế
- Ngày: 2026-11-28 · Nguồn: kế hoạch `docs/tasks/2026-11-28-app-cho-chuong-trinh-xp.md` (nhiệm vụ 11); yêu cầu người
  dùng 2026-11-28: "tính năng mới phải hoàn thiện, dùng giống hệt Windows XP"

## Dán vào canvas

**Màn / widget:** Điều khiển › `KeyPad` (screen_specs §8, components.md `KeyPad`).

**Cần:** thiết bị đã có Trình quản lý tác vụ, Alt+Tab, Explorer (Máy tính / Ảnh của tôi / Thùng rác) — panel
P-2026-11-28.28 / .29 / .32. App đã làm mọi click bên trong, nhưng 4 thao tác XP chỉ làm được bằng phím mà `KeyPad`
chưa có, nên người dùng **không dùng trọn được** các chương trình này:

| Phím XP | Làm gì (như Windows XP) | Hiện thiếu |
|---|---|---|
| **Ctrl+Alt+Del** | Mở Trình quản lý tác vụ (XP có Welcome screen: mở thẳng Task Manager). Đang mở thì đưa nó lên trên. | Không có lối nào mở Trình quản lý tác vụ |
| **Delete** | Explorer › Ảnh của tôi: ảnh đang chọn → hộp "Xác nhận xoá tệp" (Có / Không) → vào Thùng rác. Thùng rác: dòng chọn → hỏi xoá hẳn. Trình quản lý tác vụ: = Kết thúc tác vụ. | Không xoá được ảnh trên thiết bị |
| **Backspace** | Explorer: lên một cấp (Ảnh của tôi / Thùng rác → Máy tính). | Vào Ảnh của tôi rồi không quay lại Máy tính được |
| **Shift+Tab** | Hộp Alt+Tab đang mở: lùi một ô (Alt+Shift+Tab). Trong menu: mục trên. | Alt+Tab chỉ đi tới |

**Trạng thái phải vẽ:** `KeyPad` có thêm các phím (bình thường, đang nhấn, mờ khi firmware chưa có chương trình đó /
khi tắt nguồn / ban đêm như các phím khác). Gợi ý chỗ: hàng phím tổ hợp hiện có (Windows · Alt+Tab · Alt+F4 · Esc).

**Luật phải theo:**
- R-DK-19: tổ hợp là **phím có sẵn**, một chạm (không phím dính); rung nhẹ mỗi lần bấm.
- R-DK-24 (Trình quản lý tác vụ), R-DK-25 (Alt+Tab, hộp tự nhả sau 1 s), R-DK-28 (Explorer), R-DK-21 (firmware chưa có
  chuột → khoá phím).
- Vùng chạm ≥ 44.

**Dữ liệu từ thiết bị:** có sẵn — `taskmgr`, `explorer` (`trash`), `alttab` trong `/api/state`; xoá ảnh = `POST
/api/explorer {confirm: delete}` rồi `{do: delete}` (firmware đã có).

**Chuỗi:** mới — `keyCtrlAltDel` ("Ctrl+Alt+Del"), `keyDelete` ("Delete" hoặc "Xoá"), `keyBackspace` ("Backspace" hoặc
"⌫"), `keyShiftTab` ("Shift+Tab"); nhãn đọc màn hình cho từng phím.

**Dùng lại:** `KeyPad` (phím 52 bo 10, gradient `keyFaceTop` → `keyFaceBottom`, `keyEdge`, `keyPressed`), icon Material
cho Backspace / Delete.

**Gợi ý (không bắt buộc):** bàn phím đã kín 3 hàng — có thể thêm hàng 4, hoặc đổi `keyText` (Chữ, "sắp có") thành nút
mở bàn phím mở rộng.

**App đang có (dựng tạm):** chưa có. Logic các phím (trừ chỗ vẽ) làm ngay khi có bản vẽ.

## Ghi chú phía code
- Chặn việc: kế hoạch `docs/tasks/2026-11-28-app-cho-chuong-trinh-xp.md` — vòng mở Trình quản lý tác vụ, xoá ảnh,
  quay lại Máy tính, Alt+Shift+Tab.
- Đi cùng phiếu màn thiết bị `../docs/phieu_panel/2026-11-28-menu-thanh-tac-vu-va-start-may-tinh.md` (menu chuột phải
  thanh tác vụ, menu chuột phải trên tệp, hàng Start cho Máy tính bỏ túi).
