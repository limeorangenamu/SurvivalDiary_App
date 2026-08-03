import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';

class PlaceDetailPage extends StatelessWidget {
  const PlaceDetailPage({super.key, required this.place});

  final SavingPlace place;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('장소 상세')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          AppCard(
            color: place.type.color.withValues(alpha: 0.1),
            borderColor: place.type.color.withValues(alpha: 0.24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(place.type.icon, color: place.type.color, size: 38),
                const SizedBox(height: 12),
                Text(place.type.label, style: AppTextStyles.caption),
                const SizedBox(height: 3),
                Text(place.name, style: AppTextStyles.title),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.warning,
                      size: 19,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${place.rating}',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '현재 위치에서 ${place.distanceMeters}m',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _DetailRow(
            icon: Icons.location_on_outlined,
            label: '주소',
            value: place.address,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.payments_outlined,
            label: '기본요금',
            value: place.baseFee == 0 ? '무료' : Formatters.amount(place.baseFee),
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.schedule_rounded,
            label: '운영시간',
            value: place.operatingHours,
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.phone_outlined,
            label: '전화',
            value: place.phone,
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('길찾기는 UI 프로토타입에서 제공하지 않아요.')),
            ),
            child: const Text('길찾기 안내'),
          ),
        ],
      ),
    );
  }
}

class PlaceDetailSheet extends StatelessWidget {
  const PlaceDetailSheet({
    super.key,
    required this.place,
    required this.scrollController,
  });

  final SavingPlace place;
  final ScrollController scrollController;

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
              color: place.type.color.withValues(alpha: 0.1),
              borderColor: place.type.color.withValues(alpha: 0.24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(place.type.icon, color: place.type.color, size: 38),
                  const SizedBox(height: 12),
                  Text(place.type.label, style: AppTextStyles.caption),
                  const SizedBox(height: 3),
                  Text(place.name, style: AppTextStyles.title),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppColors.warning,
                        size: 19,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${place.rating}',
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '현재 위치에서 ${place.distanceMeters}m',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: '주소',
              value: place.address,
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.payments_outlined,
              label: '기본 요금',
              value:
                  place.baseFee == 0 ? '무료' : Formatters.amount(place.baseFee),
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.schedule_rounded,
              label: '영업 시간',
              value: place.operatingHours,
            ),
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: '전화',
              value: place.phone,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('길찾기는 UI 프로토타입에서 제공하지 않아요.')),
              ),
              child: const Text('길찾기 안내'),
            ),
          ],
        ),
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
          SizedBox(width: 68, child: Text(label, style: AppTextStyles.caption)),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
