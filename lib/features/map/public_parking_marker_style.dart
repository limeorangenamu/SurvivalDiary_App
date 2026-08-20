import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class PublicParkingMarkerIcon extends StatelessWidget {
  const PublicParkingMarkerIcon({super.key});

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
                  color: AppColors.pinParking,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
              ),
            ),
          ),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.pinParking,
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
            child: const Icon(
              Icons.local_parking_rounded,
              color: AppColors.surface,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}
