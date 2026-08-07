import 'mail_to_platform_interface.dart';
import 'src/mail_app.dart';
import 'src/mail_message.dart';

export 'src/mail_app.dart';
export 'src/mail_message.dart';

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

  /// Shows the OS dialog listing installed mail apps.
  ///
  /// Returns the pick, or `null` when the user dismisses it.
  static Future<MailApp?> pickApp({String? title, String? cancelLabel}) =>
      MailToPlatform.instance.pickApp(
        title: title,
        cancelLabel: cancelLabel,
      );

  /// Picks a mail app and composes in one step.
  ///
  /// Skips the dialog when exactly one app is installed. Returns `false` when
  /// nothing is installed or the user dismissed the dialog.
  static Future<bool> pickAndCompose(
    MailMessage message, {
    String? dialogTitle,
    String? cancelLabel,
  }) async {
    final apps = await installedApps();
    if (apps.isEmpty) {
      return false;
    }

    final app = apps.length == 1
        ? apps.first
        : await pickApp(title: dialogTitle, cancelLabel: cancelLabel);
    if (app == null) {
      return false;
    }

    return compose(message, app: app);
  }
}
