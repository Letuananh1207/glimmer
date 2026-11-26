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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
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

  /// Nhãn đọc màn hình ô màn chạm được
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

  /// Dòng kênh khi màn tắt
  ///
  /// In vi, this message translates to:
  /// **'Màn đang tắt'**
  String get controlScreenOffTitle;

  /// Dòng kênh khi màn tắt
  ///
  /// In vi, this message translates to:
  /// **'· bấm Bật màn để mở lại'**
  String get controlScreenOffNote;

  /// Chữ mờ giữa ô màn tối
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

  /// Nút tròn
  ///
  /// In vi, this message translates to:
  /// **'Tắt màn'**
  String get controlScreenOff;

  /// Nút tròn khi màn đang tắt (amber)
  ///
  /// In vi, this message translates to:
  /// **'Bật màn'**
  String get controlScreenOn;

  /// Nút tròn (lilac khi bật)
  ///
  /// In vi, this message translates to:
  /// **'Chế độ đêm'**
  String get controlNight;

  /// Nút tròn → màn Số liệu
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
  /// **'Firmware chưa nhận chạm'**
  String get controlOldFwTitle;

  /// Thanh báo firmware cũ
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị đang chạy {version}: chạm trên màn chưa dùng được, chỉ mở app qua Start.'**
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

  /// Nút → Cài Wi-Fi
  ///
  /// In vi, this message translates to:
  /// **'Cài Wi-Fi'**
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

  /// Màn thiết bị · menu chuột phải (panel P-2026-11-26.14 XP-Menu)
  ///
  /// In vi, this message translates to:
  /// **'Sắp xếp biểu tượng'**
  String get devXpMenuArrange;

  /// Màn thiết bị · menu chuột phải (panel P-2026-11-26.14 XP-Menu)
  ///
  /// In vi, this message translates to:
  /// **'Làm mới'**
  String get devXpMenuRefresh;

  /// Màn thiết bị · menu chuột phải (panel P-2026-11-26.14 XP-Menu)
  ///
  /// In vi, this message translates to:
  /// **'Dán'**
  String get devXpMenuPaste;

  /// Màn thiết bị · menu chuột phải (panel P-2026-11-26.14 XP-Menu)
  ///
  /// In vi, this message translates to:
  /// **'Dán lối tắt'**
  String get devXpMenuPasteShortcut;

  /// Màn thiết bị · menu chuột phải (panel P-2026-11-26.14 XP-Menu)
  ///
  /// In vi, this message translates to:
  /// **'Mới'**
  String get devXpMenuNew;

  /// Màn thiết bị · menu chuột phải (panel P-2026-11-26.14 XP-Menu)
  ///
  /// In vi, this message translates to:
  /// **'Thuộc tính'**
  String get devXpMenuProperties;

  /// Màn thiết bị · menu chuột phải (panel P-2026-11-26.14 XP-Menu)
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục'**
  String get devXpMenuRestore;

  /// Màn thiết bị · menu chuột phải (panel P-2026-11-26.14 XP-Menu)
  ///
  /// In vi, this message translates to:
  /// **'Di chuyển'**
  String get devXpMenuMove;

  /// Màn thiết bị · menu chuột phải (panel P-2026-11-26.14 XP-Menu)
  ///
  /// In vi, this message translates to:
  /// **'Kích thước'**
  String get devXpMenuSize;

  /// Màn thiết bị · menu chuột phải (panel P-2026-11-26.14 XP-Menu)
  ///
  /// In vi, this message translates to:
  /// **'Thu nhỏ'**
  String get devXpMenuMinimize;

  /// Màn thiết bị · menu chuột phải (panel P-2026-11-26.14 XP-Menu)
  ///
  /// In vi, this message translates to:
  /// **'Phóng to'**
  String get devXpMenuMaximize;

  /// Màn thiết bị · menu chuột phải (panel P-2026-11-26.14 XP-Menu)
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get devXpMenuClose;

  /// Màn thiết bị · phím tắt cạnh Đóng trong menu cửa sổ
  ///
  /// In vi, this message translates to:
  /// **'Alt+F4'**
  String get devXpMenuAltF4;

  /// Ô màn thiết bị: thứ kiểu tiêu đề như firmware ClockFmt::weekdayTitle (day = DateTime.weekday)
  ///
  /// In vi, this message translates to:
  /// **'{day, select, 1{Thứ Hai} 2{Thứ Ba} 3{Thứ Tư} 4{Thứ Năm} 5{Thứ Sáu} 6{Thứ Bảy} other{Chủ Nhật}}'**
  String devXpWeekday(String day);

  /// Ô màn thiết bị: tiêu đề cửa sổ XP của kênh (firmware XP::window)
  ///
  /// In vi, this message translates to:
  /// **'AI hôm nay'**
  String get devXpTitleAi;

  /// Ô màn thiết bị: tiêu đề cửa sổ XP của kênh (firmware XP::window)
  ///
  /// In vi, this message translates to:
  /// **'Tác tử'**
  String get devXpTitleAgents;

  /// Ô màn thiết bị: tiêu đề cửa sổ XP của kênh (firmware XP::window)
  ///
  /// In vi, this message translates to:
  /// **'Đồng hồ'**
  String get devXpTitleClock;

  /// Ô màn thiết bị: tiêu đề cửa sổ XP của kênh (firmware XP::window)
  ///
  /// In vi, this message translates to:
  /// **'Dự báo'**
  String get devXpTitleForecast;

  /// Ô màn thiết bị: tiêu đề cửa sổ XP của kênh (firmware XP::window)
  ///
  /// In vi, this message translates to:
  /// **'Thông tin'**
  String get devXpTitleInfo;

  /// Ô màn thiết bị: tiêu đề cửa sổ XP của kênh (firmware XP::window)
  ///
  /// In vi, this message translates to:
  /// **'Ảnh'**
  String get devXpTitlePhoto;

  /// Ô màn thiết bị: tiêu đề cửa sổ XP của kênh (firmware XP::window)
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get devXpTitleSetup;

  /// Ô màn thiết bị: tiêu đề cửa sổ XP của kênh (firmware XP::window)
  ///
  /// In vi, this message translates to:
  /// **'Xu hướng'**
  String get devXpTitleTrend;

  /// Ô màn thiết bị: tiêu đề cửa sổ XP của kênh (firmware XP::window)
  ///
  /// In vi, this message translates to:
  /// **'Thời tiết'**
  String get devXpTitleWeather;

  /// Ô màn thiết bị: tiêu đề thẻ agent (ch_attention paintCard)
  ///
  /// In vi, this message translates to:
  /// **'Cần bạn duyệt'**
  String get devXpCardNeedApproval;

  /// Ô màn thiết bị: tiêu đề thẻ agent (ch_attention paintCard)
  ///
  /// In vi, this message translates to:
  /// **'Xong rồi!'**
  String get devXpCardDoneTitle;

  /// Ô màn thiết bị: tiêu đề thẻ tiến độ (ch_attention cardTitle)
  ///
  /// In vi, this message translates to:
  /// **'Đang chạy {pct}%'**
  String devXpCardRunningPct(int pct);

  /// Ô màn thiết bị: dòng chi tiết khi agent báo xong (ch_attention bodyText)
  ///
  /// In vi, this message translates to:
  /// **'{name} đã xong'**
  String devXpCardFinished(String name);

  /// Ô màn thiết bị: dòng chi tiết thẻ câu hỏi (ch_attention bodyText)
  ///
  /// In vi, this message translates to:
  /// **'{name} đang chờ câu trả lời'**
  String devXpCardWaitingAnswer(String name);

  /// Ô màn thiết bị: trạng thái thẻ chờ bạn (ch_attention statusText)
  ///
  /// In vi, this message translates to:
  /// **'chờ bạn · {age}'**
  String devXpCardWaitStatus(String age);

  /// Ô màn thiết bị: thời gian dưới một phút (ch_attention statusText)
  ///
  /// In vi, this message translates to:
  /// **'{n} giây'**
  String devXpSeconds(int n);

  /// Ô màn thiết bị: thời lượng ngắn P phút / G giờ / NG ngày (TimeUtil::shortDuration)
  ///
  /// In vi, this message translates to:
  /// **'{n}{unit, select, minutes{P} hours{G} other{NG}}'**
  String devXpShortDur(int n, String unit);

  /// Ô màn thiết bị: dòng danh sách Tác tử: thẻ cần duyệt (ch_attention listRow)
  ///
  /// In vi, this message translates to:
  /// **'Cần bạn'**
  String get devXpRowNeedYou;

  /// Ô màn thiết bị: dòng danh sách Tác tử: tiêu đề hook WAITING FOR YOU
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ bạn'**
  String get devXpRowWaitingYou;

  /// Ô màn thiết bị: dòng danh sách Tác tử: loại thẻ khi không có tiêu đề (ch_attention kindLabel, viết hoa đầu câu)
  ///
  /// In vi, this message translates to:
  /// **'{kind, select, approval{Phê duyệt} error{Lỗi} input{Chờ bạn} progress{Tiến độ} warning{Cảnh báo} success{Xong} other{Thông tin}}'**
  String devXpKindWord(String kind);

  /// Ô màn thiết bị: danh sách Tác tử: số thẻ không vẽ
  ///
  /// In vi, this message translates to:
  /// **'+ {n} mục khác'**
  String devXpMoreItems(int n);

  /// Ô màn thiết bị: thanh trạng thái Tác tử: số thẻ
  ///
  /// In vi, this message translates to:
  /// **'{n} mục'**
  String devXpItems(int n);

  /// Ô màn thiết bị: thanh trạng thái Tác tử
  ///
  /// In vi, this message translates to:
  /// **'{n} cần duyệt'**
  String devXpNApprovals(int n);

  /// Ô màn thiết bị: thanh trạng thái Tác tử
  ///
  /// In vi, this message translates to:
  /// **'{n} lượt bạn'**
  String devXpNInputs(int n);

  /// Ô màn thiết bị: thanh trạng thái Tác tử khi không thẻ nào chờ bạn
  ///
  /// In vi, this message translates to:
  /// **'không mục nào chờ'**
  String get devXpNoneWaiting;

  /// Ô màn thiết bị: nhãn biểu tượng màn desktop (ch_home)
  ///
  /// In vi, this message translates to:
  /// **'Thùng rác'**
  String get devXpDeskTrash;

  /// Ô màn thiết bị: bóng thời tiết màn desktop: dòng 1 (ch_home balloonText)
  ///
  /// In vi, this message translates to:
  /// **'{temp}° · {desc}'**
  String devXpDeskNow(int temp, String desc);

  /// Ô màn thiết bị: bóng thời tiết màn desktop: dòng 2
  ///
  /// In vi, this message translates to:
  /// **'cảm giác {temp}°'**
  String devXpDeskFeels(int temp);

  /// Ô màn thiết bị: bóng thời tiết màn desktop khi chưa có số đo
  ///
  /// In vi, this message translates to:
  /// **'chưa có thời tiết'**
  String get devXpDeskNoWeather;

  /// Ô màn thiết bị: kênh Cài đặt (ch_setup)
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất cài đặt'**
  String get devXpSetupHead;

  /// Ô màn thiết bị: kênh Cài đặt: số bước còn lại
  ///
  /// In vi, this message translates to:
  /// **'Còn {n} bước nữa là xong.'**
  String devXpSetupLeft(int n);

  /// Ô màn thiết bị: kênh Cài đặt: mục danh sách
  ///
  /// In vi, this message translates to:
  /// **'Khóa Claude'**
  String get devXpSetupClaude;

  /// Ô màn thiết bị: kênh Cài đặt: mục danh sách
  ///
  /// In vi, this message translates to:
  /// **'Token Codex'**
  String get devXpSetupCodex;

  /// Ô màn thiết bị: kênh Cài đặt: mục danh sách
  ///
  /// In vi, this message translates to:
  /// **'Thời tiết, vị trí, giờ'**
  String get devXpSetupWeather;

  /// Ô màn thiết bị: kênh Cài đặt: nhãn khung nhóm
  ///
  /// In vi, this message translates to:
  /// **'Mở trong trình duyệt'**
  String get devXpSetupOpen;

  /// Ô màn thiết bị: kênh Ảnh khi trống (ch_photo drawEmpty)
  ///
  /// In vi, this message translates to:
  /// **'Chưa có ảnh'**
  String get devXpPhotoEmpty;

  /// Ô màn thiết bị: kênh Ảnh khi trống
  ///
  /// In vi, this message translates to:
  /// **'Gửi ảnh từ app glimmer'**
  String get devXpPhotoSend;

  /// Ô màn thiết bị: kênh Ảnh khi trống
  ///
  /// In vi, this message translates to:
  /// **'hoặc'**
  String get devXpPhotoOr;

  /// Ô màn thiết bị (Thời tiết, ch_weather.cpp / XP-Weather*)
  ///
  /// In vi, this message translates to:
  /// **'Đang tải thời tiết...'**
  String get devXpWeatherLoading;

  /// Ô màn thiết bị (Thời tiết, ch_weather.cpp / XP-Weather*)
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thời tiết'**
  String get devXpWeatherErrorHead;

  /// Ô màn thiết bị (Thời tiết, ch_weather.cpp / XP-Weather*)
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ trả lỗi {code}.'**
  String devXpWeatherErrHttp(int code);

  /// Ô màn thiết bị (Thời tiết, ch_weather.cpp / XP-Weather*)
  ///
  /// In vi, this message translates to:
  /// **'Không kết nối được.'**
  String get devXpWeatherErrConnect;

  /// Ô màn thiết bị (Thời tiết, ch_weather.cpp / XP-Weather*)
  ///
  /// In vi, this message translates to:
  /// **'Không mở được kết nối.'**
  String get devXpWeatherErrBegin;

  /// Ô màn thiết bị (Thời tiết, ch_weather.cpp / XP-Weather*)
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu lỗi.'**
  String get devXpWeatherErrJson;

  /// Ô màn thiết bị (Thời tiết, ch_weather.cpp / XP-Weather*)
  ///
  /// In vi, this message translates to:
  /// **'Thiếu số liệu hiện tại.'**
  String get devXpWeatherErrNoCurrent;

  /// Ô màn thiết bị (Thời tiết, ch_weather.cpp / XP-Weather*)
  ///
  /// In vi, this message translates to:
  /// **'Không rõ lỗi.'**
  String get devXpWeatherErrUnknown;

  /// Ô màn thiết bị (Thời tiết, ch_weather.cpp / XP-Weather*)
  ///
  /// In vi, this message translates to:
  /// **'Đang tự thử lại...'**
  String get devXpWeatherRetrying;

  /// Ô màn thiết bị (Thời tiết, ch_weather.cpp / XP-Weather*)
  ///
  /// In vi, this message translates to:
  /// **'cảm giác {t}°'**
  String devXpWeatherFeels(int t);

  /// Ô màn thiết bị (Thời tiết, ch_weather.cpp / XP-Weather*)
  ///
  /// In vi, this message translates to:
  /// **'ẩm {n}%'**
  String devXpWeatherHumidity(int n);

  /// Ô màn thiết bị (Thời tiết, ch_weather.cpp / XP-Weather*)
  ///
  /// In vi, this message translates to:
  /// **'gió {n}km'**
  String devXpWeatherWind(int n);

  /// Ô màn thiết bị (Dự báo, ch_forecast.cpp / XP-Forecast*)
  ///
  /// In vi, this message translates to:
  /// **'Nay'**
  String get devXpDayToday;

  /// Ô màn thiết bị (Thời tiết, ch_weather.cpp / XP-Weather*)
  ///
  /// In vi, this message translates to:
  /// **'Mai'**
  String get devXpDayTomorrow;

  /// Ô màn thiết bị (Thời tiết, ch_weather.cpp / XP-Weather*)
  ///
  /// In vi, this message translates to:
  /// **'Kia'**
  String get devXpDayAfter;

  /// Ô màn thiết bị (Thời tiết, ch_weather.cpp / XP-Weather*)
  ///
  /// In vi, this message translates to:
  /// **'{event, select, set{Mặt trời lặn} other{Mặt trời mọc}} {time}'**
  String devXpWeatherSun(String event, String time);

  /// Ô màn thiết bị (Thời tiết, ch_weather.cpp / XP-Weather*)
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật {age} trước'**
  String devXpWeatherUpdated(String age);

  /// Ô màn thiết bị (Thời tiết, ch_weather.cpp / XP-Weather*)
  ///
  /// In vi, this message translates to:
  /// **'cũ {age}'**
  String devXpStaleMeta(String age);

  /// Ô màn thiết bị: khoảng thời gian như firmware TimeUtil::shortDuration
  ///
  /// In vi, this message translates to:
  /// **'{unit, select, minutes{{n}P} hours{{n}G} other{{n}NG}}'**
  String devXpSpanShort(String unit, int n);

  /// Ô màn thiết bị: khoảng thời gian như firmware TimeUtil::shortDuration
  ///
  /// In vi, this message translates to:
  /// **'{unit, select, minutes{{n} phút} hours{{n} giờ} other{{n} ngày}}'**
  String devXpSpanLong(String unit, int n);

  /// Ô màn thiết bị (Dự báo, ch_forecast.cpp / XP-Forecast*)
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dự báo'**
  String get devXpForecastEmpty;

  /// Ô màn thiết bị (Dự báo, ch_forecast.cpp / XP-Forecast*)
  ///
  /// In vi, this message translates to:
  /// **'3 ngày tới'**
  String get devXpForecastNext3;

  /// Ô màn thiết bị (Đồng hồ, ch_clock.cpp / XP-Clock)
  ///
  /// In vi, this message translates to:
  /// **'{slot, select, night{ngủ ngon nhé} morning{chào buổi sáng} afternoon{chào buổi chiều} evening{chào buổi tối} other{nghỉ ngơi thôi}}, {name}'**
  String devXpClockGreeting(String slot, String name);

  /// Ô màn thiết bị (Đồng hồ, ch_clock.cpp / XP-Clock)
  ///
  /// In vi, this message translates to:
  /// **'bạn'**
  String get devXpClockYou;

  /// Ô màn thiết bị (Đồng hồ, ch_clock.cpp / XP-Clock)
  ///
  /// In vi, this message translates to:
  /// **'Tuần {n}'**
  String devXpClockWeek(int n);

  /// Ô màn thiết bị (Thông tin, ch_info.cpp / XP-Info)
  ///
  /// In vi, this message translates to:
  /// **'{row, select, ip{IP} ssid{SSID} rssi{Sóng} up{Đã chạy} heap{Bộ nhớ} block{Khối lớn} fw{Firmware} channels{Kênh} updated{Cập nhật} other{Lần tới}}'**
  String devXpInfoLabels(String row);

  /// Ô màn thiết bị (Thông tin, ch_info.cpp / XP-Info)
  ///
  /// In vi, this message translates to:
  /// **'{n}P'**
  String devXpInfoMinutes(int n);

  /// Ô màn thiết bị (Thông tin, ch_info.cpp / XP-Info)
  ///
  /// In vi, this message translates to:
  /// **'{n}K trống'**
  String devXpInfoHeap(int n);

  /// Ô màn thiết bị (Thông tin, ch_info.cpp / XP-Info)
  ///
  /// In vi, this message translates to:
  /// **'{n}P trước'**
  String devXpInfoAgo(int n);

  /// Ô màn thiết bị (Thông tin, ch_info.cpp / XP-Info)
  ///
  /// In vi, this message translates to:
  /// **'sau {n}P'**
  String devXpInfoNext(int n);

  /// Ô màn thiết bị (màn hệ thống, display.cpp / XP-SetupMode, XP-OtaProgress)
  ///
  /// In vi, this message translates to:
  /// **'Để bắt đầu,'**
  String get devXpSetupLine1;

  /// Ô màn thiết bị (màn hệ thống, display.cpp / XP-SetupMode, XP-OtaProgress)
  ///
  /// In vi, this message translates to:
  /// **'kết nối Wi-Fi'**
  String get devXpSetupLine2;

  /// Ô màn thiết bị (màn hệ thống, display.cpp / XP-SetupMode, XP-OtaProgress)
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt Wi-Fi'**
  String get devXpSetupPower;

  /// Ô màn thiết bị (màn hệ thống, display.cpp / XP-SetupMode, XP-OtaProgress)
  ///
  /// In vi, this message translates to:
  /// **'Đừng tắt hay rút điện máy.'**
  String get devXpOtaWarn;

  /// Ô màn thiết bị (chưa có kênh, xp.cpp drawNoChannels / XP-NoChannels)
  ///
  /// In vi, this message translates to:
  /// **'Chưa có kênh'**
  String get devXpNoChannelsHead;

  /// Ô màn thiết bị (chưa có kênh, xp.cpp drawNoChannels / XP-NoChannels)
  ///
  /// In vi, this message translates to:
  /// **'Bật kênh trên trang web:'**
  String get devXpNoChannelsLine;

  /// Ô màn thiết bị: tiêu đề cửa sổ thẻ agent theo loại (ch_attention windowTitle)
  ///
  /// In vi, this message translates to:
  /// **'Cần duyệt'**
  String get devXpCardApproval;

  /// Ô màn thiết bị: tiêu đề cửa sổ thẻ agent theo loại (ch_attention windowTitle)
  ///
  /// In vi, this message translates to:
  /// **'Lượt bạn'**
  String get devXpCardInput;

  /// Ô màn thiết bị: tiêu đề cửa sổ thẻ agent theo loại (ch_attention windowTitle)
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get devXpCardDone;

  /// Ô màn thiết bị: tiêu đề cửa sổ thẻ agent theo loại (ch_attention windowTitle)
  ///
  /// In vi, this message translates to:
  /// **'Lỗi'**
  String get devXpCardError;

  /// Ô màn thiết bị: tiêu đề cửa sổ thẻ agent theo loại (ch_attention windowTitle)
  ///
  /// In vi, this message translates to:
  /// **'Đang chạy'**
  String get devXpCardProgress;

  /// Ô màn thiết bị: tiêu đề cửa sổ thẻ agent theo loại (ch_attention windowTitle)
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo'**
  String get devXpCardWarning;

  /// Ô màn thiết bị: tiêu đề cửa sổ thẻ agent theo loại (ch_attention windowTitle)
  ///
  /// In vi, this message translates to:
  /// **'Thông tin'**
  String get devXpCardInfo;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{h}G {m}P'**
  String devXpSpanHourMin(int h, int m);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{kind, select, keyBad{khóa lỗi} blocked{bị chặn} maintenance{bảo trì} minor{chập chờn} other{sự cố}}'**
  String devXpMeta(String kind);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'hạn {left}'**
  String devXpMetaExpiring(String left);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Đang tải...'**
  String get devXpLoading;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{kind, select, week{Hạn mức tuần} day{Hạn mức ngày} hours{Phiên {n} giờ} minutes{Phiên {n} phút} other{Hạn mức}}'**
  String devXpWindow(String kind, int n);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{state, select, approval{Cần duyệt} input{Chờ bạn} error{Lỗi} working{Đang chạy} other{Xong}}'**
  String devXpProjState(String state);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hoạt động project'**
  String get devXpNoProject;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{kind, select, claude{khóa} other{token}}'**
  String devXpCredNoun(String kind);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{kind, select, claude{Khóa} other{Token}}'**
  String devXpCredNounCap(String kind);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{kind, select, claude{Khóa Claude} other{Token Codex}}'**
  String devXpCredWho(String kind);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{kind, select, claude{khóa Claude} other{token Codex}}'**
  String devXpCredWhoLower(String kind);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{noun} {state, select, expired{hết hạn} other{bị từ chối}} · {host}'**
  String devXpBanner(String noun, String state, String host);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{state, select, expired{Hết hạn} other{Bị từ chối}} · {host}'**
  String devXpBannerShort(String state, String host);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Bị chặn · {noun} vẫn tốt · thử lại'**
  String devXpBannerBlocked(String noun);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Bị chặn · {noun} vẫn tốt'**
  String devXpBannerBlockedShort(String noun);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{noun} bị từ chối'**
  String devXpCredHeadRejected(String noun);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{host} từ chối {noun}.'**
  String devXpCredRejectedLine(String host, String noun);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Nhập {noun} mới tại:'**
  String devXpCredEnterNew(String noun);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{noun} hết hạn'**
  String devXpCredHeadExpired(String noun);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Hết hạn ngày {date}.'**
  String devXpCredExpiredOn(String date);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Đã hết hạn.'**
  String get devXpCredExpired;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Bị chặn'**
  String get devXpCredHeadBlocked;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{host} chặn máy này.'**
  String devXpCredBlockedLine(String host);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{noun} vẫn tốt.'**
  String devXpCredStillGood(String noun);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Thử lại mỗi 15 phút.'**
  String get devXpCredRetry15;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Chưa có {noun}'**
  String devXpCredHeadNotSet(String noun);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Nhập {noun} tại:'**
  String devXpCredEnter(String noun);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Mất mạng'**
  String get devXpCredHeadOffline;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Không tới được {host}.'**
  String devXpCredUnreachable(String host);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Không tới {host}.'**
  String devXpCredUnreachableShort(String host);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Kiểm tra Wi-Fi.'**
  String get devXpCredCheckWifi;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được'**
  String get devXpCredHeadUpstream;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{host} trả lỗi:'**
  String devXpCredUpstreamLine(String host);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Đang tự động thử lại...'**
  String get devXpCredAutoRetry;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Chưa có {who}'**
  String devXpCredStatusNotSet(String who);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{who} hết hạn'**
  String devXpCredStatusExpired(String who);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{who} bị từ chối'**
  String devXpCredStatusRejected(String who);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{host} chặn máy này'**
  String devXpCredStatusBlocked(String host);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'đặt lại sau'**
  String get devXpResetIn;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'tín dụng'**
  String get devXpCredits;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Đã dùng'**
  String get devXpUsed;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Không có'**
  String get devXpNone;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Đặt lại tuần'**
  String get devXpWeekResets;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lượt'**
  String get devXpNoResets;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'còn {n}'**
  String devXpResetsLeft(int n);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'còn {n} · {span}'**
  String devXpResetsLeftIn(int n, String span);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'còn {n} · đến {date}'**
  String devXpResetsLeftUntil(int n, String date);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'hết sau {span}'**
  String devXpPaceEmpty(String span);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'~{pct}% khi đặt lại'**
  String devXpPaceAtReset(int pct);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Tín dụng Codex còn'**
  String get devXpAiHero;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{kind, select, blocked{Chặn} other{Khóa}}'**
  String devXpAiBad(String kind);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'CL {cl} · CX {cx}'**
  String devXpAiResets(String cl, String cx);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Dùng {name}'**
  String devXpAdviceUse(String name);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'{name} có {n} lượt đặt lại'**
  String devXpAdviceResets(String name, int n);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Cả hai sắp hết'**
  String get devXpAdviceBothLow;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'7 ngày · % hạn mức tuần'**
  String get devXpTrendLabel;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get devXpTrendToday;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Đỉnh {day}'**
  String devXpTrendPeak(String day);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Có {n} / 7 ngày'**
  String devXpTrendHave(int n);

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'Đang thu thập...'**
  String get devXpTrendCollecting;

  /// Ô màn thiết bị (kênh Claude/Codex/AI/Xu hướng, firmware ch_claude/ch_codex/ch_aidash/ch_trend/chrome.cpp)
  ///
  /// In vi, this message translates to:
  /// **'cuối {d}/{m}'**
  String devXpTrendLast(int d, int m);

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

  /// Đầu Start menu, dưới "glimmer"
  ///
  /// In vi, this message translates to:
  /// **'Start · mở chương trình trên thiết bị'**
  String get startSubtitle;

  /// Nhãn đọc màn hình nút / bảng Start
  ///
  /// In vi, this message translates to:
  /// **'Start'**
  String get startA11y;

  /// Dòng phụ Claude trong Start
  ///
  /// In vi, this message translates to:
  /// **'mức dùng, project'**
  String get startClaudeSub;

  /// Dòng phụ Codex trong Start
  ///
  /// In vi, this message translates to:
  /// **'mức dùng'**
  String get startCodexSub;

  /// Start, cột phải
  ///
  /// In vi, this message translates to:
  /// **'Desktop'**
  String get startDesktop;

  /// Start, cột phải → màn Số liệu
  ///
  /// In vi, this message translates to:
  /// **'Số liệu'**
  String get startDetails;

  /// Start, cột phải → Cài đặt
  ///
  /// In vi, this message translates to:
  /// **'Bảng điều khiển'**
  String get startControlPanel;

  /// Dòng phụ
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get startControlPanelSub;

  /// Start, cột phải → Skill
  ///
  /// In vi, this message translates to:
  /// **'Thêm / gỡ'**
  String get startAddRemove;

  /// Dòng phụ
  ///
  /// In vi, this message translates to:
  /// **'chương trình · Skill'**
  String get startAddRemoveSub;

  /// Start, cột phải → Thiết bị
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị'**
  String get startDevice;

  /// Dòng phụ
  ///
  /// In vi, this message translates to:
  /// **'firmware, sao lưu'**
  String get startDeviceSub;

  /// Hàng cuối Start → bảng Tất cả chương trình
  ///
  /// In vi, this message translates to:
  /// **'Tất cả chương trình'**
  String get startAllPrograms;

  /// Chân Start (amber)
  ///
  /// In vi, this message translates to:
  /// **'Tắt màn'**
  String get startTurnOff;

  /// Chân Start (coral) → POST /api/reboot
  ///
  /// In vi, this message translates to:
  /// **'Khởi động lại'**
  String get startRestart;

  /// Tiêu đề bảng
  ///
  /// In vi, this message translates to:
  /// **'Tất cả chương trình'**
  String get allProgramsTitle;

  /// Nút quay lại
  ///
  /// In vi, this message translates to:
  /// **'Về Start'**
  String get allProgramsBackA11y;

  /// Nhóm
  ///
  /// In vi, this message translates to:
  /// **'AGENT'**
  String get allProgramsGroupAgent;

  /// Nhóm
  ///
  /// In vi, this message translates to:
  /// **'THỜI TIẾT · ĐỒNG HỒ · ẢNH'**
  String get allProgramsGroupOther;

  /// Nhóm
  ///
  /// In vi, this message translates to:
  /// **'HỆ THỐNG'**
  String get allProgramsGroupSystem;

  /// Chú thích chấm mint
  ///
  /// In vi, this message translates to:
  /// **'● = đang mở'**
  String get allProgramsOpenLegend;

  /// Hàng cuối bảng → Skill
  ///
  /// In vi, this message translates to:
  /// **'Thêm / gỡ chương trình'**
  String get allProgramsAddRemove;

  /// Dòng phụ
  ///
  /// In vi, this message translates to:
  /// **'bật skill mới: {names} sắp có'**
  String allProgramsAddRemoveSub(String names);

  /// Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Claude'**
  String get appClaude;

  /// Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Codex'**
  String get appCodex;

  /// Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'AI'**
  String get appAi;

  /// Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Xu hướng'**
  String get appTrend;

  /// Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Agents'**
  String get appAgents;

  /// Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Ảnh'**
  String get appPhoto;

  /// Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Thời tiết'**
  String get appWeather;

  /// Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Dự báo'**
  String get appForecast;

  /// Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Đồng hồ'**
  String get appClock;

  /// Tên chương trình
  ///
  /// In vi, this message translates to:
  /// **'Thông tin'**
  String get appInfo;

  /// Tên chương trình (skill sắp có)
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn'**
  String get appChat;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['vi'].contains(locale.languageCode);

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
