import 'package:flutter_test/flutter_test.dart';
import 'package:mail_to/mail_to.dart';
import 'package:mail_to/mail_to_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakeMailToPlatform extends MailToPlatform with MockPlatformInterfaceMixin {
  FakeMailToPlatform({this.apps = const [], this.pick});

  List<MailApp> apps;
  MailApp? pick;

  int pickAppCalls = 0;
  MailApp? composedWith;
  MailMessage? composedMessage;

  @override
  Future<List<MailApp>> installedApps() async => apps;

  @override
  Future<bool> compose(MailMessage message, {MailApp? app}) async {
    composedWith = app;
    composedMessage = message;
    return true;
  }

  @override
  Future<MailApp?> pickApp({
    String? title,
    String? cancelLabel,
    String? emptyMessage,
    String? okLabel,
    bool showEmptyAlert = true,
  }) async {
    pickAppCalls++;
    return pick;
  }
}

void main() {
  const gmail = MailApp(id: 'gmail', name: 'Gmail');
  const appleMail = MailApp(
    id: 'apple_mail',
    name: 'Apple Mail',
    usesNativeComposer: true,
  );
  const message = MailMessage(subject: 'Subject', body: 'Body');

  group('MailTo', () {
    late FakeMailToPlatform platform;

    setUp(() {
      platform = FakeMailToPlatform();
      MailToPlatform.instance = platform;
    });

    test('should return the installed apps reported by the platform', () async {
      platform.apps = [appleMail, gmail];

      expect(await MailTo.installedApps(), [appleMail, gmail]);
    });

    test('should compose without a dialog when one app is installed', () async {
      platform.apps = [gmail];

      final isComposed = await MailTo.pickAndCompose(message);

      expect(isComposed, isTrue);
      expect(platform.pickAppCalls, 0);
      expect(platform.composedWith, gmail);
      expect(platform.composedMessage, message);
    });

    test('should ask for a pick when several apps are installed', () async {
      platform
        ..apps = [appleMail, gmail]
        ..pick = gmail;

      final isComposed = await MailTo.pickAndCompose(message);

      expect(isComposed, isTrue);
      expect(platform.pickAppCalls, 1);
      expect(platform.composedWith, gmail);
    });

    test('should not compose when the dialog is dismissed', () async {
      platform
        ..apps = [appleMail, gmail]
        ..pick = null;

      final isComposed = await MailTo.pickAndCompose(message);

      expect(isComposed, isFalse);
      expect(platform.composedWith, isNull);
    });

    test('should defer the empty case to the native alert', () async {
      platform
        ..apps = const []
        ..pick = null;

      final isComposed = await MailTo.pickAndCompose(message);

      expect(isComposed, isFalse);
      // pickApp is still called: the platform side owns the "no mail app"
      // alert, so callers need no branch of their own.
      expect(platform.pickAppCalls, 1);
      expect(platform.composedWith, isNull);
    });
  });

  group('MailMessage', () {
    test('should serialize every field for the platform channel', () {
      const message = MailMessage(
        subject: 'Subject',
        body: 'Body',
        to: ['a@example.com'],
        cc: ['b@example.com'],
        bcc: ['c@example.com'],
        isHtml: true,
      );

      expect(message.toMap(), {
        'subject': 'Subject',
        'body': 'Body',
        'to': ['a@example.com'],
        'cc': ['b@example.com'],
        'bcc': ['c@example.com'],
        'isHtml': true,
      });
    });
  });

  group('MailApp', () {
    test('should decode a platform map, defaulting the native flag', () {
      final app = MailApp.fromMap({'id': 'gmail', 'name': 'Gmail'});

      expect(app.id, 'gmail');
      expect(app.name, 'Gmail');
      expect(app.usesNativeComposer, isFalse);
    });
  });
}
