import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import '../models/expense_item.dart';

const _categoryColors = <String, Color>{
  'Food': Color(0xFFE58A3A),
  'Study': Color(0xFF5478B8),
  'Travel': Color(0xFF43A68B),
  'Gear': Color(0xFF9A72C7),
  'Entertainment': Color(0xFFE16B78),
};

class ExpenseChart extends StatelessWidget {
  const ExpenseChart({super.key, required this.expenses});

  final List<ExpenseItem> expenses;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CategoryDonutChart(expenses: expenses),
        const SizedBox(height: 12),
        WeeklyBarChart(expenses: expenses),
      ],
    );
  }
}

class CategoryDonutChart extends StatefulWidget {
  const CategoryDonutChart({super.key, required this.expenses});

  final List<ExpenseItem> expenses;

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant CategoryDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenses != widget.expenses) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totals = {
      for (final category in ExpenseItem.categories)
        category: widget.expenses
            .where((expense) => expense.category == category)
            .fold<double>(0, (sum, expense) => sum + expense.amount),
    };
    final total = totals.values.fold<double>(0, (sum, amount) => sum + amount);
    final values = [
      for (final category in ExpenseItem.categories) totals[category]!,
    ];
    final colors = [
      for (final category in ExpenseItem.categories) _categoryColors[category]!,
    ];
    final currencyFormat = intl.NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiêu theo danh mục',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => SizedBox(
                height: 184,
                width: double.infinity,
                child: CustomPaint(
                  painter: _DonutChartPainter(
                    values: values,
                    colors: colors,
                    progress: Curves.easeOutCubic.transform(_controller.value),
                    trackColor: colorScheme.surfaceContainerHighest,
                    centerText: currencyFormat.format(total),
                    centerLabel: 'Tổng chi tiêu',
                    textStyle: Theme.of(context).textTheme.titleMedium,
                    labelStyle: Theme.of(context).textTheme.bodySmall,
                    textDirection: Directionality.of(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                for (
                  var index = 0;
                  index < ExpenseItem.categories.length;
                  index++
                )
                  _CategoryLegendItem(
                    color: colors[index],
                    category: ExpenseItem.categories[index],
                    percentage: total == 0 ? 0 : values[index] / total * 100,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryLegendItem extends StatelessWidget {
  const _CategoryLegendItem({
    required this.color,
    required this.category,
    required this.percentage,
  });

  final Color color;
  final String category;
  final double percentage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$category ${percentage.toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({
    required this.values,
    required this.colors,
    required this.progress,
    required this.trackColor,
    required this.centerText,
    required this.centerLabel,
    required this.textStyle,
    required this.labelStyle,
    required this.textDirection,
  });

  final List<double> values;
  final List<Color> colors;
  final double progress;
  final Color trackColor;
  final String centerText;
  final String centerLabel;
  final TextStyle? textStyle;
  final TextStyle? labelStyle;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final diameter = math.min(size.height - 12, size.width * 0.58);
    final strokeWidth = math.max(14.0, diameter * 0.12);
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(
      center: center,
      radius: (diameter - strokeWidth) / 2,
    );
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    final total = values.fold<double>(0, (sum, value) => sum + value);
    if (total > 0) {
      var startAngle = -math.pi / 2;
      for (var index = 0; index < values.length; index++) {
        final sweepAngle = math.pi * 2 * values[index] / total * progress;
        if (sweepAngle > 0) {
          final segmentPaint = Paint()
            ..color = colors[index]
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..strokeCap = StrokeCap.butt;
          canvas.drawArc(rect, startAngle, sweepAngle, false, segmentPaint);
        }
        startAngle += math.pi * 2 * values[index] / total * progress;
      }
    }

    _paintCenteredText(
      canvas,
      center,
      centerText,
      textStyle?.copyWith(fontWeight: FontWeight.bold),
      -8,
    );
    _paintCenteredText(canvas, center, centerLabel, labelStyle, 14);
  }

  void _paintCenteredText(
    Canvas canvas,
    Offset center,
    String text,
    TextStyle? style,
    double verticalOffset,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: textDirection,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 130);
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + verticalOffset),
    );
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.values != values ||
      oldDelegate.colors != colors ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.centerText != centerText ||
      oldDelegate.centerLabel != centerLabel;
}

class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({super.key, required this.expenses, this.weekStart});

  final List<ExpenseItem> expenses;

  /// Optional Monday used to show a specific week; defaults to this week.
  final DateTime? weekStart;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = weekStart == null
        ? today.subtract(Duration(days: today.weekday - 1))
        : DateTime(
            weekStart!.year,
            weekStart!.month,
            weekStart!.day,
          ).subtract(Duration(days: weekStart!.weekday - 1));
    final values = List<double>.generate(7, (index) {
      final day = monday.add(Duration(days: index));
      return expenses
          .where(
            (expense) =>
                expense.date.year == day.year &&
                expense.date.month == day.month &&
                expense.date.day == day.day,
          )
          .fold<double>(0, (sum, expense) => sum + expense.amount);
    });
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiêu trong tuần',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 190,
              width: double.infinity,
              child: CustomPaint(
                painter: _WeeklyBarChartPainter(
                  values: values,
                  barColor: colorScheme.primary,
                  gridColor: colorScheme.outlineVariant,
                  labelColor: colorScheme.onSurfaceVariant,
                  valueStyle: Theme.of(context).textTheme.labelSmall,
                  dayStyle: Theme.of(context).textTheme.labelSmall,
                  textDirection: Directionality.of(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyBarChartPainter extends CustomPainter {
  const _WeeklyBarChartPainter({
    required this.values,
    required this.barColor,
    required this.gridColor,
    required this.labelColor,
    required this.valueStyle,
    required this.dayStyle,
    required this.textDirection,
  });

  static const _dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  final List<double> values;
  final Color barColor;
  final Color gridColor;
  final Color labelColor;
  final TextStyle? valueStyle;
  final TextStyle? dayStyle;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 8.0;
    const rightPadding = 8.0;
    const topPadding = 20.0;
    const bottomPadding = 26.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    final chartWidth = size.width - leftPadding - rightPadding;
    final maxValue = values.fold<double>(0, math.max);
    final scaleMax = maxValue == 0 ? 1.0 : maxValue;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var line = 0; line <= 3; line++) {
      final y = topPadding + chartHeight * line / 3;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    final slotWidth = chartWidth / values.length;
    final barWidth = math.min(22.0, slotWidth * 0.52);
    final barPaint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;
    final valueFormat = intl.NumberFormat.compact(locale: 'vi_VN');

    for (var index = 0; index < values.length; index++) {
      final barHeight = chartHeight * values[index] / scaleMax;
      final centerX = leftPadding + slotWidth * (index + 0.5);
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth / 2,
          topPadding + chartHeight - barHeight,
          barWidth,
          barHeight,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(barRect, barPaint);

      if (values[index] > 0) {
        _paintLabel(
          canvas,
          valueFormat.format(values[index]),
          Offset(
            centerX,
            math.max(0, topPadding + chartHeight - barHeight - 5),
          ),
          valueStyle?.copyWith(color: labelColor),
          maxWidth: slotWidth,
        );
      }
      _paintLabel(
        canvas,
        _dayLabels[index],
        Offset(centerX, size.height - bottomPadding + 5),
        dayStyle?.copyWith(color: labelColor),
        maxWidth: slotWidth,
      );
    }
  }

  void _paintLabel(
    Canvas canvas,
    String text,
    Offset center,
    TextStyle? style, {
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: textDirection,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, Offset(center.dx - painter.width / 2, center.dy));
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.barColor != barColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.labelColor != labelColor;
}
