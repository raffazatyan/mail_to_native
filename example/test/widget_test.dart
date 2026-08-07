import 'package:flutter_test/flutter_test.dart';
import 'package:mail_to_example/main.dart';

void main() {
  testWidgets('renders the example page', (tester) async {
    await tester.pumpWidget(const ExampleApp());

    expect(find.text('mail_to'), findsWidgets);
  });
}
