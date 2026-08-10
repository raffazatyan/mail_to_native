import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'mail_to_native_platform_interface.dart';
import 'src/mail_app.dart';
import 'src/mail_message.dart';
import 'src/share_metadata.dart';

/// Method-channel implementation of [MailToPlatform].
class MethodChannelMailTo extends MailToPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('mail_to');

  @override
  Future<List<MailApp>> installedApps() async {
    final apps = await methodChannel.invokeListMethod<Object?>('installedApps');

    return (apps ?? const [])
        .whereType<Map<Object?, Object?>>()
        .map(MailApp.fromMap)
        .where((app) => app.id.isNotEmpty)
        .toList(growable: false);
  }

  @override
  Future<bool> compose(MailMessage message, {MailApp? app}) async {
    final isComposed = await methodChannel.invokeMethod<bool>('compose', {
      'appId': app?.id,
      ...message.toMap(),
    });

    return isComposed ?? false;
  }

  @override
  Future<MailApp?> pickApp({
    String? title,
    String? cancelLabel,
    String? emptyMessage,
    String? okLabel,
    String? otherAppsLabel,
    bool showEmptyAlert = true,
    bool showOtherApps = true,
  }) async {
    final picked = await methodChannel.invokeMapMethod<Object?, Object?>(
      'pickApp',
      {
        'title': title,
        'cancelLabel': cancelLabel,
        'emptyMessage': emptyMessage,
        'okLabel': okLabel,
        'otherAppsLabel': otherAppsLabel,
        'showEmptyAlert': showEmptyAlert,
        'showOtherApps': showOtherApps,
      },
    );

    return picked == null ? null : MailApp.fromMap(picked);
  }

  @override
  Future<bool> share(MailMessage message, {ShareMetadata? metadata}) async {
    final isShared = await methodChannel.invokeMethod<bool>('share', {
      ...message.toMap(),
      'metadata': metadata?.toMap(),
    });

    return isShared ?? false;
  }
}
