import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:project_survival_diary/core/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    'com.survivaldiary.project_survival_diary/location_region',
  );

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('Android 기기에서 반환한 시도와 시군구를 변환한다', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'findRegion');
      expect(call.arguments['latitude'], 35.1578);
      expect(call.arguments['longitude'], 129.0594);
      return {'province': '부산광역시', 'district': '부산진구'};
    });

    final region = await LocationService().getCurrentRegion(
      Position(
        latitude: 35.1578,
        longitude: 129.0594,
        timestamp: DateTime(2026),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
    );

    expect(region.province, '부산광역시');
    expect(region.district, '부산진구');
  });
}
