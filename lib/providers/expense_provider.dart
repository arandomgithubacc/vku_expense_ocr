import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/expense_item.dart';
import '../services/database_helper.dart';

final databaseHelperProvider = Provider<DatabaseHelper>(
  (ref) => DatabaseHelper.instance,
);

final expenseProvider =
    AsyncNotifierProvider<ExpenseNotifier, List<ExpenseItem>>(
      ExpenseNotifier.new,
    );

class ExpenseNotifier extends AsyncNotifier<List<ExpenseItem>> {
  DatabaseHelper get _database => ref.read(databaseHelperProvider);

  @override
  Future<List<ExpenseItem>> build() => _database.getAll();

  Future<void> addExpense(ExpenseItem expense) async {
    await _database.insert(expense);
    state = AsyncData(await _database.getAll());
  }

  Future<void> removeExpense(int id) async {
    await _database.delete(id);
    state = AsyncData(await _database.getAll());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_database.getAll);
  }
}
