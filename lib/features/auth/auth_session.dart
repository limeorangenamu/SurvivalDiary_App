import 'package:flutter/foundation.dart';

import 'data/auth_api_client.dart';

class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  AuthTokens? _tokens;
  CurrentUser? _currentUser;

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
    final user = await client.getCurrentUser(tokens.accessToken);
    _tokens = tokens;
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _tokens = null;
    _currentUser = null;
    notifyListeners();
  }
}
