import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

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
import 'good_price_store_category_summary.dart';
import 'good_price_store_distance.dart';
import 'good_price_store_marker_style.dart';
import 'good_price_store_visibility.dart';
import 'place_detail_page.dart';
import 'widgets/map_canvas.dart';

class SavingMapPage extends StatefulWidget {
  const SavingMapPage({super.key});

  @override
  State<SavingMapPage> createState() => _SavingMapPageState();
}

class _SavingMapPageState extends State<SavingMapPage> {
  final GoodPriceApiService _goodPriceApiService = GoodPriceApiService();
  final LocationService _locationService = LocationService();

  String _filter = '착한가격업소';
  int _sortIndex = 0;
  SavingPlace? _selectedPlace;
  GoodPriceStore? _selectedGoodPriceStore;
  String? _selectedGoodPriceCategoryKey;
  final Map<String, GoodPriceStore> _favoriteGoodPriceStores = {};
  NaverMapController? _mapController;
  List<GoodPriceStore> _goodPriceStores = const [];
  bool _isLoadingStores = false;
  String? _storeError;
  String? _province;
  String? _district;
  int _storeRequestId = 0;
  double? _currentLatitude;
  double? _currentLongitude;
  bool _isLocating = false;
  String? _locationError;
  NLatLngBounds? _viewportBounds;
  int _viewportRequestId = 0;
  bool _isInitialLocationPending = true;

  List<GoodPriceStore> get _visibleGoodPriceStores {
    final bounds = _viewportBounds;
    final stores = bounds == null
        ? _goodPriceStores
        : _goodPriceStores.where((store) {
            if (!store.hasCoordinates) {
              return false;
            }
            return bounds.containsPoint(
              NLatLng(store.latitude!, store.longitude!),
            );
          }).toList();
    return _sortGoodPriceStores(stores);
  }

  Future<void> _loadGoodPriceStores() async {
    final province = _province;
    final district = _district;
    if (province == null) {
      return;
    }
    final accessToken = AuthSession.instance.accessToken;
    if (accessToken == null) {
      setState(() {
        _storeError = '로그인 후 착한가격업소를 확인할 수 있어요.';
        _isLoadingStores = false;
      });
      return;
    }

    final requestId = ++_storeRequestId;
    setState(() {
      _isLoadingStores = true;
      _storeError = null;
    });

    try {
      final page = await _goodPriceApiService.fetchStores(
        accessToken: accessToken,
        page: 0,
        size: 100,
        province: province,
        district: district,
        sort: _sortIndex == 1 ? 'price' : 'name',
      );
      if (!mounted || requestId != _storeRequestId) {
        return;
      }

      setState(() {
        _goodPriceStores = _sortGoodPriceStores(page.content);
        _isLoadingStores = false;
      });
    } on GoodPriceApiException catch (error) {
      if (!mounted || requestId != _storeRequestId) {
        return;
      }
      setState(() {
        _storeError = error.message;
        _isLoadingStores = false;
      });
    }
  }

  Future<void> _moveToCurrentLocation({bool showMessage = false}) async {
    try {
      final position = await _locationService.getCurrentPosition();
      final controller = _mapController;
      if (controller != null) {
        final currentLocation = NLatLng(
          position.latitude,
          position.longitude,
        );
        controller.getLocationOverlay()
          ..setPosition(currentLocation)
          ..setIsVisible(true);
        await controller.updateCamera(
          NCameraUpdate.withParams(
            target: currentLocation,
            zoom: 15,
          )..setAnimation(duration: const Duration(milliseconds: 500)),
        );
      }

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

  Future<void> _initializeMapAtCurrentLocation() async {
    await _moveToCurrentLocation();
    if (!mounted) {
      return;
    }

    _isInitialLocationPending = false;
    await _refreshCurrentViewport();
  }

  Future<void> _handleViewportChanged(MapViewport viewport) async {
    final requestId = ++_viewportRequestId;
    if (mounted) {
      setState(() {
        _currentLatitude = viewport.center.latitude;
        _currentLongitude = viewport.center.longitude;
        _viewportBounds = viewport.bounds;
        _selectedGoodPriceStore = null;
        _isLocating = true;
        _locationError = null;
      });
    }
    if (_filter != '착한가격업소') {
      if (mounted) {
        setState(() => _isLocating = false);
      }
      return;
    }

    try {
      final region = await _locationService.getRegionAt(
        latitude: viewport.center.latitude,
        longitude: viewport.center.longitude,
      );
      if (!mounted || requestId != _viewportRequestId) {
        return;
      }
      final regionChanged =
          _province != region.province || _district != region.district;
      setState(() {
        _province = region.province;
        _district = region.district;
        _isLocating = false;
        if (regionChanged) {
          _goodPriceStores = const [];
        }
      });
      if (regionChanged || _goodPriceStores.isEmpty) {
        await _loadGoodPriceStores();
      }
    } catch (error) {
      if (!mounted || requestId != _viewportRequestId) {
        return;
      }
      setState(() {
        _isLocating = false;
        _locationError = error.toString();
      });
    }
  }

  Future<void> _refreshCurrentViewport() async {
    final controller = _mapController;
    if (controller == null) {
      return;
    }
    final cameraPosition = await controller.getCameraPosition();
    final bounds = await controller.getContentBounds();
    await _handleViewportChanged(
      MapViewport(center: cameraPosition.target, bounds: bounds),
    );
  }

  String? get _viewportRegionLabel {
    final province = _province;
    if (province == null) {
      return null;
    }
    final district = _district;
    if (district == null || district.isEmpty) {
      return province;
    }
    return '$province $district';
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
      final aDistance = distanceToGoodPriceStore(
            store: a,
            latitude: latitude,
            longitude: longitude,
          ) ??
          double.infinity;
      final bDistance = distanceToGoodPriceStore(
            store: b,
            latitude: latitude,
            longitude: longitude,
          ) ??
          double.infinity;
      return aDistance.compareTo(bDistance);
    });
    return result;
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
      _selectedGoodPriceStore = null;
      if (value != '착한가격업소') {
        _selectedGoodPriceCategoryKey = null;
      }
    });
    if (value == '착한가격업소' && _goodPriceStores.isEmpty) {
      unawaited(_refreshCurrentViewport());
    }
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

  void _selectGoodPriceStore(GoodPriceStore store) {
    setState(() => _selectedGoodPriceStore = store);
  }

  void _toggleSelectedGoodPriceStoreFavorite() {
    final store = _selectedGoodPriceStore;
    if (store == null) {
      return;
    }
    setState(() {
      if (_favoriteGoodPriceStores.containsKey(store.id)) {
        _favoriteGoodPriceStores.remove(store.id);
        if (_filter == '전체') {
          _selectedGoodPriceStore = null;
        }
      } else {
        _favoriteGoodPriceStores[store.id] = store;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final places = _visiblePlaces;
    final isGoodPrice = _filter == '착한가격업소';
    final visibleGoodPriceStores = _visibleGoodPriceStores;
    final categoryGoodPriceStores = visibleGoodPriceStores
        .where(
          (store) => goodPriceStoreMatchesCategory(
            store,
            _selectedGoodPriceCategoryKey,
          ),
        )
        .toList(growable: false);
    final mapGoodPriceStores = goodPriceStoresForMap(
      filter: _filter,
      visibleStores: categoryGoodPriceStores,
      favoriteStores: _favoriteGoodPriceStores.values,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('절약 지도'),
        actions: [
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
              goodPriceStores: mapGoodPriceStores,
              onPlaceTap: (place) {
                setState(() => _selectedPlace = place);
              },
              onGoodPriceStoreTap: _selectGoodPriceStore,
              onMapReady: (controller) {
                _mapController = controller;
                unawaited(_initializeMapAtCurrentLocation());
              },
              onViewportChanged: (viewport) {
                if (_isInitialLocationPending) {
                  return;
                }
                unawaited(_handleViewportChanged(viewport));
              },
              selectedGoodPriceStore: _selectedGoodPriceStore,
              isSelectedStoreFavorite: _selectedGoodPriceStore != null &&
                  _favoriteGoodPriceStores.containsKey(
                    _selectedGoodPriceStore!.id,
                  ),
              onFavoritePressed: _toggleSelectedGoodPriceStoreFavorite,
              onGoodPriceStoreDismissed: () {
                if (_selectedGoodPriceStore != null) {
                  setState(() => _selectedGoodPriceStore = null);
                }
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
                      isGoodPrice
                          ? _viewportRegionLabel == null
                              ? '현재 지도 지역 확인 중'
                              : '$_viewportRegionLabel 착한가격업소'
                          : '내 주변 절약 장소',
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
                        _loadGoodPriceStores();
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
              height: 180,
              child: _GoodPriceStorePanel(
                stores: visibleGoodPriceStores,
                isLoading: _isLoadingStores,
                error: _storeError,
                regionLabel: _viewportRegionLabel,
                isLocating: _isLocating,
                locationError: _locationError,
                onRetry: _loadGoodPriceStores,
                onLocationRetry: _refreshCurrentViewport,
                selectedCategoryKey: _selectedGoodPriceCategoryKey,
                onCategorySelected: (categoryKey) {
                  setState(() {
                    _selectedGoodPriceStore = null;
                    _selectedGoodPriceCategoryKey = categoryKey == 'all' ||
                            categoryKey == _selectedGoodPriceCategoryKey
                        ? null
                        : categoryKey;
                  });
                },
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
    required this.isLoading,
    required this.error,
    required this.regionLabel,
    required this.isLocating,
    required this.locationError,
    required this.onRetry,
    required this.onLocationRetry,
    required this.selectedCategoryKey,
    required this.onCategorySelected,
  });

  final List<GoodPriceStore> stores;
  final bool isLoading;
  final String? error;
  final String? regionLabel;
  final bool isLocating;
  final String? locationError;
  final VoidCallback onRetry;
  final VoidCallback onLocationRetry;
  final String? selectedCategoryKey;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '주변 착한가격업소',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${stores.length}곳',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            regionLabel == null
                ? '현재 지도 화면의 지역을 확인하고 있어요.'
                : '$regionLabel · 카테고리를 누르면 지도 마커가 바뀌어요.',
            style: AppTextStyles.captionTiny,
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLocating) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text(
              '현재 지도 화면의 지역을 확인하고 있어요.',
              style: AppTextStyles.bodyMuted,
            ),
          ],
        ),
      );
    }
    if (locationError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              locationError!,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            TextButton(
              onPressed: onLocationRetry,
              child: const Text('화면 지역 다시 확인'),
            ),
          ],
        ),
      );
    }
    if (regionLabel == null) {
      return const Center(
        child: Text(
          '현재 지도 화면의 지역을 확인하지 못했어요.',
          style: AppTextStyles.bodyMuted,
        ),
      );
    }
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
        child: Text(
          '현재 지도 화면에 확인된 업소가 없어요.',
          style: AppTextStyles.bodyMuted,
        ),
      );
    }

    return _GoodPriceCategorySummary(
      stores: stores,
      selectedCategoryKey: selectedCategoryKey,
      onCategorySelected: onCategorySelected,
    );
  }
}

class _GoodPriceCategorySummary extends StatelessWidget {
  const _GoodPriceCategorySummary({
    required this.stores,
    required this.selectedCategoryKey,
    required this.onCategorySelected,
  });

  final List<GoodPriceStore> stores;
  final String? selectedCategoryKey;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final summaries = summarizeGoodPriceStoreCategories(stores);
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: summaries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final summary = summaries[index];
          final isSelected = summary.key == 'all'
              ? selectedCategoryKey == null
              : selectedCategoryKey == summary.key;
          final style = GoodPriceStoreMarkerStyle.fromCategory(
            summary.markerCategory,
          );
          return Semantics(
            button: true,
            selected: isSelected,
            label: '${summary.label}, 주변 ${summary.count}곳',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onCategorySelected(summary.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 132,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: style.color.withValues(
                    alpha: isSelected ? 0.16 : 0.07,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: style.color.withValues(
                      alpha: isSelected ? 0.9 : 0.24,
                    ),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    GoodPriceStoreMarkerIcon(style: style),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '주변 ${summary.count}곳',
                            style: AppTextStyles.captionTiny.copyWith(
                              color: style.color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
