import 'dart:math' as math;

import '../../core/services/directions_api_service.dart';

class DirectionsProgress {
  const DirectionsProgress({
    required this.remainingDistanceMeters,
    required this.remainingDurationMillis,
    required this.distanceFromRouteMeters,
  });

  final int remainingDistanceMeters;
  final int remainingDurationMillis;
  final double distanceFromRouteMeters;
}

DirectionsProgress calculateDirectionsProgress({
  required DirectionsRoute route,
  required double latitude,
  required double longitude,
}) {
  if (route.path.length < 2) {
    return DirectionsProgress(
      remainingDistanceMeters: route.distanceMeters,
      remainingDurationMillis: route.durationMillis,
      distanceFromRouteMeters: double.infinity,
    );
  }

  final segmentLengths = <double>[];
  var totalLength = 0.0;
  for (var index = 0; index < route.path.length - 1; index++) {
    final length = _distanceBetween(route.path[index], route.path[index + 1]);
    segmentLengths.add(length);
    totalLength += length;
  }

  if (totalLength == 0) {
    return DirectionsProgress(
      remainingDistanceMeters: route.distanceMeters,
      remainingDurationMillis: route.durationMillis,
      distanceFromRouteMeters: _distanceToPoint(
        latitude,
        longitude,
        route.path.first,
      ),
    );
  }

  var closestDistance = double.infinity;
  var closestDistanceAlongRoute = 0.0;
  var completedLength = 0.0;

  for (var index = 0; index < route.path.length - 1; index++) {
    final start = route.path[index];
    final end = route.path[index + 1];
    final projection = _projectOntoSegment(
      latitude: latitude,
      longitude: longitude,
      start: start,
      end: end,
    );
    if (projection.distanceMeters < closestDistance) {
      closestDistance = projection.distanceMeters;
      closestDistanceAlongRoute =
          completedLength + segmentLengths[index] * projection.fraction;
    }
    completedLength += segmentLengths[index];
  }

  final remainingRatio =
      ((totalLength - closestDistanceAlongRoute) / totalLength).clamp(0.0, 1.0);
  return DirectionsProgress(
    remainingDistanceMeters: (route.distanceMeters * remainingRatio).round(),
    remainingDurationMillis:
        (route.durationMillis * remainingRatio).round(),
    distanceFromRouteMeters: closestDistance,
  );
}

const _earthRadiusMeters = 6371000.0;

double _distanceBetween(DirectionsCoordinate first, DirectionsCoordinate second) {
  return _haversineDistance(
    first.latitude,
    first.longitude,
    second.latitude,
    second.longitude,
  );
}

double _distanceToPoint(
  double latitude,
  double longitude,
  DirectionsCoordinate point,
) {
  return _haversineDistance(
    latitude,
    longitude,
    point.latitude,
    point.longitude,
  );
}

double _haversineDistance(
  double firstLatitude,
  double firstLongitude,
  double secondLatitude,
  double secondLongitude,
) {
  final latitudeDelta = _toRadians(secondLatitude - firstLatitude);
  final longitudeDelta = _toRadians(secondLongitude - firstLongitude);
  final firstLatitudeRadians = _toRadians(firstLatitude);
  final secondLatitudeRadians = _toRadians(secondLatitude);
  final a = math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
      math.cos(firstLatitudeRadians) *
          math.cos(secondLatitudeRadians) *
          math.sin(longitudeDelta / 2) *
          math.sin(longitudeDelta / 2);
  return _earthRadiusMeters * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

_SegmentProjection _projectOntoSegment({
  required double latitude,
  required double longitude,
  required DirectionsCoordinate start,
  required DirectionsCoordinate end,
}) {
  final referenceLatitude = _toRadians(latitude);
  final longitudeScale = math.cos(referenceLatitude);
  final startX = _toRadians(start.longitude - longitude) *
      _earthRadiusMeters *
      longitudeScale;
  final startY =
      _toRadians(start.latitude - latitude) * _earthRadiusMeters;
  final endX = _toRadians(end.longitude - longitude) *
      _earthRadiusMeters *
      longitudeScale;
  final endY = _toRadians(end.latitude - latitude) * _earthRadiusMeters;
  final segmentX = endX - startX;
  final segmentY = endY - startY;
  final squaredLength = segmentX * segmentX + segmentY * segmentY;
  final fraction = squaredLength == 0
      ? 0.0
      : (-(startX * segmentX + startY * segmentY) / squaredLength)
          .clamp(0.0, 1.0);
  final closestX = startX + segmentX * fraction;
  final closestY = startY + segmentY * fraction;
  return _SegmentProjection(
    fraction: fraction,
    distanceMeters: math.sqrt(closestX * closestX + closestY * closestY),
  );
}

double _toRadians(double degrees) => degrees * math.pi / 180;

class _SegmentProjection {
  const _SegmentProjection({
    required this.fraction,
    required this.distanceMeters,
  });

  final double fraction;
  final double distanceMeters;
}
