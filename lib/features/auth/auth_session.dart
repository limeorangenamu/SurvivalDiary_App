import 'package:flutter/foundation.dart';

import 'data/auth_api_client.dart';
import 'data/auth_token_storage.dart';

class AuthSession extends ChangeNotifier {
  AuthSession._({AuthTokenStorage? tokenStorage})
      : _tokenStorage = tokenStorage ?? AuthTokenStorage();

  static final AuthSession instance = AuthSession._();

  AuthTokens? _tokens;
  CurrentUser? _currentUser;
  final AuthTokenStorage _tokenStorage;

  CurrentUser? get currentUser => _currentUser;
  String? get accessToken => _tokens?.accessToken;
  bool get isLoggedIn => _currentUser != null && accessToken != null;

  Future<void> login({
    required String email,
    required String password,
    AuthApiClient? apiClient,
  }) async {
    final client = apiClient ?? AuthApiClient();
    final tokens = await client.login(email: email, password: password);
    await establishSession(tokens, apiClient: client);
  }

  /// Completes authentication after either email or social login returns
  /// service-issued tokens from the backend.
  Future<void> establishSession(
    AuthTokens tokens, {
    AuthApiClient? apiClient,
  }) async {
    final user = await (apiClient ?? AuthApiClient()).getCurrentUser(
      tokens.accessToken,
    );
    await _tokenStorage.write(tokens);
    _tokens = tokens;
    _currentUser = user;
    notifyListeners();
  }

  Future<bool> restore({AuthApiClient? apiClient}) async {
    final tokens = await _tokenStorage.read();
    if (tokens == null) {
      if (_tokens != null || _currentUser != null) {
        _tokens = null;
        _currentUser = null;
        notifyListeners();
      }
      return false;
    }

    final client = apiClient ?? AuthApiClient();
    try {
      var activeTokens = tokens;
      CurrentUser user;
      try {
        user = await client.getCurrentUser(activeTokens.accessToken);
      } on AuthApiException {
        activeTokens = await client.refresh(tokens.refreshToken);
        user = await client.getCurrentUser(activeTokens.accessToken);
        await _tokenStorage.write(activeTokens);
      }
      _tokens = activeTokens;
      _currentUser = user;
      notifyListeners();
      return true;
    } on AuthApiException {
      await _tokenStorage.clear();
      _tokens = null;
      _currentUser = null;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout({AuthApiClient? apiClient}) async {
    final refreshToken = _tokens?.refreshToken;
    if (refreshToken != null) {
      try {
        await (apiClient ?? AuthApiClient()).logout(refreshToken);
      } on AuthApiException {
        // Local credentials still need to be removed when the server is offline.
      }
    }
    await _tokenStorage.clear();
    _tokens = null;
    _currentUser = null;
    notifyListeners();
  }
}
