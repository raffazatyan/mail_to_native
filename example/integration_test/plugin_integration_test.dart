import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mail_to/mail_to.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('installedApps returns without throwing', (tester) async {
    final apps = await MailTo.installedApps();

    // The device may have no mail app at all, so only the shape is asserted.
    for (final app in apps) {
      expect(app.id, isNotEmpty);
      expect(app.name, isNotEmpty);
    }
  });
}
