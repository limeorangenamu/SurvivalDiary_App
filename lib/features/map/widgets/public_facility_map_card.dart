import 'package:flutter/material.dart';

import '../../../core/services/public_facility_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../public_facility_marker_style.dart';

class PublicFacilityMapCard extends StatelessWidget {
  const PublicFacilityMapCard({
    super.key,
    required this.facility,
    required this.onDirectionsPressed,
    required this.onTap,
  });

  final PublicFacility facility;
  final VoidCallback onDirectionsPressed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = PublicFacilityMarkerStyle.fromCategory(facility.category);
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(14),
      child: Semantics(
        button: true,
        label: '${facility.name} 자세히 보기',
        child: InkWell(
          key: const ValueKey('public-facility-card'),
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
                        color: style.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(style.icon, color: style.color, size: 15),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        facility.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionTiny,
                      ),
                    ),
                    TextButton.icon(
                      key: const ValueKey('public-facility-directions-button'),
                      onPressed: onDirectionsPressed,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.directions_walk_rounded, size: 17),
                      label: const Text('길찾기'),
                    ),
                  ],
                ),
                Text(
                  facility.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 3),
                Text(
                  facility.locationName == facility.name
                      ? facility.address
                      : '${facility.locationName} · ${facility.address}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        facility.feeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.amount.copyWith(
                          color: facility.isFree
                              ? AppColors.primaryDeep
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      facility.distanceLabel,
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
