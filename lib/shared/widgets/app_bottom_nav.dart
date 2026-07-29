import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum AppTab { home, diary, policy, map, community }

extension AppTabExtension on AppTab {
  String get label => switch (this) {
        AppTab.home => '홈',
        AppTab.diary => '일기',
        AppTab.policy => '정책',
        AppTab.map => '지도',
        AppTab.community => '커뮤니티',
      };

  IconData get icon => switch (this) {
        AppTab.home => Icons.home_outlined,
        AppTab.diary => Icons.auto_stories_outlined,
        AppTab.policy => Icons.volunteer_activism_outlined,
        AppTab.map => Icons.map_outlined,
        AppTab.community => Icons.forum_outlined,
      };

  IconData get selectedIcon => switch (this) {
        AppTab.home => Icons.home_rounded,
        AppTab.diary => Icons.auto_stories_rounded,
        AppTab.policy => Icons.volunteer_activism_rounded,
        AppTab.map => Icons.map_rounded,
        AppTab.community => Icons.forum_rounded,
      };
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: NavigationBar(
        height: 62,
        selectedIndex: currentIndex,
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: onTap,
        destinations: [
          for (final tab in AppTab.values)
            NavigationDestination(
              key: ValueKey('bottom-${tab.name}'),
              icon: Icon(tab.icon, color: AppColors.textTertiary),
              selectedIcon: Icon(tab.selectedIcon, color: AppColors.primary),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
