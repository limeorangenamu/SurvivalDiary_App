import 'package:flutter/material.dart';

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

class _RootShellState extends State<RootShell> {
  int _currentIndex = 0;

  static const _pages = [
    HomePage(),
    ExpenseAddPage(),
    PolicyFilterPage(),
    SavingMapPage(),
    CommunityPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
