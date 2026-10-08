import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_ocr/services/receipt_parser.dart';

void main() {
  final parser = ReceiptParser();

  for (final sample in [
    ('150,000 VND', 150000.0),
    ('150.000 đ', 150000.0),
    ('150000', 150000.0),
  ]) {
    test('parses amount from ${sample.$1}', () {
      final expense = parser.parse('Cafe VKU\n${sample.$1}');

      expect(expense.amount, sample.$2);
      expect(expense.merchant, 'Cafe VKU');
    });
  }

  test('parses slash-separated date', () {
    final expense = parser.parse('Cafe VKU\nDate: 09/10/2026\nTotal: 150000');

    expect(expense.date, DateTime(2026, 10, 9));
  });

  test('parses hyphen-separated date and prioritizes total', () {
    final expense = parser.parse(
      'Cafe VKU\n09-10-2026\nItem: 25000\nTotal: 150,000 VND',
    );

    expect(expense.date, DateTime(2026, 10, 9));
    expect(expense.amount, 150000);
  });
}
