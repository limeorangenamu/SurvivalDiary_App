import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/core/services/directions_api_service.dart';
import 'package:project_survival_diary/features/map/directions_progress.dart';

void main() {
  const route = DirectionsRoute(
    distanceMeters: 1000,
    durationMillis: 600000,
    tollFare: 0,
    taxiFare: 0,
    fuelPrice: 0,
    path: [
      DirectionsCoordinate(latitude: 37.0, longitude: 127.0),
      DirectionsCoordinate(latitude: 37.0, longitude: 127.01),
    ],
  );

  test('경로 중간 위치에서는 남은 거리와 시간이 절반으로 줄어든다', () {
    final progress = calculateDirectionsProgress(
      route: route,
      latitude: 37.0,
      longitude: 127.005,
    );

    expect(progress.remainingDistanceMeters, closeTo(500, 2));
    expect(progress.remainingDurationMillis, closeTo(300000, 1200));
    expect(progress.distanceFromRouteMeters, lessThan(1));
  });

  test('경로에서 벗어난 거리를 미터 단위로 계산한다', () {
    final progress = calculateDirectionsProgress(
      route: route,
      latitude: 37.001,
      longitude: 127.005,
    );

    expect(progress.distanceFromRouteMeters, greaterThan(100));
    expect(progress.remainingDistanceMeters, closeTo(500, 2));
  });

  test('목적지에 도착하면 남은 거리와 시간이 0이 된다', () {
    final progress = calculateDirectionsProgress(
      route: route,
      latitude: 37.0,
      longitude: 127.01,
    );

    expect(progress.remainingDistanceMeters, 0);
    expect(progress.remainingDurationMillis, 0);
  });
}
