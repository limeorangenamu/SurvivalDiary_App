import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class GoodPriceMenu {
  const GoodPriceMenu({required this.name, required this.price});

  final String name;
  final String price;

  int? get numericPrice {
    final digits = price.replaceAll(RegExp('[^0-9]'), '');
    return digits.isEmpty ? null : int.tryParse(digits);
  }
}

class GoodPriceStore {
  const GoodPriceStore({
    required this.province,
    required this.district,
    required this.category,
    required this.name,
    required this.phone,
    required this.address,
    required this.menus,
    required this.latitude,
    required this.longitude,
  });

  final String province;
  final String district;
  final String category;
  final String name;
  final String phone;
  final String address;
  final List<GoodPriceMenu> menus;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get id => '$province|$district|$name|$address';

  int? get lowestPrice {
    final prices =
        menus.map((menu) => menu.numericPrice).whereType<int>().toList();
    if (prices.isEmpty) {
      return null;
    }
    prices.sort();
    return prices.first;
  }

  factory GoodPriceStore.fromJson(Map<String, dynamic> json) {
    final menus = <GoodPriceMenu>[];
    for (var index = 1; index <= 4; index++) {
      final name = _stringValue(json['menu$index']);
      final price = _stringValue(json['price$index']);
      if (name.isNotEmpty || price.isNotEmpty) {
        menus.add(GoodPriceMenu(name: name, price: price));
      }
    }

    return GoodPriceStore(
      province: _stringValue(json['province']),
      district: _stringValue(json['district']),
      category: _stringValue(json['category']),
      name: _stringValue(json['name']),
      phone: _stringValue(json['phone']),
      address: _stringValue(json['address']),
      menus: List.unmodifiable(menus),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class GoodPriceStorePage {
  const GoodPriceStorePage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
  });

  final List<GoodPriceStore> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;
}

class GoodPriceApiException implements Exception {
  const GoodPriceApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoodPriceApiService {
  GoodPriceApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<GoodPriceStorePage> fetchStores({
    required String accessToken,
    int page = 0,
    int size = 20,
    String? province,
    String? district,
    String sort = 'name',
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      'sort': sort,
    };
    if (province != null && province.trim().isNotEmpty) {
      query['province'] = province.trim();
    }
    if (district != null && district.trim().isNotEmpty) {
      query['district'] = district.trim();
    }

    final uri = Uri.parse('$_baseUrl/api/map/good-price-stores').replace(
      queryParameters: query,
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
      ).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const GoodPriceApiException('서버 응답이 늦어지고 있어요. 다시 시도해 주세요.');
    } on http.ClientException catch (error) {
      throw GoodPriceApiException(
        '서버에 연결하지 못했어요. 잠시 후 다시 시도해 주세요.\n${error.message}',
      );
    }

    final body = _decodeBody(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GoodPriceApiException(
        _errorMessage(
          body,
          response.statusCode,
          fallbackMessage: '착한가격업소를 불러오지 못했어요.',
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
      return GoodPriceStorePage(
        content: content.map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException();
          }
          return GoodPriceStore.fromJson(item);
        }).toList(growable: false),
        page: (data['page'] as num).toInt(),
        size: (data['size'] as num).toInt(),
        totalElements: (data['totalElements'] as num).toInt(),
        totalPages: (data['totalPages'] as num).toInt(),
        hasNext: data['hasNext'] as bool,
      );
    } on FormatException {
      throw const GoodPriceApiException('서버의 착한가격업소 응답 형식을 확인하지 못했어요.');
    } on TypeError {
      throw const GoodPriceApiException('서버의 착한가격업소 응답 형식을 확인하지 못했어요.');
    }
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) {
        return body;
      }
    } on FormatException {
      // The caller will convert non-JSON responses to a user-facing message.
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
