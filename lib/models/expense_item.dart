class ExpenseItem {
  const ExpenseItem({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    this.category = 'Food',
    this.imagePath,
  });

  static const categories = [
    'Food',
    'Study',
    'Travel',
    'Gear',
    'Entertainment',
  ];

  final int? id;
  final String merchant;
  final double amount;
  final DateTime date;
  final String category;
  final String? imagePath;

  Map<String, Object?> toMap() => {
    'id': id,
    'merchant': merchant,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category,
    'image_path': imagePath,
  };

  factory ExpenseItem.fromMap(Map<String, Object?> map) => ExpenseItem(
    id: map['id'] as int?,
    merchant: map['merchant'] as String,
    amount: (map['amount'] as num).toDouble(),
    date: DateTime.parse(map['date'] as String),
    category: map['category'] as String? ?? 'Food',
    imagePath: map['image_path'] as String?,
  );
}
