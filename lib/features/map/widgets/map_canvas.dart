import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../../core/services/good_price_api_service.dart';
import '../../../data/models.dart';

class SavingMapCanvas extends StatefulWidget {
  const SavingMapCanvas({
    super.key,
    required this.places,
    required this.goodPriceStores,
    required this.onPlaceTap,
    required this.onGoodPriceStoreTap,
    required this.onMapReady,
  });

  final List<SavingPlace> places;
  final List<GoodPriceStore> goodPriceStores;
  final ValueChanged<SavingPlace> onPlaceTap;
  final ValueChanged<GoodPriceStore> onGoodPriceStoreTap;
  final ValueChanged<NaverMapController> onMapReady;

  @override
  State<SavingMapCanvas> createState() => _SavingMapCanvasState();
}

class _SavingMapCanvasState extends State<SavingMapCanvas> {
  NaverMapController? _controller;

  @override
  void didUpdateWidget(covariant SavingMapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.places != widget.places ||
        oldWidget.goodPriceStores != widget.goodPriceStores) {
      unawaited(_syncMarkers());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return const SizedBox.expand();
    }

    return NaverMap(
      forceGesture: true,
      options: const NaverMapViewOptions(
        initialCameraPosition: NCameraPosition(
          target: NLatLng(37.5009, 127.0368),
          zoom: 14,
        ),
      ),
      onMapReady: (controller) async {
        _controller = controller;
        widget.onMapReady(controller);
        await _syncMarkers();
      },
    );
  }

  Future<void> _syncMarkers() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await controller.clearOverlays(type: NOverlayType.marker);
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
      final marker = NMarker(
        id: 'good-price-${store.id}',
        position: NLatLng(store.latitude!, store.longitude!),
        caption: NOverlayCaption(text: store.name),
      );
      marker.setOnTapListener((_) {
        widget.onGoodPriceStoreTap(store);
      });
      markers.add(marker);
    }
    if (markers.isNotEmpty) {
      await controller.addOverlayAll(markers);
    }
  }
}
