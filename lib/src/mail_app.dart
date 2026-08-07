import 'package:flutter/foundation.dart';

/// A mail app installed on the device.
///
/// [id] is platform-specific: a stable slug on iOS (`apple_mail`, `gmail`,
/// `outlook`, `spark`, `yahoo`) and the application package name on Android
/// (`com.google.android.gm`, …). Pass the whole object back to
/// `MailTo.compose` rather than reconstructing it.
@immutable
class MailApp {
  const MailApp({
    required this.id,
    required this.name,
    this.usesNativeComposer = false,
  });

  factory MailApp.fromMap(Map<Object?, Object?> map) => MailApp(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    usesNativeComposer: map['usesNativeComposer'] as bool? ?? false,
  );

  /// Platform-specific identifier — slug on iOS, package name on Android.
  final String id;

  /// Display name, e.g. `Gmail`. Localized by the OS on Android.
  final String name;

  /// Whether composing opens an in-app sheet instead of switching apps.
  ///
  /// True for Apple Mail, which is driven through
  /// `MFMailComposeViewController`: iOS routes `mailto:` to whichever app the
  /// user set as default, so the scheme cannot target Apple Mail itself.
  final bool usesNativeComposer;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MailApp &&
          other.id == id &&
          other.name == name &&
          other.usesNativeComposer == usesNativeComposer;

  @override
  int get hashCode => Object.hash(id, name, usesNativeComposer);

  @override
  String toString() => 'MailApp(id: $id, name: $name)';
}
