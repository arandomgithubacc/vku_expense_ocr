import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/models/expense_item.dart';
import 'package:vku_expense_ocr/widgets/custom_charts.dart';

void main() {
  testWidgets('shows animated category and weekly charts', (tester) async {
    final today = DateTime.now();
    final expenses = [
      ExpenseItem(
        merchant: 'VKU Cafe',
        amount: 50000,
        date: today,
        category: 'Food',
      ),
      ExpenseItem(
        merchant: 'Book shop',
        amount: 120000,
        date: today.subtract(const Duration(days: 1)),
        category: 'Study',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ExpenseChart(expenses: expenses)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chi tiêu theo danh mục'), findsOneWidget);
    expect(find.text('Chi tiêu trong tuần'), findsOneWidget);
    expect(find.textContaining('Food'), findsOneWidget);
    expect(find.textContaining('Study'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
