import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../providers/expense_provider.dart';
import '../widgets/custom_charts.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(expenseProvider);
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiêu VKU')),
      body: expenses.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 12),
                Text('Không thể tải khoản chi: $error'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => ref.read(expenseProvider.notifier).refresh(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          ),
        ),
        data: (items) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.isEmpty ? 1 : items.length + 1,
          itemBuilder: (context, index) {
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 80),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa có giao dịch nào',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('Quét hóa đơn đầu tiên để theo dõi chi tiêu.'),
                  ],
                ),
              );
            }
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ExpenseChart(expenses: items),
              );
            }

            final expense = items[index - 1];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.secondaryContainer,
                  child: Icon(
                    _categoryIcon(expense.category),
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
                title: Text(expense.merchant),
                subtitle: Text(
                  '${expense.category} • '
                  '${DateFormat('dd/MM/yyyy', 'vi_VN').format(expense.date)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currencyFormat.format(expense.amount),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (expense.id != null)
                      IconButton(
                        tooltip: 'Xóa giao dịch',
                        onPressed: () => ref
                            .read(expenseProvider.notifier)
                            .removeExpense(expense.id!),
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/scan'),
        tooltip: 'Quét hóa đơn',
        child: const Icon(Icons.document_scanner_outlined),
      ),
    );
  }

  IconData _categoryIcon(String category) => switch (category) {
    'Food' => Icons.restaurant_outlined,
    'Study' => Icons.menu_book_outlined,
    'Travel' => Icons.directions_bus_outlined,
    'Gear' => Icons.devices_outlined,
    'Entertainment' => Icons.movie_outlined,
    _ => Icons.receipt_outlined,
  };
}
