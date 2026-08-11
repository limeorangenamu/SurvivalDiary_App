import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models.dart';

class MonthlyCompareChart extends StatelessWidget {
  const MonthlyCompareChart({
    super.key,
    required this.items,
    required this.currentLabel,
  });

  final List<MonthlyCompare> items;
  final String currentLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: items
          .map(
            (item) =>
                '${item.label}, 이전 ${Formatters.amount(item.previous)}, $currentLabel ${Formatters.amount(item.current)}',
          )
          .join(', '),
      child: Column(
        children: [
          SizedBox(
            height: 190,
            width: double.infinity,
            child: CustomPaint(painter: _MonthlyComparePainter(items)),
          ),
          const SizedBox(height: 12),
          for (final item in items) ...[
            _CompareAmountRow(item: item, currentLabel: currentLabel),
            if (item != items.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _CompareAmountRow extends StatelessWidget {
  const _CompareAmountRow({required this.item, required this.currentLabel});

  final MonthlyCompare item;
  final String currentLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(item.label, style: AppTextStyles.captionTiny),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _AmountLabel(
            label: '이전',
            amount: item.previous,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _AmountLabel(
            label: currentLabel,
            amount: item.current,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _AmountLabel extends StatelessWidget {
  const _AmountLabel({
    required this.label,
    required this.amount,
    required this.color,
  });

  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$label ${Formatters.amount(amount)}',
              style: AppTextStyles.captionTiny.copyWith(color: color),
            ),
          ),
        ),
      ],
    );
  }
}

class _MonthlyComparePainter extends CustomPainter {
  const _MonthlyComparePainter(this.items);

  final List<MonthlyCompare> items;

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) {
      return;
    }
    const top = 14.0;
    const bottom = 30.0;
    final chartHeight = size.height - top - bottom;
    final maxValue = items
        .expand((item) => [item.previous, item.current])
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final groupWidth = size.width / items.length;
    final barWidth = (groupWidth * 0.22).clamp(10.0, 20.0);

    canvas.drawLine(
      Offset(0, top + chartHeight),
      Offset(size.width, top + chartHeight),
      Paint()
        ..color = AppColors.divider
        ..strokeWidth = 1,
    );

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      final centerX = groupWidth * (index + 0.5);
      final previousHeight = chartHeight * item.previous / maxValue;
      final currentHeight = chartHeight * item.current / maxValue;
      final previousRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - barWidth - 2,
          top + chartHeight - previousHeight,
          barWidth,
          previousHeight,
        ),
        const Radius.circular(5),
      );
      final currentRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + 2,
          top + chartHeight - currentHeight,
          barWidth,
          currentHeight,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(previousRect, Paint()..color = AppColors.border);
      canvas.drawRRect(currentRect, Paint()..color = AppColors.primary);
      final painter = TextPainter(
        text: TextSpan(text: item.label, style: AppTextStyles.captionTiny),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: groupWidth);
      painter.paint(
        canvas,
        Offset(centerX - painter.width / 2, size.height - painter.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyComparePainter oldDelegate) =>
      oldDelegate.items != items;
}
