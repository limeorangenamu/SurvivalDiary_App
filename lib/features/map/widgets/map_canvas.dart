import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models.dart';

class SavingMapCanvas extends StatelessWidget {
  const SavingMapCanvas({
    super.key,
    required this.places,
    required this.onPlaceSelected,
    this.selectedPlaceId,
  });

  final List<SavingPlace> places;
  final ValueChanged<SavingPlace> onPlaceSelected;
  final String? selectedPlaceId;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            onTapDown: (details) {
              if (places.isEmpty) {
                return;
              }
              SavingPlace? nearest;
              var nearestDistance = double.infinity;
              for (final place in places) {
                final pin = Offset(
                  size.width * place.offsetX,
                  size.height * place.offsetY,
                );
                final distance = (pin - details.localPosition).distance;
                if (distance < nearestDistance) {
                  nearestDistance = distance;
                  nearest = place;
                }
              }
              if (nearest != null && nearestDistance < 46) {
                onPlaceSelected(nearest);
              }
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: _SavingMapPainter(
                places: places,
                selectedPlaceId: selectedPlaceId,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SavingMapPainter extends CustomPainter {
  const _SavingMapPainter({
    required this.places,
    required this.selectedPlaceId,
  });

  final List<SavingPlace> places;
  final String? selectedPlaceId;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.mapBackground,
    );

    final buildingPaint = Paint()..color = AppColors.mapBuilding;
    final blocks = [
      Rect.fromLTWH(
        size.width * 0.05,
        size.height * 0.07,
        size.width * 0.24,
        size.height * 0.18,
      ),
      Rect.fromLTWH(
        size.width * 0.38,
        size.height * 0.04,
        size.width * 0.23,
        size.height * 0.24,
      ),
      Rect.fromLTWH(
        size.width * 0.7,
        size.height * 0.08,
        size.width * 0.25,
        size.height * 0.17,
      ),
      Rect.fromLTWH(
        size.width * 0.04,
        size.height * 0.47,
        size.width * 0.28,
        size.height * 0.18,
      ),
      Rect.fromLTWH(
        size.width * 0.42,
        size.height * 0.43,
        size.width * 0.2,
        size.height * 0.2,
      ),
      Rect.fromLTWH(
        size.width * 0.72,
        size.height * 0.48,
        size.width * 0.22,
        size.height * 0.16,
      ),
      Rect.fromLTWH(
        size.width * 0.08,
        size.height * 0.76,
        size.width * 0.25,
        size.height * 0.15,
      ),
      Rect.fromLTWH(
        size.width * 0.46,
        size.height * 0.75,
        size.width * 0.4,
        size.height * 0.17,
      ),
    ];
    for (final block in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(block, const Radius.circular(10)),
        buildingPaint,
      );
    }

    final roadPaint = Paint()
      ..color = AppColors.mapRoad
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 22;
    canvas.drawLine(
      Offset(size.width * 0.02, size.height * 0.36),
      Offset(size.width * 0.98, size.height * 0.36),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.34, size.height * 0.02),
      Offset(size.width * 0.34, size.height * 0.98),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.67, size.height * 0.02),
      Offset(size.width * 0.67, size.height * 0.98),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.02, size.height * 0.7),
      Offset(size.width * 0.98, size.height * 0.7),
      roadPaint,
    );

    final current = Offset(size.width * 0.5, size.height * 0.56);
    canvas.drawCircle(
      current,
      14,
      Paint()..color = AppColors.info.withValues(alpha: 0.18),
    );
    canvas.drawCircle(current, 7, Paint()..color = AppColors.surface);
    canvas.drawCircle(current, 5, Paint()..color = AppColors.info);

    for (final place in places) {
      final center = Offset(
        size.width * place.offsetX,
        size.height * place.offsetY,
      );
      _drawPin(canvas, center, place.type.color, place.id == selectedPlaceId);
    }
  }

  void _drawPin(Canvas canvas, Offset center, Color color, bool selected) {
    if (selected) {
      canvas.drawCircle(
        center,
        23,
        Paint()..color = color.withValues(alpha: 0.16),
      );
    }
    final shadowCenter = center.translate(0, 3);
    canvas.drawCircle(
      shadowCenter,
      16,
      Paint()..color = AppColors.textPrimary.withValues(alpha: 0.08),
    );
    canvas.drawCircle(center, 16, Paint()..color = color);
    canvas.drawCircle(center, 12, Paint()..color = AppColors.surface);
    canvas.drawCircle(center, 6, Paint()..color = color);
    const angle = math.pi / 4;
    final path = Path()
      ..moveTo(center.dx - 7 * math.cos(angle), center.dy + 11)
      ..lineTo(center.dx, center.dy + 23)
      ..lineTo(center.dx + 7 * math.cos(angle), center.dy + 11)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SavingMapPainter oldDelegate) =>
      oldDelegate.places != places ||
      oldDelegate.selectedPlaceId != selectedPlaceId;
}
