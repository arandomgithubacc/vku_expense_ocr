import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../models/expense_item.dart';
import '../routes/app_router.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _imagePicker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (!mounted || image == null) return;

      setState(() => _isProcessing = true);
      final ocrService = OcrService();
      late final String rawText;
      try {
        rawText = await ocrService.recognizeText(image.path);
      } finally {
        await ocrService.close();
      }
      if (!mounted) return;

      final parsedExpense = ReceiptParser().parse(rawText);
      final expense = ExpenseItem(
        merchant: parsedExpense.merchant,
        amount: parsedExpense.amount,
        date: parsedExpense.date,
        category: parsedExpense.category,
        imagePath: image.path,
      );
      await context.push(AppRoutes.review, extra: expense);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể xử lý hóa đơn: $error')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Quét hóa đơn')),
      body: Center(
        child: _isProcessing
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text('Đang nhận diện nội dung hóa đơn...'),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 88,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Thêm hóa đơn của bạn',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Chụp ảnh hoặc chọn ảnh hóa đơn. Thông tin nhận diện '
                      'sẽ được đưa sang màn hình để bạn kiểm tra.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Chụp ảnh hóa đơn'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Chọn từ thư viện'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
