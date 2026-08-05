import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../auth/auth_session.dart';
import '../../shared/widgets/app_bottom_nav.dart';
import '../community/community_page.dart';
import '../diary/expense_add_page.dart';
import '../home/home_page.dart';
import '../map/saving_map_page.dart';
import '../policy/policy_filter_page.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _homeRefreshVersion = 0;
  final _authSession = AuthSession.instance;
  bool _checkingSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authSession.addListener(_handleSessionChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSession.removeListener(_handleSessionChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _restoreSession();
    }
  }

  Future<void> _restoreSession() async {
    if (_checkingSession || !mounted) return;
    _checkingSession = true;
    try {
      await _authSession.restore();
    } finally {
      _checkingSession = false;
    }
  }

  void _handleSessionChanged() {
    if (_authSession.isLoggedIn || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _authSession.isLoggedIn) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.onboarding,
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        refreshVersion: _homeRefreshVersion,
        onOpenPolicies: () => setState(() => _currentIndex = 2),
      ),
      const ExpenseAddPage(),
      const PolicyFilterPage(),
      const SavingMapPage(),
      const CommunityPage(),
    ];
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() {
          _currentIndex = index;
          if (index == 0) {
            _homeRefreshVersion++;
          }
        }),
      ),
    );
  }
}
