import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../utils/formatters.dart';

class PublicParkingLot {
  const PublicParkingLot({
    required this.id,
    required this.name,
    required this.parkingType,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.free,
    required this.capacity,
    required this.operationDays,
    required this.weekdayHours,
    required this.saturdayHours,
    required this.holidayHours,
    required this.basicMinutes,
    required this.basicFee,
    required this.additionalMinutes,
    required this.additionalFee,
    required this.dailyFee,
    required this.monthlyFee,
    required this.paymentMethods,
    required this.notes,
    required this.institution,
    required this.accessibleParking,
    required this.referenceDate,
  });

  factory PublicParkingLot.fromJson(Map<String, dynamic> json) {
    return PublicParkingLot(
      id: _stringValue(json['id']),
      name: _stringValue(json['name']),
      parkingType: _stringValue(json['parkingType']),
      address: _stringValue(json['address']),
      phone: _stringValue(json['phone']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceMeters: (json['distanceMeters'] as num?)?.toInt(),
      free: json['free'] as bool? ?? false,
      capacity: (json['capacity'] as num?)?.toInt(),
      operationDays: _stringValue(json['operationDays']),
      weekdayHours: _stringValue(json['weekdayHours']),
      saturdayHours: _stringValue(json['saturdayHours']),
      holidayHours: _stringValue(json['holidayHours']),
      basicMinutes: (json['basicMinutes'] as num?)?.toInt(),
      basicFee: (json['basicFee'] as num?)?.toInt(),
      additionalMinutes: (json['additionalMinutes'] as num?)?.toInt(),
      additionalFee: (json['additionalFee'] as num?)?.toInt(),
      dailyFee: (json['dailyFee'] as num?)?.toInt(),
      monthlyFee: (json['monthlyFee'] as num?)?.toInt(),
      paymentMethods: _stringValue(json['paymentMethods']),
      notes: _stringValue(json['notes']),
      institution: _stringValue(json['institution']),
      accessibleParking: json['accessibleParking'] as bool? ?? false,
      referenceDate: _stringValue(json['referenceDate']),
    );
  }

  final String id;
  final String name;
  final String parkingType;
  final String address;
  final String phone;
  final double? latitude;
  final double? longitude;
  final int? distanceMeters;
  final bool free;
  final int? capacity;
  final String operationDays;
  final String weekdayHours;
  final String saturdayHours;
  final String holidayHours;
  final int? basicMinutes;
  final int? basicFee;
  final int? additionalMinutes;
  final int? additionalFee;
  final int? dailyFee;
  final int? monthlyFee;
  final String paymentMethods;
  final String notes;
  final String institution;
  final bool accessibleParking;
  final String referenceDate;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get distanceLabel {
    final meters = distanceMeters;
    if (meters == null) return '거리 정보 없음';
    if (meters < 1000) return '${meters}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  String get feeLabel {
    if (free) return '무료';
    final fee = basicFee;
    final minutes = basicMinutes;
    if (fee == null || fee <= 0 || minutes == null || minutes <= 0) {
      final monthly = monthlyFee;
      if (monthly != null && monthly > 0) {
        return '월 ${Formatters.amount(monthly)}';
      }
      return '일반 주차요금 정보 없음';
    }
    return '$minutes분 ${Formatters.amount(fee)}';
  }

  String get additionalFeeLabel {
    final minutes = additionalMinutes;
    final fee = additionalFee;
    if (minutes == null || fee == null) return '';
    return '$minutes분당 ${Formatters.amount(fee)}';
  }

  String get capacityLabel => capacity == null ? '' : '$capacity면';

  String get hoursLabel {
    final parts = <String>[];
    if (weekdayHours.isNotEmpty) parts.add('평일 $weekdayHours');
    if (saturdayHours.isNotEmpty) parts.add('토요일 $saturdayHours');
    if (holidayHours.isNotEmpty) parts.add('공휴일 $holidayHours');
    return parts.isEmpty ? '운영시간 정보 없음' : parts.join(' · ');
  }
}

class PublicParkingPage {
  const PublicParkingPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
  });

  final List<PublicParkingLot> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
}

class PublicParkingApiException implements Exception {
  const PublicParkingApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PublicParkingApiService {
  PublicParkingApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<PublicParkingPage> fetchParkingLots({
    required String accessToken,
    required double southWestLat,
    required double southWestLng,
    required double northEastLat,
    required double northEastLng,
    required double latitude,
    required double longitude,
    int page = 0,
    int size = 100,
    bool freeOnly = false,
    String sort = 'distance',
  }) async {
    final uri = Uri.parse('$_baseUrl/api/map/public-parking').replace(
      queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
        'southWestLat': southWestLat.toString(),
        'southWestLng': southWestLng.toString(),
        'northEastLat': northEastLat.toString(),
        'northEastLng': northEastLng.toString(),
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'freeOnly': freeOnly.toString(),
        'sort': sort,
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
      ).timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const PublicParkingApiException(
        '공영주차장 정보를 준비하는 데 시간이 걸리고 있어요. 다시 시도해 주세요.',
      );
    } on http.ClientException catch (error) {
      throw PublicParkingApiException(
        '서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.\n${error.message}',
      );
    }

    final body = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PublicParkingApiException(
        _errorMessage(body, response.statusCode),
      );
    }

    try {
      if (body['success'] != true || body['data'] is! Map<String, dynamic>) {
        throw const FormatException();
      }
      final data = body['data'] as Map<String, dynamic>;
      final content = data['content'];
      if (content is! List) throw const FormatException();
      return PublicParkingPage(
        content: content.map((item) {
          if (item is! Map<String, dynamic>) throw const FormatException();
          return PublicParkingLot.fromJson(item);
        }).toList(growable: false),
        page: (data['page'] as num).toInt(),
        size: (data['size'] as num).toInt(),
        totalElements: (data['totalElements'] as num).toInt(),
        totalPages: (data['totalPages'] as num).toInt(),
        hasNext: data['hasNext'] as bool,
      );
    } on FormatException {
      throw const PublicParkingApiException(
        '서버의 공영주차장 응답 형식을 확인하지 못했어요.',
      );
    } on TypeError {
      throw const PublicParkingApiException(
        '서버의 공영주차장 응답 형식을 확인하지 못했어요.',
      );
    }
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) return body;
    } on FormatException {
      // The caller turns non-JSON responses into a user-facing message.
    }
    return const {};
  }

  String _errorMessage(Map<String, dynamic> body, int statusCode) {
    final error = body['error'];
    if (error is Map<String, dynamic>) {
      final message = error['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    if (statusCode == 401 || statusCode == 403) {
      return '로그인 정보가 만료되었어요. 다시 로그인해 주세요.';
    }
    return '공영주차장을 불러오지 못했어요.';
  }
}

String _stringValue(Object? value) => value?.toString().trim() ?? '';
