import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class TrendLineChart extends StatelessWidget {
  const TrendLineChart({super.key, required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '최근 7일 지출 추이 선 차트',
      child: SizedBox(
        height: 130,
        width: double.infinity,
        child: CustomPaint(painter: _TrendLinePainter(values)),
      ),
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  const _TrendLinePainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    const topPadding = 12.0;
    const bottomPadding = 18.0;
    final chartHeight = size.height - topPadding - bottomPadding;
    final gridPaint = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index++) {
      final y = topPadding + chartHeight * index / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    if (values.length < 2) {
      return;
    }
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = (maxValue - minValue).abs() < 1 ? 1 : maxValue - minValue;
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = size.width * index / (values.length - 1);
      final normalized = (values[index] - minValue) / range;
      final y = topPadding + chartHeight * (1 - normalized);
      points.add(Offset(x, y));
    }
    final fillPath = Path()
      ..moveTo(points.first.dx, size.height - bottomPadding)
      ..lineTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath
      ..lineTo(points.last.dx, size.height - bottomPadding)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()..color = AppColors.primary.withValues(alpha: 0.09),
    );
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
    for (final point in points) {
      canvas.drawCircle(point, 4, Paint()..color = AppColors.surface);
      canvas.drawCircle(point, 3, Paint()..color = AppColors.primary);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) =>
      oldDelegate.values != values;
}
