import 'package:flutter/material.dart';

import '../../core/services/housing_rent_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/auth_session.dart';
import 'housing_deal_detail_page.dart';

class HousingDealPage extends StatefulWidget {
  const HousingDealPage({super.key, required this.condition});

  final HousingRentSearchCondition condition;

  @override
  State<HousingDealPage> createState() => _HousingDealPageState();
}

class _HousingDealPageState extends State<HousingDealPage> {
  final HousingRentApiService _apiService = HousingRentApiService();

  List<HousingRentDeal> _deals = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDeals();
  }

  Future<void> _loadDeals() async {
    final accessToken = AuthSession.instance.accessToken;
    if (accessToken == null) {
      setState(() {
        _isLoading = false;
        _error = '로그인 후 실거래 정보를 확인할 수 있어요.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final deals = await _apiService.fetchDeals(
        accessToken: accessToken,
        condition: widget.condition,
        endMonth: DateTime.now(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _deals = deals;
        _isLoading = false;
      });
    } on HousingRentApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('부동산 실거래')),
      body: RefreshIndicator(
        onRefresh: _loadDeals,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  Text(widget.condition.region, style: AppTextStyles.title),
                  const SizedBox(height: 8),
                  Text(
                    '최근 3개월 전월세 신고 거래 · 총 ${_deals.length}건',
                    style: AppTextStyles.bodyMuted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text('최근 거래', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 10),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _HousingDealMessage(
                message: _error!,
                actionLabel: '다시 시도',
                onAction: _loadDeals,
              )
            else if (_deals.isEmpty)
              const _HousingDealMessage(
                message: '선택한 지역에서 최근 3개월 전월세 거래를 찾지 못했어요.',
              )
            else
              for (final deal in _deals)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HousingDealCard(
                    deal: deal,
                    onTap: () => _showDetail(deal),
                  ),
                ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                '국토교통부 단독·다가구 및 오피스텔 전월세 실거래가 자료',
                style: AppTextStyles.captionTiny,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(HousingRentDeal deal) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HousingDealDetailPage(deal: deal),
      ),
    );
  }
}

class _HousingDealMessage extends StatelessWidget {
  const _HousingDealMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _HousingDealCard extends StatelessWidget {
  const _HousingDealCard({required this.deal, required this.onTap});

  final HousingRentDeal deal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = deal.dealType == '월세'
        ? '보증금 ${Formatters.compactAmount(deal.depositWon)} / '
            '월 ${Formatters.compactAmount(deal.monthlyRentWon)}'
        : '보증금 ${Formatters.compactAmount(deal.depositWon)}';
    final details = <String>[
      Formatters.date(deal.contractDate),
      '${deal.areaSquareMeters.toStringAsFixed(1)}㎡',
      if (deal.floor != null) '${deal.floor}층',
      if (deal.buildYear != null) '${deal.buildYear}년 준공',
    ];

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _DealBadge(label: deal.dealType),
              const SizedBox(width: 6),
              _DealBadge(label: deal.propertyType, muted: true),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            deal.propertyName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionTitle,
          ),
          if (deal.neighborhood.isNotEmpty || deal.lotNumber.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              [deal.neighborhood, deal.lotNumber]
                  .where((value) => value.isNotEmpty)
                  .join(' '),
              style: AppTextStyles.captionTiny,
            ),
          ],
          const SizedBox(height: 12),
          Text(price, style: AppTextStyles.amount),
          const SizedBox(height: 6),
          Text(details.join(' · '), style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _DealBadge extends StatelessWidget {
  const _DealBadge({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: muted ? AppColors.surfaceAlt : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionTiny.copyWith(
          color: muted ? AppColors.textSecondary : AppColors.primaryDeep,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
