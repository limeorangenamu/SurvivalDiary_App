import 'package:flutter/material.dart';

import '../../../core/services/public_parking_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../place_expense_summary.dart';
import 'place_spending_summary.dart';

class PublicParkingMapCard extends StatelessWidget {
  const PublicParkingMapCard({
    super.key,
    required this.parkingLot,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.onDirectionsPressed,
    required this.onTap,
    this.spendingSummary,
  });

  final PublicParkingLot parkingLot;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final VoidCallback onDirectionsPressed;
  final VoidCallback onTap;
  final PlaceExpenseSummary? spendingSummary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(14),
      child: Semantics(
        button: true,
        label: '${parkingLot.name} 자세히 보기',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.pinParking.withValues(alpha: 0.13),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.local_parking_rounded,
                        color: AppColors.pinParking,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '공영 · ${parkingLot.parkingType}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionTiny,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onDirectionsPressed,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.directions_car_rounded, size: 17),
                      label: const Text('길찾기'),
                    ),
                    IconButton(
                      key: const ValueKey('public-parking-favorite-button'),
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
                Text(
                  parkingLot.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  parkingLot.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                if (spendingSummary != null) ...[
                  const SizedBox(height: 6),
                  PlaceSpendingSummary(
                    summary: spendingSummary!,
                    accentColor: AppColors.pinParking,
                    compact: true,
                  ),
                ],
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        parkingLot.feeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.amount.copyWith(
                          color: parkingLot.free
                              ? AppColors.primaryDeep
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      parkingLot.distanceLabel,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
