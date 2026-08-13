import 'package:flutter/material.dart';

import '../../core/services/housing_rent_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/app_card.dart';
import 'housing_deal_marker_style.dart';

class HousingDealDetailPage extends StatelessWidget {
  const HousingDealDetailPage({super.key, required this.deal});

  final HousingRentDeal deal;

  @override
  Widget build(BuildContext context) {
    final style = HousingDealMarkerStyle.fromPropertyType(deal.propertyType);
    return Scaffold(
      appBar: AppBar(title: const Text('전월세 실거래 상세')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          AppCard(
            color: style.color.withValues(alpha: 0.1),
            borderColor: style.color.withValues(alpha: 0.28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(style.icon, color: style.color, size: 38),
                const SizedBox(height: 12),
                Text(
                  '${deal.propertyType} · ${deal.dealType}',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 3),
                Text(deal.propertyName, style: AppTextStyles.title),
                const SizedBox(height: 10),
                Text(_priceLabel(deal), style: AppTextStyles.amount),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('거래 정보', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.event_outlined,
            label: '계약일',
            value: Formatters.date(deal.contractDate),
          ),
          const SizedBox(height: 8),
          _DetailRow(
            icon: Icons.straighten_rounded,
            label: '면적',
            value: '${deal.areaSquareMeters.toStringAsFixed(1)}㎡',
          ),
          if (deal.floor != null) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.layers_outlined,
              label: '층',
              value: '${deal.floor}층',
            ),
          ],
          if (deal.buildYear != null) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.construction_outlined,
              label: '준공',
              value: '${deal.buildYear}년',
            ),
          ],
          if (deal.contractType.isNotEmpty) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.description_outlined,
              label: '계약구분',
              value: deal.contractType,
            ),
          ],
          if (deal.contractTerm.isNotEmpty) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.date_range_outlined,
              label: '계약기간',
              value: deal.contractTerm,
            ),
          ],
          if (deal.renewalRequestRightUsed.isNotEmpty) ...[
            const SizedBox(height: 8),
            _DetailRow(
              icon: Icons.refresh_rounded,
              label: '갱신요구권',
              value: deal.renewalRequestRightUsed,
            ),
          ],
          if (deal.previousDepositWon != null ||
              deal.previousMonthlyRentWon != null) ...[
            const SizedBox(height: 18),
            const Text('종전 계약', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.history_rounded,
              label: '종전 금액',
              value: _previousPriceLabel(deal),
            ),
          ],
          const SizedBox(height: 18),
          const Text('위치 정보', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: '주소',
            value: deal.address.isEmpty
                ? [deal.neighborhood, deal.lotNumber]
                    .where((value) => value.isNotEmpty)
                    .join(' ')
                : deal.address,
          ),
          if (deal.locationAccuracy == '동 단위') ...[
            const SizedBox(height: 8),
            const AppCard(
              color: AppColors.warningSoft,
              borderColor: AppColors.warning,
              child: Text(
                '단독/다가구 자료는 개인정보 보호로 지번이 제공되지 않아 동 중심의 대략적인 위치를 표시해요.',
                style: AppTextStyles.caption,
              ),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            '출처: 국토교통부 전월세 실거래가 자료',
            textAlign: TextAlign.center,
            style: AppTextStyles.captionTiny,
          ),
        ],
      ),
    );
  }
}

String _priceLabel(HousingRentDeal deal) {
  if (deal.dealType == '월세') {
    return '보증금 ${Formatters.compactAmount(deal.depositWon)} / '
        '월 ${Formatters.compactAmount(deal.monthlyRentWon)}';
  }
  return '보증금 ${Formatters.compactAmount(deal.depositWon)}';
}

String _previousPriceLabel(HousingRentDeal deal) {
  final parts = <String>[];
  if (deal.previousDepositWon != null) {
    parts.add('보증금 ${Formatters.compactAmount(deal.previousDepositWon!)}');
  }
  if (deal.previousMonthlyRentWon != null) {
    parts.add('월 ${Formatters.compactAmount(deal.previousMonthlyRentWon!)}');
  }
  return parts.isEmpty ? '정보 없음' : parts.join(' / ');
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
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(width: 68, child: Text(label, style: AppTextStyles.caption)),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
