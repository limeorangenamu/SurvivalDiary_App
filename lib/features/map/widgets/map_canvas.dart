import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

import '../../../data/models.dart';

class SavingMapCanvas extends StatelessWidget {
  const SavingMapCanvas({
    super.key,
    required this.places,
    required this.onPlaceTap,
    required this.onMapReady,
  });

  final List<SavingPlace> places;
  final ValueChanged<SavingPlace> onPlaceTap;
  final ValueChanged<NaverMapController> onMapReady;

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
        onMapReady(controller);
        final markers = <NMarker>{};

        for (final place in places) {
          final marker = NMarker(
            id: place.id,
            position: NLatLng(place.latitude, place.longitude),
            caption: NOverlayCaption(text: place.name),
          );

          marker.setOnTapListener((_) {
            onPlaceTap(place);
          });

          markers.add(marker);
        }

        await controller.addOverlayAll(markers);
      },
    );
  }
}
