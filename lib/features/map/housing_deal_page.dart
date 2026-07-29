import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';

class HousingDealPage extends StatelessWidget {
  const HousingDealPage({super.key, required this.region});

  final String region;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('부동산 실거래')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          AppCard(
            color: AppColors.primarySoft,
            borderColor: AppColors.primarySoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('선택 지역', style: AppTextStyles.caption),
                const SizedBox(height: 4),
                Text(region, style: AppTextStyles.title),
                const SizedBox(height: 8),
                const Text(
                  '최근 3개월 신고 거래 · 총 18건',
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('최근 거래', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          for (final deal in MockData.housingDeals)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _HousingDealCard(deal: deal),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '국토교통부 실거래가 API를 연결하지 않은 샘플 데이터입니다.',
              style: AppTextStyles.captionTiny,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _HousingDealCard extends StatelessWidget {
  const _HousingDealCard({required this.deal});

  final HousingDeal deal;

  @override
  Widget build(BuildContext context) {
    final isRent = deal.dealType == '월세';
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  deal.dealType,
                  style: AppTextStyles.captionTiny.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  deal.propertyName,
                  style: AppTextStyles.sectionTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isRent
                ? '보증금 1,000만원 / ${Formatters.compactAmount(deal.amount)}'
                : Formatters.compactAmount(deal.amount),
            style: AppTextStyles.amount,
          ),
          const SizedBox(height: 6),
          Text(
            '${Formatters.date(deal.dealDate)} · '
            '${deal.area.toStringAsFixed(1)}㎡ · ${deal.floor}층',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}
