import 'package:flutter_test/flutter_test.dart';
import 'package:bin_tag_app/main.dart';

void main() {
  testWidgets('Shows default text', (WidgetTester tester) async {
    await tester.pumpWidget(const NfcReaderApp());
    expect(find.text('Scan an NFC tag'), findsOneWidget);
  });
}
