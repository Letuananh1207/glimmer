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

  /// Nút viền, mở Cài Wi-Fi
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị mới / đang hiện glimmer-setup'**
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

  /// Chi tiết
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị phải đang hiện KẾT NỐI WI-FI · glimmer-setup (khoảng 1 phút sau khi cắm điện). Android sẽ hỏi bạn xác nhận kết nối.'**
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

  /// Chi tiết
  ///
  /// In vi, this message translates to:
  /// **'IP {ip}'**
  String wifiDoneDetail(String ip);

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

  /// Chi tiết lỗi
  ///
  /// In vi, this message translates to:
  /// **'Chưa thấy thiết bị trên \"{ssid}\". Sai mật khẩu, mạng chỉ có 5 GHz, hoặc mạng phải đăng nhập web — khi đó thiết bị sẽ lại hiện glimmer-setup.'**
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

  /// Không dùng từ 2026-11-25.3 — Mô tả ô skill
  ///
  /// In vi, this message translates to:
  /// **'Nội dung vui cho màn hình.'**
  String get skillFunDesc;

  /// Tiêu đề màn Skill
  ///
  /// In vi, this message translates to:
  /// **'Skill'**
  String get skillsTitle;

  /// Phụ đề màn Skill
  ///
  /// In vi, this message translates to:
  /// **'Mỗi skill bật là một tab trên dock thiết bị.'**
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

  /// Tab 1 thanh dưới (2026-11-25.3), mọi skill
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

  /// Chú thích dưới danh sách (R-SK-3)
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị xoay các tab theo thứ tự trên. Thẻ cần duyệt vẫn chen ngang mọi tab.'**
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

  /// Nút viền → Cài đặt
  ///
  /// In vi, this message translates to:
  /// **'Đặt vị trí trong Cài đặt'**
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
