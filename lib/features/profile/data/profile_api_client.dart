import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../core/config/app_config.dart';
import '../../auth/data/auth_api_client.dart';

class ProfileApiException implements Exception {
  const ProfileApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ProfileApiClient {
  ProfileApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<CurrentUser> getMe({required String accessToken}) async {
    final response = await _send(
      'GET',
      '/api/users/me',
      accessToken: accessToken,
    );
    return CurrentUser.fromJson(_responseData(response));
  }

  Future<CurrentUser> updateProfile({
    required String accessToken,
    required String name,
    required String phone,
    required String birthDate,
    required String gender,
    required String region,
    required String bio,
    String? password,
    List<String> interests = const [],
  }) async {
    final response = await _send(
      'PATCH',
      '/api/users/me',
      accessToken: accessToken,
      body: {
        'name': name,
        'phone': phone,
        'birthDate': birthDate.isEmpty ? null : birthDate,
        'gender': gender.isEmpty ? null : gender,
        'region': region,
        'bio': bio,
        if (password != null && password.isNotEmpty) 'password': password,
        'signupInterests': interests,
      },
    );
    return CurrentUser.fromJson(_responseData(response));
  }

  Future<CurrentUser> uploadProfileImage({
    required String accessToken,
    required Uint8List bytes,
    required String filename,
  }) async {
    if (bytes.length > 5 * 1024 * 1024) {
      throw const ProfileApiException('프로필 사진은 5MB 이하로 선택해 주세요.');
    }

    final uri = Uri.parse('$_baseUrl/api/users/me/profile-image');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $accessToken',
      })
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: filename,
          contentType: _mediaType(filename),
        ),
      );

    try {
      final streamed =
          await _client.send(request).timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);
      _ensureSuccess(response);
      return CurrentUser.fromJson(_responseData(response));
    } on http.ClientException catch (error) {
      throw ProfileApiException('프로필 사진을 전송하지 못했어요. ${error.message}');
    } on TimeoutException {
      throw const ProfileApiException('프로필 사진 전송 시간이 초과됐어요.');
    }
  }

  Future<CurrentUser> deleteProfileImage({required String accessToken}) async {
    final response = await _send(
      'DELETE',
      '/api/users/me/profile-image',
      accessToken: accessToken,
    );
    return CurrentUser.fromJson(_responseData(response));
  }

  Future<http.Response> _send(
    String method,
    String path, {
    required String accessToken,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    try {
      final request = http.Request(method, uri)
        ..headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
          if (body != null) 'Content-Type': 'application/json',
        });
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final streamed =
          await _client.send(request).timeout(const Duration(seconds: 10));
      final response = await http.Response.fromStream(streamed);
      _ensureSuccess(response);
      return response;
    } on http.ClientException catch (error) {
      throw ProfileApiException('서버에 연결하지 못했어요. ${error.message}');
    } on TimeoutException {
      throw const ProfileApiException('서버 응답 시간이 초과됐어요.');
    }
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProfileApiException(_errorMessage(response));
    }
  }

  Map<String, dynamic> _responseData(http.Response response) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return body['data'] as Map<String, dynamic>;
    }
    throw const ProfileApiException('서버 응답 형식을 확인하지 못했어요.');
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic>) {
        final error = body['error'];
        if (error is Map<String, dynamic> && error['message'] is String) {
          return error['message'] as String;
        }
      }
    } on FormatException {
      // 상태 코드 기반 문구를 사용한다.
    }
    return '회원 정보를 처리하지 못했어요. (${response.statusCode})';
  }

  MediaType _mediaType(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    return switch (extension) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      'gif' => MediaType('image', 'gif'),
      _ => MediaType('image', 'jpeg'),
    };
  }
}
