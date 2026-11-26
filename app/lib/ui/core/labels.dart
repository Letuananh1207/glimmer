// Words for values that come from the device or the domain layer.
import '../../domain/models/app_error.dart';
import '../../domain/models/device_photo.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/durations.dart';

extension Labels on AppLocalizations {
  /// Project state label.
  String projectState(String s) => switch (s) {
        'approval' => stateApproval,
        'input' => stateInput,
        'error' => stateError,
        'working' => stateWorking,
        _ => stateDone,
      };

  /// Attention card kind label.
  String cardKind(String k) => switch (k) {
        'approval' => stateApproval,
        'input' => stateInput,
        'success' => stateDone,
        'error' => stateError,
        'progress' => cardProgress,
        'warning' => cardWarning,
        _ => cardInfo,
      };

  /// R-DUNG-3: countdown text, null when unknown.
  String? countdown(int? seconds) => seconds == null ? null : (seconds == 0 ? devNow : spanShort(seconds));

  /// "12m trước".
  String ago(int seconds) => commonAgo(agoShort(seconds));

  /// What went wrong, in words.
  String error(AppError e) => switch (e.kind) {
        AppErrorKind.unauthorized => devErrUnauthorized,
        AppErrorKind.http => devErrHttp(e.status),
        AppErrorKind.unreachable => devErrUnreachable(e.detail),
        AppErrorKind.flashFailed => devErrFlashFailed(e.detail),
        AppErrorKind.rateLimited => devErrRateLimited,
        AppErrorKind.releaseHttp => devErrReleaseHttp(e.status),
        AppErrorKind.download => devErrDownload(e.status),
        AppErrorKind.noAsset => devErrNoAsset(e.detail),
        AppErrorKind.notFound => connectNotFound,
        AppErrorKind.noDeviceAt => connectNoDeviceAt(e.detail),
        AppErrorKind.wifiPermission => devErrWifiPermission,
        AppErrorKind.setupAp => devErrSetupAp,
        AppErrorKind.notOnNetwork => wifiNotFound(e.detail),
        AppErrorKind.noAnswerAfterFlash => devErrNoAnswerAfterFlash,
        AppErrorKind.configUnreadable => devErrConfigUnreadable,
        AppErrorKind.invalidBackup => devErrInvalidBackup,
        AppErrorKind.skillUnsupported => devErrSkillUnsupported,
        AppErrorKind.skillLastOne => skillsLastOne,
        AppErrorKind.photoFull => photoCropErrorFullTitle(PhotoInfo.defaultMaxCount),
        AppErrorKind.photoTooBig => photoCropErrorTooBigTitle,
        AppErrorKind.photoNoSpace => photoCropErrorNoSpaceTitle,
        AppErrorKind.photoRejected => photoCropErrorRejectedTitle,
        AppErrorKind.photoNotFound => devErrHttp(e.status),
        AppErrorKind.cancelled => commonCancel,
        AppErrorKind.other => e.detail,
      };
}
