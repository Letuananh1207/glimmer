/// Why something failed. The UI turns [AppError.kind] into words (l10n) — no user-facing text here.
enum AppErrorKind {
  /// The device asked for an API token (HTTP 401).
  unauthorized,

  /// The device answered with an HTTP error ([AppError.status]).
  http,

  /// No answer (timeout / unreachable); [AppError.detail] = the low-level error.
  unreachable,

  /// OTA upload rejected; [AppError.detail] = the device's answer.
  flashFailed,

  /// GitHub rate limit (HTTP 403 on the releases API).
  rateLimited,

  /// GitHub releases API answered [AppError.status].
  releaseHttp,

  /// Downloading a release asset failed ([AppError.status], 0 = network).
  download,

  /// The release has no asset named [AppError.detail].
  noAsset,

  /// Discovery found no display on this network.
  notFound,

  /// Nothing answered at the typed address [AppError.detail].
  noDeviceAt,

  /// Location / nearby-Wi-Fi permission refused.
  wifiPermission,

  /// Could not join or reach the setup AP "glimmer-setup".
  setupAp,

  /// The device did not show up on Wi-Fi [AppError.detail] after the change.
  notOnNetwork,

  /// The device did not answer after flashing the firmware.
  noAnswerAfterFlash,

  /// The device's config could not be read for a backup.
  configUnreadable,

  /// The picked file is not a glimmer config; [AppError.detail] = parser message.
  invalidBackup,

  /// The device's firmware cannot switch skills, or does not have skill [AppError.detail] (R-SK-4).
  skillUnsupported,

  /// Anything else; [AppError.detail] = the error.
  other,
}

class AppError implements Exception {
  const AppError(this.kind, {this.status = 0, this.detail = ''});

  /// Wraps anything thrown into an [AppError] (an [AppError] passes through).
  factory AppError.from(Object e) => e is AppError ? e : AppError(AppErrorKind.other, detail: '$e');

  final AppErrorKind kind;
  final int status;
  final String detail;

  @override
  String toString() => 'AppError(${kind.name}, $status, $detail)';
}
