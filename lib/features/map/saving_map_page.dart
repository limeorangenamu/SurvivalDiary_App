import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

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
import 'good_price_store_category_summary.dart';
import 'good_price_store_detail_page.dart';
import 'good_price_store_distance.dart';
import 'good_price_store_marker_style.dart';
import 'good_price_store_visibility.dart';
import 'housing_deal_detail_page.dart';
import 'housing_deal_marker_style.dart';
import 'housing_lawd_code.dart';
import 'place_detail_page.dart';
import 'widgets/map_canvas.dart';
import 'widgets/public_facility_detail_sheet.dart';
import 'widgets/public_parking_detail_sheet.dart';

class SavingMapPage extends StatefulWidget {
  const SavingMapPage({super.key});

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

  String _filter = '전체';
  int _sortIndex = 0;
  SavingPlace? _selectedPlace;
  GoodPriceStore? _selectedGoodPriceStore;
  PublicFacility? _selectedPublicFacility;
  PublicParkingLot? _selectedParkingLot;
  HousingRentDeal? _selectedHousingDeal;
  String? _selectedGoodPriceCategoryKey;
  final Map<String, GoodPriceStore> _favoriteGoodPriceStores = {};
  NaverMapController? _mapController;
  List<GoodPriceStore> _goodPriceStores = const [];
  List<PublicFacility> _publicFacilities = const [];
  List<PublicParkingLot> _parkingLots = const [];
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

  void _changeFilter(String value) {
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
      _directionsRequestId++;
      if (value != '착한가격업소') {
        _selectedGoodPriceCategoryKey = null;
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
    setState(() {
      _selectedGoodPriceStore = store;
      _selectedPublicFacility = null;
      _selectedParkingLot = null;
      _selectedHousingDeal = null;
      _directionsRoute = null;
      _directionsDestinationName = null;
      _isLoadingDirections = false;
      _directionsRequestId++;
    });
  }

  void _selectPublicFacility(PublicFacility facility) {
    setState(() {
      _selectedPublicFacility = facility;
      _selectedGoodPriceStore = null;
      _selectedParkingLot = null;
      _selectedHousingDeal = null;
      _directionsRoute = null;
      _directionsDestinationName = null;
      _isLoadingDirections = false;
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
        builder: (_) => GoodPriceStoreDetailPage(store: store),
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
    setState(() {
      _selectedParkingLot = parkingLot;
      _selectedGoodPriceStore = null;
      _selectedPublicFacility = null;
      _selectedHousingDeal = null;
      _directionsRoute = null;
      _directionsDestinationName = null;
      _isLoadingDirections = false;
      _directionsRequestId++;
    });
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
          onDirectionsPressed: () {
            Navigator.of(sheetContext).pop();
            unawaited(_openParkingDirections(parkingLot));
          },
        ),
      ),
    );
  }

  void _selectHousingDeal(HousingRentDeal deal) {
    setState(() {
      _selectedHousingDeal = deal;
      _selectedGoodPriceStore = null;
      _selectedPublicFacility = null;
      _selectedParkingLot = null;
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

    final requestId = ++_directionsRequestId;
    setState(() {
      _isLoadingDirections = true;
      _directionsRoute = null;
      _directionsDestinationName = destinationName;
      _directionsMode = mode;
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
        _isLoadingDirections = false;
        _selectedGoodPriceStore = null;
        _selectedPublicFacility = null;
        _selectedParkingLot = null;
        _selectedHousingDeal = null;
      });
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
    setState(() {
      _directionsRequestId++;
      _directionsRoute = null;
      _directionsDestinationName = null;
      _directionsMode = DirectionsMode.walking;
      _isLoadingDirections = false;
    });
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
  }

  @override
  Widget build(BuildContext context) {
    final places = _visiblePlaces;
    final isGoodPrice = _filter == '착한가격업소';
    final isPublicFacility = _filter == '공공시설';
    final isPublicParking = _filter == '공영주차장';
    final isHousing = _filter == '주거지';
    final visibleGoodPriceStores = _visibleGoodPriceStores;
    final visibleHousingDeals = _visibleHousingDeals;
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
              publicFacilities: isPublicFacility ? _publicFacilities : const [],
              parkingLots: isPublicParking ? _parkingLots : const [],
              housingDeals: isHousing ? visibleHousingDeals : const [],
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
              onFavoritePressed: _toggleSelectedGoodPriceStoreFavorite,
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
                        label: filter == '전체' ? 'MY' : filter,
                        selected: _filter == filter,
                        onTap: () => _changeFilter(filter),
                      ),
                    ),
                ],
              ),
            ),
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
                onClose: _clearDirections,
              ),
            )
          else if (isGoodPrice)
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
          else if (isPublicFacility)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              height: 210,
              child: _PublicFacilityPanel(
                facilities: _publicFacilities,
                isLoading: _isLoadingPublicFacilities,
                error: _publicFacilityError,
                freeOnly: _publicFacilityFreeOnly,
                onRetry: _loadPublicFacilities,
                onFreeOnlyChanged: (value) {
                  setState(() {
                    _publicFacilityFreeOnly = value;
                    _selectedPublicFacility = null;
                    _publicFacilities = const [];
                  });
                  unawaited(_loadPublicFacilities());
                },
                onFacilitySelected: _selectPublicFacility,
              ),
            )
          else if (isPublicParking)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              height: 210,
              child: _PublicParkingPanel(
                parkingLots: _parkingLots,
                isLoading: _isLoadingParkingLots,
                error: _parkingError,
                freeOnly: _parkingFreeOnly,
                onRetry: _loadParkingLots,
                onFreeOnlyChanged: (value) {
                  setState(() {
                    _parkingFreeOnly = value;
                    _selectedParkingLot = null;
                    _parkingLots = const [];
                  });
                  unawaited(_loadParkingLots());
                },
                onParkingSelected: _selectParkingLot,
              ),
            )
          else if (_filter == '주거지')
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              height: 150,
              child: _HousingDealPanel(
                deals: visibleHousingDeals,
                isLoading: _isLoadingHousingDeals,
                error: _housingDealError,
                regionLabel: _viewportRegionLabel,
                isLocating: _isLocating,
                locationError: _locationError,
                onRetry: _loadHousingDeals,
                onLocationRetry: _refreshCurrentViewport,
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
    required this.onClose,
  });

  final String destinationName;
  final DirectionsRoute? route;
  final DirectionsMode mode;
  final bool isLoading;
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
    final durationMinutes = (route.durationMillis / 60000).ceil();
    final distance = route.distanceMeters >= 1000
        ? '${(route.distanceMeters / 1000).toStringAsFixed(1)}km'
        : '${route.distanceMeters}m';
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
