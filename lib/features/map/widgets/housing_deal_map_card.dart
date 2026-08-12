import 'package:flutter/material.dart';

import '../../../core/services/housing_rent_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../housing_deal_marker_style.dart';

class HousingDealMapCard extends StatelessWidget {
  const HousingDealMapCard({
    super.key,
    required this.deal,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.onTap,
  });

  final HousingRentDeal deal;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = HousingDealMarkerStyle.fromPropertyType(deal.propertyType);
    final price = deal.dealType == '월세'
        ? '보증금 ${Formatters.compactAmount(deal.depositWon)} / '
            '월 ${Formatters.compactAmount(deal.monthlyRentWon)}'
        : '보증금 ${Formatters.compactAmount(deal.depositWon)}';
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: const ValueKey('housing-deal-map-card'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(style.icon, color: style.color, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${deal.propertyType} · ${deal.dealType}',
                      style: AppTextStyles.captionTiny,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('housing-deal-favorite-button'),
                    tooltip: isFavorite ? '찜 해제' : '찜하기',
                    visualDensity: VisualDensity.compact,
                    onPressed: onFavoritePressed,
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite
                          ? AppColors.danger
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                deal.propertyName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 5),
              Text(
                price,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.amount,
              ),
              const Spacer(),
              Text(
                deal.locationAccuracy == '동 단위'
                    ? '${deal.neighborhood} · 대략적인 위치'
                    : deal.address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.captionTiny,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
