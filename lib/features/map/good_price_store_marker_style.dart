import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class GoodPriceStoreMarkerStyle {
  const GoodPriceStoreMarkerStyle({
    required this.color,
    required this.icon,
  });

  final Color color;
  final IconData icon;

  static GoodPriceStoreMarkerStyle fromCategory(String category) {
    return switch (category.trim()) {
      '전체' => const GoodPriceStoreMarkerStyle(
          color: AppColors.pinGoodPrice,
          icon: Icons.storefront_rounded,
        ),
      '한식' => const GoodPriceStoreMarkerStyle(
          color: AppColors.pinGoodPriceFood,
          icon: Icons.rice_bowl_rounded,
        ),
      '중식' => const GoodPriceStoreMarkerStyle(
          color: AppColors.pinGoodPriceFood,
          icon: Icons.ramen_dining_rounded,
        ),
      '일식' => const GoodPriceStoreMarkerStyle(
          color: AppColors.pinGoodPriceFood,
          icon: Icons.set_meal_rounded,
        ),
      '양식' => const GoodPriceStoreMarkerStyle(
          color: AppColors.pinGoodPriceFood,
          icon: Icons.restaurant_rounded,
        ),
      '기타요식업' => const GoodPriceStoreMarkerStyle(
          color: AppColors.pinGoodPriceFood,
          icon: Icons.local_cafe_rounded,
        ),
      '미용업' => const GoodPriceStoreMarkerStyle(
          color: AppColors.pinGoodPriceBeauty,
          icon: Icons.content_cut_rounded,
        ),
      '이용업' => const GoodPriceStoreMarkerStyle(
          color: AppColors.pinGoodPriceBarber,
          icon: Icons.face_rounded,
        ),
      '세탁업' => const GoodPriceStoreMarkerStyle(
          color: AppColors.pinGoodPriceLaundry,
          icon: Icons.local_laundry_service_rounded,
        ),
      '숙박업' => const GoodPriceStoreMarkerStyle(
          color: AppColors.pinGoodPriceLodging,
          icon: Icons.hotel_rounded,
        ),
      '목욕업' => const GoodPriceStoreMarkerStyle(
          color: AppColors.pinGoodPriceBath,
          icon: Icons.hot_tub_rounded,
        ),
      '기타비요식업' => const GoodPriceStoreMarkerStyle(
          color: AppColors.pinGoodPriceService,
          icon: Icons.storefront_rounded,
        ),
      _ => const GoodPriceStoreMarkerStyle(
          color: AppColors.textSecondary,
          icon: Icons.sell_rounded,
        ),
    };
  }
}

class GoodPriceStoreMarkerIcon extends StatelessWidget {
  const GoodPriceStoreMarkerIcon({
    super.key,
    required this.style,
  });

  final GoodPriceStoreMarkerStyle style;

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
