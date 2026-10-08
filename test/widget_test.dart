// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vku_expense_ocr/main.dart';

void main() {
  testWidgets('Home navigates to scan screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.text('Chi tiêu VKU'), findsOneWidget);

    await tester.tap(find.byTooltip('Quét hóa đơn'));
    await tester.pumpAndSettle();

    expect(find.text('Chụp ảnh hóa đơn'), findsOneWidget);
    expect(find.text('Chọn từ thư viện'), findsOneWidget);
  });
}
