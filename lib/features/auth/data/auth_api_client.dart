import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import 'signup_request.dart';

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
