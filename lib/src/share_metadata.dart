
import 'package:flutter/foundation.dart';

/// Header shown above the app grid in the system share sheet.
///
/// Without it iOS falls back to the host app's icon and no title, because a
/// plain text item carries no preview. Supplying this fills in the
/// `LPLinkMetadata` header — icon, bold title, grey subtitle.
///
/// Android shows [title] in the chooser preview; [subtitle] and [icon] are
/// iOS-only.
@immutable
class ShareMetadata {
  const ShareMetadata({this.title, this.subtitle, this.icon, this.image});

  /// Bold first line. Falls back to the message subject when null.
  final String? title;

  /// Grey second line — iOS renders it where a shared link would show its
  /// domain.
  ///
  /// Ignored unless [icon] or [image] is supplied: iOS treats an item with a
  /// subtitle as a file and swaps the tile for a generic document glyph, so
  /// without artwork the host app's icon is the better trade. iOS only.
  final String? subtitle;

  /// PNG or JPEG bytes for the thumbnail.
  ///
  /// Leave it null — iOS then draws the host app's icon full-bleed, which is
  /// what you want in almost every case. Supplying artwork makes
  /// LinkPresentation aspect-fit it into a white tile. Falls back to [image]
  /// when one is given. iOS only.
  final Uint8List? icon;

  /// PNG bytes shared as a picture alongside the text — a rendered card, a
  /// screenshot, a chart.
  ///
  /// Recipients get an image: an attachment in mail, a photo in messengers.
  /// Also becomes the sheet's preview thumbnail unless [icon] overrides it.
  final Uint8List? image;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareMetadata &&
          other.title == title &&
          other.subtitle == subtitle &&
          other.icon == icon &&
          other.image == image;

  @override
  int get hashCode => Object.hash(title, subtitle, icon, image);

  Map<String, Object?> toMap() => {
    'title': title,
    'subtitle': subtitle,
    'icon': icon,
    'image': image,
  };
}
