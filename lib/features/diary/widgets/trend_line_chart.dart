import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';

class TrendLineChart extends StatelessWidget {
  const TrendLineChart({
    super.key,
    required this.values,
    required this.labels,
  }) : assert(values.length == labels.length);

  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '기간별 지출 추이 선 차트',
      child: SizedBox(
        height: 170,
        width: double.infinity,
        child: CustomPaint(
          painter: _TrendLinePainter(values, labels),
        ),
      ),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  const _TrendLinePainter(this.values, this.labels);

  final List<double> values;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 48.0;
    const rightPadding = 6.0;
    const topPadding = 10.0;
    const bottomPadding = 30.0;
    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    final chartBottom = topPadding + chartHeight;
    final maxValue = values.isEmpty
        ? 0.0
        : values.reduce((a, b) => a > b ? a : b);
    final axisMax = maxValue <= 0 ? 1000.0 : maxValue;
    final gridPaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;

    for (var index = 0; index < 4; index++) {
      final y = topPadding + chartHeight * index / 3;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
      final tickValue = axisMax * (3 - index) / 3;
      final tickPainter = TextPainter(
        text: TextSpan(
          text: Formatters.compactAmount(tickValue.round()),
          style: AppTextStyles.captionTiny,
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftPadding - 8);
      tickPainter.paint(
        canvas,
        Offset(
          leftPadding - tickPainter.width - 7,
          y - tickPainter.height / 2,
        ),
      );
    }

    if (values.isEmpty) {
      return;
    }

    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? leftPadding + chartWidth / 2
          : leftPadding + chartWidth * index / (values.length - 1);
      final normalized = (values[index] / axisMax).clamp(0.0, 1.0);
      final y = topPadding + chartHeight * (1 - normalized);
      points.add(Offset(x, y));

      final labelPainter = TextPainter(
        text: TextSpan(
          text: labels[index],
          style: AppTextStyles.captionTiny,
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: chartWidth / values.length);
      final labelX = (x - labelPainter.width / 2).clamp(
        leftPadding - 4,
        size.width - rightPadding - labelPainter.width,
      ).toDouble();
      labelPainter.paint(
        canvas,
        Offset(labelX, chartBottom + 8),
      );
    }

    final fillPath = Path()
      ..moveTo(points.first.dx, chartBottom)
      ..lineTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath
      ..lineTo(points.last.dx, chartBottom)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()..color = AppColors.primary.withValues(alpha: 0.09),
    );
    if (points.length > 1) {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        linePath.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(
        linePath,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = AppColors.surface);
      canvas.drawCircle(point, 3, Paint()..color = AppColors.primary);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.labels != labels;
}
