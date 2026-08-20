import 'package:flutter/material.dart';

import '../../../core/services/public_parking_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../place_expense_summary.dart';
import 'place_spending_summary.dart';

class PublicParkingDetailSheet extends StatelessWidget {
  const PublicParkingDetailSheet({
    super.key,
    required this.parkingLot,
    required this.scrollController,
    required this.onDirectionsPressed,
    this.spendingSummary,
  });

  final PublicParkingLot parkingLot;
  final ScrollController scrollController;
  final VoidCallback onDirectionsPressed;
  final PlaceExpenseSummary? spendingSummary;

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.pinParking.withValues(alpha: 0.1),
              borderColor: AppColors.pinParking.withValues(alpha: 0.24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.local_parking_rounded,
                    color: AppColors.pinParking,
                    size: 38,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '공영 · ${parkingLot.parkingType}',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 3),
                  Text(parkingLot.name, style: AppTextStyles.title),
                  const SizedBox(height: 8),
                  Text(
                    '${parkingLot.distanceLabel} · ${parkingLot.feeLabel}',
                    style: AppTextStyles.body.copyWith(
                      color: parkingLot.free
                          ? AppColors.primaryDeep
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (spendingSummary != null) ...[
              const SizedBox(height: 14),
              PlaceSpendingSummary(
                summary: spendingSummary!,
                accentColor: AppColors.pinParking,
              ),
            ],
            const SizedBox(height: 14),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: '주소',
              value: parkingLot.address,
            ),
            _optionalRow(
              icon: Icons.local_parking_outlined,
              label: '주차면',
              value: parkingLot.capacityLabel,
            ),
            _optionalRow(
              icon: Icons.calendar_today_outlined,
              label: '운영요일',
              value: parkingLot.operationDays,
            ),
            _optionalRow(
              icon: Icons.schedule_rounded,
              label: '운영시간',
              value: parkingLot.hoursLabel,
            ),
            _optionalRow(
              icon: Icons.payments_outlined,
              label: '추가요금',
              value: parkingLot.additionalFeeLabel,
            ),
            _optionalRow(
              icon: Icons.today_outlined,
              label: '일 주차',
              value: _amount(parkingLot.dailyFee),
            ),
            _optionalRow(
              icon: Icons.date_range_outlined,
              label: '월 정기권',
              value: _amount(parkingLot.monthlyFee),
            ),
            _optionalRow(
              icon: Icons.credit_card_outlined,
              label: '결제방법',
              value: parkingLot.paymentMethods,
            ),
            _optionalRow(
              icon: Icons.accessible_rounded,
              label: '장애인 구역',
              value: parkingLot.accessibleParking ? '보유' : '',
            ),
            _optionalRow(
              icon: Icons.apartment_rounded,
              label: '관리기관',
              value: parkingLot.institution,
            ),
            _optionalRow(
              icon: Icons.phone_outlined,
              label: '전화',
              value: parkingLot.phone,
            ),
            _optionalRow(
              icon: Icons.info_outline_rounded,
              label: '안내',
              value: parkingLot.notes,
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onDirectionsPressed,
              icon: const Icon(Icons.directions_car_rounded),
              label: const Text('자동차 길찾기'),
            ),
          ],
        ),
      ),
    );
  }

  String _amount(int? value) => value == null ? '' : Formatters.amount(value);

  Widget _optionalRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    if (value.isEmpty || value == '운영시간 정보 없음') {
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.pinParking),
          const SizedBox(width: 12),
          SizedBox(width: 68, child: Text(label, style: AppTextStyles.caption)),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
