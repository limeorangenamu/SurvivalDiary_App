import 'package:flutter/material.dart';

import '../../core/services/good_price_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_card.dart';
import 'good_price_store_marker_style.dart';

class GoodPriceStoreDetailPage extends StatelessWidget {
  const GoodPriceStoreDetailPage({super.key, required this.store});

  final GoodPriceStore store;

  @override
  Widget build(BuildContext context) {
    final style = GoodPriceStoreMarkerStyle.fromCategory(store.category);
    return Scaffold(
      appBar: AppBar(title: const Text('착한가격업소 상세')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          AppCard(
            color: style.color.withValues(alpha: 0.1),
            borderColor: style.color.withValues(alpha: 0.24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(style.icon, color: style.color, size: 38),
                const SizedBox(height: 12),
                Text(store.category, style: AppTextStyles.caption),
                const SizedBox(height: 3),
                Text(store.name, style: AppTextStyles.title),
                const SizedBox(height: 8),
                Text(
                  [store.province, store.district]
                      .where((value) => value.isNotEmpty)
                      .join(' '),
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: '주소',
            value: store.address.isEmpty ? '등록된 주소가 없어요.' : store.address,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.phone_outlined,
            label: '전화',
            value: store.phone.isEmpty ? '등록된 전화번호가 없어요.' : store.phone,
          ),
          const SizedBox(height: 18),
          const Text('메뉴와 가격', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 10),
          if (store.menus.isEmpty)
            const AppCard(
              child: Text(
                '등록된 메뉴 정보가 없어요.',
                style: AppTextStyles.bodyMuted,
              ),
            )
          else
            for (final menu in store.menus) ...[
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        menu.name.isEmpty ? '메뉴' : menu.name,
                        style: AppTextStyles.body,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      menu.price.isEmpty ? '가격 정보 없음' : menu.price,
                      style: AppTextStyles.amount,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
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
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          SizedBox(width: 56, child: Text(label, style: AppTextStyles.caption)),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
