import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pill_chip.dart';
import 'widgets/map_canvas.dart';
import '../../core/services/location_service.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';


class SavingMapPage extends StatefulWidget {
  const SavingMapPage({super.key});

  @override
  State<SavingMapPage> createState() => _SavingMapPageState();
}

class _SavingMapPageState extends State<SavingMapPage> {
  String _filter = '전체';
  int _sortIndex = 0;
  SavingPlace? _selectedPlace;
  NaverMapController? _mapController;

  List<SavingPlace> get _visiblePlaces {
    if (_filter == '주거지') {
      return [];
    }
    var result = _filter == '전체'
        ? [...MockData.places]
        : MockData.places
            .where((place) => place.type.label == _filter)
            .toList();
    if (_sortIndex == 0) {
      result.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    } else {
      result.sort((a, b) => a.baseFee.compareTo(b.baseFee));
    }
    return result;
  }

  void _changeFilter(String value) {
    setState(() {
      _filter = value;
      _selectedPlace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final places = _visiblePlaces;
    return Scaffold(
      appBar: AppBar(
        title: const Text('절약 지도'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              try {
                final position = await LocationService().getCurrentPosition();

                final controller = _mapController;

                if (controller == null) {
                  throw Exception('지도를 준비 중이에요. 잠시 후 다시 눌러주세요.');
                }

                await controller.updateCamera(
                  NCameraUpdate.withParams(
                    target: NLatLng(position.latitude, position.longitude),
                    zoom: 15,
                  )..setAnimation(
                    duration: const Duration(milliseconds: 500),
                  ),
                );

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('현재 위치로 이동했어요.')),
                );
              } catch (error) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error.toString())),
                );
              }
            },
            icon: const Icon(Icons.my_location_rounded, size: 18),
            label: const Text('내 주변'),
          ),
        ],
      ),
      body: ListView(
        key: const PageStorageKey('map-scroll'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final filter in const [
                  '전체',
                  '착한가격업소',
                  '공공시설',
                  '공영주차장',
                  '주거지',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: PillChip(
                      label: filter,
                      selected: _filter == filter,
                      onTap: () => _changeFilter(filter),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                size: 18,
                color: AppColors.info,
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text('서울 강남구 역삼동', style: AppTextStyles.caption),
              ),
              SortToggle(
                options: const ['거리순', '가격순'],
                selectedIndex: _sortIndex,
                onChanged: (value) => setState(() {
                  _sortIndex = value;
                  _selectedPlace = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 365,
            child: SavingMapCanvas(
              places: places,
              onPlaceTap: (place) =>
                  setState(() => _selectedPlace = place),
              onMapReady: (controller) => _mapController = controller,
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedPlace != null)
            _SelectedPlaceCard(
              place: _selectedPlace!,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.placeDetail,
                arguments: _selectedPlace,
              ),
            )
          else if (_filter == '주거지')
            _HousingSummaryCard(
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.housingRegion),
            ),
        ],
      ),
    );
  }
}

class _SelectedPlaceCard extends StatelessWidget {
  const _SelectedPlaceCard({required this.place, required this.onTap});

  final SavingPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: place.type.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(place.type.icon, color: place.type.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.type.label, style: AppTextStyles.captionTiny),
                const SizedBox(height: 2),
                Text(place.name, style: AppTextStyles.sectionTitle),
                const SizedBox(height: 4),
                Text(
                  '${place.distanceMeters}m · '
                  '${place.baseFee == 0 ? '무료' : Formatters.amount(place.baseFee)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _HousingSummaryCard extends StatelessWidget {
  const _HousingSummaryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.primarySoft,
      borderColor: AppColors.primary,
      onTap: onTap,
      child: const Row(
        children: [
          Icon(
            Icons.apartment_rounded,
            color: AppColors.primary,
            size: 30,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '주거 실거래 지역 선택',
                  style: AppTextStyles.sectionTitle,
                ),
                SizedBox(height: 4),
                Text(
                  '시·도부터 동까지 선택해 거래를 조회해요.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
