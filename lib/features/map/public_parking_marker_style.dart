import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PublicParkingMarkerIcon extends StatelessWidget {
  const PublicParkingMarkerIcon({super.key});

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
                  color: AppColors.pinParking,
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.pinParking,
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
            child: const Icon(
              Icons.local_parking_rounded,
              color: AppColors.surface,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
