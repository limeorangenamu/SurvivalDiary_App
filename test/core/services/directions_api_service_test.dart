import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:project_survival_diary/core/services/directions_api_service.dart';

void main() {
  test('현재 위치와 목적지를 전달하고 도보 경로를 변환한다', () async {
    final service = DirectionsApiService(
      baseUrl: 'http://localhost:8080',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/map/directions');
        expect(request.url.queryParameters['startLatitude'], '35.1578');
        expect(request.url.queryParameters['startLongitude'], '129.0592');
        expect(request.url.queryParameters['goalLatitude'], '35.16');
        expect(request.url.queryParameters['goalLongitude'], '129.065');
        expect(request.headers['authorization'], 'Bearer access-token');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'distanceMeters': 1250,
              'durationMillis': 240000,
              'tollFare': 0,
              'taxiFare': 0,
              'fuelPrice': 0,
              'path': [
                {'latitude': 35.1578, 'longitude': 129.0592},
                {'latitude': 35.1600, 'longitude': 129.0650},
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );

    final route = await service.fetchOptimalRoute(
      accessToken: 'access-token',
      startLatitude: 35.1578,
      startLongitude: 129.0592,
      goalLatitude: 35.1600,
      goalLongitude: 129.0650,
    );

    expect(route.distanceMeters, 1250);
    expect(route.durationMillis, 240000);
    expect(route.taxiFare, 0);
    expect(route.path, hasLength(2));
    expect(route.path.last.latitude, 35.1600);
    expect(route.path.last.longitude, 129.0650);
  });

  test('백엔드의 경로 오류 메시지를 전달한다', () async {
    final service = DirectionsApiService(
      baseUrl: 'http://localhost:8080',
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': false,
            'error': {'code': 'L004', 'message': '도보 경로를 찾을 수 없습니다.'},
          }),
          422,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );

    expect(
      () => service.fetchOptimalRoute(
        accessToken: 'access-token',
        startLatitude: 35.1578,
        startLongitude: 129.0592,
        goalLatitude: 35.1600,
        goalLongitude: 129.0650,
      ),
      throwsA(
        isA<DirectionsApiException>().having(
          (error) => error.message,
          'message',
          '도보 경로를 찾을 수 없습니다.',
        ),
      ),
    );
  });
}
