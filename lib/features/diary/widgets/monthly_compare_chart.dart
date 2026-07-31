import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models.dart';

class MonthlyCompareChart extends StatelessWidget {
  const MonthlyCompareChart({super.key, required this.items});

  final List<MonthlyCompare> items;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '이전 기간과 선택 기간 지출 비교 막대 차트',
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: CustomPaint(painter: _MonthlyComparePainter(items)),
      ),
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
