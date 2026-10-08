import '../models/expense_item.dart';

class ReceiptParser {
  static final _datePattern = RegExp(r'\b(\d{2})[/-](\d{2})[/-](\d{4})\b');
  static final _amountPattern = RegExp(
    r'(?<![\d/.-])(?:\d{1,3}(?:[.,]\d{3})+|\d+)(?:[.,]\d{1,2})?(?![\d/.-])\s*(?:VND|VNĐ|đ)?',
    caseSensitive: false,
  );
  static final _totalLabelPattern = RegExp(
    r'\b(total|grand\s+total|amount\s+due|tổng\s+cộng|thanh\s+toán|phải\s+trả)\b',
    caseSensitive: false,
  );

  ExpenseItem parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    return ExpenseItem(
      merchant: lines.isEmpty ? 'Chưa xác định' : lines.first,
      amount: _findAmount(rawText) ?? 0,
      date: _findDate(rawText) ?? DateTime.now(),
    );
  }

  double? _findAmount(String rawText) {
    final textWithoutDates = rawText.replaceAll(_datePattern, ' ');
    final lines = textWithoutDates.split(RegExp(r'\r?\n'));

    for (final line in lines.reversed) {
      if (_totalLabelPattern.hasMatch(line)) {
        final match = _amountPattern.firstMatch(line);
        if (match != null) return _parseAmount(match.group(0)!);
      }
    }

    final matches = _amountPattern.allMatches(textWithoutDates).toList();
    if (matches.isEmpty) return null;

    final currencyMatch = matches.lastWhere(
      (match) => RegExp(r'(?:VND|VNĐ|đ)\s*$', caseSensitive: false)
          .hasMatch(match.group(0)!),
      orElse: () => matches.last,
    );
    return _parseAmount(currencyMatch.group(0)!);
  }

  double? _parseAmount(String value) {
    final numericValue = value
        .replaceAll(RegExp(r'\s*(?:VND|VNĐ|đ)\s*$', caseSensitive: false), '')
        .replaceAll(' ', '');
    final lastSeparator = numericValue.lastIndexOf(RegExp('[.,]'));
    if (lastSeparator == -1) return double.tryParse(numericValue);

    final separator = numericValue[lastSeparator];
    final digitsAfterSeparator = numericValue.length - lastSeparator - 1;
    if (digitsAfterSeparator == 3) {
      return double.tryParse(numericValue.replaceAll(RegExp('[.,]'), ''));
    }

    final normalized = numericValue
        .replaceAll(separator == '.' ? ',' : '.', '')
        .replaceAll(separator, '.');
    return double.tryParse(normalized);
  }

  DateTime? _findDate(String rawText) {
    final match = _datePattern.firstMatch(rawText);
    if (match == null) return null;

    final day = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }
}
