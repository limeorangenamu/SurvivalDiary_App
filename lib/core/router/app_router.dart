import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../features/auth/onboarding_page.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/signup_page.dart';
import '../../features/auth/signup_success_page.dart';
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
import '../../features/policy/policy_external_link_confirm_page.dart';
import '../../features/policy/policy_list_page.dart';
import '../../features/policy/data/policy_models.dart';
import '../../features/root/root_shell.dart';
import '../../features/auth/auth_session.dart';
import '../theme/app_text_styles.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name;
    final isPublicRoute = routeName == AppRoutes.onboarding ||
        routeName == AppRoutes.login ||
        routeName == AppRoutes.signup ||
        routeName == AppRoutes.signupSuccess;

    if (!isPublicRoute && !AuthSession.instance.isLoggedIn) {
      return MaterialPageRoute<dynamic>(
        settings: const RouteSettings(name: AppRoutes.onboarding),
        builder: (_) => const OnboardingPage(),
      );
    }

    final page = switch (routeName) {
      AppRoutes.root => const RootShell(),
      AppRoutes.onboarding => const OnboardingPage(),
      AppRoutes.login => const LoginPage(),
      AppRoutes.signup => const SignupPage(),
      AppRoutes.signupSuccess => const SignupSuccessPage(),
      AppRoutes.notification => const NotificationPage(),
      AppRoutes.dailySummary => const DailySummaryPage(),
      AppRoutes.budgetSetting => const BudgetSettingPage(),
      AppRoutes.expenseStats => const ExpenseStatsPage(),
      AppRoutes.detectedExpenses => const DetectedExpensePage(),
      AppRoutes.policyResults
          when settings.arguments is PolicyFilterCondition =>
        PolicyListPage(condition: settings.arguments! as PolicyFilterCondition),
      AppRoutes.policyDetail when settings.arguments is PolicyDetailArguments =>
        PolicyDetailPage(
          arguments: settings.arguments! as PolicyDetailArguments,
        ),
      AppRoutes.policyExternalLinkConfirm
          when settings.arguments is PolicyExternalLinkArguments =>
        PolicyExternalLinkConfirmPage(
          arguments: settings.arguments! as PolicyExternalLinkArguments,
        ),
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
