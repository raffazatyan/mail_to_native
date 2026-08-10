import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mail_to_native_method_channel.dart';
import 'src/mail_app.dart';
import 'src/mail_message.dart';
import 'src/share_metadata.dart';

abstract class MailToPlatform extends PlatformInterface {
  MailToPlatform() : super(token: _token);

  static final Object _token = Object();

  static MailToPlatform _instance = MethodChannelMailTo();

  static MailToPlatform get instance => _instance;

  static set instance(MailToPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Mail apps installed on the device.
  Future<List<MailApp>> installedApps() {
    throw UnimplementedError('installedApps() has not been implemented.');
  }

  /// Opens [app]'s compose screen prefilled with [message].
  ///
  /// Passing `null` for [app] hands the message to the platform default.
  Future<bool> compose(MailMessage message, {MailApp? app}) {
    throw UnimplementedError('compose() has not been implemented.');
  }

  /// Shows the OS dialog listing installed mail apps and returns the pick,
  /// or `null` when dismissed or when nothing is installed.
  Future<MailApp?> pickApp({
    String? title,
    String? cancelLabel,
    String? emptyMessage,
    String? okLabel,
    String? otherAppsLabel,
    bool showEmptyAlert = true,
    bool showOtherApps = true,
  }) {
    throw UnimplementedError('pickApp() has not been implemented.');
  }

  /// Opens the system share sheet with [message].
  Future<bool> share(MailMessage message, {ShareMetadata? metadata}) {
    throw UnimplementedError('share() has not been implemented.');
  }
}
