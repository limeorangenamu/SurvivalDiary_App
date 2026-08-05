import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class HousingRentSearchCondition {
  const HousingRentSearchCondition({
    required this.region,
    required this.lawdCode,
    required this.neighborhood,
  });

  final String region;
  final String lawdCode;
  final String neighborhood;
}

class HousingRentDeal {
  const HousingRentDeal({
    required this.id,
    required this.propertyType,
    required this.propertyName,
    required this.dealType,
    required this.depositTenThousandWon,
    required this.monthlyRentTenThousandWon,
    required this.contractDate,
    required this.areaSquareMeters,
    required this.floor,
    required this.neighborhood,
    required this.lotNumber,
    required this.buildYear,
    required this.contractTerm,
    required this.contractType,
    required this.previousDepositTenThousandWon,
    required this.previousMonthlyRentTenThousandWon,
    required this.renewalRequestRightUsed,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.locationAccuracy,
  });

  final String id;
  final String propertyType;
  final String propertyName;
  final String dealType;
  final int depositTenThousandWon;
  final int monthlyRentTenThousandWon;
  final DateTime contractDate;
  final double areaSquareMeters;
  final int? floor;
  final String neighborhood;
  final String lotNumber;
  final int? buildYear;
  final String contractTerm;
  final String contractType;
  final int? previousDepositTenThousandWon;
  final int? previousMonthlyRentTenThousandWon;
  final String renewalRequestRightUsed;
  final String address;
  final double? latitude;
  final double? longitude;
  final String locationAccuracy;

  int get depositWon => depositTenThousandWon * 10000;
  int get monthlyRentWon => monthlyRentTenThousandWon * 10000;
  int? get previousDepositWon => previousDepositTenThousandWon == null
      ? null
      : previousDepositTenThousandWon! * 10000;
  int? get previousMonthlyRentWon => previousMonthlyRentTenThousandWon == null
      ? null
      : previousMonthlyRentTenThousandWon! * 10000;
  bool get hasCoordinates => latitude != null && longitude != null;

  factory HousingRentDeal.fromJson(Map<String, dynamic> json) {
    return HousingRentDeal(
      id: _stringValue(json['id']),
      propertyType: _stringValue(json['propertyType']),
      propertyName: _stringValue(json['propertyName']),
      dealType: _stringValue(json['dealType']),
      depositTenThousandWon:
          (json['depositTenThousandWon'] as num?)?.toInt() ?? 0,
      monthlyRentTenThousandWon:
          (json['monthlyRentTenThousandWon'] as num?)?.toInt() ?? 0,
      contractDate: DateTime.parse(_stringValue(json['contractDate'])),
      areaSquareMeters: (json['areaSquareMeters'] as num?)?.toDouble() ?? 0,
      floor: (json['floor'] as num?)?.toInt(),
      neighborhood: _stringValue(json['neighborhood']),
      lotNumber: _stringValue(json['lotNumber']),
      buildYear: (json['buildYear'] as num?)?.toInt(),
      contractTerm: _stringValue(json['contractTerm']),
      contractType: _stringValue(json['contractType']),
      previousDepositTenThousandWon:
          (json['previousDepositTenThousandWon'] as num?)?.toInt(),
      previousMonthlyRentTenThousandWon:
          (json['previousMonthlyRentTenThousandWon'] as num?)?.toInt(),
      renewalRequestRightUsed: _stringValue(json['renewalRequestRightUsed']),
      address: _stringValue(json['address']),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      locationAccuracy: _stringValue(json['locationAccuracy']),
    );
  }
}

class HousingRentApiException implements Exception {
  const HousingRentApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class HousingRentApiService {
  HousingRentApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<List<HousingRentDeal>> fetchDeals({
    required String accessToken,
    required HousingRentSearchCondition condition,
    required DateTime endMonth,
    int months = 3,
    int limit = 100,
  }) async {
    final dealYmd =
        '${endMonth.year}${endMonth.month.toString().padLeft(2, '0')}';
    final uri = Uri.parse('$_baseUrl/api/map/housing-rent-deals').replace(
      queryParameters: {
        'lawdCd': condition.lawdCode,
        'dealYmd': dealYmd,
        'months': months.toString(),
        'neighborhood': condition.neighborhood,
        'region': condition.region,
        'limit': limit.toString(),
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
      throw const HousingRentApiException(
        '실거래 정보를 불러오는 데 시간이 오래 걸리고 있어요. 다시 시도해 주세요.',
      );
    } on http.ClientException catch (error) {
      throw HousingRentApiException(
        '서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.\n${error.message}',
      );
    }

    final body = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HousingRentApiException(
        _errorMessage(
          body,
          response.statusCode,
          fallbackMessage: '주거 실거래 정보를 불러오지 못했어요.',
        ),
      );
    }

    try {
      if (body['success'] != true || body['data'] is! List) {
        throw const FormatException();
      }
      return (body['data'] as List).map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException();
        }
        return HousingRentDeal.fromJson(item);
      }).toList(growable: false);
    } on FormatException {
      throw const HousingRentApiException(
        '서버의 주거 실거래 응답 형식을 확인하지 못했어요.',
      );
    } on TypeError {
      throw const HousingRentApiException(
        '서버의 주거 실거래 응답 형식을 확인하지 못했어요.',
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
      // The caller converts non-JSON responses to a user-facing error.
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
