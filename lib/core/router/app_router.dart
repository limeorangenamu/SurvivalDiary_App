import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../features/auth/onboarding_page.dart';
import '../../features/community/post_detail_page.dart';
import '../../features/community/post_write_page.dart';
import '../../features/diary/budget_setting_page.dart';
import '../../features/diary/detected_expense_page.dart';
import '../../features/diary/expense_stats_page.dart';
import '../../features/home/daily_summary_page.dart';
import '../../features/home/notification_page.dart';
import '../../features/map/housing_deal_page.dart';
import '../../features/map/housing_region_page.dart';
import '../../features/map/place_detail_page.dart';
import '../../features/policy/policy_detail_page.dart';
import '../../features/root/root_shell.dart';
import '../theme/app_text_styles.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      AppRoutes.root => const RootShell(),
      AppRoutes.onboarding => const OnboardingPage(),
      AppRoutes.notification => const NotificationPage(),
      AppRoutes.dailySummary => const DailySummaryPage(),
      AppRoutes.budgetSetting => const BudgetSettingPage(),
      AppRoutes.expenseStats => const ExpenseStatsPage(),
      AppRoutes.detectedExpenses => const DetectedExpensePage(),
      AppRoutes.policyDetail when settings.arguments is Policy =>
        PolicyDetailPage(policy: settings.arguments! as Policy),
      AppRoutes.placeDetail when settings.arguments is SavingPlace =>
        PlaceDetailPage(place: settings.arguments! as SavingPlace),
      AppRoutes.housingRegion => const HousingRegionPage(),
      AppRoutes.housingDeal => HousingDealPage(
          region: settings.arguments as String? ?? '서울특별시 강남구 역삼동',
        ),
      AppRoutes.postDetail when settings.arguments is CommunityPost =>
        PostDetailPage(post: settings.arguments! as CommunityPost),
      AppRoutes.postWrite => const PostWritePage(),
      _ => const _UnknownRoutePage(),
    };
    return MaterialPageRoute<dynamic>(settings: settings, builder: (_) => page);
  }
}

class _UnknownRoutePage extends StatelessWidget {
  const _UnknownRoutePage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('화면을 찾을 수 없어요.', style: AppTextStyles.body)),
    );
  }
}
