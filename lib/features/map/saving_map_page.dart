import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/directions_api_service.dart';
import '../../core/services/good_price_api_service.dart';
import '../../core/services/housing_rent_api_service.dart';
import '../../core/services/location_service.dart';
import '../../core/services/public_facility_api_service.dart';
import '../../core/services/public_parking_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pill_chip.dart';
import '../auth/auth_session.dart';
import '../diary/data/expense_api_client.dart';
import 'good_price_store_category_summary.dart';
import 'good_price_store_detail_page.dart';
import 'good_price_store_distance.dart';
import 'good_price_store_marker_style.dart';
import 'good_price_store_visibility.dart';
import 'housing_deal_detail_page.dart';
import 'housing_deal_marker_style.dart';
import 'housing_lawd_code.dart';
import 'place_detail_page.dart';
import 'data/map_favorite_repository.dart';
import 'directions_progress.dart';
import 'place_expense_summary.dart';
import 'public_facility_marker_style.dart';
import 'widgets/map_canvas.dart';
import 'widgets/public_facility_detail_sheet.dart';
import 'widgets/public_parking_detail_sheet.dart';

const _allBannerKey = '__all__';
const _freeBannerKey = '__free__';
const _myGoodPriceKey = 'good-price';
const _myPublicFacilityKey = 'public-facility';
const _myPublicParkingKey = 'public-parking';
const _myHousingKey = 'housing';

class SavingMapPage extends StatefulWidget {
  const SavingMapPage({super.key, this.refreshVersion = 0});

  final int refreshVersion;

  @override
  State<SavingMapPage> createState() => _SavingMapPageState();
}

class _SavingMapPageState extends State<SavingMapPage> {
  final DirectionsApiService _directionsApiService = DirectionsApiService();
  final GoodPriceApiService _goodPriceApiService = GoodPriceApiService();
  final PublicFacilityApiService _publicFacilityApiService =
      PublicFacilityApiService();
  final PublicParkingApiService _publicParkingApiService =
      PublicParkingApiService();
  final HousingRentApiService _housingRentApiService = HousingRentApiService();
  final LocationService _locationService = LocationService();
  final ExpenseApiClient _expenseApiClient = ExpenseApiClient();
  final MapFavoriteRepository _favoriteRepository = MapFavoriteRepository();

  String _filter = '전체';
  int _sortIndex = 0;
  SavingPlace? _selectedPlace;
  GoodPriceStore? _selectedGoodPriceStore;
  PublicFacility? _selectedPublicFacility;
  PublicParkingLot? _selectedParkingLot;
  HousingRentDeal? _selectedHousingDeal;
  String? _selectedMyFavoriteType;
  String? _selectedGoodPriceCategoryKey;
  String? _selectedPublicFacilityCategory;
  String? _selectedParkingType;
  String? _selectedHousingPropertyType;
  final Map<String, GoodPriceStore> _favoriteGoodPriceStores = {};
  final Map<String, PublicFacility> _favoritePublicFacilities = {};
  final Map<String, PublicParkingLot> _favoriteParkingLots = {};
  final Map<String, HousingRentDeal> _favoriteHousingDeals = {};
  NaverMapController? _mapController;
  List<GoodPriceStore> _goodPriceStores = const [];
  List<PublicFacility> _publicFacilities = const [];
  List<PublicParkingLot> _parkingLots = const [];
  List<Expense> _cardExpenses = const [];
  bool _isLoadingCardExpenses = false;
  bool _isLoadingStores = false;
  bool _isLoadingPublicFacilities = false;
  bool _isLoadingParkingLots = false;
  String? _storeError;
  String? _publicFacilityError;
  String? _parkingError;
  bool _publicFacilityFreeOnly = false;
  bool _parkingFreeOnly = false;
  List<HousingRentDeal> _housingDeals = const [];
  bool _isLoadingHousingDeals = false;
  String? _housingDealError;
  int _housingRequestId = 0;
  String? _province;
  String? _district;
  int _storeRequestId = 0;
  int _publicFacilityRequestId = 0;
  int _parkingRequestId = 0;
  double? _currentLatitude;
  double? _currentLongitude;
  bool _isLocating = false;
  String? _locationError;
  NLatLngBounds? _viewportBounds;
  int _viewportRequestId = 0;
  bool _isInitialLocationPending = true;
  DirectionsRoute? _directionsRoute;
  String? _directionsDestinationName;
  DirectionsMode _directionsMode = DirectionsMode.walking;
  bool _isLoadingDirections = false;
  int _directionsRequestId = 0;
  StreamSubscription<Position>? _directionsPositionSubscription;
  double? _directionsGoalLatitude;
  double? _directionsGoalLongitude;
  int? _remainingDistanceMeters;
  int? _remainingDurationMillis;
  bool _isReroutingDirections = false;
  String? _directionsTrackingError;
  DateTime? _lastDirectionsRerouteAt;

  static const _routeDeviationThresholdMeters = 60.0;
  static const _rerouteCooldown = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    unawaited(_loadFavorites());
    unawaited(_loadCardExpenses());
  }

  @override
  void didUpdateWidget(covariant SavingMapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshVersion != oldWidget.refreshVersion) {
      unawaited(_loadCardExpenses());
    }
  }

  @override
  void dispose() {
    _stopDirectionsTracking();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await _favoriteRepository.load();
      if (!mounted) return;
      setState(() {
        _favoriteGoodPriceStores
          ..clear()
          ..addAll(favorites.goodPriceStores);
        _favoritePublicFacilities
          ..clear()
          ..addAll(favorites.publicFacilities);
        _favoriteParkingLots
          ..clear()
          ..addAll(favorites.parkingLots);
        _favoriteHousingDeals
          ..clear()
          ..addAll(favorites.housingDeals);
      });
    } on Object {
      // The map remains usable even if platform storage is temporarily unavailable.
    }
  }

  Future<void> _loadCardExpenses() async {
    final accessToken = AuthSession.instance.accessToken;
    if (accessToken == null || _isLoadingCardExpenses) {
      return;
    }
    _isLoadingCardExpenses = true;
    try {
      final expenses = await _expenseApiClient.getExpenses(
        accessToken: accessToken,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _cardExpenses = expenses
            .where((expense) => expense.entryType == ExpenseEntryType.auto)
            .toList(growable: false);
      });
    } on ExpenseApiException {
      // Spending information is supplementary, so keep the map usable.
    } finally {
      _isLoadingCardExpenses = false;
    }
  }

  PlaceExpenseSummary? _goodPriceSpendingSummary(GoodPriceStore store) {
    return summarizeCardExpensesForPlace(
      expenses: _cardExpenses,
      placeNames: [store.name],
    );
  }

  PlaceExpenseSummary? _parkingSpendingSummary(PublicParkingLot parkingLot) {
    return summarizeCardExpensesForPlace(
      expenses: _cardExpenses,
      placeNames: [parkingLot.name],
    );
  }

  Future<void> _persistFavorites() async {
    try {
      await _favoriteRepository.save(
        MapFavorites(
          goodPriceStores: _favoriteGoodPriceStores,
          publicFacilities: _favoritePublicFacilities,
          parkingLots: _favoriteParkingLots,
          housingDeals: _favoriteHousingDeals,
        ),
      );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('찜 목록을 저장하지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

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

  List<HousingRentDeal> get _visibleHousingDeals {
    final bounds = _viewportBounds;
    if (bounds == null) {
      return _housingDeals;
    }
    return _housingDeals.where((deal) {
      if (!deal.hasCoordinates) {
        return false;
      }
      return bounds.containsPoint(NLatLng(deal.latitude!, deal.longitude!));
    }).toList(growable: false);
  }

  List<PublicFacility> get _visiblePublicFacilities {
    final category = _selectedPublicFacilityCategory;
    if (category == null) return _publicFacilities;
    return _publicFacilities
        .where((facility) => _facilityCategory(facility) == category)
        .toList(growable: false);
  }

  List<PublicParkingLot> get _visibleParkingLots {
    final parkingType = _selectedParkingType;
    if (parkingType == null) return _parkingLots;
    return _parkingLots
        .where((parkingLot) => _parkingType(parkingLot) == parkingType)
        .toList(growable: false);
  }

  Future<void> _loadPublicFacilities() async {
    final bounds = _viewportBounds;
    final latitude = _currentLatitude;
    final longitude = _currentLongitude;
    if (bounds == null || latitude == null || longitude == null) {
      return;
    }
    final accessToken = AuthSession.instance.accessToken;
    if (accessToken == null) {
      setState(() {
        _publicFacilityError = '로그인 후 공공시설을 확인할 수 있어요.';
        _isLoadingPublicFacilities = false;
      });
      return;
    }

    final requestId = ++_publicFacilityRequestId;
    setState(() {
      _isLoadingPublicFacilities = true;
      _publicFacilityError = null;
    });

    try {
      final page = await _publicFacilityApiService.fetchFacilities(
        accessToken: accessToken,
        southWestLat: bounds.southWest.latitude,
        southWestLng: bounds.southWest.longitude,
        northEastLat: bounds.northEast.latitude,
        northEastLng: bounds.northEast.longitude,
        latitude: latitude,
        longitude: longitude,
        freeOnly: _publicFacilityFreeOnly,
        sort: _publicFacilityFreeOnly ? 'free' : 'distance',
      );
      if (!mounted || requestId != _publicFacilityRequestId) {
        return;
      }
      setState(() {
        _publicFacilities = page.content;
        final selectedCategory = _selectedPublicFacilityCategory;
        if (selectedCategory != null &&
            !page.content.any(
              (facility) => _facilityCategory(facility) == selectedCategory,
            )) {
          _selectedPublicFacilityCategory = null;
        }
        _isLoadingPublicFacilities = false;
      });
    } on PublicFacilityApiException catch (error) {
      if (!mounted || requestId != _publicFacilityRequestId) {
        return;
      }
      setState(() {
        _publicFacilityError = error.message;
        _isLoadingPublicFacilities = false;
      });
    }
  }

  Future<void> _loadParkingLots() async {
    final bounds = _viewportBounds;
    final latitude = _currentLatitude;
    final longitude = _currentLongitude;
    if (bounds == null || latitude == null || longitude == null) {
      return;
    }
    final accessToken = AuthSession.instance.accessToken;
    if (accessToken == null) {
      setState(() {
        _parkingError = '로그인 후 공영주차장을 확인할 수 있어요.';
        _isLoadingParkingLots = false;
      });
      return;
    }

    final requestId = ++_parkingRequestId;
    setState(() {
      _isLoadingParkingLots = true;
      _parkingError = null;
    });

    try {
      final page = await _publicParkingApiService.fetchParkingLots(
        accessToken: accessToken,
        southWestLat: bounds.southWest.latitude,
        southWestLng: bounds.southWest.longitude,
        northEastLat: bounds.northEast.latitude,
        northEastLng: bounds.northEast.longitude,
        latitude: latitude,
        longitude: longitude,
        freeOnly: _parkingFreeOnly,
        sort: _sortIndex == 1 ? 'fee' : 'distance',
      );
      if (!mounted || requestId != _parkingRequestId) {
        return;
      }
      setState(() {
        _parkingLots = page.content;
        final selectedParkingType = _selectedParkingType;
        if (selectedParkingType != null &&
            !page.content.any(
              (parkingLot) => _parkingType(parkingLot) == selectedParkingType,
            )) {
          _selectedParkingType = null;
        }
        _isLoadingParkingLots = false;
      });
    } on PublicParkingApiException catch (error) {
      if (!mounted || requestId != _parkingRequestId) {
        return;
      }
      setState(() {
        _parkingError = error.message;
        _isLoadingParkingLots = false;
      });
    }
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
        final selectedCategoryKey = _selectedGoodPriceCategoryKey;
        if (selectedCategoryKey != null &&
            !page.content.any(
              (store) => goodPriceStoreMatchesCategory(
                store,
                selectedCategoryKey,
              ),
            )) {
          _selectedGoodPriceCategoryKey = null;
        }
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

  Future<void> _loadHousingDeals() async {
    final province = _province;
    final district = _district;
    if (province == null || district == null) {
      return;
    }
    final lawdCode = housingLawdCodeFor(
      province: province,
      district: district,
    );
    if (lawdCode == null) {
      setState(() {
        _housingDealError = '$province $district의 실거래 지역코드를 확인하지 못했어요.';
        _isLoadingHousingDeals = false;
      });
      return;
    }
    final accessToken = AuthSession.instance.accessToken;
    if (accessToken == null) {
      setState(() {
        _housingDealError = '로그인 후 주거 실거래를 확인할 수 있어요.';
        _isLoadingHousingDeals = false;
      });
      return;
    }

    final requestId = ++_housingRequestId;
    setState(() {
      _isLoadingHousingDeals = true;
      _housingDealError = null;
    });
    try {
      final deals = await _housingRentApiService.fetchDeals(
        accessToken: accessToken,
        condition: HousingRentSearchCondition(
          region: '$province $district',
          lawdCode: lawdCode,
          neighborhood: '',
        ),
        endMonth: DateTime.now(),
        limit: 50,
      );
      if (!mounted || requestId != _housingRequestId) {
        return;
      }
      setState(() {
        _housingDeals = deals;
        final selectedPropertyType = _selectedHousingPropertyType;
        if (selectedPropertyType != null &&
            !deals.any(
              (deal) => deal.propertyType == selectedPropertyType,
            )) {
          _selectedHousingPropertyType = null;
        }
        _isLoadingHousingDeals = false;
      });
    } on HousingRentApiException catch (error) {
      if (!mounted || requestId != _housingRequestId) {
        return;
      }
      setState(() {
        _housingDealError = error.message;
        _isLoadingHousingDeals = false;
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
        _selectedPublicFacility = null;
        _selectedParkingLot = null;
        _selectedHousingDeal = null;
        _isLocating = true;
        _locationError = null;
      });
    }
    if (_filter == '공공시설') {
      if (mounted) {
        setState(() => _isLocating = false);
      }
      await _loadPublicFacilities();
      return;
    }
    if (_filter == '공영주차장') {
      if (mounted) {
        setState(() => _isLocating = false);
      }
      await _loadParkingLots();
      return;
    }
    final isGoodPrice = _filter == '착한가격업소';
    final isHousing = _filter == '주거지';
    if (!isGoodPrice && !isHousing) {
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
          if (isGoodPrice) {
            _goodPriceStores = const [];
          }
          if (isHousing) {
            _housingDeals = const [];
          }
        }
      });
      if (isGoodPrice && (regionChanged || _goodPriceStores.isEmpty)) {
        await _loadGoodPriceStores();
      } else if (isHousing && (regionChanged || _housingDeals.isEmpty)) {
        await _loadHousingDeals();
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
    if (_filter == '주거지' ||
        _filter == '착한가격업소' ||
        _filter == '공공시설' ||
        _filter == '공영주차장') {
      return [];
    }
    final result = _filter == '전체'
        ? MockData.places
            .where(
              (place) =>
                  place.type != PlaceType.goodPrice &&
                  place.type != PlaceType.publicFacility &&
                  place.type != PlaceType.publicParking,
            )
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

  void _selectGoodPriceCategory(String categoryKey) {
    setState(() {
      _selectedGoodPriceStore = null;
      _selectedGoodPriceCategoryKey =
          categoryKey == 'all' || categoryKey == _selectedGoodPriceCategoryKey
              ? null
              : categoryKey;
    });
  }

  void _selectHousingPropertyType(String propertyType) {
    setState(() {
      _selectedHousingDeal = null;
      _selectedHousingPropertyType =
          propertyType == _selectedHousingPropertyType ? null : propertyType;
    });
  }

  void _selectPublicFacilityCategory(String category) {
    final wasFreeOnly = _publicFacilityFreeOnly;
    setState(() {
      _selectedPublicFacility = null;
      _publicFacilityFreeOnly = category == _freeBannerKey;
      _selectedPublicFacilityCategory =
          category == _allBannerKey || category == _freeBannerKey
              ? null
              : category == _selectedPublicFacilityCategory
                  ? null
                  : category;
      if (wasFreeOnly != _publicFacilityFreeOnly) {
        _publicFacilities = const [];
      }
    });
    if (wasFreeOnly != _publicFacilityFreeOnly) {
      unawaited(_loadPublicFacilities());
    }
  }

  void _selectParkingType(String parkingType) {
    final wasFreeOnly = _parkingFreeOnly;
    setState(() {
      _selectedParkingLot = null;
      _parkingFreeOnly = parkingType == _freeBannerKey;
      _selectedParkingType =
          parkingType == _allBannerKey || parkingType == _freeBannerKey
              ? null
              : parkingType == _selectedParkingType
                  ? null
                  : parkingType;
      if (wasFreeOnly != _parkingFreeOnly) {
        _parkingLots = const [];
      }
    });
    if (wasFreeOnly != _parkingFreeOnly) {
      unawaited(_loadParkingLots());
    }
  }

  void _selectMyFavoriteType(String favoriteType) {
    setState(() {
      _selectedGoodPriceStore = null;
      _selectedPublicFacility = null;
      _selectedParkingLot = null;
      _selectedHousingDeal = null;
      _selectedMyFavoriteType = favoriteType == _allBannerKey ||
              favoriteType == _selectedMyFavoriteType
          ? null
          : favoriteType;
    });
  }

  void _changeFilter(String value) {
    _stopDirectionsTracking();
    setState(() {
      _filter = value;
      _sortIndex = 0;
      _selectedPlace = null;
      _selectedGoodPriceStore = null;
      _selectedPublicFacility = null;
      _selectedParkingLot = null;
      _selectedHousingDeal = null;
      _directionsRoute = null;
      _directionsDestinationName = null;
      _isLoadingDirections = false;
      _clearDirectionsTrackingState();
      _directionsRequestId++;
      if (value != '전체') {
        _selectedMyFavoriteType = null;
      }
      if (value != '착한가격업소') {
        _selectedGoodPriceCategoryKey = null;
      }
      if (value != '공공시설') {
        _selectedPublicFacilityCategory = null;
      }
      if (value != '공영주차장') {
        _selectedParkingType = null;
      }
      if (value != '주거지') {
        _selectedHousingPropertyType = null;
      }
    });
    if (value == '착한가격업소' && _goodPriceStores.isEmpty) {
      unawaited(_refreshCurrentViewport());
    } else if (value == '주거지') {
      unawaited(_refreshCurrentViewport());
    }
    if (value == '공공시설' && _publicFacilities.isEmpty) {
      unawaited(_refreshCurrentViewport());
    }
    if (value == '공영주차장' && _parkingLots.isEmpty) {
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
    _stopDirectionsTracking();
    setState(() {
      _selectedGoodPriceStore = store;
      _selectedPublicFacility = null;
      _selectedParkingLot = null;
      _selectedHousingDeal = null;
      _directionsRoute = null;
      _directionsDestinationName = null;
      _isLoadingDirections = false;
      _clearDirectionsTrackingState();
      _directionsRequestId++;
    });
    unawaited(_loadCardExpenses());
  }

  void _selectPublicFacility(PublicFacility facility) {
    _stopDirectionsTracking();
    setState(() {
      _selectedPublicFacility = facility;
      _selectedGoodPriceStore = null;
      _selectedParkingLot = null;
      _selectedHousingDeal = null;
      _directionsRoute = null;
      _directionsDestinationName = null;
      _isLoadingDirections = false;
      _clearDirectionsTrackingState();
      _directionsRequestId++;
    });
  }

  void _showGoodPriceStoreDetail() {
    final store = _selectedGoodPriceStore;
    if (store == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GoodPriceStoreDetailPage(
          store: store,
          spendingSummary: _goodPriceSpendingSummary(store),
        ),
      ),
    );
  }

  void _showPublicFacilityDetail() {
    final facility = _selectedPublicFacility;
    if (facility == null) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.68,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (_, scrollController) => PublicFacilityDetailSheet(
          facility: facility,
          scrollController: scrollController,
          onDirectionsPressed: () {
            Navigator.of(sheetContext).pop();
            unawaited(_openPublicFacilityDirections(facility));
          },
        ),
      ),
    );
  }

  void _selectParkingLot(PublicParkingLot parkingLot) {
    _stopDirectionsTracking();
    setState(() {
      _selectedParkingLot = parkingLot;
      _selectedGoodPriceStore = null;
      _selectedPublicFacility = null;
      _selectedHousingDeal = null;
      _directionsRoute = null;
      _directionsDestinationName = null;
      _isLoadingDirections = false;
      _clearDirectionsTrackingState();
      _directionsRequestId++;
    });
    unawaited(_loadCardExpenses());
  }

  void _showParkingDetail() {
    final parkingLot = _selectedParkingLot;
    if (parkingLot == null) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.5,
        maxChildSize: 0.92,
        builder: (_, scrollController) => PublicParkingDetailSheet(
          parkingLot: parkingLot,
          scrollController: scrollController,
          spendingSummary: _parkingSpendingSummary(parkingLot),
          onDirectionsPressed: () {
            Navigator.of(sheetContext).pop();
            unawaited(_openParkingDirections(parkingLot));
          },
        ),
      ),
    );
  }

  void _selectHousingDeal(HousingRentDeal deal) {
    _stopDirectionsTracking();
    setState(() {
      _selectedHousingDeal = deal;
      _selectedGoodPriceStore = null;
      _selectedPublicFacility = null;
      _selectedParkingLot = null;
      _directionsRoute = null;
      _directionsDestinationName = null;
      _isLoadingDirections = false;
      _clearDirectionsTrackingState();
      _directionsRequestId++;
    });
  }

  void _showHousingDealDetail() {
    final deal = _selectedHousingDeal;
    if (deal == null) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HousingDealDetailPage(deal: deal),
      ),
    );
  }

  Future<void> _openSelectedGoodPriceStoreDirections() async {
    final store = _selectedGoodPriceStore;
    if (store == null) {
      return;
    }
    await _openDirections(
      destinationName: store.name,
      goalLatitude: store.latitude,
      goalLongitude: store.longitude,
      missingLocationMessage: '이 업소는 위치 정보가 없어 길찾기를 시작할 수 없어요.',
    );
  }

  Future<void> _openSelectedPublicFacilityDirections() async {
    final facility = _selectedPublicFacility;
    if (facility == null) {
      return;
    }
    await _openPublicFacilityDirections(facility);
  }

  Future<void> _openSelectedParkingDirections() async {
    final parkingLot = _selectedParkingLot;
    if (parkingLot == null) {
      return;
    }
    await _openParkingDirections(parkingLot);
  }

  Future<void> _openParkingDirections(PublicParkingLot parkingLot) {
    return _openDirections(
      destinationName: parkingLot.name,
      goalLatitude: parkingLot.latitude,
      goalLongitude: parkingLot.longitude,
      missingLocationMessage: '이 주차장은 위치 정보가 없어 길찾기를 시작할 수 없어요.',
      mode: DirectionsMode.driving,
    );
  }

  Future<void> _openPublicFacilityDirections(PublicFacility facility) {
    return _openDirections(
      destinationName: facility.name,
      goalLatitude: facility.latitude,
      goalLongitude: facility.longitude,
      missingLocationMessage: '이 시설은 위치 정보가 없어 길찾기를 시작할 수 없어요.',
    );
  }

  Future<void> _openDirections({
    required String destinationName,
    required double? goalLatitude,
    required double? goalLongitude,
    required String missingLocationMessage,
    DirectionsMode mode = DirectionsMode.walking,
  }) async {
    if (goalLatitude == null || goalLongitude == null) {
      _showDirectionsError(missingLocationMessage);
      return;
    }
    final accessToken = AuthSession.instance.accessToken;
    if (accessToken == null) {
      final routeType = mode == DirectionsMode.driving ? '자동차' : '도보';
      _showDirectionsError('로그인 후 $routeType 경로를 확인할 수 있어요.');
      return;
    }

    _stopDirectionsTracking();
    final requestId = ++_directionsRequestId;
    setState(() {
      _isLoadingDirections = true;
      _directionsRoute = null;
      _directionsDestinationName = destinationName;
      _directionsMode = mode;
      _directionsGoalLatitude = goalLatitude;
      _directionsGoalLongitude = goalLongitude;
      _remainingDistanceMeters = null;
      _remainingDurationMillis = null;
      _isReroutingDirections = false;
      _directionsTrackingError = null;
      _lastDirectionsRerouteAt = null;
    });

    try {
      final position = await _locationService.getCurrentPosition();
      final controller = _mapController;
      if (controller != null) {
        controller.getLocationOverlay()
          ..setPosition(NLatLng(position.latitude, position.longitude))
          ..setIsVisible(true);
      }
      final route = await _directionsApiService.fetchOptimalRoute(
        accessToken: accessToken,
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        goalLatitude: goalLatitude,
        goalLongitude: goalLongitude,
        mode: mode,
      );
      if (!mounted || requestId != _directionsRequestId) {
        return;
      }
      setState(() {
        _directionsRoute = route;
        _remainingDistanceMeters = route.distanceMeters;
        _remainingDurationMillis = route.durationMillis;
        _isLoadingDirections = false;
        _selectedGoodPriceStore = null;
        _selectedPublicFacility = null;
        _selectedParkingLot = null;
        _selectedHousingDeal = null;
      });
      _startDirectionsTracking();
    } on DirectionsApiException catch (error) {
      if (!mounted || requestId != _directionsRequestId) {
        return;
      }
      setState(() => _isLoadingDirections = false);
      _showDirectionsError(error.message);
    } catch (error) {
      if (!mounted || requestId != _directionsRequestId) {
        return;
      }
      setState(() => _isLoadingDirections = false);
      _showDirectionsError(error.toString());
    }
  }

  void _clearDirections() {
    _stopDirectionsTracking();
    setState(() {
      _directionsRequestId++;
      _directionsRoute = null;
      _directionsDestinationName = null;
      _directionsMode = DirectionsMode.walking;
      _isLoadingDirections = false;
      _clearDirectionsTrackingState();
    });
  }

  void _startDirectionsTracking() {
    _stopDirectionsTracking();
    final requestId = _directionsRequestId;
    _directionsPositionSubscription = _locationService.watchPosition().listen(
      (position) => _handleDirectionsPosition(position, requestId),
      onError: (Object error) {
        if (!mounted || requestId != _directionsRequestId) {
          return;
        }
        setState(() {
          _directionsTrackingError = '실시간 위치를 확인할 수 없어요.';
        });
      },
    );
  }

  void _stopDirectionsTracking() {
    final subscription = _directionsPositionSubscription;
    _directionsPositionSubscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
  }

  void _clearDirectionsTrackingState() {
    _directionsGoalLatitude = null;
    _directionsGoalLongitude = null;
    _remainingDistanceMeters = null;
    _remainingDurationMillis = null;
    _isReroutingDirections = false;
    _directionsTrackingError = null;
    _lastDirectionsRerouteAt = null;
  }

  void _handleDirectionsPosition(Position position, int requestId) {
    if (!mounted || requestId != _directionsRequestId) {
      return;
    }
    final route = _directionsRoute;
    if (route == null) {
      return;
    }

    final locationOverlay = _mapController?.getLocationOverlay();
    if (locationOverlay != null) {
      locationOverlay
        ..setPosition(NLatLng(position.latitude, position.longitude))
        ..setIsVisible(true);
    }

    final progress = calculateDirectionsProgress(
      route: route,
      latitude: position.latitude,
      longitude: position.longitude,
    );
    setState(() {
      _remainingDistanceMeters = progress.remainingDistanceMeters;
      _remainingDurationMillis = progress.remainingDurationMillis;
      _directionsTrackingError = null;
    });

    final lastRerouteAt = _lastDirectionsRerouteAt;
    final canReroute = lastRerouteAt == null ||
        DateTime.now().difference(lastRerouteAt) >= _rerouteCooldown;
    final reliableDeviation =
        progress.distanceFromRouteMeters - position.accuracy;
    if (reliableDeviation >= _routeDeviationThresholdMeters &&
        !_isReroutingDirections &&
        canReroute) {
      unawaited(_rerouteDirectionsFromPosition(position, requestId));
    }
  }

  Future<void> _rerouteDirectionsFromPosition(
    Position position,
    int requestId,
  ) async {
    final accessToken = AuthSession.instance.accessToken;
    final goalLatitude = _directionsGoalLatitude;
    final goalLongitude = _directionsGoalLongitude;
    if (accessToken == null || goalLatitude == null || goalLongitude == null) {
      return;
    }

    setState(() {
      _isReroutingDirections = true;
      _lastDirectionsRerouteAt = DateTime.now();
    });
    try {
      final route = await _directionsApiService.fetchOptimalRoute(
        accessToken: accessToken,
        startLatitude: position.latitude,
        startLongitude: position.longitude,
        goalLatitude: goalLatitude,
        goalLongitude: goalLongitude,
        mode: _directionsMode,
      );
      if (!mounted || requestId != _directionsRequestId) {
        return;
      }
      setState(() {
        _directionsRoute = route;
        _remainingDistanceMeters = route.distanceMeters;
        _remainingDurationMillis = route.durationMillis;
        _isReroutingDirections = false;
      });
    } on Object {
      if (!mounted || requestId != _directionsRequestId) {
        return;
      }
      setState(() {
        _isReroutingDirections = false;
        _directionsTrackingError = '경로를 다시 찾지 못했어요.';
      });
    }
  }

  void _showDirectionsError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
    unawaited(_persistFavorites());
  }

  void _toggleSelectedPublicFacilityFavorite() {
    final facility = _selectedPublicFacility;
    if (facility == null) return;
    setState(() {
      if (_favoritePublicFacilities.containsKey(facility.id)) {
        _favoritePublicFacilities.remove(facility.id);
        if (_filter == '전체') _selectedPublicFacility = null;
      } else {
        _favoritePublicFacilities[facility.id] = facility;
      }
    });
    unawaited(_persistFavorites());
  }

  void _toggleSelectedParkingFavorite() {
    final parkingLot = _selectedParkingLot;
    if (parkingLot == null) return;
    setState(() {
      if (_favoriteParkingLots.containsKey(parkingLot.id)) {
        _favoriteParkingLots.remove(parkingLot.id);
        if (_filter == '전체') _selectedParkingLot = null;
      } else {
        _favoriteParkingLots[parkingLot.id] = parkingLot;
      }
    });
    unawaited(_persistFavorites());
  }

  void _toggleSelectedHousingFavorite() {
    final deal = _selectedHousingDeal;
    if (deal == null) return;
    setState(() {
      if (_favoriteHousingDeals.containsKey(deal.id)) {
        _favoriteHousingDeals.remove(deal.id);
        if (_filter == '전체') _selectedHousingDeal = null;
      } else {
        _favoriteHousingDeals[deal.id] = deal;
      }
    });
    unawaited(_persistFavorites());
  }

  @override
  Widget build(BuildContext context) {
    final places = _visiblePlaces;
    final isGoodPrice = _filter == '착한가격업소';
    final isPublicFacility = _filter == '공공시설';
    final isPublicParking = _filter == '공영주차장';
    final isHousing = _filter == '주거지';
    final isMy = _filter == '전체';
    final showsAllMyFavorites = _selectedMyFavoriteType == null;
    final showsMyGoodPrice =
        showsAllMyFavorites || _selectedMyFavoriteType == _myGoodPriceKey;
    final showsMyPublicFacility =
        showsAllMyFavorites || _selectedMyFavoriteType == _myPublicFacilityKey;
    final showsMyPublicParking =
        showsAllMyFavorites || _selectedMyFavoriteType == _myPublicParkingKey;
    final showsMyHousing =
        showsAllMyFavorites || _selectedMyFavoriteType == _myHousingKey;
    final visibleGoodPriceStores = _visibleGoodPriceStores;
    final visiblePublicFacilities = _visiblePublicFacilities;
    final visibleParkingLots = _visibleParkingLots;
    final visibleHousingDeals = _visibleHousingDeals;
    final categoryGoodPriceStores = visibleGoodPriceStores
        .where(
          (store) => goodPriceStoreMatchesCategory(
            store,
            _selectedGoodPriceCategoryKey,
          ),
        )
        .toList(growable: false);
    final categoryHousingDeals = visibleHousingDeals
        .where(
          (deal) =>
              _selectedHousingPropertyType == null ||
              deal.propertyType == _selectedHousingPropertyType,
        )
        .toList(growable: false);
    final mapGoodPriceStores = isMy
        ? showsMyGoodPrice
            ? _favoriteGoodPriceStores.values.toList(growable: false)
            : const <GoodPriceStore>[]
        : goodPriceStoresForMap(
            filter: _filter,
            visibleStores: categoryGoodPriceStores,
            favoriteStores: _favoriteGoodPriceStores.values,
          );
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleSpacing: 16,
        title: SizedBox(
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
                    label: filter == '전체' ? 'MY' : filter,
                    selected: _filter == filter,
                    onTap: () => _changeFilter(filter),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: SavingMapCanvas(
              places: places,
              goodPriceStores: mapGoodPriceStores,
              publicFacilities: isMy
                  ? showsMyPublicFacility
                      ? _favoritePublicFacilities.values.toList(growable: false)
                      : const []
                  : isPublicFacility
                      ? visiblePublicFacilities
                      : const [],
              parkingLots: isMy
                  ? showsMyPublicParking
                      ? _favoriteParkingLots.values.toList(growable: false)
                      : const []
                  : isPublicParking
                      ? visibleParkingLots
                      : const [],
              housingDeals: isMy
                  ? showsMyHousing
                      ? _favoriteHousingDeals.values.toList(growable: false)
                      : const []
                  : isHousing
                      ? categoryHousingDeals
                      : const [],
              directionsRoute: _directionsRoute,
              onPlaceTap: (place) {
                setState(() => _selectedPlace = place);
              },
              onGoodPriceStoreTap: _selectGoodPriceStore,
              onPublicFacilityTap: _selectPublicFacility,
              onParkingLotTap: _selectParkingLot,
              onHousingDealTap: _selectHousingDeal,
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
              selectedPublicFacility: _selectedPublicFacility,
              selectedParkingLot: _selectedParkingLot,
              selectedHousingDeal: _selectedHousingDeal,
              isSelectedStoreFavorite: _selectedGoodPriceStore != null &&
                  _favoriteGoodPriceStores.containsKey(
                    _selectedGoodPriceStore!.id,
                  ),
              isSelectedFacilityFavorite: _selectedPublicFacility != null &&
                  _favoritePublicFacilities.containsKey(
                    _selectedPublicFacility!.id,
                  ),
              isSelectedParkingFavorite: _selectedParkingLot != null &&
                  _favoriteParkingLots.containsKey(_selectedParkingLot!.id),
              isSelectedHousingFavorite: _selectedHousingDeal != null &&
                  _favoriteHousingDeals.containsKey(_selectedHousingDeal!.id),
              selectedStoreSpendingSummary: _selectedGoodPriceStore == null
                  ? null
                  : _goodPriceSpendingSummary(_selectedGoodPriceStore!),
              selectedParkingSpendingSummary: _selectedParkingLot == null
                  ? null
                  : _parkingSpendingSummary(_selectedParkingLot!),
              onStoreFavoritePressed: _toggleSelectedGoodPriceStoreFavorite,
              onFacilityFavoritePressed: _toggleSelectedPublicFacilityFavorite,
              onParkingFavoritePressed: _toggleSelectedParkingFavorite,
              onHousingFavoritePressed: _toggleSelectedHousingFavorite,
              onDirectionsPressed: () {
                unawaited(_openSelectedGoodPriceStoreDirections());
              },
              onGoodPriceStoreCardTap: _showGoodPriceStoreDetail,
              onPublicFacilityDirectionsPressed: () {
                unawaited(_openSelectedPublicFacilityDirections());
              },
              onPublicFacilityCardTap: _showPublicFacilityDetail,
              onParkingDirectionsPressed: () {
                unawaited(_openSelectedParkingDirections());
              },
              onParkingCardTap: _showParkingDetail,
              onGoodPriceStoreDismissed: () {
                if (_selectedGoodPriceStore != null) {
                  setState(() => _selectedGoodPriceStore = null);
                }
              },
              onPublicFacilityDismissed: () {
                if (_selectedPublicFacility != null) {
                  setState(() => _selectedPublicFacility = null);
                }
              },
              onParkingDismissed: () {
                if (_selectedParkingLot != null) {
                  setState(() => _selectedParkingLot = null);
                }
              },
              onHousingDealCardTap: _showHousingDealDetail,
              onHousingDealDismissed: () {
                if (_selectedHousingDeal != null) {
                  setState(() => _selectedHousingDeal = null);
                }
              },
            ),
          ),
          if ((isMy ||
                  isGoodPrice ||
                  isPublicFacility ||
                  isPublicParking ||
                  isHousing) &&
              !_isLoadingDirections &&
              _directionsRoute == null)
            Positioned(
              key: const ValueKey('map-category-panel'),
              left: 16,
              right: 16,
              bottom: 16,
              child: switch (_filter) {
                '전체' => _MyFavoritesCategoryBar(
                    goodPriceCount: _favoriteGoodPriceStores.length,
                    publicFacilityCount: _favoritePublicFacilities.length,
                    publicParkingCount: _favoriteParkingLots.length,
                    housingCount: _favoriteHousingDeals.length,
                    selectedType: _selectedMyFavoriteType,
                    onTypeSelected: _selectMyFavoriteType,
                  ),
                '착한가격업소' => _GoodPriceCategorySummary(
                    stores: visibleGoodPriceStores,
                    selectedCategoryKey: _selectedGoodPriceCategoryKey,
                    onCategorySelected: _selectGoodPriceCategory,
                  ),
                '공공시설' => _PublicFacilityCategoryBar(
                    facilities: _publicFacilities,
                    selectedCategory: _selectedPublicFacilityCategory,
                    freeOnly: _publicFacilityFreeOnly,
                    isLoading: _isLoadingPublicFacilities,
                    error: _publicFacilityError,
                    onRetry: _loadPublicFacilities,
                    onCategorySelected: _selectPublicFacilityCategory,
                  ),
                '공영주차장' => _PublicParkingTypeBar(
                    parkingLots: _parkingLots,
                    selectedParkingType: _selectedParkingType,
                    freeOnly: _parkingFreeOnly,
                    isLoading: _isLoadingParkingLots,
                    error: _parkingError,
                    onRetry: _loadParkingLots,
                    onParkingTypeSelected: _selectParkingType,
                  ),
                _ => _HousingPropertyTypeBar(
                    deals: visibleHousingDeals,
                    selectedPropertyType: _selectedHousingPropertyType,
                    onPropertyTypeSelected: _selectHousingPropertyType,
                  ),
              },
            ),
          if (_isLoadingDirections || _directionsRoute != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _DirectionsSummaryCard(
                destinationName: _directionsDestinationName ?? '목적지',
                route: _directionsRoute,
                mode: _directionsMode,
                isLoading: _isLoadingDirections,
                remainingDistanceMeters: _remainingDistanceMeters,
                remainingDurationMillis: _remainingDurationMillis,
                isRerouting: _isReroutingDirections,
                trackingError: _directionsTrackingError,
                onClose: _clearDirections,
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
            )
        ],
      ),
    );
  }
}

class _MyFavoritesCategoryBar extends StatelessWidget {
  const _MyFavoritesCategoryBar({
    required this.goodPriceCount,
    required this.publicFacilityCount,
    required this.publicParkingCount,
    required this.housingCount,
    required this.selectedType,
    required this.onTypeSelected,
  });

  final int goodPriceCount;
  final int publicFacilityCount;
  final int publicParkingCount;
  final int housingCount;
  final String? selectedType;
  final ValueChanged<String> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    return _MapBannerList(
      options: [
        _MapBannerOption(
          key: _allBannerKey,
          label: '전체',
          count: goodPriceCount +
              publicFacilityCount +
              publicParkingCount +
              housingCount,
          color: AppColors.danger,
          icon: Icons.favorite_rounded,
        ),
        _MapBannerOption(
          key: _myGoodPriceKey,
          label: '착한가격업소',
          count: goodPriceCount,
          color: AppColors.pinGoodPrice,
          icon: Icons.storefront_rounded,
        ),
        _MapBannerOption(
          key: _myPublicFacilityKey,
          label: '공공시설',
          count: publicFacilityCount,
          color: AppColors.pinPublic,
          icon: Icons.account_balance_rounded,
        ),
        _MapBannerOption(
          key: _myPublicParkingKey,
          label: '공영주차장',
          count: publicParkingCount,
          color: AppColors.pinParking,
          icon: Icons.local_parking_rounded,
        ),
        _MapBannerOption(
          key: _myHousingKey,
          label: '주거지',
          count: housingCount,
          color: AppColors.categoryLeisure,
          icon: Icons.home_rounded,
        ),
      ],
      selectedKey: selectedType ?? _allBannerKey,
      keyPrefix: 'my-favorite-type',
      onSelected: onTypeSelected,
      favoriteCounts: true,
      maxColumns: 2,
    );
  }
}

class _PublicParkingPanel extends StatelessWidget {
  const _PublicParkingPanel({
    required this.parkingLots,
    required this.isLoading,
    required this.error,
    required this.freeOnly,
    required this.onRetry,
    required this.onFreeOnlyChanged,
    required this.onParkingSelected,
  });

  final List<PublicParkingLot> parkingLots;
  final bool isLoading;
  final String? error;
  final bool freeOnly;
  final VoidCallback onRetry;
  final ValueChanged<bool> onFreeOnlyChanged;
  final ValueChanged<PublicParkingLot> onParkingSelected;

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
                  '현재 화면의 공영주차장',
                  style: AppTextStyles.sectionTitle,
                ),
              ),
              Text('${parkingLots.length}곳', style: AppTextStyles.caption),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(
                  '무료',
                  style: freeOnly
                      ? AppTextStyles.caption.copyWith(
                          color: AppColors.surface,
                        )
                      : null,
                ),
                selected: freeOnly,
                onSelected: onFreeOnlyChanged,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '주차장을 누르면 요금과 운영시간을 확인할 수 있어요.',
            style: AppTextStyles.captionTiny,
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading && parkingLots.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text(
              '공영주차장 데이터를 준비하고 있어요.',
              style: AppTextStyles.bodyMuted,
            ),
          ],
        ),
      );
    }
    if (error != null && parkingLots.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMuted,
            ),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (parkingLots.isEmpty) {
      return const Center(
        child: Text(
          '현재 지도 화면에 확인된 공영주차장이 없어요.',
          style: AppTextStyles.bodyMuted,
        ),
      );
    }

    return Stack(
      children: [
        ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: parkingLots.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final parkingLot = parkingLots[index];
            return Semantics(
              button: true,
              label: '${parkingLot.name}, ${parkingLot.feeLabel}',
              child: InkWell(
                onTap: () => onParkingSelected(parkingLot),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 190,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '공영 · ${parkingLot.parkingType}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionTiny.copyWith(
                          color: AppColors.pinParking,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        parkingLot.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${parkingLot.distanceLabel} · ${parkingLot.feeLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: parkingLot.free
                              ? AppColors.primaryDeep
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (isLoading)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

class _PublicFacilityPanel extends StatelessWidget {
  const _PublicFacilityPanel({
    required this.facilities,
    required this.isLoading,
    required this.error,
    required this.freeOnly,
    required this.onRetry,
    required this.onFreeOnlyChanged,
    required this.onFacilitySelected,
  });

  final List<PublicFacility> facilities;
  final bool isLoading;
  final String? error;
  final bool freeOnly;
  final VoidCallback onRetry;
  final ValueChanged<bool> onFreeOnlyChanged;
  final ValueChanged<PublicFacility> onFacilitySelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('현재 화면의 공공시설', style: AppTextStyles.sectionTitle),
              ),
              Text('${facilities.length}곳', style: AppTextStyles.caption),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(
                  '무료',
                  style: freeOnly
                      ? const TextStyle(color: AppColors.surface)
                      : null,
                ),
                selected: freeOnly,
                onSelected: onFreeOnlyChanged,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            '시설을 누르면 위치와 상세 정보를 확인할 수 있어요.',
            style: AppTextStyles.captionTiny,
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading && facilities.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 8),
            Text('공공시설 데이터를 준비하고 있어요.', style: AppTextStyles.bodyMuted),
          ],
        ),
      );
    }
    if (error != null && facilities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMuted,
            ),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (facilities.isEmpty) {
      return const Center(
        child: Text('현재 지도 화면에 확인된 공공시설이 없어요.', style: AppTextStyles.bodyMuted),
      );
    }

    return Stack(
      children: [
        ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: facilities.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final facility = facilities[index];
            return Semantics(
              button: true,
              label: '${facility.name}, ${facility.feeLabel}',
              child: InkWell(
                onTap: () => onFacilitySelected(facility),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 190,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        facility.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionTiny,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        facility.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${facility.distanceLabel} · ${facility.feeLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: facility.isFree
                              ? AppColors.primaryDeep
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        if (isLoading)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

class _DirectionsSummaryCard extends StatelessWidget {
  const _DirectionsSummaryCard({
    required this.destinationName,
    required this.route,
    required this.mode,
    required this.isLoading,
    required this.remainingDistanceMeters,
    required this.remainingDurationMillis,
    required this.isRerouting,
    required this.trackingError,
    required this.onClose,
  });

  final String destinationName;
  final DirectionsRoute? route;
  final DirectionsMode mode;
  final bool isLoading;
  final int? remainingDistanceMeters;
  final int? remainingDurationMillis;
  final bool isRerouting;
  final String? trackingError;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('directions-summary-card'),
      borderColor: AppColors.primary,
      child: isLoading ? _buildLoading() : _buildRoute(route!),
    );
  }

  Widget _buildLoading() {
    final routeType = mode == DirectionsMode.driving ? '자동차' : '도보';
    return Row(
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '$destinationName $routeType 경로를 찾고 있어요.',
            style: AppTextStyles.body,
          ),
        ),
        IconButton(
          tooltip: '길찾기 취소',
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  Widget _buildRoute(DirectionsRoute route) {
    final isDriving = mode == DirectionsMode.driving;
    final routeType = isDriving ? '자동차' : '도보';
    final liveDistanceMeters = remainingDistanceMeters ?? route.distanceMeters;
    final liveDurationMillis = remainingDurationMillis ?? route.durationMillis;
    final durationMinutes = (liveDurationMillis / 60000).ceil();
    final distance = liveDistanceMeters >= 1000
        ? '${(liveDistanceMeters / 1000).toStringAsFixed(1)}km'
        : '${liveDistanceMeters}m';
    final trackingStatus =
        trackingError ?? (isRerouting ? '경로를 다시 찾고 있어요.' : '실시간 위치를 반영하고 있어요.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isDriving
                  ? Icons.directions_car_rounded
                  : Icons.directions_walk_rounded,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$destinationName $routeType 추천 경로',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionTitle,
              ),
            ),
            IconButton(
              tooltip: '경로 닫기',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '$distance · 약 $durationMinutes분',
          style: AppTextStyles.amount.copyWith(color: AppColors.primaryDeep),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (isRerouting)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  trackingError == null
                      ? Icons.my_location_rounded
                      : Icons.location_disabled_rounded,
                  size: 14,
                  color: trackingError == null
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            Expanded(
              child: Text(
                trackingStatus,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
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

class _MapBannerOption {
  const _MapBannerOption({
    required this.key,
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String key;
  final String label;
  final int count;
  final Color color;
  final IconData icon;
}

class _MapCategoryBanner extends StatelessWidget {
  const _MapCategoryBanner({
    super.key,
    required this.label,
    required this.countLabel,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.width = 132,
  });

  final String label;
  final String countLabel;
  final Color color;
  final Widget icon;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label, $countLabel',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: width,
          transform: Matrix4.translationValues(0, isSelected ? -6 : 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.55),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 26,
                height: 31,
                child: FittedBox(fit: BoxFit.contain, child: icon),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: isSelected
                            ? AppColors.surface
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      countLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionTiny.copyWith(
                        color: isSelected
                            ? AppColors.surface.withValues(alpha: 0.9)
                            : AppColors.textSecondary,
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
  }
}

class _PublicFacilityCategoryBar extends StatelessWidget {
  const _PublicFacilityCategoryBar({
    required this.facilities,
    required this.selectedCategory,
    required this.freeOnly,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onCategorySelected,
  });

  final List<PublicFacility> facilities;
  final String? selectedCategory;
  final bool freeOnly;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<String> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final facility in facilities) {
      final category = _facilityCategory(facility);
      counts[category] = (counts[category] ?? 0) + 1;
    }
    final categories = counts.entries.toList()
      ..sort((left, right) {
        final countOrder = right.value.compareTo(left.value);
        return countOrder != 0 ? countOrder : left.key.compareTo(right.key);
      });
    final options = <_MapBannerOption>[
      const _MapBannerOption(
        key: _allBannerKey,
        label: '전체',
        count: 0,
        color: AppColors.pinPublic,
        icon: Icons.account_balance_rounded,
      ),
      _MapBannerOption(
        key: _freeBannerKey,
        label: '무료',
        count: facilities.where((facility) => facility.isFree).length,
        color: AppColors.primary,
        icon: Icons.money_off_rounded,
      ),
      for (final category in categories)
        _MapBannerOption(
          key: category.key,
          label: category.key,
          count: category.value,
          color: _facilityBannerColor(category.key),
          icon: PublicFacilityMarkerStyle.fromCategory(category.key).icon,
        ),
    ];

    return _MapBannerLoadState(
      isLoading: isLoading,
      error: error,
      isEmpty: facilities.isEmpty,
      loadingMessage: '공공시설 데이터를 준비하고 있어요.',
      onRetry: onRetry,
      child: _MapBannerList(
        options: [
          _MapBannerOption(
            key: options.first.key,
            label: options.first.label,
            count: facilities.length,
            color: options.first.color,
            icon: options.first.icon,
          ),
          ...options.skip(1),
        ],
        selectedKey:
            freeOnly ? _freeBannerKey : selectedCategory ?? _allBannerKey,
        keyPrefix: 'public-facility-category',
        onSelected: onCategorySelected,
        maxColumns: 2,
      ),
    );
  }
}

class _PublicParkingTypeBar extends StatelessWidget {
  const _PublicParkingTypeBar({
    required this.parkingLots,
    required this.selectedParkingType,
    required this.freeOnly,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.onParkingTypeSelected,
  });

  final List<PublicParkingLot> parkingLots;
  final String? selectedParkingType;
  final bool freeOnly;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final ValueChanged<String> onParkingTypeSelected;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final parkingLot in parkingLots) {
      final parkingType = _parkingType(parkingLot);
      counts[parkingType] = (counts[parkingType] ?? 0) + 1;
    }
    final parkingTypes = counts.entries.toList()
      ..sort((left, right) {
        final countOrder = right.value.compareTo(left.value);
        return countOrder != 0 ? countOrder : left.key.compareTo(right.key);
      });
    final options = <_MapBannerOption>[
      _MapBannerOption(
        key: _allBannerKey,
        label: '전체',
        count: parkingLots.length,
        color: AppColors.pinParking,
        icon: Icons.local_parking_rounded,
      ),
      _MapBannerOption(
        key: _freeBannerKey,
        label: '무료',
        count: parkingLots.where((parkingLot) => parkingLot.free).length,
        color: AppColors.primary,
        icon: Icons.money_off_rounded,
      ),
      for (final parkingType in parkingTypes)
        _MapBannerOption(
          key: parkingType.key,
          label: parkingType.key,
          count: parkingType.value,
          color: _parkingBannerColor(parkingType.key),
          icon: _parkingBannerIcon(parkingType.key),
        ),
    ];

    return _MapBannerLoadState(
      isLoading: isLoading,
      error: error,
      isEmpty: parkingLots.isEmpty,
      loadingMessage: '공영주차장 데이터를 준비하고 있어요.',
      onRetry: onRetry,
      child: _MapBannerList(
        options: options,
        selectedKey:
            freeOnly ? _freeBannerKey : selectedParkingType ?? _allBannerKey,
        keyPrefix: 'public-parking-type',
        onSelected: onParkingTypeSelected,
      ),
    );
  }
}

class _MapBannerLoadState extends StatelessWidget {
  const _MapBannerLoadState({
    required this.isLoading,
    required this.error,
    required this.isEmpty,
    required this.loadingMessage,
    required this.onRetry,
    required this.child,
  });

  final bool isLoading;
  final String? error;
  final bool isEmpty;
  final String loadingMessage;
  final VoidCallback onRetry;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isLoading && isEmpty) {
      return SizedBox(
        height: 70,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(width: 10),
              Text(loadingMessage, style: AppTextStyles.bodyMuted),
            ],
          ),
        ),
      );
    }
    if (error != null && isEmpty) {
      return SizedBox(
        height: 70,
        child: Row(
          children: [
            Expanded(
              child: Text(
                error!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMuted,
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    return Stack(
      children: [
        child,
        if (isLoading)
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

class _MapBannerList extends StatelessWidget {
  const _MapBannerList({
    required this.options,
    required this.selectedKey,
    required this.keyPrefix,
    required this.onSelected,
    this.favoriteCounts = false,
    this.countUnit = '곳',
    this.maxColumns = 3,
    this.iconBuilder,
  });

  final List<_MapBannerOption> options;
  final String selectedKey;
  final String keyPrefix;
  final ValueChanged<String> onSelected;
  final bool favoriteCounts;
  final String countUnit;
  final int maxColumns;
  final Widget Function(_MapBannerOption option)? iconBuilder;

  @override
  Widget build(BuildContext context) {
    final visibleOptions =
        options.where((option) => option.count > 0).toList(growable: false);
    if (visibleOptions.isEmpty) {
      return const SizedBox.shrink();
    }

    Widget buildBanner(_MapBannerOption option, double width) {
      return _MapCategoryBanner(
        key: ValueKey('$keyPrefix-${option.key}'),
        label: option.label,
        countLabel: favoriteCounts
            ? '찜 ${option.count}개'
            : '주변 ${option.count}$countUnit',
        color: option.color,
        icon: iconBuilder?.call(option) ??
            PublicFacilityMarkerIcon(
              style: PublicFacilityMarkerStyle(
                color: option.color,
                icon: option.icon,
              ),
            ),
        isSelected: selectedKey == option.key,
        onTap: () => onSelected(option.key),
        width: width,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = visibleOptions.length < maxColumns
            ? visibleOptions.length
            : maxColumns;
        final bannerWidth = constraints.hasBoundedWidth
            ? (constraints.maxWidth - (columns - 1) * 8) / columns
            : 104.0;
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in visibleOptions)
                buildBanner(option, bannerWidth),
            ],
          ),
        );
      },
    );
  }
}

String _facilityCategory(PublicFacility facility) {
  final category = facility.category.trim();
  return category.isEmpty ? '기타 시설' : category;
}

String _parkingType(PublicParkingLot parkingLot) {
  final parkingType = parkingLot.parkingType.trim();
  return parkingType.isEmpty ? '기타 주차장' : parkingType;
}

Color _facilityBannerColor(String category) {
  final normalized = category.trim();
  if (normalized.contains('회의') || normalized.contains('강의')) {
    return AppColors.info;
  }
  if (_containsAny(normalized, ['체육', '운동', '구장', '골프', '수영'])) {
    return AppColors.primary;
  }
  if (_containsAny(normalized, ['공연', '강당', '문화', '전시'])) {
    return AppColors.categoryLeisure;
  }
  if (_containsAny(normalized, ['공원', '야외', '광장'])) {
    return AppColors.primaryDark;
  }
  return AppColors.pinPublic;
}

Color _parkingBannerColor(String parkingType) {
  final normalized = parkingType.trim();
  if (normalized.contains('노외')) return AppColors.info;
  if (normalized.contains('부설')) return AppColors.categoryLeisure;
  if (normalized.contains('노상')) return AppColors.pinParking;
  return AppColors.warning;
}

IconData _parkingBannerIcon(String parkingType) {
  final normalized = parkingType.trim();
  if (normalized.contains('노외')) return Icons.directions_car_rounded;
  if (normalized.contains('부설')) return Icons.domain_rounded;
  return Icons.local_parking_rounded;
}

bool _containsAny(String value, List<String> keywords) {
  return keywords.any(value.contains);
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
    final styles = {
      for (final summary in summaries)
        summary.key: GoodPriceStoreMarkerStyle.fromCategory(
          summary.markerCategory,
        ),
    };
    return _MapBannerList(
      options: [
        for (final summary in summaries)
          _MapBannerOption(
            key: summary.key,
            label: summary.label,
            count: summary.count,
            color: styles[summary.key]!.color,
            icon: styles[summary.key]!.icon,
          ),
      ],
      selectedKey: selectedCategoryKey ?? 'all',
      keyPrefix: 'good-price-category',
      onSelected: onCategorySelected,
      iconBuilder: (option) => GoodPriceStoreMarkerIcon(
        style: GoodPriceStoreMarkerStyle(
          color: option.color,
          icon: option.icon,
        ),
      ),
    );
  }
}

class _HousingDealPanel extends StatelessWidget {
  const _HousingDealPanel({
    required this.deals,
    required this.isLoading,
    required this.error,
    required this.regionLabel,
    required this.isLocating,
    required this.locationError,
    required this.onRetry,
    required this.onLocationRetry,
  });

  final List<HousingRentDeal> deals;
  final bool isLoading;
  final String? error;
  final String? regionLabel;
  final bool isLocating;
  final String? locationError;
  final VoidCallback onRetry;
  final VoidCallback onLocationRetry;

  @override
  Widget build(BuildContext context) {
    final singleFamily =
        deals.where((deal) => deal.propertyType == '단독/다가구').length;
    final officetel = deals.where((deal) => deal.propertyType == '오피스텔').length;
    final jeonse = deals.where((deal) => deal.dealType == '전세').length;
    final monthlyRent = deals.where((deal) => deal.dealType == '월세').length;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('주거 실거래', style: AppTextStyles.sectionTitle),
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
                  '${deals.length}건',
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
                : '$regionLabel · 최근 3개월 최신 거래',
            style: AppTextStyles.captionTiny,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _buildContent(
              singleFamily: singleFamily,
              officetel: officetel,
              jeonse: jeonse,
              monthlyRent: monthlyRent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required int singleFamily,
    required int officetel,
    required int jeonse,
    required int monthlyRent,
  }) {
    if (isLocating || (isLoading && deals.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }
    if (locationError != null) {
      return _HousingPanelError(
        message: locationError!,
        onRetry: onLocationRetry,
      );
    }
    if (error != null && deals.isEmpty) {
      return _HousingPanelError(message: error!, onRetry: onRetry);
    }
    if (deals.isEmpty) {
      return const Center(
        child: Text(
          '현재 지도 화면에 표시할 최근 거래가 없어요.',
          style: AppTextStyles.bodyMuted,
        ),
      );
    }
    final singleStyle = HousingDealMarkerStyle.fromPropertyType('단독/다가구');
    final officetelStyle = HousingDealMarkerStyle.fromPropertyType('오피스텔');
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _HousingCount(
          icon: singleStyle.icon,
          color: singleStyle.color,
          label: '단독/다가구',
          count: singleFamily,
        ),
        _HousingCount(
          icon: officetelStyle.icon,
          color: officetelStyle.color,
          label: '오피스텔',
          count: officetel,
        ),
        _HousingCount(
          icon: Icons.key_rounded,
          color: AppColors.primary,
          label: '전세',
          count: jeonse,
        ),
        _HousingCount(
          icon: Icons.payments_outlined,
          color: AppColors.danger,
          label: '월세',
          count: monthlyRent,
        ),
      ],
    );
  }
}

class _HousingCount extends StatelessWidget {
  const _HousingCount({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 23),
        const SizedBox(height: 3),
        Text(label, style: AppTextStyles.captionTiny),
        Text(
          '$count건',
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HousingPanelError extends StatelessWidget {
  const _HousingPanelError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMuted,
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    );
  }
}

class _HousingPropertyTypeBar extends StatelessWidget {
  const _HousingPropertyTypeBar({
    required this.deals,
    required this.selectedPropertyType,
    required this.onPropertyTypeSelected,
  });

  final List<HousingRentDeal> deals;
  final String? selectedPropertyType;
  final ValueChanged<String> onPropertyTypeSelected;

  @override
  Widget build(BuildContext context) {
    const propertyTypes = ['단독/다가구', '오피스텔'];
    return _MapBannerList(
      options: [
        for (final propertyType in propertyTypes)
          _MapBannerOption(
            key: propertyType,
            label: propertyType,
            count:
                deals.where((deal) => deal.propertyType == propertyType).length,
            color: HousingDealMarkerStyle.fromPropertyType(propertyType).color,
            icon: HousingDealMarkerStyle.fromPropertyType(propertyType).icon,
          ),
      ],
      selectedKey: selectedPropertyType ?? '',
      keyPrefix: 'housing-property-type',
      onSelected: onPropertyTypeSelected,
      countUnit: '건',
      maxColumns: 2,
      iconBuilder: (option) => HousingDealMarkerIcon(
        style: HousingDealMarkerStyle(
          color: option.color,
          icon: option.icon,
        ),
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
