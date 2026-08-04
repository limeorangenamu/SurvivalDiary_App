import 'package:flutter/material.dart';

import '../../../core/services/good_price_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../good_price_store_marker_style.dart';

class GoodPriceStoreMapCard extends StatelessWidget {
  const GoodPriceStoreMapCard({
    super.key,
    required this.store,
    required this.isFavorite,
    required this.onFavoritePressed,
    required this.onDirectionsPressed,
    required this.onTap,
  });

  final GoodPriceStore store;
  final bool isFavorite;
  final VoidCallback onFavoritePressed;
  final VoidCallback onDirectionsPressed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = GoodPriceStoreMarkerStyle.fromCategory(store.category);
    final firstMenu = store.menus.isEmpty ? null : store.menus.first;
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(14),
      child: Semantics(
        button: true,
        label: '${store.name} 자세히 보기',
        child: InkWell(
          key: const ValueKey('good-price-store-card'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
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
                        store.category,
                        style: AppTextStyles.captionTiny,
                      ),
                    ),
                    TextButton.icon(
                      key: const ValueKey('good-price-directions-button'),
                      onPressed: onDirectionsPressed,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.directions_walk_rounded, size: 17),
                      label: const Text('길찾기'),
                    ),
                    IconButton(
                      key: const ValueKey('good-price-favorite-button'),
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
                  store.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  store.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
                const Spacer(),
                Text(
                  firstMenu == null
                      ? '등록된 메뉴 정보가 없어요.'
                      : '${firstMenu.name.isEmpty ? '메뉴' : firstMenu.name} · '
                          '${firstMenu.price.isEmpty ? '가격 정보 없음' : firstMenu.price}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.amount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
