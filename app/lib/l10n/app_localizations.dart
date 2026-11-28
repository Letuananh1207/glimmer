import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('vi')];

  /// Không còn hiện trên thanh dưới từ 2026-11-25.2 (tab 1 mang tên skill); giữ cho tiêu đề / đọc màn hình
  ///
  /// In vi, this message translates to:
  /// **'Tổng quan'**
  String get navDashboard;

  /// Tab dưới
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get navSettings;

  /// Tab dưới
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị'**
  String get navDevice;

  /// Nút hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get commonCancel;

  /// Nút thử lại
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get commonRetry;

  /// Nút hộp thoại đặt giá trị
  ///
  /// In vi, this message translates to:
  /// **'Đặt'**
  String get commonSet;

  /// Nút lưu token app
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get commonSave;

  /// Thời gian đã qua, time = "2m", "3h"
  ///
  /// In vi, this message translates to:
  /// **'{time} trước'**
  String commonAgo(String time);

  /// Kết nối · đang tìm
  ///
  /// In vi, this message translates to:
  /// **'Đang tìm thiết bị…'**
  String get connectSearchingTitle;

  /// Kết nối · đang tìm
  ///
  /// In vi, this message translates to:
  /// **'Tìm glimmer trên mạng Wi-Fi của điện thoại.'**
  String get connectSearchingBody;

  /// Kết nối · chưa có thiết bị
  ///
  /// In vi, this message translates to:
  /// **'Chưa kết nối'**
  String get connectIdleTitle;

  /// Kết nối · khi không có lỗi cụ thể
  ///
  /// In vi, this message translates to:
  /// **'Điện thoại cần ở cùng mạng Wi-Fi với thiết bị.'**
  String get connectIdleBody;

  /// Lỗi tìm tự động
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy thiết bị trên mạng này.'**
  String get connectNotFound;

  /// Lỗi khi nhập IP
  ///
  /// In vi, this message translates to:
  /// **'Không có thiết bị glimmer ở {url}.'**
  String connectNoDeviceAt(String url);

  /// Nút chính
  ///
  /// In vi, this message translates to:
  /// **'Tìm lại'**
  String get connectRetry;

  /// Nút viền
  ///
  /// In vi, this message translates to:
  /// **'Nhập địa chỉ IP'**
  String get connectManual;

  /// Nút viền ở Kết nối → màn Quét mã (đổi 2026-11-28.12, icon qr)
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR trên màn thiết bị'**
  String get connectNewDevice;

  /// Hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Nhập địa chỉ thiết bị'**
  String get connectManualTitle;

  /// Hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'IP hiện trên kênh Thông tin của thiết bị, ví dụ 192.168.1.50.'**
  String get connectManualHint;

  /// Ô nhập
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ IP'**
  String get connectManualIp;

  /// Ô nhập, ẩn chữ
  ///
  /// In vi, this message translates to:
  /// **'API token (nếu có)'**
  String get connectManualToken;

  /// Nút hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Kết nối'**
  String get connectManualOk;

  /// Dòng dưới tên glimmer khi thiết bị ở glimmer-setup
  ///
  /// In vi, this message translates to:
  /// **'chế độ cài đặt · {ip}'**
  String dashboardSetupMode(String ip);

  /// Thẻ ghi chú
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị đang ở chế độ cài đặt Wi-Fi (glimmer-setup). Vào tab Thiết bị → Wi-Fi.'**
  String get dashboardSetupNote;

  /// Nhãn thẻ
  ///
  /// In vi, this message translates to:
  /// **'MỨC DÙNG CLAUDE'**
  String get dashboardUsageTitle;

  /// Meta, amber
  ///
  /// In vi, this message translates to:
  /// **'chưa có khóa Claude — thêm trong Cài đặt'**
  String get dashboardUsageNoKey;

  /// Meta, coral
  ///
  /// In vi, this message translates to:
  /// **'khóa Claude lỗi — cập nhật trong Cài đặt'**
  String get dashboardUsageKeyBad;

  /// Meta, amber
  ///
  /// In vi, this message translates to:
  /// **'claude.ai đang chặn thiết bị — tự thử lại'**
  String get dashboardUsageBlocked;

  /// Meta, amber
  ///
  /// In vi, this message translates to:
  /// **'số liệu cũ ({time} trước)'**
  String dashboardUsageStale(String time);

  /// Dòng %
  ///
  /// In vi, this message translates to:
  /// **'Tuần'**
  String get dashboardWeek;

  /// Dòng %
  ///
  /// In vi, this message translates to:
  /// **'Phiên 5 giờ'**
  String get dashboardSession;

  /// time = "3d 4h"
  ///
  /// In vi, this message translates to:
  /// **'đặt lại sau {time}'**
  String dashboardResetIn(String time);

  /// Nhãn thẻ
  ///
  /// In vi, this message translates to:
  /// **'PROJECT'**
  String get dashboardProjects;

  /// Nút chữ
  ///
  /// In vi, this message translates to:
  /// **'Xóa bảng'**
  String get dashboardProjectsClear;

  /// Bảng project trống
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hoạt động. Hook của Claude Code sẽ gửi trạng thái lên đây.'**
  String get dashboardProjectsEmpty;

  /// Nhãn thẻ
  ///
  /// In vi, this message translates to:
  /// **'THẺ TRÊN MÀN HÌNH'**
  String get dashboardCards;

  /// Nút chữ
  ///
  /// In vi, this message translates to:
  /// **'Xóa hết'**
  String get dashboardCardsClearAll;

  /// Nút
  ///
  /// In vi, this message translates to:
  /// **'Tải số liệu ngay'**
  String get dashboardRefreshNow;

  /// Không dùng từ 2026-11-25.3 — Nút
  ///
  /// In vi, this message translates to:
  /// **'Hiện màn Claude'**
  String get dashboardShowClaude;

  /// Snackbar
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa bảng project'**
  String get dashboardDoneProjectsCleared;

  /// Snackbar
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa thẻ'**
  String get dashboardDoneCardCleared;

  /// Snackbar
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa mọi thẻ'**
  String get dashboardDoneCardsCleared;

  /// Snackbar
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị đang tải số liệu mới'**
  String get dashboardDoneRefresh;

  /// Snackbar
  ///
  /// In vi, this message translates to:
  /// **'Đã chuyển sang màn Claude'**
  String get dashboardDoneShowClaude;

  /// Trạng thái project / loại thẻ
  ///
  /// In vi, this message translates to:
  /// **'Cần duyệt'**
  String get stateApproval;

  /// Trạng thái
  ///
  /// In vi, this message translates to:
  /// **'Chờ bạn'**
  String get stateInput;

  /// Trạng thái
  ///
  /// In vi, this message translates to:
  /// **'Lỗi'**
  String get stateError;

  /// Trạng thái
  ///
  /// In vi, this message translates to:
  /// **'Đang chạy'**
  String get stateWorking;

  /// Trạng thái
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get stateDone;

  /// Loại thẻ
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ'**
  String get cardProgress;

  /// Loại thẻ
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo'**
  String get cardWarning;

  /// Loại thẻ
  ///
  /// In vi, this message translates to:
  /// **'Thông tin'**
  String get cardInfo;

  /// Nhóm
  ///
  /// In vi, this message translates to:
  /// **'MÀN HÌNH'**
  String get settingsSectionDisplay;

  /// Thanh trượt, hiện "Độ sáng: 80%"
  ///
  /// In vi, this message translates to:
  /// **'Độ sáng'**
  String get settingsBrightness;

  /// Công tắc
  ///
  /// In vi, this message translates to:
  /// **'Tự giảm sáng khi rảnh'**
  String get settingsIdleDim;

  /// Phụ
  ///
  /// In vi, this message translates to:
  /// **'15 phút không có hoạt động agent → 15%'**
  String get settingsIdleDimSub;

  /// Công tắc
  ///
  /// In vi, this message translates to:
  /// **'Số lớn là mức dùng tuần'**
  String get settingsWeeklyHero;

  /// Phụ
  ///
  /// In vi, this message translates to:
  /// **'tắt: số lớn là phiên 5 giờ'**
  String get settingsWeeklyHeroSub;

  /// Công tắc
  ///
  /// In vi, this message translates to:
  /// **'Đồng hồ 24 giờ'**
  String get settingsClock24h;

  /// Nhóm
  ///
  /// In vi, this message translates to:
  /// **'BAN ĐÊM'**
  String get settingsSectionNight;

  /// Chọn
  ///
  /// In vi, this message translates to:
  /// **'Chế độ'**
  String get settingsNightMode;

  /// Lựa chọn
  ///
  /// In vi, this message translates to:
  /// **'Không'**
  String get settingsNightNone;

  /// Lựa chọn
  ///
  /// In vi, this message translates to:
  /// **'Giảm sáng'**
  String get settingsNightDim;

  /// Lựa chọn
  ///
  /// In vi, this message translates to:
  /// **'Đồng hồ'**
  String get settingsNightClock;

  /// Lựa chọn
  ///
  /// In vi, this message translates to:
  /// **'Tắt màn'**
  String get settingsNightOff;

  /// Giờ bắt đầu
  ///
  /// In vi, this message translates to:
  /// **'Từ'**
  String get settingsNightFrom;

  /// Giờ kết thúc
  ///
  /// In vi, this message translates to:
  /// **'Đến'**
  String get settingsNightTo;

  /// Thanh trượt, chỉ khi Giảm sáng
  ///
  /// In vi, this message translates to:
  /// **'Độ sáng ban đêm'**
  String get settingsNightBright;

  /// Nhóm
  ///
  /// In vi, this message translates to:
  /// **'SỐ LIỆU CLAUDE'**
  String get settingsSectionClaude;

  /// Dòng khóa
  ///
  /// In vi, this message translates to:
  /// **'Khóa Claude (sessionKey)'**
  String get settingsClaudeKey;

  /// Hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Dán sessionKey của claude.ai (bắt đầu bằng sk-ant-…).'**
  String get settingsClaudeKeyHint;

  /// Chọn
  ///
  /// In vi, this message translates to:
  /// **'Tải số liệu mỗi'**
  String get settingsRefresh;

  /// Lựa chọn thời gian
  ///
  /// In vi, this message translates to:
  /// **'{n} phút'**
  String settingsMinutes(String n);

  /// Lựa chọn
  ///
  /// In vi, this message translates to:
  /// **'1 giờ'**
  String get settingsHour;

  /// Lựa chọn
  ///
  /// In vi, this message translates to:
  /// **'Không bao giờ'**
  String get settingsNever;

  /// Dòng tên
  ///
  /// In vi, this message translates to:
  /// **'Tên của bạn'**
  String get settingsUserName;

  /// Nhóm
  ///
  /// In vi, this message translates to:
  /// **'AGENT'**
  String get settingsSectionAgent;

  /// Công tắc
  ///
  /// In vi, this message translates to:
  /// **'Màn danh sách tác tử'**
  String get settingsShowAgents;

  /// Phụ
  ///
  /// In vi, this message translates to:
  /// **'thẻ duyệt vẫn hiện khi tắt'**
  String get settingsShowAgentsSub;

  /// Công tắc
  ///
  /// In vi, this message translates to:
  /// **'Giữ thẻ duyệt tới khi trả lời'**
  String get settingsPinApprovals;

  /// Công tắc
  ///
  /// In vi, this message translates to:
  /// **'Thẻ \"xong\" khi agent dừng'**
  String get settingsDoneCards;

  /// Chọn
  ///
  /// In vi, this message translates to:
  /// **'Bỏ thẻ chờ sau'**
  String get settingsApprovalTtl;

  /// Dòng khóa
  ///
  /// In vi, this message translates to:
  /// **'API token của thiết bị'**
  String get settingsApiToken;

  /// Hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Nếu đặt, hook / app phải gửi kèm token này. Để trống để bỏ.'**
  String get settingsApiTokenHint;

  /// Dòng
  ///
  /// In vi, this message translates to:
  /// **'Token app đang dùng'**
  String get settingsAppToken;

  /// Hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Token cho app'**
  String get settingsAppTokenTitle;

  /// Trạng thái khóa
  ///
  /// In vi, this message translates to:
  /// **'đã đặt'**
  String get settingsSecretSet;

  /// Trạng thái khóa / tên
  ///
  /// In vi, this message translates to:
  /// **'chưa đặt'**
  String get settingsSecretUnset;

  /// Trạng thái khóa
  ///
  /// In vi, this message translates to:
  /// **'sẽ đổi khi lưu'**
  String get settingsSecretPending;

  /// Token app
  ///
  /// In vi, this message translates to:
  /// **'không có'**
  String get settingsNone;

  /// Snackbar
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu'**
  String get settingsSaved;

  /// Nút viền
  ///
  /// In vi, this message translates to:
  /// **'Bỏ thay đổi'**
  String get settingsDiscard;

  /// Nút chính, count = số mục đã đổi
  ///
  /// In vi, this message translates to:
  /// **'Lưu ({count})'**
  String settingsSaveCount(String count);

  /// Nút khi đang lưu
  ///
  /// In vi, this message translates to:
  /// **'Đang lưu…'**
  String get settingsSaving;

  /// Nhãn thẻ
  ///
  /// In vi, this message translates to:
  /// **'THIẾT BỊ'**
  String get deviceInfo;

  /// Khóa
  ///
  /// In vi, this message translates to:
  /// **'Firmware'**
  String get deviceFirmware;

  /// Khóa
  ///
  /// In vi, this message translates to:
  /// **'Bản build'**
  String get deviceBuild;

  /// Khóa
  ///
  /// In vi, this message translates to:
  /// **'Wi-Fi'**
  String get deviceWifi;

  /// Khóa
  ///
  /// In vi, this message translates to:
  /// **'IP'**
  String get deviceIp;

  /// Khóa
  ///
  /// In vi, this message translates to:
  /// **'Đã chạy'**
  String get deviceUptime;

  /// Khóa
  ///
  /// In vi, this message translates to:
  /// **'Bộ nhớ trống'**
  String get deviceHeap;

  /// Giá trị
  ///
  /// In vi, this message translates to:
  /// **'{free} KB (khối lớn nhất {block} KB)'**
  String deviceHeapValue(String free, String block);

  /// Giá trị Wi-Fi
  ///
  /// In vi, this message translates to:
  /// **'chế độ cài đặt'**
  String get deviceSetupMode;

  /// Dòng
  ///
  /// In vi, this message translates to:
  /// **'Đổi Wi-Fi cho thiết bị'**
  String get deviceChangeWifi;

  /// Phụ
  ///
  /// In vi, this message translates to:
  /// **'Khi chuyển nhà / nơi làm'**
  String get deviceChangeWifiSub;

  /// Dòng, tiêu đề và nút hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Khởi động lại'**
  String get deviceReboot;

  /// Hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị sẽ tắt màn hình vài giây rồi bật lại.'**
  String get deviceRebootBody;

  /// Dòng
  ///
  /// In vi, this message translates to:
  /// **'Kết nối thiết bị khác'**
  String get deviceForget;

  /// Nhãn thẻ
  ///
  /// In vi, this message translates to:
  /// **'CẬP NHẬT'**
  String get deviceUpdates;

  /// Trạng thái
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra bản mới…'**
  String get deviceChecking;

  /// Có thể kèm " · {commit}"
  ///
  /// In vi, this message translates to:
  /// **'Bản mới nhất: {date}'**
  String deviceLatest(String date);

  /// mint
  ///
  /// In vi, this message translates to:
  /// **'Có bản mới hơn thiết bị.'**
  String get deviceNewer;

  /// inkDim
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị có vẻ đã cập nhật.'**
  String get deviceUpToDate;

  /// Dòng / hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật firmware'**
  String get deviceUpdateFw;

  /// Phụ
  ///
  /// In vi, this message translates to:
  /// **'Giữ nguyên cấu hình và lịch sử'**
  String get deviceUpdateFwSub;

  /// Hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Tải firmware mới nhất từ {repo} và nạp qua Wi-Fi. Cấu hình được giữ nguyên.'**
  String deviceUpdateFwBody(String repo);

  /// Nút hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật'**
  String get deviceUpdate;

  /// Dòng / hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật đầy đủ'**
  String get deviceUpdateFull;

  /// Phụ
  ///
  /// In vi, this message translates to:
  /// **'Kèm font + giao diện web; tự sao lưu và khôi phục cấu hình'**
  String get deviceUpdateFullSub;

  /// Hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Nạp firmware và hệ thống tệp (font, giao diện web). Ứng dụng sẽ sao lưu cấu hình, nạp, rồi tự khôi phục qua Wi-Fi glimmer-setup (Android sẽ hỏi xác nhận). Lịch sử mức dùng 7 ngày bị xóa.'**
  String get deviceUpdateFullBody;

  /// Nút hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu'**
  String get deviceStart;

  /// Dòng / hộp thoại / nút
  ///
  /// In vi, this message translates to:
  /// **'Sao lưu cấu hình'**
  String get deviceBackup;

  /// Phụ
  ///
  /// In vi, this message translates to:
  /// **'Có mật khẩu Wi-Fi và khóa — giữ kín'**
  String get deviceBackupSub;

  /// Hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Tệp chứa mật khẩu Wi-Fi và khóa Claude ở dạng chữ thường. Chỉ lưu ở nơi an toàn.'**
  String get deviceBackupBody;

  /// Dòng / hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục cấu hình'**
  String get deviceRestore;

  /// Hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Thay toàn bộ cấu hình thiết bị bằng tệp \"{file}\"? Thiết bị sẽ khởi động lại.'**
  String deviceRestoreBody(String file);

  /// Nút hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục'**
  String get deviceRestoreOk;

  /// Thẻ tiến trình
  ///
  /// In vi, this message translates to:
  /// **'Đừng tắt ứng dụng hay rút điện thiết bị.'**
  String get deviceBusyNote;

  /// Bước
  ///
  /// In vi, this message translates to:
  /// **'Nạp firmware…'**
  String get deviceStepFlashFw;

  /// Bước
  ///
  /// In vi, this message translates to:
  /// **'Nạp hệ thống tệp…'**
  String get deviceStepFlashFs;

  /// Bước
  ///
  /// In vi, this message translates to:
  /// **'Tải {name}…'**
  String deviceStepDownload(String name);

  /// Bước
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị đang khởi động lại…'**
  String get deviceStepRebooting;

  /// Bước
  ///
  /// In vi, this message translates to:
  /// **'Sao lưu cấu hình…'**
  String get deviceStepBackup;

  /// Bước
  ///
  /// In vi, this message translates to:
  /// **'Gửi cấu hình…'**
  String get deviceStepSendConfig;

  /// Thanh trên
  ///
  /// In vi, this message translates to:
  /// **'Cài Wi-Fi cho thiết bị'**
  String get wifiTitle;

  /// Nhãn
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị chỉ nhớ một mạng, chỉ dùng Wi-Fi 2,4 GHz và không vào được mạng phải đăng nhập qua trang web (khách sạn, sân bay). Khi đó hãy dùng hotspot điện thoại.'**
  String get wifiNote;

  /// Ô nhập
  ///
  /// In vi, this message translates to:
  /// **'Tên Wi-Fi (SSID)'**
  String get wifiSsid;

  /// Ô nhập, ẩn chữ
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu (để trống nếu mạng mở)'**
  String get wifiPass;

  /// Nút chính
  ///
  /// In vi, this message translates to:
  /// **'Gửi cho thiết bị'**
  String get wifiSend;

  /// Trạng thái
  ///
  /// In vi, this message translates to:
  /// **'Gửi Wi-Fi mới cho thiết bị…'**
  String get wifiStepDirect;

  /// Trạng thái
  ///
  /// In vi, this message translates to:
  /// **'Đang vào Wi-Fi glimmer-setup…'**
  String get wifiStepJoinAp;

  /// Chi tiết (đổi 2026-11-28.12)
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị phải đang hiện màn cài Wi-Fi có mã QR. Android sẽ hỏi bạn xác nhận kết nối.'**
  String get wifiStepJoinApDetail;

  /// Trạng thái
  ///
  /// In vi, this message translates to:
  /// **'Gửi \"{ssid}\" cho thiết bị…'**
  String wifiStepSend(String ssid);

  /// Trạng thái
  ///
  /// In vi, this message translates to:
  /// **'Chờ thiết bị vào \"{ssid}\"…'**
  String wifiStepWait(String ssid);

  /// Chi tiết
  ///
  /// In vi, this message translates to:
  /// **'Có thể mất tới 4 phút. Điện thoại cần ở cùng mạng này.'**
  String get wifiStepWaitDetail;

  /// Trạng thái, mint
  ///
  /// In vi, this message translates to:
  /// **'Xong! Thiết bị đã vào \"{ssid}\".'**
  String wifiDone(String ssid);

  /// Chi tiết khi xong; bỏ phần "đã nhớ…" nếu mạng mở (đổi 2026-11-28.12)
  ///
  /// In vi, this message translates to:
  /// **'IP {ip} · đã nhớ mật khẩu \"{ssid}\".'**
  String wifiDoneDetail(String ip, String ssid);

  /// Nút
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get wifiDoneButton;

  /// Trạng thái, coral
  ///
  /// In vi, this message translates to:
  /// **'Chưa xong'**
  String get wifiFailed;

  /// Chi tiết lỗi (đổi 2026-11-28.12, R-WF-5)
  ///
  /// In vi, this message translates to:
  /// **'Chưa thấy thiết bị trên \"{ssid}\". Sai mật khẩu, mạng chỉ có 5 GHz, hoặc mạng phải đăng nhập web — khi đó thiết bị sẽ lại hiện mã QR. Mật khẩu vừa gửi không được nhớ.'**
  String wifiNotFound(String ssid);

  /// Lỗi: thiết bị trả 401
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị yêu cầu API token.'**
  String get devErrUnauthorized;

  /// Lỗi: thiết bị trả mã HTTP
  ///
  /// In vi, this message translates to:
  /// **'Lỗi HTTP {status}'**
  String devErrHttp(int status);

  /// Lỗi: thiết bị không trả lời
  ///
  /// In vi, this message translates to:
  /// **'Không kết nối được thiết bị ({error})'**
  String devErrUnreachable(String error);

  /// Lỗi: thiết bị từ chối ảnh nạp
  ///
  /// In vi, this message translates to:
  /// **'Nạp thất bại: {detail}'**
  String devErrFlashFailed(String detail);

  /// Lỗi: GitHub 403
  ///
  /// In vi, this message translates to:
  /// **'GitHub đang giới hạn lượt gọi, thử lại sau ít phút.'**
  String get devErrRateLimited;

  /// Lỗi: GitHub releases
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được bản phát hành (HTTP {status}).'**
  String devErrReleaseHttp(int status);

  /// Lỗi: tải tệp nạp
  ///
  /// In vi, this message translates to:
  /// **'Tải thất bại (HTTP {status}).'**
  String devErrDownload(int status);

  /// Lỗi: thiếu tệp trong bản phát hành
  ///
  /// In vi, this message translates to:
  /// **'bản phát hành không có {name}'**
  String devErrNoAsset(String name);

  /// Lỗi: thiếu quyền Wi-Fi
  ///
  /// In vi, this message translates to:
  /// **'Cần quyền vị trí / thiết bị Wi-Fi lân cận để vào glimmer-setup.'**
  String get devErrWifiPermission;

  /// Lỗi: không vào được AP cài đặt
  ///
  /// In vi, this message translates to:
  /// **'Không vào được glimmer-setup. Thiết bị có đang hiện màn cài đặt Wi-Fi không?'**
  String get devErrSetupAp;

  /// Lỗi: mã QR vừa quét không phải mã trên màn cài đặt của thiết bị (R-WF-4)
  ///
  /// In vi, this message translates to:
  /// **'Đây không phải mã của glimmer. Quét mã trên màn cài đặt Wi-Fi của thiết bị.'**
  String get devErrNotGlimmerQr;

  /// Lỗi: cập nhật đầy đủ
  ///
  /// In vi, this message translates to:
  /// **'thiết bị không trả lời sau khi nạp firmware'**
  String get devErrNoAnswerAfterFlash;

  /// Lỗi: cập nhật đầy đủ
  ///
  /// In vi, this message translates to:
  /// **'không đọc được cấu hình để sao lưu'**
  String get devErrConfigUnreadable;

  /// Lỗi: tệp khôi phục
  ///
  /// In vi, this message translates to:
  /// **'Tệp không hợp lệ: không phải tệp cấu hình glimmer'**
  String get devErrInvalidBackup;

  /// Tổng quan: thẻ cần token
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị có API token — nhập token trong Cài đặt để xem thẻ.'**
  String get devCardsNeedToken;

  /// Đếm ngược đã tới (R-DUNG-3)
  ///
  /// In vi, this message translates to:
  /// **'ngay'**
  String get devNow;

  /// Cài đặt: nhãn thanh trượt
  ///
  /// In vi, this message translates to:
  /// **'{title}: {value}%'**
  String devSliderValue(String title, int value);

  /// Thiết bị: dòng Wi-Fi
  ///
  /// In vi, this message translates to:
  /// **'{ssid} ({rssi} dBm)'**
  String devWifiRssi(String ssid, int rssi);

  /// Thiết bị: chữ kèm khi chia sẻ tệp sao lưu
  ///
  /// In vi, this message translates to:
  /// **'Cấu hình glimmer'**
  String get devBackupShareText;

  /// Thiết bị: thông báo
  ///
  /// In vi, this message translates to:
  /// **'Sao lưu lỗi: {error}'**
  String devBackupFailed(String error);

  /// Thiết bị: bước khôi phục
  ///
  /// In vi, this message translates to:
  /// **'Vào Wi-Fi glimmer-setup để khôi phục…'**
  String get devStepJoinApRestore;

  /// Thiết bị: bước chờ
  ///
  /// In vi, this message translates to:
  /// **'Chờ thiết bị khởi động lại…'**
  String get devStepWaitReboot;

  /// Thiết bị: bước cập nhật đầy đủ
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị chuyển sang glimmer-setup…'**
  String get devStepToSetupAp;

  /// Thiết bị: bước khởi động lại
  ///
  /// In vi, this message translates to:
  /// **'Đang khởi động lại…'**
  String get devStepRebootingShort;

  /// Thiết bị: thông báo
  ///
  /// In vi, this message translates to:
  /// **'Đã khôi phục cấu hình'**
  String get devRestoreDone;

  /// Thiết bị: thông báo
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi cấu hình; chưa thấy thiết bị trên mạng'**
  String get devRestoreSentNotFound;

  /// Thiết bị: thông báo
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục lỗi: {error}'**
  String devRestoreFailed(String error);

  /// Thiết bị: thông báo
  ///
  /// In vi, this message translates to:
  /// **'Chưa khôi phục được. Bản sao lưu: {path}'**
  String devRestoreLater(String path);

  /// Thiết bị: thông báo
  ///
  /// In vi, this message translates to:
  /// **'Đã nạp; chưa thấy thiết bị trả lời'**
  String get devUpdateNoAnswer;

  /// Thiết bị: thông báo
  ///
  /// In vi, this message translates to:
  /// **'Xong — firmware {fw}'**
  String devUpdateDone(String fw);

  /// Thiết bị: thông báo
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật lỗi: {error}'**
  String devUpdateFailed(String error);

  /// Lỗi: firmware cũ không đổi được skill (R-SK-4)
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị chưa hỗ trợ skill này — cập nhật firmware.'**
  String get devErrSkillUnsupported;

  /// Tab 2 của thanh dưới
  ///
  /// In vi, this message translates to:
  /// **'Skill'**
  String get navSkills;

  /// Tên skill; cũng là nhãn tab 1 khi Agent đang dùng
  ///
  /// In vi, this message translates to:
  /// **'Agent'**
  String get skillAgentName;

  /// Mô tả dòng skill (một dòng)
  ///
  /// In vi, this message translates to:
  /// **'Mức dùng và thẻ duyệt'**
  String get skillAgentDesc;

  /// Không dùng từ 2026-11-25.3 — Kênh thiết bị của skill Agent
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ · Danh sách agent · Claude · Codex · AI · Xu hướng'**
  String get skillAgentChannels;

  /// Tên skill (sắp có)
  ///
  /// In vi, this message translates to:
  /// **'Nhạc'**
  String get skillMusicName;

  /// Không dùng từ 2026-11-25.3 — Mô tả ô skill
  ///
  /// In vi, this message translates to:
  /// **'Bài đang phát và điều khiển nhạc.'**
  String get skillMusicDesc;

  /// Tên skill (sắp có)
  ///
  /// In vi, this message translates to:
  /// **'Mạng xã hội'**
  String get skillSocialName;

  /// Không dùng từ 2026-11-25.3 — Mô tả ô skill
  ///
  /// In vi, this message translates to:
  /// **'Thông báo và số liệu mạng xã hội.'**
  String get skillSocialDesc;

  /// Tên skill (sắp có)
  ///
  /// In vi, this message translates to:
  /// **'Giải trí'**
  String get skillFunName;

  /// Mô tả hàng Giải trí ở màn Skill (đổi 2026-11-28.13)
  ///
  /// In vi, this message translates to:
  /// **'Dò mìn, chơi bằng app'**
  String get skillFunDesc;

  /// Tiêu đề màn Skill
  ///
  /// In vi, this message translates to:
  /// **'Skill'**
  String get skillsTitle;

  /// Dòng phụ dưới tiêu đề màn Skill (đổi 2026-11-28.14)
  ///
  /// In vi, this message translates to:
  /// **'Mỗi skill bật là một chương trình trên máy.'**
  String get skillsSubtitle;

  /// Không dùng từ 2026-11-25.3 — Nhãn ô skill đang dùng
  ///
  /// In vi, this message translates to:
  /// **'Đang dùng'**
  String get skillsCurrent;

  /// Không dùng từ 2026-11-25.3 — Nhãn đọc màn hình của ô đang dùng
  ///
  /// In vi, this message translates to:
  /// **'{skill} — đang dùng, mở màn chính'**
  String skillsCurrentA11y(String skill);

  /// Nhãn ô skill chưa có gói
  ///
  /// In vi, this message translates to:
  /// **'Sắp có'**
  String get skillsSoon;

  /// Không dùng từ 2026-11-25.3 — Nhãn ô skill chọn được
  ///
  /// In vi, this message translates to:
  /// **'Dùng skill này'**
  String get skillsUse;

  /// Không dùng từ 2026-11-25.3 — Nhãn ô skill đang đổi
  ///
  /// In vi, this message translates to:
  /// **'Đang đổi…'**
  String get skillsSwitching;

  /// Không dùng từ 2026-11-25.3 — Thanh báo khi đang đổi
  ///
  /// In vi, this message translates to:
  /// **'Đang chuyển màn thiết bị sang {skill}…'**
  String skillsSwitchingBanner(String skill);

  /// Không dùng từ 2026-11-25.3 — Dòng phụ thanh báo đang đổi
  ///
  /// In vi, this message translates to:
  /// **'Chờ thiết bị nhận, vài giây.'**
  String get skillsSwitchingHint;

  /// Không dùng từ 2026-11-25.3 — Thanh báo lỗi, coral
  ///
  /// In vi, this message translates to:
  /// **'Chưa đổi được skill'**
  String get skillsErrorTitle;

  /// Không dùng từ 2026-11-25.3 — skill = skill đang dùng
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không trả lời. Màn thiết bị vẫn là {skill}.'**
  String skillsErrorBody(String skill);

  /// Thanh báo firmware cũ, amber
  ///
  /// In vi, this message translates to:
  /// **'Firmware chưa có dock'**
  String get skillsLegacyTitle;

  /// fw = phiên bản firmware
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị đang chạy {fw} — chỉ có skill Agent, không bật / tắt được. Cập nhật firmware để dùng dock.'**
  String skillsLegacyBody(String fw);

  /// Không dùng từ 2026-11-25.3 — Nhãn thẻ kênh
  ///
  /// In vi, this message translates to:
  /// **'MÀN THIẾT BỊ ĐANG XOAY'**
  String get skillsChannelsTitle;

  /// Không dùng từ 2026-11-25.3 — Kênh hệ thống (R-SK-2)
  ///
  /// In vi, this message translates to:
  /// **'+ luôn có: Đồng hồ · Thời tiết · Dự báo · Thông tin · Ban đêm'**
  String get skillsChannelsSystem;

  /// Không dùng từ 2026-11-25.3 — R-SK-3
  ///
  /// In vi, this message translates to:
  /// **'Thẻ cần duyệt / chờ trả lời của agent vẫn chen ngang ở mọi skill.'**
  String get skillsAttentionNote;

  /// Không dùng từ 2026-11-26.5 (thay bằng navControl). Tab 1 thanh dưới (2026-11-25.3), mọi skill
  ///
  /// In vi, this message translates to:
  /// **'Màn hình'**
  String get navHome;

  /// Đọc màn hình cho huy hiệu tab 1 / tab Agent
  ///
  /// In vi, this message translates to:
  /// **'{count} agent đang chờ'**
  String navHomeBadgeA11y(String count);

  /// Nhãn thanh tab dock
  ///
  /// In vi, this message translates to:
  /// **'Tab của Màn hình'**
  String get homeTabsA11y;

  /// Nút cuối mỗi tab Màn hình
  ///
  /// In vi, this message translates to:
  /// **'Hiện {skill} trên thiết bị'**
  String homeShowOnDevice(String skill);

  /// Tên skill / tab dock
  ///
  /// In vi, this message translates to:
  /// **'Thời tiết'**
  String get skillWeatherName;

  /// Mô tả dòng skill
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay và 3 ngày tới'**
  String get skillWeatherDesc;

  /// Tên skill / tab dock
  ///
  /// In vi, this message translates to:
  /// **'Đồng hồ'**
  String get skillClockName;

  /// Mô tả dòng skill
  ///
  /// In vi, this message translates to:
  /// **'Giờ, ngày, giờ ban đêm'**
  String get skillClockDesc;

  /// Tên skill (sắp có)
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn'**
  String get skillChatName;

  /// Nhãn công tắc
  ///
  /// In vi, this message translates to:
  /// **'Bật / tắt skill {skill}'**
  String skillsToggleA11y(String skill);

  /// Mô tả dòng skill khi đang gửi
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi thiết bị…'**
  String get skillsSending;

  /// Thanh báo lỗi, coral
  ///
  /// In vi, this message translates to:
  /// **'Chưa tắt được {skill}'**
  String skillsErrorOffTitle(String skill);

  /// Thanh báo lỗi, coral
  ///
  /// In vi, this message translates to:
  /// **'Chưa bật được {skill}'**
  String skillsErrorOnTitle(String skill);

  /// Thân thanh báo lỗi
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không trả lời. {skill} vẫn bật trên thiết bị.'**
  String skillsErrorOffBody(String skill);

  /// Thân thanh báo lỗi
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không trả lời. {skill} vẫn tắt trên thiết bị.'**
  String skillsErrorOnBody(String skill);

  /// Thay mô tả dòng skill bật duy nhất, amber
  ///
  /// In vi, this message translates to:
  /// **'Cần ít nhất một skill bật'**
  String get skillsLastOne;

  /// Mô tả Thời tiết / Đồng hồ khi firmware cũ
  ///
  /// In vi, this message translates to:
  /// **'Luôn có (firmware cũ)'**
  String get skillsAlwaysOn;

  /// Ghi chú dưới danh sách skill (đổi 2026-11-28.14: thiết bị không còn xoay tab / dock)
  ///
  /// In vi, this message translates to:
  /// **'Mỗi skill bật thêm chương trình vào desktop và Start của thiết bị. Thẻ cần duyệt vẫn chen ngang mọi màn.'**
  String get skillsOrderNote;

  /// Nhãn nhóm chip sắp có
  ///
  /// In vi, this message translates to:
  /// **'SẮP CÓ'**
  String get skillsSoonTitle;

  /// Nhãn thẻ tab Thời tiết
  ///
  /// In vi, this message translates to:
  /// **'THỜI TIẾT'**
  String get weatherTitle;

  /// Meta thẻ thời tiết; place = tên nơi (bỏ "place ·" nếu thiết bị không có)
  ///
  /// In vi, this message translates to:
  /// **'{place} · {age} trước'**
  String weatherMeta(String place, String age);

  /// Nhiệt cao / thấp hôm nay
  ///
  /// In vi, this message translates to:
  /// **'cao {hi}° · thấp {lo}°'**
  String weatherHiLo(String hi, String lo);

  /// Nhiệt cảm giác
  ///
  /// In vi, this message translates to:
  /// **'cảm giác {t}°'**
  String weatherFeels(String t);

  /// Dòng dự báo ngày mai (như kênh Weather)
  ///
  /// In vi, this message translates to:
  /// **'MAI'**
  String get weatherDayTomorrow;

  /// Dòng dự báo ngày kia; ngày sau dùng thứ T2…CN
  ///
  /// In vi, this message translates to:
  /// **'KIA'**
  String get weatherDayAfter;

  /// Meta amber khi thiếu vị trí
  ///
  /// In vi, this message translates to:
  /// **'chưa có vị trí'**
  String get weatherNoLocationMeta;

  /// Tiêu đề trạng thái thiếu vị trí
  ///
  /// In vi, this message translates to:
  /// **'Chưa đặt vị trí'**
  String get weatherNoLocationTitle;

  /// Thân trạng thái thiếu vị trí
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị cần vĩ độ / kinh độ để lấy thời tiết và dự báo.'**
  String get weatherNoLocationBody;

  /// Nút ở tab Thời tiết khi chưa đặt vị trí → màn Vị trí thời tiết (đổi 2026-11-26.9)
  ///
  /// In vi, this message translates to:
  /// **'Đặt vị trí thời tiết'**
  String get weatherSetLocation;

  /// Nhãn thẻ tab Đồng hồ
  ///
  /// In vi, this message translates to:
  /// **'ĐỒNG HỒ'**
  String get clockTitle;

  /// Dòng ngày dưới giờ, viết hoa thứ
  ///
  /// In vi, this message translates to:
  /// **'{weekday} {date} · tuần {week}'**
  String clockDate(String weekday, String date, String week);

  /// Nhãn dòng
  ///
  /// In vi, this message translates to:
  /// **'Múi giờ'**
  String get clockTz;

  /// Nhãn dòng
  ///
  /// In vi, this message translates to:
  /// **'Kiểu giờ'**
  String get clockFormat;

  /// Giá trị kiểu giờ
  ///
  /// In vi, this message translates to:
  /// **'24 giờ'**
  String get clockFormat24;

  /// Giá trị kiểu giờ
  ///
  /// In vi, this message translates to:
  /// **'12 giờ'**
  String get clockFormat12;

  /// Nhãn dòng
  ///
  /// In vi, this message translates to:
  /// **'Ban đêm'**
  String get clockNight;

  /// mode = làm tối / chỉ đồng hồ / tắt màn
  ///
  /// In vi, this message translates to:
  /// **'{start} – {end} · {mode}'**
  String clockNightValue(String start, String end, String mode);

  /// Màn hình · dòng dự báo: thứ (day = DateTime.weekday, 1 = thứ Hai)
  ///
  /// In vi, this message translates to:
  /// **'{day, select, 1{T2} 2{T3} 3{T4} 4{T5} 5{T6} 6{T7} other{CN}}'**
  String devWeekdayShort(String day);

  /// Màn hình · tab Đồng hồ: thứ trong clockDate (day = DateTime.weekday)
  ///
  /// In vi, this message translates to:
  /// **'{day, select, 1{THỨ HAI} 2{THỨ BA} 3{THỨ TƯ} 4{THỨ NĂM} 5{THỨ SÁU} 6{THỨ BẢY} other{CHỦ NHẬT}}'**
  String devWeekdayLong(String day);

  /// clockNightValue mode: nightMode 1
  ///
  /// In vi, this message translates to:
  /// **'làm tối'**
  String get devClockNightDim;

  /// clockNightValue mode: nightMode 2
  ///
  /// In vi, this message translates to:
  /// **'chỉ đồng hồ'**
  String get devClockNightClock;

  /// clockNightValue mode: nightMode 3
  ///
  /// In vi, this message translates to:
  /// **'tắt màn'**
  String get devClockNightOff;

  /// Tab Đồng hồ, kiểu 12 giờ: sáng (như ClockFmt firmware)
  ///
  /// In vi, this message translates to:
  /// **'SA'**
  String get devClockAm;

  /// Tab Đồng hồ, kiểu 12 giờ: chiều
  ///
  /// In vi, this message translates to:
  /// **'CH'**
  String get devClockPm;

  /// Meta thẻ thời tiết khi thiết bị có vị trí nhưng chưa tải được lần nào
  ///
  /// In vi, this message translates to:
  /// **'chưa có số liệu'**
  String get devWeatherNoData;

  /// Snackbar sau ShowOnDeviceButton
  ///
  /// In vi, this message translates to:
  /// **'Đã chuyển sang màn {skill}'**
  String devShowOnDeviceDone(String skill);

  /// Tên skill / tab dock Ảnh
  ///
  /// In vi, this message translates to:
  /// **'Ảnh'**
  String get skillPhotoName;

  /// Mô tả dòng skill Ảnh
  ///
  /// In vi, this message translates to:
  /// **'Ảnh của bạn, gửi từ điện thoại'**
  String get skillPhotoDesc;

  /// Thay mô tả dòng Ảnh khi skill tắt mà thiết bị có ảnh, màu mint
  ///
  /// In vi, this message translates to:
  /// **'{count} ảnh đã có trên thiết bị. Bật để xoay.'**
  String skillsPhotoHint(int count);

  /// Mô tả dòng skill khi firmware chưa có skill đó, amber
  ///
  /// In vi, this message translates to:
  /// **'Cần firmware mới'**
  String get skillsNeedFirmware;

  /// Nút nhỏ trên dòng skill cần firmware → tab Thiết bị
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật'**
  String get skillsUpdateFirmware;

  /// Nhãn thẻ tab Ảnh
  ///
  /// In vi, this message translates to:
  /// **'ẢNH TRÊN THIẾT BỊ'**
  String get photoOnDevice;

  /// Meta thẻ tab Ảnh
  ///
  /// In vi, this message translates to:
  /// **'{count}/{max} · còn {free} chỗ'**
  String photoCount(int count, int max, int free);

  /// Meta thẻ tab Ảnh khi đủ, amber
  ///
  /// In vi, this message translates to:
  /// **'{max}/{max} · hết chỗ'**
  String photoCountFull(int max);

  /// Meta thẻ tab Ảnh khi chưa có ảnh
  ///
  /// In vi, this message translates to:
  /// **'0/{max}'**
  String photoCountEmpty(int max);

  /// Ô cuối lưới, nút ở trạng thái chưa có ảnh, tiêu đề bảng chọn nguồn
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh'**
  String get photoAdd;

  /// Ô thêm ảnh khi đã đủ (khoá)
  ///
  /// In vi, this message translates to:
  /// **'Đủ {max} ảnh'**
  String photoFullTile(int max);

  /// Dòng dưới lưới khi đủ ảnh
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị giữ tối đa {max} ảnh. Xoá bớt một ảnh để thêm ảnh mới.'**
  String photoFullBody(int max);

  /// Nhãn đọc màn hình của ô ảnh
  ///
  /// In vi, this message translates to:
  /// **'Ảnh {index}, bấm để xoá'**
  String photoTileA11y(int index);

  /// Nhãn đọc màn hình ô ảnh không có bản xem
  ///
  /// In vi, this message translates to:
  /// **'Ảnh {name}, gửi từ nơi khác, bấm để xoá'**
  String photoUnknownA11y(String name);

  /// Dòng nhỏ trong ô ảnh app không giữ bản sao
  ///
  /// In vi, this message translates to:
  /// **'không có bản xem'**
  String get photoNoPreview;

  /// Chú thích dưới thẻ tab Ảnh
  ///
  /// In vi, this message translates to:
  /// **'Bấm vào ảnh để xoá. Cập nhật đầy đủ ở tab Thiết bị sẽ xoá hết ảnh trên thiết bị.'**
  String get photoNote;

  /// Tab Ảnh chưa có ảnh
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh'**
  String get photoEmptyTitle;

  /// Tab Ảnh chưa có ảnh
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh trong máy, cắt vuông rồi gửi lên. Thiết bị xoay từng ảnh, tối đa {max} ảnh.'**
  String photoEmptyBody(int max);

  /// Dòng phụ bảng chọn nguồn ảnh
  ///
  /// In vi, this message translates to:
  /// **'Ảnh sẽ được cắt vuông 188 × 188 trước khi gửi.'**
  String get photoAddHint;

  /// Bảng chọn nguồn ảnh
  ///
  /// In vi, this message translates to:
  /// **'Chọn trong thư viện'**
  String get photoFromGallery;

  /// Bảng chọn nguồn ảnh
  ///
  /// In vi, this message translates to:
  /// **'Chụp ảnh'**
  String get photoFromCamera;

  /// Hộp thoại xoá ảnh
  ///
  /// In vi, this message translates to:
  /// **'Xoá ảnh này?'**
  String get photoDeleteTitle;

  /// Hộp thoại xoá ảnh
  ///
  /// In vi, this message translates to:
  /// **'Ảnh bị xoá khỏi thiết bị, không lấy lại được.'**
  String get photoDeleteBody;

  /// Nút xoá (coral) trong hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get photoDelete;

  /// Lớp phủ trên ô ảnh đang xoá
  ///
  /// In vi, this message translates to:
  /// **'Đang xoá'**
  String get photoDeleting;

  /// Thanh báo xoá lỗi
  ///
  /// In vi, this message translates to:
  /// **'Chưa xoá được ảnh'**
  String get photoDeleteErrorTitle;

  /// Thanh báo xoá lỗi
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không trả lời. Ảnh vẫn còn trên thiết bị.'**
  String get photoDeleteErrorBody;

  /// Tiêu đề màn cắt ảnh
  ///
  /// In vi, this message translates to:
  /// **'Cắt ảnh'**
  String get photoCropTitle;

  /// Nhãn đọc màn hình vùng cắt
  ///
  /// In vi, this message translates to:
  /// **'Vùng cắt, kéo để dời, chụm để phóng'**
  String get photoCropAreaA11y;

  /// Dòng hướng dẫn dưới vùng cắt
  ///
  /// In vi, this message translates to:
  /// **'Kéo để dời · chụm hai ngón để phóng'**
  String get photoCropHint;

  /// Nhãn phần xem trước
  ///
  /// In vi, this message translates to:
  /// **'XEM TRƯỚC TRÊN THIẾT BỊ'**
  String get photoCropPreview;

  /// Cạnh ô xem trước
  ///
  /// In vi, this message translates to:
  /// **'Ảnh 188 × 188, đúng như màn thiết bị hiện.'**
  String get photoCropPreviewBody;

  /// Cạnh ô xem trước, muted
  ///
  /// In vi, this message translates to:
  /// **'App tự thu nhỏ và nén dưới 40 KB trước khi gửi.'**
  String get photoCropPreviewNote;

  /// Nút phụ màn cắt ảnh
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh khác'**
  String get photoCropPickOther;

  /// Nút chính màn cắt ảnh
  ///
  /// In vi, this message translates to:
  /// **'Gửi ảnh'**
  String get photoCropSend;

  /// Thẻ tiến độ khi gửi
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi ảnh…'**
  String get photoCropSending;

  /// Thẻ tiến độ khi gửi
  ///
  /// In vi, this message translates to:
  /// **'Giữ app mở tới khi xong.'**
  String get photoCropKeepOpen;

  /// Thẻ gửi xong
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi lên thiết bị'**
  String get photoCropDoneTitle;

  /// Thẻ gửi xong
  ///
  /// In vi, this message translates to:
  /// **'Ảnh {count}/{max}. Thiết bị hiện ảnh này ở lượt xoay tới.'**
  String photoCropDoneBody(int count, int max);

  /// Nút phụ khi gửi xong
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh khác'**
  String get photoCropAddAnother;

  /// Nút chính khi gửi xong → tab Ảnh
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get photoCropDone;

  /// Nút khi lỗi đủ ảnh / hết chỗ → tab Ảnh
  ///
  /// In vi, this message translates to:
  /// **'Về danh sách ảnh'**
  String get photoCropBackToList;

  /// Nút chính khi ảnh quá lớn
  ///
  /// In vi, this message translates to:
  /// **'Cắt lại'**
  String get photoCropRecrop;

  /// Lỗi full
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị đã đủ {max} ảnh'**
  String photoCropErrorFullTitle(int max);

  /// Lỗi full
  ///
  /// In vi, this message translates to:
  /// **'Xoá bớt một ảnh rồi gửi lại. Vùng cắt này được giữ.'**
  String get photoCropErrorFullBody;

  /// Lỗi too_big sau khi app đã tự giảm chất lượng
  ///
  /// In vi, this message translates to:
  /// **'Ảnh vẫn quá lớn'**
  String get photoCropErrorTooBigTitle;

  /// Lỗi too_big
  ///
  /// In vi, this message translates to:
  /// **'Đã giảm chất lượng mà ảnh vẫn trên 40 KB. Chọn vùng ít chi tiết hơn, hoặc ảnh khác.'**
  String get photoCropErrorTooBigBody;

  /// Lỗi no_space
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị hết chỗ lưu'**
  String get photoCropErrorNoSpaceTitle;

  /// Lỗi no_space
  ///
  /// In vi, this message translates to:
  /// **'Bộ nhớ thiết bị gần đầy. Xoá bớt ảnh rồi thử lại.'**
  String get photoCropErrorNoSpaceBody;

  /// Lỗi not_jpeg / progressive / bad_size / truncated / empty
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không nhận ảnh'**
  String get photoCropErrorRejectedTitle;

  /// Lỗi thiết bị từ chối ảnh
  ///
  /// In vi, this message translates to:
  /// **'Ảnh app tạo ra bị lỗi. Thử lại; nếu vẫn lỗi, hãy báo lỗi app.'**
  String get photoCropErrorRejectedBody;

  /// Lỗi mạng khi gửi
  ///
  /// In vi, this message translates to:
  /// **'Mất kết nối với thiết bị'**
  String get photoCropErrorOfflineTitle;

  /// Lỗi mạng khi gửi
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra thiết bị còn bật và cùng mạng Wi-Fi với điện thoại.'**
  String get photoCropErrorOfflineBody;

  /// PhotoCrop: điện thoại không giải mã được ảnh vừa chọn (thiết kế chưa vẽ)
  ///
  /// In vi, this message translates to:
  /// **'Không mở được ảnh này'**
  String get devPhotoUnreadableTitle;

  /// PhotoCrop: nội dung thanh báo ảnh không mở được
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh khác (JPEG, PNG hoặc HEIC).'**
  String get devPhotoUnreadableBody;

  /// Tab Ảnh: GET /api/photos lỗi (thiết kế chưa vẽ)
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được danh sách ảnh'**
  String get devPhotoLoadErrorTitle;

  /// Tab 1 thanh dưới
  ///
  /// In vi, this message translates to:
  /// **'Điều khiển'**
  String get navControl;

  /// Nút icon refresh đầu màn Điều khiển
  ///
  /// In vi, this message translates to:
  /// **'Làm mới số liệu'**
  String get controlRefreshA11y;

  /// Không dùng từ 2026-11-27.10. Nhãn đọc màn hình ô màn chạm được
  ///
  /// In vi, this message translates to:
  /// **'Màn thiết bị đang hiện {app}. Chạm như chuột: nút cửa sổ, thanh tác vụ, start, biểu tượng'**
  String controlScreenA11y(String app);

  /// Không dùng từ 2026-11-26.6. Dòng kênh dưới ô màn
  ///
  /// In vi, this message translates to:
  /// **'· đổi kênh sau {seconds} s'**
  String controlNextIn(int seconds);

  /// Không dùng từ 2026-11-26.6. Dòng kênh ngay sau khi đổi
  ///
  /// In vi, this message translates to:
  /// **'· vừa chuyển'**
  String get controlJustSwitched;

  /// Không dùng từ 2026-11-26.6. Dòng kênh khi dừng xoay, amber
  ///
  /// In vi, this message translates to:
  /// **'· đã dừng xoay, giữ kênh này'**
  String get controlPausedNote;

  /// Không dùng từ 2026-11-27.10. Dòng kênh khi màn tắt
  ///
  /// In vi, this message translates to:
  /// **'Màn đang tắt'**
  String get controlScreenOffTitle;

  /// Không dùng từ 2026-11-27.10. Dòng kênh khi màn tắt
  ///
  /// In vi, this message translates to:
  /// **'· bấm Bật màn để mở lại'**
  String get controlScreenOffNote;

  /// Không dùng từ 2026-11-27.10. Chữ mờ giữa ô màn tối
  ///
  /// In vi, this message translates to:
  /// **'MÀN ĐANG TẮT'**
  String get controlScreenOffOverlay;

  /// Dòng kênh khi đêm
  ///
  /// In vi, this message translates to:
  /// **'Chế độ đêm'**
  String get controlNightTitle;

  /// Dòng kênh khi đêm
  ///
  /// In vi, this message translates to:
  /// **'· tới {time}, không xoay kênh'**
  String controlNightNote(String time);

  /// Không dùng từ 2026-11-26.6. Nút d-pad trái
  ///
  /// In vi, this message translates to:
  /// **'Kênh trước'**
  String get controlPrev;

  /// Không dùng từ 2026-11-26.6. Nút d-pad phải
  ///
  /// In vi, this message translates to:
  /// **'Kênh sau'**
  String get controlNext;

  /// Không dùng từ 2026-11-26.6. Nút d-pad giữa
  ///
  /// In vi, this message translates to:
  /// **'Dừng xoay'**
  String get controlPause;

  /// Không dùng từ 2026-11-26.6. Nút d-pad giữa khi đang dừng (amber)
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục xoay'**
  String get controlResume;

  /// Không dùng từ 2026-11-26.6. Nhóm nút tab skill
  ///
  /// In vi, this message translates to:
  /// **'Nhảy tới tab'**
  String get controlJumpGroupA11y;

  /// Không dùng từ 2026-11-26.6. Nhãn đọc màn hình nút tab skill
  ///
  /// In vi, this message translates to:
  /// **'Hiện {skill} trên thiết bị'**
  String controlJumpA11y(String skill);

  /// Nhãn đọc màn hình thanh trượt
  ///
  /// In vi, this message translates to:
  /// **'Độ sáng'**
  String get controlBrightness;

  /// Không dùng từ 2026-11-27.10. Nút tròn
  ///
  /// In vi, this message translates to:
  /// **'Tắt màn'**
  String get controlScreenOff;

  /// Không dùng từ 2026-11-27.10. Nút tròn khi màn đang tắt (amber)
  ///
  /// In vi, this message translates to:
  /// **'Bật màn'**
  String get controlScreenOn;

  /// Không dùng từ 2026-11-27.10. Nút tròn (lilac khi bật)
  ///
  /// In vi, this message translates to:
  /// **'Chế độ đêm'**
  String get controlNight;

  /// Không dùng từ 2026-11-27.10. Nút tròn → màn Số liệu
  ///
  /// In vi, this message translates to:
  /// **'Số liệu'**
  String get controlDetails;

  /// Không dùng từ 2026-11-26.7. Chip trên ô màn khi lệnh đang gửi
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi…'**
  String get controlSending;

  /// Thanh báo nổi; command = tên nút
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không nhận lệnh \"{command}\".'**
  String controlFailed(String command);

  /// Thẻ dưới ô màn khi thẻ agent giữ màn
  ///
  /// In vi, this message translates to:
  /// **'THẺ AGENT ĐANG CHIẾM MÀN'**
  String get controlCardLabel;

  /// Thẻ giữ màn (approval); input → controlCardBodyInput
  ///
  /// In vi, this message translates to:
  /// **'{agent} · {project} cần bạn duyệt {tool}'**
  String controlCardBody(String agent, String project, String tool);

  /// Thẻ giữ màn (input)
  ///
  /// In vi, this message translates to:
  /// **'{agent} · {project} đang chờ bạn trả lời'**
  String controlCardBodyInput(String agent, String project);

  /// Thẻ giữ màn
  ///
  /// In vi, this message translates to:
  /// **'Duyệt trên máy tính. Bỏ thẻ chỉ gỡ nó khỏi màn thiết bị.'**
  String get controlCardNote;

  /// Nút viền trong thẻ giữ màn
  ///
  /// In vi, this message translates to:
  /// **'Bỏ thẻ khỏi màn'**
  String get controlDismissCard;

  /// Không dùng từ 2026-11-26.6. Thay hàng nút tab khi một skill bật
  ///
  /// In vi, this message translates to:
  /// **'Chỉ skill {skill} đang bật — ‹ › đi qua các kênh của skill này và Thông tin.'**
  String controlSingleNote(String skill);

  /// Thanh báo firmware cũ
  ///
  /// In vi, this message translates to:
  /// **'Firmware chưa có chuột'**
  String get controlOldFwTitle;

  /// Thanh báo firmware cũ
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị đang chạy {version}: chưa nhận chuột, phím và nút nguồn từ app.'**
  String controlOldFwBody(String version);

  /// Nút trong thanh báo → tab Thiết bị
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật firmware'**
  String get controlUpdateFirmware;

  /// Thanh báo
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị đang ở glimmer-setup'**
  String get controlSetupTitle;

  /// Thanh báo
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị chưa vào được Wi-Fi nên chưa điều khiển được.'**
  String get controlSetupBody;

  /// Nút chữ trên thanh báo glimmer-setup ở Điều khiển → màn Quét mã (đổi 2026-11-28.12, icon qr 18)
  ///
  /// In vi, this message translates to:
  /// **'Quét mã trên màn'**
  String get controlSetupAction;

  /// Thanh báo coral
  ///
  /// In vi, this message translates to:
  /// **'Không thấy thiết bị'**
  String get controlOfflineTitle;

  /// Thanh báo coral
  ///
  /// In vi, this message translates to:
  /// **'Không trả lời ở {ip} từ {ago} trước.'**
  String controlOfflineBody(String ip, String ago);

  /// Phủ trên ô màn
  ///
  /// In vi, this message translates to:
  /// **'Mất kết nối'**
  String get controlOfflineOverlay;

  /// Phủ trên ô màn
  ///
  /// In vi, this message translates to:
  /// **'hình cuối cùng app nhận được'**
  String get controlOfflineOverlayNote;

  /// Tiêu đề màn Số liệu (màn phụ)
  ///
  /// In vi, this message translates to:
  /// **'Số liệu'**
  String get detailsTitle;

  /// Nút quay lại màn Số liệu
  ///
  /// In vi, this message translates to:
  /// **'Về Điều khiển'**
  String get detailsBackA11y;

  /// Lỗi: nút điều khiển firmware chưa có (R-DK-3)
  ///
  /// In vi, this message translates to:
  /// **'Firmware chưa có lệnh này — cập nhật firmware.'**
  String get devErrControlUnsupported;

  /// Điều khiển · tên lệnh trong controlFailed khi mở chương trình không được
  ///
  /// In vi, this message translates to:
  /// **'Mở {app}'**
  String devControlCmdOpen(String app);

  /// Điều khiển · tên lệnh trong controlFailed khi Start → Desktop (thu nhỏ hết) không được
  ///
  /// In vi, this message translates to:
  /// **'Desktop'**
  String get devControlCmdDesktop;

  /// Điều khiển · tên lệnh trong controlFailed khi tắt app (×) không được
  ///
  /// In vi, this message translates to:
  /// **'Tắt {app}'**
  String devControlCmdClose(String app);

  /// Điều khiển · tên lệnh trong controlFailed khi thu nhỏ (_) không được
  ///
  /// In vi, this message translates to:
  /// **'Thu nhỏ {app}'**
  String devControlCmdMinimize(String app);

  /// Màn thiết bị · Ngày và Giờ (panel P-2026-11-26.22)
  ///
  /// In vi, this message translates to:
  /// **'{index, select, 0{Los Angeles} 1{New York} 2{Brasília} 3{London} 4{Paris, Berlin} 5{Moskva} 6{Dubai} 7{New Delhi} 8{Hà Nội} 9{Singapore} 10{Tokyo, Seoul} other{Sydney}}'**
  String devXpZoneName(String index);

  /// Không dùng từ 2026-11-26.7. Dòng dưới ô màn
  ///
  /// In vi, this message translates to:
  /// **'· đang mở trên thiết bị'**
  String get controlOpenOnDevice;

  /// Không dùng từ 2026-11-26.7. Dòng dưới ô màn sau khi chạm nút thanh tác vụ
  ///
  /// In vi, this message translates to:
  /// **'· vừa chạm trên thanh tác vụ'**
  String get controlJustOpened;

  /// Không dùng từ 2026-11-26.7. Tên màn chính trong dòng dưới ô màn
  ///
  /// In vi, this message translates to:
  /// **'Desktop'**
  String get controlDesktop;

  /// Không dùng từ 2026-11-26.7. Dòng dưới ô màn khi đang ở desktop sau thu nhỏ
  ///
  /// In vi, this message translates to:
  /// **'· {app} đã thu nhỏ'**
  String controlMinimizedNote(String app);

  /// Không dùng từ 2026-11-26.7. Dòng dưới ô màn khi vừa cài skill
  ///
  /// In vi, this message translates to:
  /// **'· {skill} vừa cài'**
  String controlInstalledNote(String skill);

  /// Không dùng từ 2026-11-26.7. Dòng dưới ô màn ở desktop
  ///
  /// In vi, this message translates to:
  /// **'· chạm biểu tượng để mở'**
  String get controlTapIconNote;

  /// Không dùng từ 2026-11-26.7. Chip trên ô màn khi vừa chạm _
  ///
  /// In vi, this message translates to:
  /// **'Thu nhỏ…'**
  String get controlMinimizing;

  /// Không dùng từ 2026-11-26.7. Chip khi vừa chạm ×
  ///
  /// In vi, this message translates to:
  /// **'Đang tắt {app}…'**
  String controlClosing(String app);

  /// Không dùng từ 2026-11-26.7. Chip khi vừa chạm nút thanh tác vụ
  ///
  /// In vi, this message translates to:
  /// **'Đang mở…'**
  String get controlOpening;

  /// Không dùng từ 2026-11-26.7. Chip khi vừa chạm biểu tượng desktop
  ///
  /// In vi, this message translates to:
  /// **'Đang mở {app}…'**
  String controlOpeningApp(String app);

  /// Không dùng từ 2026-11-26.7. Chip (dấu tích mint) khi vừa cài skill
  ///
  /// In vi, this message translates to:
  /// **'Đã cài {skill}'**
  String controlInstalled(String skill);

  /// Không dùng từ 2026-11-26.8. Thẻ hướng dẫn dưới ô màn
  ///
  /// In vi, this message translates to:
  /// **'CHẠM MÀN NHƯ DÙNG CHUỘT'**
  String get controlLegendTitle;

  /// Không dùng từ 2026-11-26.8. Thẻ hướng dẫn, ký hiệu _
  ///
  /// In vi, this message translates to:
  /// **'thu nhỏ'**
  String get controlLegendMin;

  /// Không dùng từ 2026-11-26.8. Thẻ hướng dẫn, ký hiệu □
  ///
  /// In vi, this message translates to:
  /// **'phóng to'**
  String get controlLegendMax;

  /// Không dùng từ 2026-11-26.8. Thẻ hướng dẫn, ký hiệu ×
  ///
  /// In vi, this message translates to:
  /// **'tắt app'**
  String get controlLegendClose;

  /// Không dùng từ 2026-11-26.8. Thẻ hướng dẫn, ký hiệu ▭
  ///
  /// In vi, this message translates to:
  /// **'nút dưới: đổi app'**
  String get controlLegendTaskbar;

  /// Không dùng từ 2026-11-26.8. Ký hiệu trong thẻ hướng dẫn
  ///
  /// In vi, this message translates to:
  /// **'start'**
  String get controlLegendStartKey;

  /// Không dùng từ 2026-11-26.8. Thẻ hướng dẫn
  ///
  /// In vi, this message translates to:
  /// **'mở Start'**
  String get controlLegendStart;

  /// Không dùng từ 2026-11-26.8. Ký hiệu trong thẻ hướng dẫn
  ///
  /// In vi, this message translates to:
  /// **'giữ'**
  String get controlLegendHoldKey;

  /// Không dùng từ 2026-11-26.8. Thẻ hướng dẫn
  ///
  /// In vi, this message translates to:
  /// **'chuột phải'**
  String get controlLegendHold;

  /// Không dùng từ 2026-11-27.10. Đầu Start menu, dưới "glimmer"
  ///
  /// In vi, this message translates to:
  /// **'Start · mở chương trình trên thiết bị'**
  String get startSubtitle;

  /// Không dùng từ 2026-11-27.10. Nhãn đọc màn hình nút / bảng Start
  ///
  /// In vi, this message translates to:
  /// **'Start'**
  String get startA11y;

  /// Không dùng từ 2026-11-27.10. Dòng phụ Claude trong Start
  ///
  /// In vi, this message translates to:
  /// **'mức dùng, project'**
  String get startClaudeSub;

  /// Không dùng từ 2026-11-27.10. Dòng phụ Codex trong Start
  ///
  /// In vi, this message translates to:
  /// **'mức dùng'**
  String get startCodexSub;

  /// Không dùng từ 2026-11-27.10. Start, cột phải
  ///
  /// In vi, this message translates to:
  /// **'Desktop'**
  String get startDesktop;

  /// Không dùng từ 2026-11-27.10. Start, cột phải → màn Số liệu
  ///
  /// In vi, this message translates to:
  /// **'Số liệu'**
  String get startDetails;

  /// Không dùng từ 2026-11-27.10. Start, cột phải → Cài đặt
  ///
  /// In vi, this message translates to:
  /// **'Bảng điều khiển'**
  String get startControlPanel;

  /// Không dùng từ 2026-11-27.10. Dòng phụ
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get startControlPanelSub;

  /// Không dùng từ 2026-11-27.10. Start, cột phải → Skill
  ///
  /// In vi, this message translates to:
  /// **'Thêm / gỡ'**
  String get startAddRemove;

  /// Không dùng từ 2026-11-27.10. Dòng phụ
  ///
  /// In vi, this message translates to:
  /// **'chương trình · Skill'**
  String get startAddRemoveSub;

  /// Không dùng từ 2026-11-27.10. Start, cột phải → Thiết bị
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị'**
  String get startDevice;

  /// Không dùng từ 2026-11-27.10. Dòng phụ
  ///
  /// In vi, this message translates to:
  /// **'firmware, sao lưu'**
  String get startDeviceSub;

  /// Không dùng từ 2026-11-27.10. Hàng cuối Start → bảng Tất cả chương trình
  ///
  /// In vi, this message translates to:
  /// **'Tất cả chương trình'**
  String get startAllPrograms;

  /// Không dùng từ 2026-11-27.10. Chân Start (amber)
  ///
  /// In vi, this message translates to:
  /// **'Tắt màn'**
  String get startTurnOff;

  /// Không dùng từ 2026-11-27.10. Chân Start (coral) → POST /api/reboot
  ///
  /// In vi, this message translates to:
  /// **'Khởi động lại'**
  String get startRestart;

  /// Không dùng từ 2026-11-27.10. Tiêu đề bảng
  ///
  /// In vi, this message translates to:
  /// **'Tất cả chương trình'**
  String get allProgramsTitle;

  /// Không dùng từ 2026-11-27.10. Nút quay lại
  ///
  /// In vi, this message translates to:
  /// **'Về Start'**
  String get allProgramsBackA11y;

  /// Không dùng từ 2026-11-27.10. Nhóm
  ///
  /// In vi, this message translates to:
  /// **'AGENT'**
  String get allProgramsGroupAgent;

  /// Không dùng từ 2026-11-27.10. Nhóm
  ///
  /// In vi, this message translates to:
  /// **'THỜI TIẾT · ĐỒNG HỒ · ẢNH'**
  String get allProgramsGroupOther;

  /// Không dùng từ 2026-11-27.10. Nhóm
  ///
  /// In vi, this message translates to:
  /// **'HỆ THỐNG'**
  String get allProgramsGroupSystem;

  /// Không dùng từ 2026-11-27.10. Chú thích chấm mint
  ///
  /// In vi, this message translates to:
  /// **'● = đang mở'**
  String get allProgramsOpenLegend;

  /// Không dùng từ 2026-11-27.10. Hàng cuối bảng → Skill
  ///
  /// In vi, this message translates to:
  /// **'Thêm / gỡ chương trình'**
  String get allProgramsAddRemove;

  /// Không dùng từ 2026-11-27.10. Dòng phụ
  ///
  /// In vi, this message translates to:
  /// **'bật skill mới: {names} sắp có'**
  String allProgramsAddRemoveSub(String names);

  /// Không dùng từ 2026-11-27.10. Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Claude'**
  String get appClaude;

  /// Không dùng từ 2026-11-27.10. Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Codex'**
  String get appCodex;

  /// Không dùng từ 2026-11-27.10. Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'AI'**
  String get appAi;

  /// Không dùng từ 2026-11-27.10. Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Xu hướng'**
  String get appTrend;

  /// Không dùng từ 2026-11-27.10. Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Agents'**
  String get appAgents;

  /// Không dùng từ 2026-11-27.10. Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Ảnh'**
  String get appPhoto;

  /// Không dùng từ 2026-11-27.10. Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Thời tiết'**
  String get appWeather;

  /// Không dùng từ 2026-11-27.10. Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Dự báo'**
  String get appForecast;

  /// Không dùng từ 2026-11-27.10. Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Đồng hồ'**
  String get appClock;

  /// Không dùng từ 2026-11-27.10. Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Thông tin'**
  String get appInfo;

  /// Không dùng từ 2026-11-27.10. Tên chương trình (skill sắp có)
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn'**
  String get appChat;

  /// Nhóm Cài đặt
  ///
  /// In vi, this message translates to:
  /// **'THỜI TIẾT'**
  String get settingsSectionWeather;

  /// Dòng Cài đặt → màn Vị trí thời tiết; phụ = tên nơi hoặc settingsWeatherLocationNone
  ///
  /// In vi, this message translates to:
  /// **'Vị trí thời tiết'**
  String get settingsWeatherLocation;

  /// Phụ khi thiết bị chưa có vị trí
  ///
  /// In vi, this message translates to:
  /// **'chưa đặt'**
  String get settingsWeatherLocationNone;

  /// Tiêu đề thanh trên
  ///
  /// In vi, this message translates to:
  /// **'Vị trí thời tiết'**
  String get weatherLocationTitle;

  /// Nhãn thẻ vị trí hiện tại
  ///
  /// In vi, this message translates to:
  /// **'THIẾT BỊ ĐANG DÙNG'**
  String get weatherLocationCurrent;

  /// Toạ độ, 2 số lẻ
  ///
  /// In vi, this message translates to:
  /// **'{lat}, {lon}'**
  String weatherLocationCoords(String lat, String lon);

  /// Nút chữ → bảng sửa tên
  ///
  /// In vi, this message translates to:
  /// **'Sửa tên'**
  String get weatherLocationRename;

  /// Nút chữ coral → hỏi xoá
  ///
  /// In vi, this message translates to:
  /// **'Xoá vị trí'**
  String get weatherLocationClear;

  /// Thẻ khi chưa đặt (tiêu đề dùng weatherNoLocationTitle)
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị chưa lấy được thời tiết. Chọn một nơi bên dưới.'**
  String get weatherLocationUnsetBody;

  /// Thẻ hiện tại, firmware không có weatherPlace
  ///
  /// In vi, this message translates to:
  /// **'Firmware này chưa hiện tên nơi — thiết bị chỉ nhận toạ độ. Cập nhật firmware để thấy tên trên màn Thời tiết và Đồng hồ.'**
  String get weatherLocationOldFwNote;

  /// Nút GPS
  ///
  /// In vi, this message translates to:
  /// **'Dùng vị trí hiện tại'**
  String get weatherLocationUseGps;

  /// Phụ nút GPS
  ///
  /// In vi, this message translates to:
  /// **'Chỉ lấy khi bạn bấm, rồi hỏi lại trước khi gửi.'**
  String get weatherLocationUseGpsSub;

  /// Nút GPS khi đang lấy
  ///
  /// In vi, this message translates to:
  /// **'Đang lấy vị trí…'**
  String get weatherLocationGpsLoading;

  /// Phụ khi đang lấy
  ///
  /// In vi, this message translates to:
  /// **'Chờ định vị của điện thoại, vài giây.'**
  String get weatherLocationGpsLoadingSub;

  /// Thanh báo amber
  ///
  /// In vi, this message translates to:
  /// **'Chưa cho phép vị trí'**
  String get weatherLocationGpsDeniedTitle;

  /// Thanh báo
  ///
  /// In vi, this message translates to:
  /// **'App cần quyền vị trí để lấy toạ độ của điện thoại. Hoặc tìm thành phố bên dưới.'**
  String get weatherLocationGpsDeniedBody;

  /// Nút viền khi quyền bị từ chối hẳn
  ///
  /// In vi, this message translates to:
  /// **'Mở cài đặt điện thoại'**
  String get weatherLocationOpenAppSettings;

  /// Thanh báo amber
  ///
  /// In vi, this message translates to:
  /// **'Định vị đang tắt'**
  String get weatherLocationGpsOffTitle;

  /// Thanh báo
  ///
  /// In vi, this message translates to:
  /// **'Bật định vị (GPS) của điện thoại rồi bấm lại.'**
  String get weatherLocationGpsOffBody;

  /// Nút viền → cài đặt vị trí của hệ thống
  ///
  /// In vi, this message translates to:
  /// **'Bật định vị'**
  String get weatherLocationTurnOnGps;

  /// Thanh báo coral
  ///
  /// In vi, this message translates to:
  /// **'Không lấy được vị trí'**
  String get weatherLocationGpsFailTitle;

  /// Thanh báo; nút commonRetry
  ///
  /// In vi, this message translates to:
  /// **'Điện thoại chưa định vị được (trong nhà, sóng yếu). Thử lại hoặc tìm thành phố.'**
  String get weatherLocationGpsFailBody;

  /// Nhãn nhóm
  ///
  /// In vi, this message translates to:
  /// **'HOẶC TÌM THÀNH PHỐ'**
  String get weatherLocationSearchSection;

  /// Chữ mờ ô tìm
  ///
  /// In vi, this message translates to:
  /// **'Tên thành phố, vd Đà Nẵng'**
  String get weatherLocationSearchHint;

  /// Ghi chú dưới ô tìm
  ///
  /// In vi, this message translates to:
  /// **'Chữ bạn gõ được gửi tới Open-Meteo để tìm (như trang web của thiết bị).'**
  String get weatherLocationSearchPrivacy;

  /// Nhãn đọc màn hình nút × trong ô tìm
  ///
  /// In vi, this message translates to:
  /// **'Xoá chữ'**
  String get weatherLocationSearchClearA11y;

  /// Dòng khi đang tìm
  ///
  /// In vi, this message translates to:
  /// **'Đang tìm…'**
  String get weatherLocationSearching;

  /// Dòng phụ kết quả; area = "Tỉnh, Nước"
  ///
  /// In vi, this message translates to:
  /// **'{area} · {lat}, {lon}'**
  String weatherLocationResultSub(String area, String lat, String lon);

  /// Không có kết quả
  ///
  /// In vi, this message translates to:
  /// **'Không thấy “{query}”'**
  String weatherLocationNoResultsTitle(String query);

  /// Không có kết quả
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra chính tả, hoặc thử tên không dấu / tên tiếng Anh.'**
  String get weatherLocationNoResultsBody;

  /// Lỗi mạng, coral
  ///
  /// In vi, this message translates to:
  /// **'Không tìm được'**
  String get weatherLocationSearchErrorTitle;

  /// Lỗi mạng; nút commonRetry
  ///
  /// In vi, this message translates to:
  /// **'Điện thoại không tới được Open-Meteo. Kiểm tra mạng rồi thử lại.'**
  String get weatherLocationSearchErrorBody;

  /// Tiêu đề bảng xác nhận
  ///
  /// In vi, this message translates to:
  /// **'Đặt vị trí này?'**
  String get weatherLocationConfirmTitle;

  /// Tiêu đề bảng khi bấm Sửa tên
  ///
  /// In vi, this message translates to:
  /// **'Sửa tên nơi'**
  String get weatherLocationRenameTitle;

  /// Nhãn ô tên
  ///
  /// In vi, this message translates to:
  /// **'TÊN HIỆN TRÊN THIẾT BỊ'**
  String get weatherLocationNameLabel;

  /// Bộ đếm ký tự
  ///
  /// In vi, this message translates to:
  /// **'{n}/16'**
  String weatherLocationNameCount(String n);

  /// Dưới ô tên
  ///
  /// In vi, this message translates to:
  /// **'Tối đa 16 ký tự để vừa khe trên màn thiết bị.'**
  String get weatherLocationNameHint;

  /// Nhãn khung xem trước
  ///
  /// In vi, this message translates to:
  /// **'TRÊN THIẾT BỊ'**
  String get weatherLocationPreview;

  /// Xem trước dòng cửa sổ Thời tiết
  ///
  /// In vi, this message translates to:
  /// **'Thời tiết: {desc} · {place}'**
  String weatherLocationPreviewWeather(String desc, String place);

  /// Xem trước dòng múi giờ
  ///
  /// In vi, this message translates to:
  /// **'Đồng hồ: Múi giờ: GMT{offset} · {place}'**
  String weatherLocationPreviewClock(String offset, String place);

  /// Nút chính bảng xác nhận
  ///
  /// In vi, this message translates to:
  /// **'Đặt cho thiết bị'**
  String get weatherLocationApply;

  /// Nút chính khi firmware cũ
  ///
  /// In vi, this message translates to:
  /// **'Đặt toạ độ cho thiết bị'**
  String get weatherLocationApplyCoords;

  /// Nút chính bảng sửa tên
  ///
  /// In vi, this message translates to:
  /// **'Lưu tên'**
  String get weatherLocationSaveName;

  /// Nút chính khi đang gửi
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi…'**
  String get weatherLocationSending;

  /// Thanh báo trong bảng, coral
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không nhận'**
  String get weatherLocationRejectedTitle;

  /// Thanh báo; nút chính thành commonRetry
  ///
  /// In vi, this message translates to:
  /// **'Vị trí trên thiết bị chưa đổi. Kiểm tra thiết bị còn cùng mạng rồi thử lại.'**
  String get weatherLocationRejectedBody;

  /// Bảng xác nhận, firmware cũ (thay ô tên)
  ///
  /// In vi, this message translates to:
  /// **'Firmware này chưa hiện tên nơi: thiết bị chỉ nhận toạ độ.'**
  String get weatherLocationOldFwSheet;

  /// Thông báo nhỏ sau khi thiết bị nhận
  ///
  /// In vi, this message translates to:
  /// **'Đã đặt {place} cho thiết bị.'**
  String weatherLocationDone(String place);

  /// Hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Xoá vị trí thời tiết?'**
  String get weatherLocationClearTitle;

  /// Hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị sẽ không lấy thời tiết và dự báo nữa, tên “{place}” cũng bỏ khỏi màn Thời tiết và Đồng hồ. Mọi điện thoại cùng thấy thay đổi này.'**
  String weatherLocationClearBody(String place);

  /// Nút coral hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get weatherLocationClearOk;

  /// Nhãn đọc màn hình bàn rê
  ///
  /// In vi, this message translates to:
  /// **'Bàn rê: rê một ngón để di chuột trên thiết bị, chạm nhẹ để click'**
  String get controlTrackpadA11y;

  /// Nút chuột trái dưới bàn rê
  ///
  /// In vi, this message translates to:
  /// **'Trái'**
  String get controlMouseLeft;

  /// Nút chuột phải dưới bàn rê
  ///
  /// In vi, this message translates to:
  /// **'Phải'**
  String get controlMouseRight;

  /// Nhãn đọc màn hình
  ///
  /// In vi, this message translates to:
  /// **'Chuột trái'**
  String get controlMouseLeftA11y;

  /// Nhãn đọc màn hình
  ///
  /// In vi, this message translates to:
  /// **'Chuột phải'**
  String get controlMouseRightA11y;

  /// Nhóm phím
  ///
  /// In vi, this message translates to:
  /// **'Phím'**
  String get controlKeysA11y;

  /// Phím Windows (lá cờ) — mở / đóng Start trên thiết bị
  ///
  /// In vi, this message translates to:
  /// **'Windows'**
  String get keyWindows;

  /// Phím tổ hợp có sẵn — cửa sổ kế
  ///
  /// In vi, this message translates to:
  /// **'Alt+Tab'**
  String get keyAltTab;

  /// Phím tổ hợp có sẵn — đóng cửa sổ trên cùng
  ///
  /// In vi, this message translates to:
  /// **'Alt+F4'**
  String get keyAltF4;

  /// Phím
  ///
  /// In vi, this message translates to:
  /// **'Esc'**
  String get keyEsc;

  /// Phím
  ///
  /// In vi, this message translates to:
  /// **'Tab'**
  String get keyTab;

  /// Phím
  ///
  /// In vi, this message translates to:
  /// **'Enter'**
  String get keyEnter;

  /// Nhãn đọc màn hình phím mũi tên
  ///
  /// In vi, this message translates to:
  /// **'Trái'**
  String get keyLeft;

  /// Nhãn đọc màn hình phím mũi tên
  ///
  /// In vi, this message translates to:
  /// **'Lên'**
  String get keyUp;

  /// Nhãn đọc màn hình phím mũi tên
  ///
  /// In vi, this message translates to:
  /// **'Xuống'**
  String get keyDown;

  /// Nhãn đọc màn hình phím mũi tên
  ///
  /// In vi, this message translates to:
  /// **'Phải'**
  String get keyRight;

  /// Phím mở bàn phím chữ (chưa dùng, mờ)
  ///
  /// In vi, this message translates to:
  /// **'Chữ'**
  String get keyText;

  /// Dòng phụ dưới phím Chữ
  ///
  /// In vi, this message translates to:
  /// **'sắp có'**
  String get keyTextSoon;

  /// Nhãn đọc màn hình nút nguồn khi đang bật
  ///
  /// In vi, this message translates to:
  /// **'Tắt máy'**
  String get powerOff;

  /// Nút nguồn khi máy tắt; nút to giữa bàn rê
  ///
  /// In vi, this message translates to:
  /// **'Bật máy'**
  String get powerOn;

  /// Nhãn đọc màn hình nút nguồn khi đang tắt
  ///
  /// In vi, this message translates to:
  /// **'Đang tắt máy'**
  String get powerShutting;

  /// Nhãn đọc màn hình nút nguồn khi đang khởi động
  ///
  /// In vi, this message translates to:
  /// **'Đang khởi động'**
  String get powerBooting;

  /// Nút vuông chế độ đêm
  ///
  /// In vi, this message translates to:
  /// **'Chế độ đêm'**
  String get controlNightA11y;

  /// Nút vuông → màn Số liệu
  ///
  /// In vi, this message translates to:
  /// **'Số liệu'**
  String get controlDetailsA11y;

  /// Nhãn thẻ kho (thay photoOnDevice khi firmware có photo_source)
  ///
  /// In vi, this message translates to:
  /// **'KHO ẢNH'**
  String get photoLibraryTitle;

  /// Meta khi kho > 8 ảnh (cached = 8)
  ///
  /// In vi, this message translates to:
  /// **'{count} ảnh · {cached} trên máy'**
  String photoLibraryCount(String count, String cached);

  /// Meta khi kho ≤ 8 ảnh
  ///
  /// In vi, this message translates to:
  /// **'{count} ảnh · cả {count} trên máy'**
  String photoLibraryCountAll(String count);

  /// Meta kho trống
  ///
  /// In vi, this message translates to:
  /// **'chưa có ảnh'**
  String get photoLibraryCountEmpty;

  /// Dòng trạng thái, chấm mint (photo_source.state = online)
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị đang lấy ảnh từ điện thoại'**
  String get photoSourceOnline;

  /// Bên phải dòng trạng thái online (photo_source.index / count)
  ///
  /// In vi, this message translates to:
  /// **'đang chiếu {index}/{count}'**
  String photoSourceShowing(String index, String count);

  /// Dòng trạng thái, chấm muted (offline)
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị chỉ chiếu 8 ảnh đã giữ'**
  String get photoSourceOffline;

  /// Dòng phụ khi offline
  ///
  /// In vi, this message translates to:
  /// **'Điện thoại khác mạng, hoặc app đã tắt quá 2 phút.'**
  String get photoSourceOfflineBody;

  /// Nhãn trên ô ảnh thiết bị đang chiếu
  ///
  /// In vi, this message translates to:
  /// **'ĐANG CHIẾU'**
  String get photoLibraryShowingTag;

  /// Nhãn đọc màn hình ô ảnh kho
  ///
  /// In vi, this message translates to:
  /// **'Ảnh {n}{onDevice}{showing}, bấm để xoá'**
  String photoLibraryTileA11y(String n, String onDevice, String showing);

  /// Ghép vào photoLibraryTileA11y
  ///
  /// In vi, this message translates to:
  /// **', đang ở trên thiết bị'**
  String get photoLibraryOnDeviceA11y;

  /// Ghép vào photoLibraryTileA11y
  ///
  /// In vi, this message translates to:
  /// **', thiết bị đang chiếu'**
  String get photoLibraryShowingA11y;

  /// Dưới thẻ kho (thay photoNote)
  ///
  /// In vi, this message translates to:
  /// **'8 ảnh mới nhất được giữ trên thiết bị để chiếu cả khi điện thoại vắng. Bấm ảnh để xoá khỏi kho.'**
  String get photoLibraryNote;

  /// Kho trống
  ///
  /// In vi, this message translates to:
  /// **'Kho ảnh trống'**
  String get photoLibraryEmptyTitle;

  /// Kho trống
  ///
  /// In vi, this message translates to:
  /// **'Thêm ảnh từ thư viện hoặc máy ảnh. Ảnh nằm trên điện thoại, không giới hạn số ảnh; thiết bị lấy ảnh từ đây để chiếu.'**
  String get photoLibraryEmptyBody;

  /// Phủ trên ô ảnh mới
  ///
  /// In vi, this message translates to:
  /// **'Đang thêm…'**
  String get photoLibraryAdding;

  /// Thanh báo coral
  ///
  /// In vi, this message translates to:
  /// **'Chưa thêm được ảnh'**
  String get photoLibraryAddErrorTitle;

  /// Thanh báo; nút commonRetry
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không nhận bản đệm nên ảnh chưa vào kho. Vùng cắt được giữ.'**
  String get photoLibraryAddErrorBody;

  /// Hộp thoại xoá
  ///
  /// In vi, this message translates to:
  /// **'Xoá ảnh khỏi kho?'**
  String get photoLibraryDeleteTitle;

  /// Hộp thoại xoá
  ///
  /// In vi, this message translates to:
  /// **'Ảnh bị xoá khỏi điện thoại, và khỏi thiết bị nếu đang được giữ trên máy. Không lấy lại được.'**
  String get photoLibraryDeleteBody;

  /// Phủ trên ô đang xoá
  ///
  /// In vi, this message translates to:
  /// **'Đang xoá…'**
  String get photoLibraryDeleting;

  /// Thanh báo coral (tiêu đề photoDeleteErrorTitle); nút commonRetry
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị không nhận lệnh xoá bản đệm. Ảnh vẫn còn trong kho.'**
  String get photoLibraryDeleteErrorBody;

  /// Nút chính màn Cắt ảnh khi firmware có photo_source (thay photoCropSend)
  ///
  /// In vi, this message translates to:
  /// **'Thêm vào kho'**
  String get photoCropAddToLibrary;

  /// Nút lớn đầu form Cài Wi-Fi → màn Quét mã
  ///
  /// In vi, this message translates to:
  /// **'Quét mã trên màn thiết bị'**
  String get wifiScanEntry;

  /// Dòng phụ nút quét
  ///
  /// In vi, this message translates to:
  /// **'Nhanh nhất: app tự gửi mạng điện thoại đang dùng.'**
  String get wifiScanEntrySub;

  /// Vạch chia giữa nút quét và form
  ///
  /// In vi, this message translates to:
  /// **'HOẶC NHẬP TAY'**
  String get wifiOrManual;

  /// Nút chữ dưới form → bảng mật khẩu đã nhớ; count = 0 → ẩn
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu đã nhớ ({count})'**
  String wifiSavedLink(String count);

  /// Thanh báo sau khi quét (mint)
  ///
  /// In vi, this message translates to:
  /// **'Đã đọc mã của thiết bị'**
  String get wifiScannedTitle;

  /// Bước password
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị sẽ vào mạng điện thoại đang dùng.'**
  String get wifiScannedBody;

  /// Bước formScanned
  ///
  /// In vi, this message translates to:
  /// **'Điện thoại chưa ở mạng Wi-Fi nào nên app không biết mạng để gửi. Nhập tên mạng và mật khẩu.'**
  String get wifiScannedNoNetwork;

  /// Nhãn bước password
  ///
  /// In vi, this message translates to:
  /// **'MẠNG SẼ GỬI'**
  String get wifiNetworkToSend;

  /// Nút chữ → form đầy đủ (tên mạng sửa được)
  ///
  /// In vi, this message translates to:
  /// **'Đổi mạng'**
  String get wifiChangeNetwork;

  /// Nhãn ô mật khẩu bước password
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu Wi-Fi “{ssid}”'**
  String wifiPassFor(String ssid);

  /// Ghi chú bước password (R-WF-5)
  ///
  /// In vi, this message translates to:
  /// **'App nhớ mật khẩu này trong kho bảo mật của máy khi thiết bị vào được mạng — lần sau quét là xong.'**
  String get wifiRememberNote;

  /// Tiêu đề bảng
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu đã nhớ'**
  String get wifiSavedTitle;

  /// Bảng mật khẩu đã nhớ
  ///
  /// In vi, this message translates to:
  /// **'Chỉ trên điện thoại này, trong kho bảo mật. Quét mã ở các mạng này sẽ gửi luôn, không hỏi.'**
  String get wifiSavedBody;

  /// Dòng phụ mỗi mạng
  ///
  /// In vi, this message translates to:
  /// **'dùng lần cuối {when}'**
  String wifiSavedLastUsed(String when);

  /// Nút coral mỗi dòng / hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Quên'**
  String get wifiForget;

  /// Hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu “{ssid}”?'**
  String wifiForgetTitle(String ssid);

  /// Hộp thoại
  ///
  /// In vi, this message translates to:
  /// **'Lần sau quét mã ở mạng này, app sẽ hỏi lại mật khẩu. Thiết bị không bị ảnh hưởng.'**
  String get wifiForgetBody;

  /// Tiêu đề màn Quét mã
  ///
  /// In vi, this message translates to:
  /// **'Quét mã trên thiết bị'**
  String get wifiScanTitle;

  /// Nút × màn Quét mã
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get wifiScanCloseA11y;

  /// Bảng dưới màn quét
  ///
  /// In vi, this message translates to:
  /// **'Đưa mã QR vào khung'**
  String get wifiScanHelpTitle;

  /// Bảng dưới, cạnh ảnh màn log-on
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị hiện màn này khi chưa vào được Wi-Fi. Giữ máy cách màn khoảng một gang tay.'**
  String get wifiScanHelpBody;

  /// Nhãn ảnh nhỏ
  ///
  /// In vi, this message translates to:
  /// **'Màn cài Wi-Fi của thiết bị có mã QR'**
  String get wifiScanHelpImageA11y;

  /// Nút chữ → form Cài Wi-Fi
  ///
  /// In vi, this message translates to:
  /// **'Không có mã? Nhập tay'**
  String get wifiScanManual;

  /// Đọc được mã (khung mint)
  ///
  /// In vi, this message translates to:
  /// **'Đã đọc mã glimmer-setup'**
  String get wifiScanFound;

  /// Dòng phụ trước khi tự đóng (rung nhẹ)
  ///
  /// In vi, this message translates to:
  /// **'Đang chuyển sang bước tiếp…'**
  String get wifiScanFoundBody;

  /// Mã lạ (coral) — cùng nghĩa với lỗi devErrNotGlimmerQr của app
  ///
  /// In vi, this message translates to:
  /// **'Đây không phải mã của glimmer'**
  String get wifiScanWrongTitle;

  /// Mã lạ (R-WF-4)
  ///
  /// In vi, this message translates to:
  /// **'Quét mã trên màn cài đặt Wi-Fi của thiết bị. App không làm gì với mã này.'**
  String get wifiScanWrongBody;

  /// Nút chính khi mã lạ
  ///
  /// In vi, this message translates to:
  /// **'Quét lại'**
  String get wifiScanAgain;

  /// Chưa có quyền camera
  ///
  /// In vi, this message translates to:
  /// **'Cần quyền camera'**
  String get wifiScanCameraTitle;

  /// Chưa có quyền camera
  ///
  /// In vi, this message translates to:
  /// **'App chỉ dùng camera để đọc mã QR trên màn thiết bị, không chụp hay lưu ảnh.'**
  String get wifiScanCameraBody;

  /// Nút chính → hộp xin quyền của hệ thống
  ///
  /// In vi, this message translates to:
  /// **'Cho phép camera'**
  String get wifiScanAllowCamera;

  /// Nút viền khi quyền bị từ chối hẳn
  ///
  /// In vi, this message translates to:
  /// **'Mở cài đặt điện thoại'**
  String get wifiScanOpenSettings;

  /// Nút đóng bảng
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get commonClose;

  /// Cài Wi-Fi · bảng mật khẩu đã nhớ: {when} của wifiSavedLastUsed khi là hôm nay (ngày khác: dd/MM)
  ///
  /// In vi, this message translates to:
  /// **'hôm nay'**
  String get devWifiUsedToday;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
