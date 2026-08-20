import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

class CurrentRegion {
  const CurrentRegion({required this.province, required this.district});

  final String province;
  final String district;
}

class LocationService {
  static const _regionChannel = MethodChannel(
    'com.survivaldiary.project_survival_diary/location_region',
  );

  Future<Position> getCurrentPosition() async {
    await _ensureLocationAvailable();

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  Stream<Position> watchPosition() async* {
    await _ensureLocationAvailable();

    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
  }

  Future<void> _ensureLocationAvailable() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('기기 위치 서비스가 꺼져 있어요.');
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('위치 권한이 거부되었어요.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 영구적으로 거부되었어요. 설정에서 허용해주세요.');
    }
  }

  Future<CurrentRegion> getCurrentRegion(Position position) async {
    return getRegionAt(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<CurrentRegion> getRegionAt({
    required double latitude,
    required double longitude,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      throw Exception('현재 지역 자동 확인은 Android에서만 지원해요.');
    }
    try {
      final response = await _regionChannel.invokeMapMethod<String, dynamic>(
        'findRegion',
        {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      final province = response?['province']?.toString().trim() ?? '';
      final district = response?['district']?.toString().trim() ?? '';
      if (province.isEmpty) {
        throw Exception('현재 위치의 시도를 확인하지 못했어요.');
      }
      return CurrentRegion(province: province, district: district);
    } on PlatformException catch (error) {
      throw Exception(error.message ?? '현재 위치의 지역을 확인하지 못했어요.');
    }
  }
}
