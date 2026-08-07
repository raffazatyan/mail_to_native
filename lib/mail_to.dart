import 'mail_to_platform_interface.dart';
import 'src/mail_app.dart';
import 'src/mail_message.dart';
import 'src/share_metadata.dart';

export 'src/mail_app.dart';
export 'src/mail_message.dart';
export 'src/share_metadata.dart';

/// Opens a mail app's compose screen with the message prefilled.
///
/// ```dart
/// const message = MailMessage(subject: 'Notes', body: 'Hello');
///
/// // Let the user choose in a native dialog, then compose.
/// await MailTo.pickAndCompose(message);
///
/// // Or drive the list yourself.
/// final apps = await MailTo.installedApps();
/// await MailTo.compose(message, app: apps.first);
/// ```
///
/// iOS detection only sees apps whose schemes are declared in
/// `LSApplicationQueriesSchemes` — see the README for the snippet.
abstract final class MailTo {
  /// Mail apps installed on the device, in a stable order.
  ///
  /// Empty when none are installed. On iOS, Apple Mail is reported only when
  /// it has an account configured.
  static Future<List<MailApp>> installedApps() =>
      MailToPlatform.instance.installedApps();

  /// Opens [app]'s compose screen prefilled with [message].
  ///
  /// Omit [app] to hand the message to the platform default handler.
  /// Returns `false` when no app could be opened.
  static Future<bool> compose(MailMessage message, {MailApp? app}) =>
      MailToPlatform.instance.compose(message, app: app);

  /// Opens the system share sheet with [message] — every app that accepts
  /// text, not just mail clients.
  ///
  /// `UIActivityViewController` on iOS, `ACTION_SEND` chooser on Android.
  /// Pass [metadata] to fill the sheet's header — icon, title, subtitle.
  /// Returns `false` when the sheet could not be presented.
  static Future<bool> share(MailMessage message, {ShareMetadata? metadata}) =>
      MailToPlatform.instance.share(message, metadata: metadata);

  /// Shows the OS dialog listing installed mail apps.
  ///
  /// Returns the pick, or `null` when the user dismisses it. A pick with
  /// [MailApp.isOther] means the user chose "other apps" — hand the message to
  /// [share]; [pickAndCompose] does that for you.
  ///
  /// The dialog always appears, even with a single app installed, so the user
  /// can still reach the "other apps" entry.
  ///
  /// With no mail app installed it shows [emptyMessage] with an [okLabel]
  /// button (plus "other apps") and returns `null` — callers need no
  /// empty-list branch. Pass `showEmptyAlert: false` to suppress it and just
  /// get `null`, or `showOtherApps: false` to drop the share entry.
  static Future<MailApp?> pickApp({
    String? title,
    String? cancelLabel,
    String? emptyMessage,
    String? okLabel,
    String? otherAppsLabel,
    bool showEmptyAlert = true,
    bool showOtherApps = true,
  }) => MailToPlatform.instance.pickApp(
    title: title,
    cancelLabel: cancelLabel,
    emptyMessage: emptyMessage,
    okLabel: okLabel,
    otherAppsLabel: otherAppsLabel,
    showEmptyAlert: showEmptyAlert,
    showOtherApps: showOtherApps,
  );

  /// Picks a mail app and composes in one step.
  ///
  /// The dialog is always shown — no auto-select on a single app — and
  /// "other apps" routes to the system share sheet, whose header is filled
  /// from [shareMetadata]. Returns `false` when nothing was composed or
  /// shared.
  static Future<bool> pickAndCompose(
    MailMessage message, {
    String? dialogTitle,
    String? cancelLabel,
    String? emptyMessage,
    String? okLabel,
    String? otherAppsLabel,
    bool showEmptyAlert = true,
    bool showOtherApps = true,
    ShareMetadata? shareMetadata,
  }) async {
    final app = await pickApp(
      title: dialogTitle,
      cancelLabel: cancelLabel,
      emptyMessage: emptyMessage,
      okLabel: okLabel,
      otherAppsLabel: otherAppsLabel,
      showEmptyAlert: showEmptyAlert,
      showOtherApps: showOtherApps,
    );
    if (app == null) {
      return false;
    }

    return app.isOther
        ? share(message, metadata: shareMetadata)
        : compose(message, app: app);
  }
}
