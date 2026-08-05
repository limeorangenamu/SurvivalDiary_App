import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class PublicFacility {
  const PublicFacility({
    required this.id,
    required this.name,
    required this.locationName,
    required this.category,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.paid,
    required this.fee,
    required this.weekdayHours,
    required this.weekendHours,
    required this.closedDays,
    required this.institution,
    required this.department,
    required this.homepageUrl,
    required this.imageUrl,
    required this.capacity,
    required this.area,
    required this.amenities,
    required this.applicationMethod,
    required this.referenceDate,
  });

  final String id;
  final String name;
  final String locationName;
  final String category;
  final String address;
  final String phone;
  final double? latitude;
  final double? longitude;
  final int? distanceMeters;
  final bool? paid;
  final String fee;
  final String weekdayHours;
  final String weekendHours;
  final String closedDays;
  final String institution;
  final String department;
  final String homepageUrl;
  final String imageUrl;
  final String capacity;
  final String area;
  final String amenities;
  final String applicationMethod;
  final String referenceDate;

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get isFree => paid == false;

  String get feeLabel {
    final value = fee.trim();
    if (value.isEmpty) return '요금 정보 없음';
    if (isFree || value == '0') return '무료';
    if (value.contains('원') || !RegExp(r'\d').hasMatch(value)) return value;
    return '$value원';
  }

  String get distanceLabel {
    final meters = distanceMeters;
    if (meters == null) {
      return '거리 정보 없음';
    }
    if (meters < 1000) {
      return '${meters}m';
    }
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  String get hoursLabel {
    final parts = <String>[];
    if (weekdayHours.isNotEmpty) {
      parts.add('평일 $weekdayHours');
    }
    if (weekendHours.isNotEmpty) {
      parts.add('주말 $weekendHours');
    }
    return parts.isEmpty ? '운영시간 정보 없음' : parts.join(' · ');
  }

  factory PublicFacility.fromJson(Map<String, dynamic> json) {
    return PublicFacility(
      id: _stringValue(json['id']),
      name: _stringValue(json['name']),
      locationName: _stringValue(json['locationName']),
      category: _stringValue(json['category']),
      address: _stringValue(json['address']),
      phone: _stringValue(json['phone']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceMeters: (json['distanceMeters'] as num?)?.toInt(),
      paid: json['paid'] as bool?,
      fee: _stringValue(json['fee']),
      weekdayHours: _stringValue(json['weekdayHours']),
      weekendHours: _stringValue(json['weekendHours']),
      closedDays: _stringValue(json['closedDays']),
      institution: _stringValue(json['institution']),
      department: _stringValue(json['department']),
      homepageUrl: _stringValue(json['homepageUrl']),
      imageUrl: _stringValue(json['imageUrl']),
      capacity: _stringValue(json['capacity']),
      area: _stringValue(json['area']),
      amenities: _stringValue(json['amenities']),
      applicationMethod: _stringValue(json['applicationMethod']),
      referenceDate: _stringValue(json['referenceDate']),
    );
  }
}

class PublicFacilityPage {
  const PublicFacilityPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
  });

  final List<PublicFacility> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
}

class PublicFacilityApiException implements Exception {
  const PublicFacilityApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PublicFacilityApiService {
  PublicFacilityApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<PublicFacilityPage> fetchFacilities({
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
    final uri = Uri.parse('$_baseUrl/api/map/public-facilities').replace(
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
      ).timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw const PublicFacilityApiException(
        '공공시설 정보를 준비하는 데 시간이 걸리고 있어요. 다시 시도해 주세요.',
      );
    } on http.ClientException catch (error) {
      throw PublicFacilityApiException(
        '서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.\n${error.message}',
      );
    }

    final body = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PublicFacilityApiException(
        _errorMessage(
          body,
          response.statusCode,
          fallbackMessage: '공공시설을 불러오지 못했어요.',
        ),
      );
    }

    try {
      if (body['success'] != true || body['data'] is! Map<String, dynamic>) {
        throw const FormatException();
      }
      final data = body['data'] as Map<String, dynamic>;
      final content = data['content'];
      if (content is! List) {
        throw const FormatException();
      }
      return PublicFacilityPage(
        content: content.map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException();
          }
          return PublicFacility.fromJson(item);
        }).toList(growable: false),
        page: (data['page'] as num).toInt(),
        size: (data['size'] as num).toInt(),
        totalElements: (data['totalElements'] as num).toInt(),
        totalPages: (data['totalPages'] as num).toInt(),
        hasNext: data['hasNext'] as bool,
      );
    } on FormatException {
      throw const PublicFacilityApiException(
        '서버의 공공시설 응답 형식을 확인하지 못했어요.',
      );
    } on TypeError {
      throw const PublicFacilityApiException(
        '서버의 공공시설 응답 형식을 확인하지 못했어요.',
      );
    }
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) {
        return body;
      }
    } on FormatException {
      // The caller turns non-JSON responses into a user-facing message.
    }
    return const {};
  }

  String _errorMessage(
    Map<String, dynamic> body,
    int statusCode, {
    required String fallbackMessage,
  }) {
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
    return fallbackMessage;
  }
}

String _stringValue(Object? value) => value?.toString().trim() ?? '';
