import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/expense_item.dart';
import '../providers/expense_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, this.expense});

  final ExpenseItem? expense;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchantController;
  late final TextEditingController _amountController;
  late final TextEditingController _dateController;
  late String _category;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _merchantController = TextEditingController(
      text: expense?.merchant ?? '',
    );
    _amountController = TextEditingController(
      text: expense == null ? '' : _formatAmount(expense.amount),
    );
    _dateController = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(expense?.date ?? DateTime.now()),
    );
    _category = ExpenseItem.categories.contains(expense?.category)
        ? expense!.category
        : ExpenseItem.categories.first;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) =>
      amount == amount.roundToDouble()
      ? amount.toStringAsFixed(0)
      : amount.toString();

  DateTime? _parseDate(String value) {
    final match = RegExp(r'^(\d{2})[/-](\d{2})[/-](\d{4})$')
        .firstMatch(value.trim());
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

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    final date = _parseDate(_dateController.text)!;
    final amount = double.parse(
      _amountController.text.trim().replaceAll(',', '.'),
    );
    final expense = ExpenseItem(
      merchant: _merchantController.text.trim(),
      amount: amount,
      date: date,
      category: _category,
      imagePath: widget.expense?.imagePath,
    );

    setState(() => _isSaving = true);
    try {
      await ref.read(expenseProvider.notifier).addExpense(expense);
      if (mounted) context.go('/');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu giao dịch: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kiểm tra hóa đơn')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (widget.expense?.imagePath case final imagePath?)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(imagePath),
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    color: colorScheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const Text('Không thể hiển thị ảnh hóa đơn'),
                  ),
                ),
              ),
            if (widget.expense?.imagePath != null)
              const SizedBox(height: 20),
            Text(
              'Thông tin giao dịch',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _merchantController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Tên cửa hàng',
                prefixIcon: Icon(Icons.store_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập tên cửa hàng'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Số tiền',
                suffixText: '₫',
                prefixIcon: Icon(Icons.payments_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = double.tryParse(
                  (value ?? '').trim().replaceAll(',', '.'),
                );
                if (amount == null || amount <= 0) {
                  return 'Vui lòng nhập số tiền hợp lệ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _dateController,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Ngày tháng',
                hintText: 'DD/MM/YYYY',
                prefixIcon: Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (value) => _parseDate(value ?? '') == null
                  ? 'Nhập ngày hợp lệ theo định dạng DD/MM/YYYY'
                  : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Danh mục',
                prefixIcon: Icon(Icons.category_outlined),
                border: OutlineInputBorder(),
              ),
              items: [
                for (final category in ExpenseItem.categories)
                  DropdownMenuItem(value: category, child: Text(category)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveExpense,
              icon: _isSaving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Đang lưu...' : 'Lưu giao dịch'),
            ),
          ],
        ),
      ),
    );
  }
}
