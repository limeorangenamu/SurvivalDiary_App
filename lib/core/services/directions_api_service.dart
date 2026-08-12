import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

enum DirectionsMode {
  walking('WALKING'),
  driving('DRIVING');

  const DirectionsMode(this.apiValue);

  final String apiValue;
}

class DirectionsCoordinate {
  const DirectionsCoordinate({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  factory DirectionsCoordinate.fromJson(Map<String, dynamic> json) {
    return DirectionsCoordinate(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class DirectionsRoute {
  const DirectionsRoute({
    required this.distanceMeters,
    required this.durationMillis,
    required this.tollFare,
    required this.taxiFare,
    required this.fuelPrice,
    required this.path,
  });

  final int distanceMeters;
  final int durationMillis;
  final int tollFare;
  final int taxiFare;
  final int fuelPrice;
  final List<DirectionsCoordinate> path;

  factory DirectionsRoute.fromJson(Map<String, dynamic> json) {
    final rawPath = json['path'];
    if (rawPath is! List) {
      throw const FormatException();
    }
    final path = rawPath.map((point) {
      if (point is! Map<String, dynamic>) {
        throw const FormatException();
      }
      return DirectionsCoordinate.fromJson(point);
    }).toList(growable: false);
    if (path.length < 2) {
      throw const FormatException();
    }

    return DirectionsRoute(
      distanceMeters: (json['distanceMeters'] as num).toInt(),
      durationMillis: (json['durationMillis'] as num).toInt(),
      tollFare: (json['tollFare'] as num).toInt(),
      taxiFare: (json['taxiFare'] as num).toInt(),
      fuelPrice: (json['fuelPrice'] as num).toInt(),
      path: List.unmodifiable(path),
    );
  }
}

class DirectionsApiException implements Exception {
  const DirectionsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DirectionsApiService {
  DirectionsApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<DirectionsRoute> fetchOptimalRoute({
    required String accessToken,
    required double startLatitude,
    required double startLongitude,
    required double goalLatitude,
    required double goalLongitude,
    DirectionsMode mode = DirectionsMode.walking,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/map/directions').replace(
      queryParameters: {
        'startLatitude': startLatitude.toString(),
        'startLongitude': startLongitude.toString(),
        'goalLatitude': goalLatitude.toString(),
        'goalLongitude': goalLongitude.toString(),
        'mode': mode.apiValue,
      },
    );

    late final http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Cache-Control': 'no-cache',
        },
      ).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const DirectionsApiException(
        '도보 경로를 찾는 데 시간이 오래 걸리고 있어요. 다시 시도해 주세요.',
      );
    } on http.ClientException catch (error) {
      throw DirectionsApiException(
        '서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.\n${error.message}',
      );
    }

    final body = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw DirectionsApiException(
        _errorMessage(body, response.statusCode),
      );
    }

    try {
      if (body['success'] != true || body['data'] is! Map<String, dynamic>) {
        throw const FormatException();
      }
      return DirectionsRoute.fromJson(body['data'] as Map<String, dynamic>);
    } on FormatException {
      throw const DirectionsApiException('서버의 길찾기 응답 형식을 확인하지 못했어요.');
    } on TypeError {
      throw const DirectionsApiException('서버의 길찾기 응답 형식을 확인하지 못했어요.');
    }
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) {
        return body;
      }
    } on FormatException {
      // 호출부에서 사용자용 오류 문구로 변환한다.
    }
    return const {};
  }

  String _errorMessage(Map<String, dynamic> body, int statusCode) {
    final error = body['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
    }
    if (statusCode == 401 || statusCode == 403) {
      return '로그인 정보가 만료되었어요. 다시 로그인해 주세요.';
    }
    return '도보 경로를 불러오지 못했어요.';
  }
}
