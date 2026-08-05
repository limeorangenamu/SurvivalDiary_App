import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../../core/services/directions_api_service.dart';
import '../../../core/services/good_price_api_service.dart';
import '../../../core/services/public_facility_api_service.dart';
import '../../../core/services/housing_rent_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models.dart';
import '../good_price_store_marker_style.dart';
import '../housing_deal_marker_style.dart';
import '../public_facility_marker_style.dart';
import 'good_price_store_map_card.dart';
import 'housing_deal_map_card.dart';
import 'public_facility_map_card.dart';

class MapViewport {
  const MapViewport({required this.center, required this.bounds});

  final NLatLng center;
  final NLatLngBounds bounds;
}

class SavingMapCanvas extends StatefulWidget {
  const SavingMapCanvas({
    super.key,
    required this.places,
    required this.goodPriceStores,
    required this.publicFacilities,
    required this.housingDeals,
    required this.directionsRoute,
    required this.onPlaceTap,
    required this.onGoodPriceStoreTap,
    required this.onPublicFacilityTap,
    required this.onHousingDealTap,
    required this.onMapReady,
    required this.onViewportChanged,
    required this.selectedGoodPriceStore,
    required this.selectedPublicFacility,
    required this.selectedHousingDeal,
    required this.isSelectedStoreFavorite,
    required this.onFavoritePressed,
    required this.onDirectionsPressed,
    required this.onGoodPriceStoreCardTap,
    required this.onPublicFacilityDirectionsPressed,
    required this.onPublicFacilityCardTap,
    required this.onGoodPriceStoreDismissed,
    required this.onPublicFacilityDismissed,
    required this.onHousingDealCardTap,
    required this.onHousingDealDismissed,
  });

  final List<SavingPlace> places;
  final List<GoodPriceStore> goodPriceStores;
  final List<PublicFacility> publicFacilities;
  final List<HousingRentDeal> housingDeals;
  final DirectionsRoute? directionsRoute;
  final ValueChanged<SavingPlace> onPlaceTap;
  final ValueChanged<GoodPriceStore> onGoodPriceStoreTap;
  final ValueChanged<PublicFacility> onPublicFacilityTap;
  final ValueChanged<HousingRentDeal> onHousingDealTap;
  final ValueChanged<NaverMapController> onMapReady;
  final ValueChanged<MapViewport> onViewportChanged;
  final GoodPriceStore? selectedGoodPriceStore;
  final PublicFacility? selectedPublicFacility;
  final HousingRentDeal? selectedHousingDeal;
  final bool isSelectedStoreFavorite;
  final VoidCallback onFavoritePressed;
  final VoidCallback onDirectionsPressed;
  final VoidCallback onGoodPriceStoreCardTap;
  final VoidCallback onPublicFacilityDirectionsPressed;
  final VoidCallback onPublicFacilityCardTap;
  final VoidCallback onGoodPriceStoreDismissed;
  final VoidCallback onPublicFacilityDismissed;
  final VoidCallback onHousingDealCardTap;
  final VoidCallback onHousingDealDismissed;

  @override
  State<SavingMapCanvas> createState() => _SavingMapCanvasState();
}

class _SavingMapCanvasState extends State<SavingMapCanvas> {
  NaverMapController? _controller;
  final Map<String, Future<NOverlayImage>> _goodPriceMarkerIcons = {};
  final Map<String, Future<NOverlayImage>> _publicFacilityMarkerIcons = {};
  final Map<String, Future<NOverlayImage>> _housingMarkerIcons = {};
  int _markerSyncId = 0;
  NPoint? _selectedStoreScreenPoint;
  NPoint? _selectedFacilityScreenPoint;
  NPoint? _selectedHousingScreenPoint;

  @override
  void didUpdateWidget(covariant SavingMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.places != widget.places ||
        oldWidget.goodPriceStores != widget.goodPriceStores ||
        oldWidget.publicFacilities != widget.publicFacilities ||
        oldWidget.housingDeals != widget.housingDeals) {
      unawaited(_syncMarkers());
    }
    if (oldWidget.directionsRoute != widget.directionsRoute) {
      unawaited(_syncDirectionsRoute());
    }
    if (oldWidget.selectedGoodPriceStore?.id !=
        widget.selectedGoodPriceStore?.id) {
      if (widget.selectedGoodPriceStore == null) {
        _selectedStoreScreenPoint = null;
      } else {
        unawaited(_updateSelectedStoreScreenPoint());
      }
    }
    if (oldWidget.selectedPublicFacility?.id !=
        widget.selectedPublicFacility?.id) {
      if (widget.selectedPublicFacility == null) {
        _selectedFacilityScreenPoint = null;
      } else {
        unawaited(_updateSelectedFacilityScreenPoint());
      }
    }
    if (oldWidget.selectedHousingDeal?.id != widget.selectedHousingDeal?.id) {
      if (widget.selectedHousingDeal == null) {
        _selectedHousingScreenPoint = null;
      } else {
        unawaited(_updateSelectedHousingScreenPoint());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return const SizedBox.expand();
    }

    return Stack(
      children: [
        Positioned.fill(
          child: NaverMap(
            forceGesture: true,
            options: const NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: NLatLng(36.35, 127.8),
                zoom: 7,
              ),
            ),
            onMapReady: (controller) async {
              _controller = controller;
              widget.onMapReady(controller);
              await _syncMarkers();
              await _syncDirectionsRoute();
            },
            onMapTapped: (_, __) => _dismissSelections(),
            onCameraChange: (_, __) {
              _dismissSelections();
            },
            onCameraIdle: () {
              unawaited(_notifyViewportChanged());
            },
          ),
        ),
        if (widget.selectedGoodPriceStore != null &&
            _selectedStoreScreenPoint != null)
          Positioned.fill(child: _buildSelectedStoreOverlay()),
        if (widget.selectedPublicFacility != null &&
            _selectedFacilityScreenPoint != null)
          Positioned.fill(child: _buildSelectedFacilityOverlay()),
        if (widget.selectedHousingDeal != null &&
            _selectedHousingScreenPoint != null)
          Positioned.fill(child: _buildSelectedHousingOverlay()),
      ],
    );
  }

  Widget _buildSelectedFacilityOverlay() {
    final facility = widget.selectedPublicFacility!;
    final point = _selectedFacilityScreenPoint!;
    const cardWidth = 270.0;
    const cardHeight = 158.0;
    return IgnorePointer(
      ignoring: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxLeft = (constraints.maxWidth - cardWidth - 8)
              .clamp(8.0, double.infinity);
          final left = (point.x - cardWidth / 2).clamp(8.0, maxLeft);
          final top = (point.y - cardHeight - 62).clamp(
            8.0,
            (constraints.maxHeight - cardHeight - 8)
                .clamp(8.0, double.infinity),
          );
          final pointerLeft = (point.x - left - 7).clamp(
            14.0,
            cardWidth - 28,
          );
          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                width: cardWidth,
                height: cardHeight,
                child: PublicFacilityMapCard(
                  facility: facility,
                  onDirectionsPressed: widget.onPublicFacilityDirectionsPressed,
                  onTap: widget.onPublicFacilityCardTap,
                ),
              ),
              Positioned(
                left: left + pointerLeft,
                top: top + cardHeight - 6,
                child: Transform.rotate(
                  angle: 0.785398,
                  child: Container(
                    width: 14,
                    height: 14,
                    color: AppColors.surface,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectedStoreOverlay() {
    final store = widget.selectedGoodPriceStore!;
    final point = _selectedStoreScreenPoint!;
    const cardWidth = 270.0;
    const cardHeight = 158.0;
    return IgnorePointer(
      ignoring: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxLeft = (constraints.maxWidth - cardWidth - 8)
              .clamp(8.0, double.infinity);
          final left = (point.x - cardWidth / 2).clamp(8.0, maxLeft);
          final top = (point.y - cardHeight - 62).clamp(
            8.0,
            (constraints.maxHeight - cardHeight - 8)
                .clamp(8.0, double.infinity),
          );
          final pointerLeft = (point.x - left - 7).clamp(
            14.0,
            cardWidth - 28,
          );
          return Stack(
            children: [
              Positioned(
                left: left,
                top: top,
                width: cardWidth,
                height: cardHeight,
                child: GoodPriceStoreMapCard(
                  store: store,
                  isFavorite: widget.isSelectedStoreFavorite,
                  onFavoritePressed: widget.onFavoritePressed,
                  onDirectionsPressed: widget.onDirectionsPressed,
                  onTap: widget.onGoodPriceStoreCardTap,
                ),
              ),
              Positioned(
                left: left + pointerLeft,
                top: top + cardHeight - 6,
                child: Transform.rotate(
                  angle: 0.785398,
                  child: Container(
                    width: 14,
                    height: 14,
                    color: AppColors.surface,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectedHousingOverlay() {
    final deal = widget.selectedHousingDeal!;
    final point = _selectedHousingScreenPoint!;
    const cardWidth = 276.0;
    const cardHeight = 146.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxLeft =
            (constraints.maxWidth - cardWidth - 8).clamp(8.0, double.infinity);
        final left = (point.x - cardWidth / 2).clamp(8.0, maxLeft);
        final top = (point.y - cardHeight - 62).clamp(
          8.0,
          (constraints.maxHeight - cardHeight - 8).clamp(8.0, double.infinity),
        );
        final pointerLeft = (point.x - left - 7).clamp(14.0, cardWidth - 28);
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: cardWidth,
              height: cardHeight,
              child: HousingDealMapCard(
                deal: deal,
                onTap: widget.onHousingDealCardTap,
              ),
            ),
            Positioned(
              left: left + pointerLeft,
              top: top + cardHeight - 6,
              child: Transform.rotate(
                angle: 0.785398,
                child: Container(
                  width: 14,
                  height: 14,
                  color: AppColors.surface,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateSelectedStoreScreenPoint() async {
    final controller = _controller;
    final store = widget.selectedGoodPriceStore;
    if (controller == null || store == null || !store.hasCoordinates) {
      return;
    }
    final point = await controller.latLngToScreenLocation(
      NLatLng(store.latitude!, store.longitude!),
    );
    if (!mounted ||
        controller != _controller ||
        store.id != widget.selectedGoodPriceStore?.id) {
      return;
    }
    setState(() => _selectedStoreScreenPoint = point);
  }

  Future<void> _updateSelectedFacilityScreenPoint() async {
    final controller = _controller;
    final facility = widget.selectedPublicFacility;
    if (controller == null || facility == null || !facility.hasCoordinates) {
      return;
    }
    final point = await controller.latLngToScreenLocation(
      NLatLng(facility.latitude!, facility.longitude!),
    );
    if (!mounted ||
        controller != _controller ||
        facility.id != widget.selectedPublicFacility?.id) {
      return;
    }
    setState(() => _selectedFacilityScreenPoint = point);
  }

  Future<void> _updateSelectedHousingScreenPoint() async {
    final controller = _controller;
    final deal = widget.selectedHousingDeal;
    if (controller == null || deal == null || !deal.hasCoordinates) {
      return;
    }
    final point = await controller.latLngToScreenLocation(
      NLatLng(deal.latitude!, deal.longitude!),
    );
    if (!mounted ||
        controller != _controller ||
        deal.id != widget.selectedHousingDeal?.id) {
      return;
    }
    setState(() => _selectedHousingScreenPoint = point);
  }

  void _dismissSelections() {
    if (widget.selectedGoodPriceStore != null) {
      widget.onGoodPriceStoreDismissed();
    }
    if (widget.selectedPublicFacility != null) {
      widget.onPublicFacilityDismissed();
    }
    if (widget.selectedHousingDeal != null) {
      widget.onHousingDealDismissed();
    }
  }

  Future<void> _notifyViewportChanged() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    final cameraPosition = await controller.getCameraPosition();
    final bounds = await controller.getContentBounds();
    if (!mounted || controller != _controller) {
      return;
    }
    widget.onViewportChanged(
      MapViewport(center: cameraPosition.target, bounds: bounds),
    );
  }

  Future<void> _syncMarkers() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    final syncId = ++_markerSyncId;
    final markers = <NMarker>{};
    for (final place in widget.places) {
      final marker = NMarker(
        id: place.id,
        position: NLatLng(place.latitude, place.longitude),
        caption: NOverlayCaption(text: place.name),
      );
      marker.setOnTapListener((_) {
        widget.onPlaceTap(place);
      });
      markers.add(marker);
    }
    for (final store in widget.goodPriceStores.where(
      (store) => store.hasCoordinates,
    )) {
      final icon = await _goodPriceMarkerIcon(store.category);
      if (!mounted || syncId != _markerSyncId || controller != _controller) {
        return;
      }
      final marker = NMarker(
        id: 'good-price-${store.id}',
        position: NLatLng(store.latitude!, store.longitude!),
        icon: icon,
        size: const Size(44, 52),
        caption: NOverlayCaption(text: store.name),
      );
      marker.setOnTapListener((_) {
        widget.onGoodPriceStoreTap(store);
      });
      markers.add(marker);
    }
    for (final facility in widget.publicFacilities.where(
      (facility) => facility.hasCoordinates,
    )) {
      final icon = await _publicFacilityMarkerIcon(facility.category);
      if (!mounted || syncId != _markerSyncId || controller != _controller) {
        return;
      }
      final marker = NMarker(
        id: 'public-facility-${facility.id}',
        position: NLatLng(facility.latitude!, facility.longitude!),
        icon: icon,
        size: const Size(44, 52),
        caption: NOverlayCaption(text: facility.name),
      );
      marker.setOnTapListener((_) {
        widget.onPublicFacilityTap(facility);
      });
      markers.add(marker);
    }
    final markerDeals = <String, HousingRentDeal>{};
    for (final deal
        in widget.housingDeals.where((deal) => deal.hasCoordinates)) {
      final key = '${deal.propertyType}|${deal.latitude}|${deal.longitude}';
      markerDeals.putIfAbsent(key, () => deal);
    }
    for (final entry in markerDeals.entries) {
      final deal = entry.value;
      final icon = await _housingMarkerIcon(deal.propertyType);
      if (!mounted || syncId != _markerSyncId || controller != _controller) {
        return;
      }
      final marker = NMarker(
        id: 'housing-${entry.key.hashCode}',
        position: NLatLng(deal.latitude!, deal.longitude!),
        icon: icon,
        size: const Size(44, 52),
        caption: NOverlayCaption(text: deal.propertyName),
      );
      marker.setOnTapListener((_) => widget.onHousingDealTap(deal));
      markers.add(marker);
    }
    if (!mounted || syncId != _markerSyncId || controller != _controller) {
      return;
    }
    await controller.clearOverlays(type: NOverlayType.marker);
    if (markers.isNotEmpty) {
      await controller.addOverlayAll(markers);
    }
  }

  Future<void> _syncDirectionsRoute() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await controller.clearOverlays(type: NOverlayType.pathOverlay);

    final route = widget.directionsRoute;
    if (route == null) {
      return;
    }
    final coords = route.path
        .map((point) => NLatLng(point.latitude, point.longitude))
        .toList(growable: false);
    if (coords.length < 2) {
      return;
    }

    final pathOverlay = NPathOverlay(
      id: 'directions-route',
      coords: coords,
      width: 8,
      color: AppColors.primary,
      outlineWidth: 3,
      outlineColor: AppColors.surface,
      isHideCollidedSymbols: true,
    );
    await controller.addOverlay(pathOverlay);
    await controller.updateCamera(
      NCameraUpdate.fitBounds(
        NLatLngBounds.from(coords),
        padding: const EdgeInsets.fromLTRB(48, 150, 48, 210),
      )..setAnimation(duration: const Duration(milliseconds: 600)),
    );
  }

  Future<NOverlayImage> _goodPriceMarkerIcon(String category) {
    final normalizedCategory = category.trim();
    return _goodPriceMarkerIcons.putIfAbsent(normalizedCategory, () {
      final style = GoodPriceStoreMarkerStyle.fromCategory(normalizedCategory);
      return NOverlayImage.fromWidget(
        widget: GoodPriceStoreMarkerIcon(style: style),
        size: const Size(44, 52),
        context: context,
      );
    });
  }

  Future<NOverlayImage> _publicFacilityMarkerIcon(String category) {
    final normalizedCategory = category.trim();
    return _publicFacilityMarkerIcons.putIfAbsent(normalizedCategory, () {
      final style = PublicFacilityMarkerStyle.fromCategory(normalizedCategory);
      return NOverlayImage.fromWidget(
        widget: PublicFacilityMarkerIcon(style: style),
        size: const Size(44, 52),
        context: context,
      );
    });
  }

  Future<NOverlayImage> _housingMarkerIcon(String propertyType) {
    return _housingMarkerIcons.putIfAbsent(propertyType, () {
      final style = HousingDealMarkerStyle.fromPropertyType(propertyType);
      return NOverlayImage.fromWidget(
        widget: HousingDealMarkerIcon(style: style),
        size: const Size(44, 52),
        context: context,
      );
    });
  }
}
