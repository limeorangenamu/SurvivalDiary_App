import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_api_client.dart';

/// Persists only the service-issued tokens in platform secure storage.
/// Provider tokens from Kakao or Naver are never stored here.
class AuthTokenStorage {
  AuthTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _accessTokenKey = 'auth.access_token';
  static const _refreshTokenKey = 'auth.refresh_token';
  static const _tokenTypeKey = 'auth.token_type';
  static const _expiresInSecondsKey = 'auth.expires_in_seconds';

  final FlutterSecureStorage _storage;

  Future<void> write(AuthTokens tokens) async {
    await _storage.write(key: _accessTokenKey, value: tokens.accessToken);
    await _storage.write(key: _refreshTokenKey, value: tokens.refreshToken);
    await _storage.write(key: _tokenTypeKey, value: tokens.tokenType);
    await _storage.write(
      key: _expiresInSecondsKey,
      value: tokens.expiresInSeconds.toString(),
    );
  }

  Future<AuthTokens?> read() async {
    final values = await _storage.readAll();
    final accessToken = values[_accessTokenKey];
    final refreshToken = values[_refreshTokenKey];
    if (accessToken == null || refreshToken == null) {
      return null;
    }

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: values[_tokenTypeKey] ?? 'Bearer',
      expiresInSeconds: int.tryParse(values[_expiresInSecondsKey] ?? '') ?? 0,
    );
  }

  Future<void> clear() => _storage.deleteAll();
}
