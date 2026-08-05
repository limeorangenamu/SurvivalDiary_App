import 'package:flutter/material.dart';

import '../../../core/services/public_facility_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_card.dart';
import '../public_facility_marker_style.dart';

class PublicFacilityDetailSheet extends StatelessWidget {
  const PublicFacilityDetailSheet({
    super.key,
    required this.facility,
    required this.scrollController,
    required this.onDirectionsPressed,
  });

  final PublicFacility facility;
  final ScrollController scrollController;
  final VoidCallback onDirectionsPressed;

  @override
  Widget build(BuildContext context) {
    final style = PublicFacilityMarkerStyle.fromCategory(facility.category);
    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              color: style.color.withValues(alpha: 0.1),
              borderColor: style.color.withValues(alpha: 0.24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(style.icon, color: style.color, size: 38),
                  const SizedBox(height: 12),
                  Text(facility.category, style: AppTextStyles.caption),
                  const SizedBox(height: 3),
                  Text(facility.name, style: AppTextStyles.title),
                  if (facility.locationName != facility.name) ...[
                    const SizedBox(height: 4),
                    Text(
                      facility.locationName,
                      style: AppTextStyles.bodyMuted,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '${facility.distanceLabel} · ${facility.feeLabel}',
                    style: AppTextStyles.body.copyWith(
                      color: facility.isFree
                          ? AppColors.primaryDeep
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: '주소',
              value: facility.address,
            ),
            _optionalRow(
              icon: Icons.schedule_rounded,
              label: '운영시간',
              value: facility.hoursLabel,
            ),
            _optionalRow(
              icon: Icons.event_busy_outlined,
              label: '휴관일',
              value: facility.closedDays,
            ),
            _optionalRow(
              icon: Icons.people_alt_outlined,
              label: '수용인원',
              value: facility.capacity.isEmpty ? '' : '${facility.capacity}명',
            ),
            _optionalRow(
              icon: Icons.square_foot_rounded,
              label: '면적',
              value: facility.area.isEmpty ? '' : '${facility.area}㎡',
            ),
            _optionalRow(
              icon: Icons.chair_outlined,
              label: '부대시설',
              value: facility.amenities,
            ),
            _optionalRow(
              icon: Icons.how_to_reg_outlined,
              label: '신청방법',
              value: facility.applicationMethod,
            ),
            _optionalRow(
              icon: Icons.apartment_rounded,
              label: '관리기관',
              value: facility.institution,
            ),
            _optionalRow(
              icon: Icons.phone_outlined,
              label: '전화',
              value: facility.phone,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onDirectionsPressed,
              icon: const Icon(Icons.directions_walk_rounded),
              label: const Text('도보 길찾기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionalRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    if (value.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: _DetailRow(icon: icon, label: label, value: value),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(width: 68, child: Text(label, style: AppTextStyles.caption)),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
