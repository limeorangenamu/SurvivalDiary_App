import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class HousingDealMarkerStyle {
  const HousingDealMarkerStyle({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  static HousingDealMarkerStyle fromPropertyType(String propertyType) {
    return switch (propertyType.trim()) {
      '단독/다가구' => const HousingDealMarkerStyle(
          color: AppColors.warning,
          icon: Icons.home_work_rounded,
        ),
      '오피스텔' => const HousingDealMarkerStyle(
          color: AppColors.info,
          icon: Icons.apartment_rounded,
        ),
      _ => const HousingDealMarkerStyle(
          color: AppColors.textSecondary,
          icon: Icons.home_rounded,
        ),
    };
  }
}

class HousingDealMarkerIcon extends StatelessWidget {
  const HousingDealMarkerIcon({super.key, required this.style});

  final HousingDealMarkerStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 52,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 31,
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: style.color,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: style.color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(style.icon, color: AppColors.surface, size: 23),
          ),
        ],
      ),
    );
  }
}
