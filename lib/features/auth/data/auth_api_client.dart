import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import 'signup_request.dart';

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresInSeconds,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        tokenType: json['tokenType'] as String? ?? 'Bearer',
        expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 0,
      );

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresInSeconds;
}

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.birthDate,
    required this.gender,
    required this.interests,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    final rawInterest = json['signupInterest'];
    return CurrentUser(
      id: (json['userId'] as num).toInt(),
      email: json['email'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      birthDate: json['birthDate'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      interests: rawInterest is String && rawInterest.isNotEmpty
          ? rawInterest.split(',')
          : const [],
    );
  }

  final int id;
  int get userId => id;
  final String email;
  final String name;
  final String phone;
  final String birthDate;
  final String gender;
  final List<String> interests;
}

class AuthApiException implements Exception {
  const AuthApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthApiClient {
  AuthApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<void> signup(SignupRequest request) async {
    final uri = Uri.parse('$_baseUrl/api/auth/signup');
    late final http.Response response;
    try {
      response = await _client.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );
    } on http.ClientException catch (error) {
      throw AuthApiException(
        '백엔드 서버에 연결하지 못했어요.\n요청 주소: $uri\n${error.message}',
      );
    }

    if (response.statusCode == 201) {
      return;
    }

    throw AuthApiException(_errorMessage(response));
  }

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final response = await _post(
      '/api/auth/login',
      {'email': email, 'password': password},
    );
    if (response.statusCode != 200) {
      throw AuthApiException(_errorMessage(response));
    }
    return AuthTokens.fromJson(_responseData(response));
  }

  Future<CurrentUser> getCurrentUser(String accessToken) async {
    final uri = Uri.parse('$_baseUrl/api/users/me');
    late final http.Response response;
    try {
      response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
      );
    } on http.ClientException catch (error) {
      throw AuthApiException('서버에 연결하지 못했어요.\n요청 주소: $uri\n${error.message}');
    }
    if (response.statusCode != 200) {
      throw AuthApiException(_errorMessage(response));
    }
    return CurrentUser.fromJson(_responseData(response));
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('$_baseUrl$path');
    try {
      return await _client.post(
        uri,
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: jsonEncode(body),
      );
    } on http.ClientException catch (error) {
      throw AuthApiException('서버에 연결하지 못했어요.\n요청 주소: $uri\n${error.message}');
    }
  }

  Map<String, dynamic> _responseData(http.Response response) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    throw const AuthApiException('서버 응답 형식을 확인하지 못했어요.');
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) {
        final error = body['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.isNotEmpty) {
            return message;
          }
        }
      }
    } on FormatException {
      // Fall back to a status-based message for non-JSON responses.
    }

    if (response.statusCode == 409) {
      return '이미 가입된 이메일이에요.';
    }
    if (response.statusCode == 400) {
      return '입력한 정보를 다시 확인해 주세요.';
    }
    return '회원가입을 완료하지 못했어요. 잠시 후 다시 시도해 주세요.';
  }
}
