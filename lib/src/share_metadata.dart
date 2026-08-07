
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
  const ShareMetadata({this.title, this.subtitle, this.icon});

  /// Bold first line. Falls back to the message subject when null.
  final String? title;

  /// Grey second line — iOS renders it where a shared link would show its
  /// domain. iOS only.
  final String? subtitle;

  /// PNG or JPEG bytes for the thumbnail. Defaults to the host app's icon.
  /// iOS only.
  final Uint8List? icon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareMetadata &&
          other.title == title &&
          other.subtitle == subtitle &&
          other.icon == icon;

  @override
  int get hashCode => Object.hash(title, subtitle, icon);

  Map<String, Object?> toMap() => {
    'title': title,
    'subtitle': subtitle,
    'icon': icon,
  };
}
