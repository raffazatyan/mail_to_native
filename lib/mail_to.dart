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
  ///
  /// With no mail app installed it shows a one-button alert ([emptyMessage] +
  /// [okLabel]) and returns `null` — callers need no empty-list branch. Pass
  /// `showEmptyAlert: false` to suppress it and just get `null`.
  static Future<MailApp?> pickApp({
    String? title,
    String? cancelLabel,
    String? emptyMessage,
    String? okLabel,
    bool showEmptyAlert = true,
  }) => MailToPlatform.instance.pickApp(
    title: title,
    cancelLabel: cancelLabel,
    emptyMessage: emptyMessage,
    okLabel: okLabel,
    showEmptyAlert: showEmptyAlert,
  );

  /// Picks a mail app and composes in one step.
  ///
  /// Skips the dialog when exactly one app is installed, and shows the
  /// "no mail app" alert when none is. Returns `false` when nothing was
  /// composed.
  static Future<bool> pickAndCompose(
    MailMessage message, {
    String? dialogTitle,
    String? cancelLabel,
    String? emptyMessage,
    String? okLabel,
    bool showEmptyAlert = true,
  }) async {
    final apps = await installedApps();

    final app = apps.length == 1
        ? apps.first
        : await pickApp(
            title: dialogTitle,
            cancelLabel: cancelLabel,
            emptyMessage: emptyMessage,
            okLabel: okLabel,
            showEmptyAlert: showEmptyAlert,
          );
    if (app == null) {
      return false;
    }

    return compose(message, app: app);
  }
}
