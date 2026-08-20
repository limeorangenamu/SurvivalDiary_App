import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PublicFacilityMarkerStyle {
  const PublicFacilityMarkerStyle({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  static PublicFacilityMarkerStyle fromCategory(String category) {
    final normalized = category.trim();
    if (normalized.contains('회의') || normalized.contains('강의')) {
      return const PublicFacilityMarkerStyle(
        color: AppColors.pinPublic,
        icon: Icons.groups_rounded,
      );
    }
    if (_containsAny(normalized, ['체육', '운동', '구장', '골프', '수영'])) {
      return const PublicFacilityMarkerStyle(
        color: AppColors.pinPublic,
        icon: Icons.sports_soccer_rounded,
      );
    }
    if (_containsAny(normalized, ['공연', '강당', '문화', '전시'])) {
      return const PublicFacilityMarkerStyle(
        color: AppColors.pinPublic,
        icon: Icons.theater_comedy_rounded,
      );
    }
    if (_containsAny(normalized, ['공원', '야외', '광장'])) {
      return const PublicFacilityMarkerStyle(
        color: AppColors.pinPublic,
        icon: Icons.park_rounded,
      );
    }
    return const PublicFacilityMarkerStyle(
      color: AppColors.pinPublic,
      icon: Icons.account_balance_rounded,
    );
  }

  static bool _containsAny(String value, List<String> keywords) {
    return keywords.any(value.contains);
  }
}

class PublicFacilityMarkerIcon extends StatelessWidget {
  const PublicFacilityMarkerIcon({super.key, required this.style});

  final PublicFacilityMarkerStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 33,
      height: 39,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 23,
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  color: style.color,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
              ),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: style.color,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.surface, width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.25),
                  blurRadius: 4.5,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Icon(style.icon, color: AppColors.surface, size: 17),
          ),
        ],
      ),
    );
  }
}
