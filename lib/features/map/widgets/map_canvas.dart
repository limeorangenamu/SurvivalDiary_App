import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../../core/services/directions_api_service.dart';
import '../../../core/services/good_price_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models.dart';
import '../good_price_store_marker_style.dart';
import 'good_price_store_map_card.dart';

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
    required this.directionsRoute,
    required this.onPlaceTap,
    required this.onGoodPriceStoreTap,
    required this.onMapReady,
    required this.onViewportChanged,
    required this.selectedGoodPriceStore,
    required this.isSelectedStoreFavorite,
    required this.onFavoritePressed,
    required this.onDirectionsPressed,
    required this.onGoodPriceStoreCardTap,
    required this.onGoodPriceStoreDismissed,
  });

  final List<SavingPlace> places;
  final List<GoodPriceStore> goodPriceStores;
  final DirectionsRoute? directionsRoute;
  final ValueChanged<SavingPlace> onPlaceTap;
  final ValueChanged<GoodPriceStore> onGoodPriceStoreTap;
  final ValueChanged<NaverMapController> onMapReady;
  final ValueChanged<MapViewport> onViewportChanged;
  final GoodPriceStore? selectedGoodPriceStore;
  final bool isSelectedStoreFavorite;
  final VoidCallback onFavoritePressed;
  final VoidCallback onDirectionsPressed;
  final VoidCallback onGoodPriceStoreCardTap;
  final VoidCallback onGoodPriceStoreDismissed;

  @override
  State<SavingMapCanvas> createState() => _SavingMapCanvasState();
}

class _SavingMapCanvasState extends State<SavingMapCanvas> {
  NaverMapController? _controller;
  final Map<String, Future<NOverlayImage>> _goodPriceMarkerIcons = {};
  int _markerSyncId = 0;
  NPoint? _selectedStoreScreenPoint;

  @override
  void didUpdateWidget(covariant SavingMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.places != widget.places ||
        oldWidget.goodPriceStores != widget.goodPriceStores) {
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
            onMapTapped: (_, __) => widget.onGoodPriceStoreDismissed(),
            onCameraChange: (_, __) {
              if (widget.selectedGoodPriceStore != null) {
                widget.onGoodPriceStoreDismissed();
              }
            },
            onCameraIdle: () {
              unawaited(_notifyViewportChanged());
            },
          ),
        ),
        if (widget.selectedGoodPriceStore != null &&
            _selectedStoreScreenPoint != null)
          Positioned.fill(child: _buildSelectedStoreOverlay()),
      ],
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
}
