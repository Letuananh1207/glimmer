import 'dart:ui' as ui;

import '../../../../../domain/models/mirror_frame.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/themes/xp_colors.dart';
import '../mirror_channel.dart';
import '../xp_canvas.dart';
import '../xp_paint.dart';

/// Photo — one of the user's photos (`ch_photo.cpp`, XP-Photo / XP-Photo-Empty): window "Ảnh · 2/5" (photo
/// icon), the 188×188 photo at (26, 24) on the beige body. None on the device → the empty window (photo icon ×3
/// muted at (96, 52), "Chưa có ảnh", how to send one).
///
/// The device cannot send its photos back: [image] is the app's own copy of the photo it sent (decoded by the
/// ControlViewModel); without one the photo's place is a neutral field with the photo icon.
class PhotoChannel extends MirrorChannel {
  const PhotoChannel({this.image});

  final ui.Image? image;

  static const _x = 26, _y = 24, _side = 188, _mid = 120;

  void _empty(XpCanvas c, AppLocalizations l) {
    Xp.drawIcon(c, XpIcon.photo, 96, 52, XpColors.emptyIcon, scale: 3);
    c.text(l.devXpPhotoEmpty, _mid, 100, XpFont.jb16b, XpColors.muted, align: XpAlign.center);
    c.text(l.devXpPhotoSend, _mid, 128, XpFont.jb11, XpColors.black, align: XpAlign.center);
    c.text(l.devXpPhotoOr, _mid, 146, XpFont.jb11, XpColors.muted, align: XpAlign.center);
    c.text('glimmer.local', _mid, 163, XpFont.jb12b, XpColors.link, align: XpAlign.center);
  }

  @override
  void paint(XpCanvas c, MirrorFrame f, AppLocalizations l) {
    final p = f.agents.photo;
    if (p.empty) {
      Xp.window(c, l.devXpTitlePhoto, icon: XpIcon.photo);
      _empty(c, l);
      return;
    }
    Xp.window(c, l.devXpTitlePhoto, icon: XpIcon.photo, meta: '${p.index + 1}/${p.count}');
    final img = p.jpeg == null ? null : image;
    if (img != null) {
      c.image(img, _x, _y, _side, _side);
      return;
    }
    Xp.field(c, _x, _y, _side, _side);
    Xp.drawIcon(c, XpIcon.photo, _mid - 24, _y + _side ~/ 2 - 16, XpColors.emptyIcon, scale: 3);
  }
}

/// [channels] with the Photo painter drawing [image] (the app's copy of the shown photo); unchanged when null.
Map<String, MirrorChannel> withPhoto(Map<String, MirrorChannel> channels, ui.Image? image) =>
    image == null ? channels : {...channels, 'Photo': PhotoChannel(image: image)};
