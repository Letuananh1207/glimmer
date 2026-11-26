import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';

/// Info (`ch_info.cpp`, XP-Info): a white list box (10, 28) 220×180 split by a rule at x 82, ten rows from y 31 every
/// 17.5 px — muted label at x 16, black value at x 88 (cut to fit x 88…228). No status bar.
class InfoChannel extends MirrorChannel {
  const InfoChannel();

  static const _rows = ['ip', 'ssid', 'rssi', 'up', 'heap', 'block', 'fw', 'channels', 'updated', 'next'];

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    Xp.window(c, l.devXpTitleInfo, icon: XpIcon.info);
    Xp.field(c, 10, 28, 220, 180);
    c.fill(82, 29, 1, 178, XpColors.rowLine);
    final v = f.ambient.info;
    final values = [
      v.ip,
      v.ssid,
      '${v.rssi} dBm',
      l.devXpInfoMinutes(v.upMin),
      l.devXpInfoHeap(v.heapK),
      '${v.blockK}K',
      'v${v.fw}',
      '${v.channelsOn} / ${v.channelsTotal}',
      v.updatedMin == null ? '--' : l.devXpInfoAgo(v.updatedMin!),
      l.devXpInfoNext(v.nextMin),
    ];
    for (var i = 0; i < _rows.length; i++) {
      final y = 31 + (i * 35) ~/ 2;
      c.text(l.devXpInfoLabels(_rows[i]), 16, y, XpFont.jb11, XpColors.muted);
      c.text(values[i], 88, y, XpFont.jb11, XpColors.black, maxWidth: 228.0 - 88);
    }
  }
}
