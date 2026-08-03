import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/good_price_api_service.dart';
import '../../core/services/location_service.dart';
import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pill_chip.dart';
import '../auth/auth_session.dart';
import 'place_detail_page.dart';
import 'widgets/map_canvas.dart';

class SavingMapPage extends StatefulWidget {
  const SavingMapPage({super.key});

  @override
  State<SavingMapPage> createState() => _SavingMapPageState();
}

class _SavingMapPageState extends State<SavingMapPage> {
  final GoodPriceApiService _goodPriceApiService = GoodPriceApiService();

  String _filter = '착한가격업소';
  int _sortIndex = 0;
  SavingPlace? _selectedPlace;
  NaverMapController? _mapController;
  List<GoodPriceStore> _goodPriceStores = const [];
  bool _isLoadingStores = false;
  bool _isLoadingMoreStores = false;
  String? _storeError;
  String? _province;
  String? _district;
  int _storePage = 0;
  int _totalStores = 0;
  bool _hasNextStorePage = false;
  int _storeRequestId = 0;
  double? _currentLatitude;
  double? _currentLongitude;

  @override
  void initState() {
    super.initState();
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadGoodPriceStores(reset: true);
      });
    }
  }

  Future<void> _loadGoodPriceStores({required bool reset}) async {
    final accessToken = AuthSession.instance.accessToken;
    if (accessToken == null) {
      setState(() {
        _storeError = '로그인 후 착한가격업소를 확인할 수 있어요.';
        _isLoadingStores = false;
        _isLoadingMoreStores = false;
      });
      return;
    }

    final requestId = ++_storeRequestId;
    final nextPage = reset ? 0 : _storePage + 1;
    setState(() {
      if (reset) {
        _isLoadingStores = true;
        _storeError = null;
      } else {
        _isLoadingMoreStores = true;
      }
    });

    try {
      final page = await _goodPriceApiService.fetchStores(
        accessToken: accessToken,
        page: nextPage,
        province: _province,
        district: _district,
        sort: _sortIndex == 1 ? 'price' : 'name',
      );
      if (!mounted || requestId != _storeRequestId) {
        return;
      }

      final stores = reset
          ? page.content
          : <GoodPriceStore>[
              ..._goodPriceStores,
              ...page.content.where(
                (store) => !_goodPriceStores.any(
                  (existing) => existing.id == store.id,
                ),
              ),
            ];
      setState(() {
        _goodPriceStores = _sortGoodPriceStores(stores);
        _storePage = page.page;
        _totalStores = page.totalElements;
        _hasNextStorePage = page.hasNext;
        _isLoadingStores = false;
        _isLoadingMoreStores = false;
      });
    } on GoodPriceApiException catch (error) {
      if (!mounted || requestId != _storeRequestId) {
        return;
      }
      setState(() {
        _storeError = error.message;
        _isLoadingStores = false;
        _isLoadingMoreStores = false;
      });
    }
  }

  Future<void> _moveToCurrentLocation({bool showMessage = false}) async {
    try {
      final position = await LocationService().getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLatitude = position.latitude;
          _currentLongitude = position.longitude;
          _goodPriceStores = _sortGoodPriceStores(_goodPriceStores);
        });
      }
      final controller = _mapController;
      if (controller == null) {
        return;
      }
      await controller.updateCamera(
        NCameraUpdate.withParams(
          target: NLatLng(position.latitude, position.longitude),
          zoom: 15,
        )..setAnimation(duration: const Duration(milliseconds: 500)),
      );
      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('현재 위치로 이동했어요.')),
        );
      }
    } catch (error) {
      if (showMessage && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  List<GoodPriceStore> _sortGoodPriceStores(List<GoodPriceStore> stores) {
    final result = [...stores];
    if (_sortIndex == 1) {
      result.sort((a, b) {
        final aPrice = a.lowestPrice ?? 1 << 30;
        final bPrice = b.lowestPrice ?? 1 << 30;
        return aPrice.compareTo(bPrice);
      });
      return result;
    }

    final latitude = _currentLatitude;
    final longitude = _currentLongitude;
    if (latitude == null || longitude == null) {
      result.sort((a, b) => a.name.compareTo(b.name));
      return result;
    }
    result.sort((a, b) {
      final aDistance = _distanceTo(a, latitude, longitude);
      final bDistance = _distanceTo(b, latitude, longitude);
      return aDistance.compareTo(bDistance);
    });
    return result;
  }

  double _distanceTo(
    GoodPriceStore store,
    double latitude,
    double longitude,
  ) {
    if (!store.hasCoordinates) {
      return double.infinity;
    }
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      store.latitude!,
      store.longitude!,
    );
  }

  List<SavingPlace> get _visiblePlaces {
    if (_filter == '주거지' || _filter == '착한가격업소') {
      return [];
    }
    final result = _filter == '전체'
        ? MockData.places
            .where((place) => place.type != PlaceType.goodPrice)
            .toList()
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
      _sortIndex = 0;
      _selectedPlace = null;
    });
    if (value == '착한가격업소' && _goodPriceStores.isEmpty) {
      _loadGoodPriceStores(reset: true);
    }
  }

  Future<void> _showRegionFilter() async {
    final provinceController = TextEditingController(text: _province);
    final districtController = TextEditingController(text: _district);
    final applied = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('지역으로 검색'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: provinceController,
              decoration: const InputDecoration(
                labelText: '시·도',
                hintText: '예: 서울특별시',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: districtController,
              decoration: const InputDecoration(
                labelText: '시·군·구',
                hintText: '예: 종로구',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              provinceController.clear();
              districtController.clear();
            },
            child: const Text('전국'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (provinceController.text.trim().isEmpty &&
                  districtController.text.trim().isNotEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('시·도를 먼저 입력해 주세요.')),
                );
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            child: const Text('적용'),
          ),
        ],
      ),
    );
    if (applied != true || !mounted) {
      return;
    }
    setState(() {
      _province = _emptyToNull(provinceController.text);
      _district = _emptyToNull(districtController.text);
    });
    await _loadGoodPriceStores(reset: true);
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

  void _showGoodPriceDetail(GoodPriceStore store) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(store.name, style: AppTextStyles.title),
              const SizedBox(height: 6),
              Text(store.category, style: AppTextStyles.caption),
              const SizedBox(height: 16),
              Text(store.address, style: AppTextStyles.body),
              if (store.phone.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(store.phone, style: AppTextStyles.bodyMuted),
              ],
              const SizedBox(height: 20),
              const Text('착한가격 메뉴', style: AppTextStyles.sectionTitle),
              const SizedBox(height: 8),
              if (store.menus.isEmpty)
                const Text('등록된 메뉴 정보가 없어요.', style: AppTextStyles.bodyMuted)
              else
                for (final menu in store.menus)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            menu.name.isEmpty ? '메뉴' : menu.name,
                            style: AppTextStyles.body,
                          ),
                        ),
                        Text(
                          menu.price.isEmpty ? '가격 정보 없음' : menu.price,
                          style: AppTextStyles.amount,
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  String get _regionLabel {
    if (_province == null) {
      return '전국 착한가격업소';
    }
    if (_district == null) {
      return _province!;
    }
    return '$_province $_district';
  }

  @override
  Widget build(BuildContext context) {
    final places = _visiblePlaces;
    final isGoodPrice = _filter == '착한가격업소';
    return Scaffold(
      appBar: AppBar(
        title: const Text('절약 지도'),
        actions: [
          IconButton(
            tooltip: '지역 검색',
            onPressed: isGoodPrice ? _showRegionFilter : null,
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: '현재 위치',
            onPressed: () => _moveToCurrentLocation(showMessage: true),
            icon: const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SavingMapCanvas(
              places: places,
              goodPriceStores: isGoodPrice ? _goodPriceStores : const [],
              onPlaceTap: (place) {
                setState(() => _selectedPlace = place);
              },
              onGoodPriceStoreTap: _showGoodPriceDetail,
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
                  Expanded(
                    child: Text(
                      isGoodPrice ? _regionLabel : '내 주변 절약 장소',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  SortToggle(
                    options: isGoodPrice
                        ? const ['거리순', '가격순']
                        : const ['거리순', '가격순'],
                    selectedIndex: _sortIndex,
                    onChanged: (value) {
                      setState(() {
                        _sortIndex = value;
                        _selectedPlace = null;
                      });
                      if (isGoodPrice) {
                        _loadGoodPriceStores(reset: true);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          if (isGoodPrice)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              height: 250,
              child: _GoodPriceStorePanel(
                stores: _goodPriceStores,
                totalStores: _totalStores,
                isLoading: _isLoadingStores,
                isLoadingMore: _isLoadingMoreStores,
                error: _storeError,
                hasNext: _hasNextStorePage,
                onRetry: () => _loadGoodPriceStores(reset: true),
                onLoadMore: () => _loadGoodPriceStores(reset: false),
                onStoreTap: _showGoodPriceDetail,
                currentLatitude: _currentLatitude,
                currentLongitude: _currentLongitude,
              ),
            )
          else if (_filter == '주거지')
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SingleChildScrollView(
                key: const PageStorageKey('map-scroll'),
                child: _HousingSummaryCard(
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRoutes.housingRegion,
                  ),
                ),
              ),
            )
          else if (_selectedPlace != null)
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

class _GoodPriceStorePanel extends StatelessWidget {
  const _GoodPriceStorePanel({
    required this.stores,
    required this.totalStores,
    required this.isLoading,
    required this.isLoadingMore,
    required this.error,
    required this.hasNext,
    required this.onRetry,
    required this.onLoadMore,
    required this.onStoreTap,
    required this.currentLatitude,
    required this.currentLongitude,
  });

  final List<GoodPriceStore> stores;
  final int totalStores;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasNext;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final ValueChanged<GoodPriceStore> onStoreTap;
  final double? currentLatitude;
  final double? currentLongitude;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('착한가격업소', style: AppTextStyles.sectionTitle),
              ),
              Text('총 $totalStores곳', style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '좌표가 확인된 업소는 지도 마커로 함께 표시돼요.',
            style: AppTextStyles.captionTiny,
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading && stores.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null && stores.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (stores.isEmpty) {
      return const Center(
        child: Text('조건에 맞는 업소가 없어요.', style: AppTextStyles.bodyMuted),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: stores.length + (hasNext ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        if (index == stores.length) {
          return SizedBox(
            width: 110,
            child: Center(
              child: isLoadingMore
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: onLoadMore,
                      child: const Text('더 보기'),
                    ),
            ),
          );
        }
        final store = stores[index];
        final lowestPrice = store.lowestPrice;
        final distance = _distanceText(store);
        return SizedBox(
          width: 220,
          child: Material(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onStoreTap(store),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(store.category, style: AppTextStyles.captionTiny),
                    const SizedBox(height: 3),
                    Text(
                      store.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      store.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                    const Spacer(),
                    Text(
                      [
                        if (distance != null) distance,
                        lowestPrice == null
                            ? '가격 정보 없음'
                            : '${Formatters.amount(lowestPrice)}부터',
                      ].join(' · '),
                      style: AppTextStyles.amount,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String? _distanceText(GoodPriceStore store) {
    final latitude = currentLatitude;
    final longitude = currentLongitude;
    if (!store.hasCoordinates || latitude == null || longitude == null) {
      return null;
    }
    final meters = Geolocator.distanceBetween(
      latitude,
      longitude,
      store.latitude!,
      store.longitude!,
    ).round();
    if (meters < 1000) {
      return '${meters}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
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
          Icon(Icons.apartment_rounded, color: AppColors.primary, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('주거 실거래 지역 선택', style: AppTextStyles.sectionTitle),
                SizedBox(height: 4),
                Text(
                  '시·도부터 동까지 선택해 거래를 조회해요.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
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

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
