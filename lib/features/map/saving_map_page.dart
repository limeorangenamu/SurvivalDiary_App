import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pill_chip.dart';
import 'place_detail_page.dart';
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

  Future<void> _moveToCurrentLocation({
    bool showMessage = false,
  }) async {
    try {
      // 1. 위치 서비스 활성화 여부와 권한을 확인하고,
      //    필요하면 사용자에게 권한을 요청합니다.
      final position = await LocationService().getCurrentPosition();

      // 2. 지도 준비 전이면 카메라 이동을 하지 않습니다.
      final controller = _mapController;
      if (controller == null) {
        return;
      }

      // 3. 현재 위도/경도로 지도 중심을 이동합니다.
      await controller.updateCamera(
        NCameraUpdate.withParams(
          target: NLatLng(position.latitude, position.longitude),
          zoom: 15,
        )..setAnimation(
            duration: const Duration(milliseconds: 500),
          ),
      );

      // 자동 이동할 때는 보통 알림을 보이지 않습니다.
      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('현재 위치로 이동했어요.'),
          ),
        );
      }
    } catch (error) {
      // 자동 실행 실패는 조용히 넘기고,
      // 사용자가 직접 버튼을 눌렀을 때만 오류를 보여 줍니다.
      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

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

  void _showPlaceDetail(SavingPlace place) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (context, scrollController) => PlaceDetailSheet(
          place: place,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final places = _visiblePlaces;
    return Scaffold(
      appBar: AppBar(
        title: const Text('절약 지도'),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () {
              // Search UI will be added in a later step.
            },
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SavingMapCanvas(
              places: places,
              onPlaceTap: (place) {
                setState(() => _selectedPlace = place);
              },
              onMapReady: (controller) {
                _mapController = controller;
                _moveToCurrentLocation();
              },
            ),
          ),
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: SizedBox(
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
          ),
          Positioned(
            top: 68,
            left: 16,
            right: 16,
            child: AppCard(
              child: Row(
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
            ),
          ),
          if (_selectedPlace != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _SelectedPlaceCard(
                place: _selectedPlace!,
                onTap: () => _showPlaceDetail(_selectedPlace!),
              ),
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
