import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../auth/auth_session.dart';
import 'data/home_api_client.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pig_mascot.dart';
import '../../shared/widgets/section_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  BudgetSummary? _budget;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final token = AuthSession.instance.accessToken;
    if (token == null) return;

    try {
      final summary = await HomeApiClient().getSummary(accessToken: token);
      if (!mounted) return;
      setState(() {
        _budget = summary;
        _errorMessage = null;
      });
    } on HomeApiException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final budget = _budget ??
        BudgetSummary.empty(
          userName: AuthSession.instance.currentUser?.name ?? '',
        );
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        key: const PageStorageKey('home-scroll'),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: SliverList.list(
              children: [
                if (_errorMessage != null) ...[
                  AppCard(
                    color: AppColors.dangerSoft,
                    borderColor: AppColors.danger,
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.danger),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_errorMessage!)),
                        IconButton(
                          onPressed: _loadSummary,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '안녕하세요, ${budget.userName}님! 👋',
                            style: AppTextStyles.title,
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            '오늘도 가볍게 지갑을 지켜봐요.',
                            style: AppTextStyles.bodyMuted,
                          ),
                        ],
                      ),
                    ),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          key: const ValueKey('notification-button'),
                          tooltip: '알림',
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.notification,
                          ),
                          icon: const Icon(Icons.notifications_none_rounded),
                        ),
                        Positioned(
                          right: 7,
                          top: 7,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const ValueKey('account-button'),
                          tooltip: '계정',
                          onPressed: () => _showAccountMenu(context),
                          icon: const Icon(Icons.account_circle_outlined),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _BudgetHeroCard(
                  budget: budget,
                  onSetting: () =>
                      Navigator.pushNamed(context, AppRoutes.budgetSetting),
                ),
                if (budget.isNearLimit || budget.isOverLimit) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    color: budget.isOverLimit
                        ? AppColors.dangerSoft
                        : AppColors.warningSoft,
                    borderColor: budget.isOverLimit
                        ? AppColors.danger
                        : AppColors.warning,
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: budget.isOverLimit
                              ? AppColors.danger
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            budget.isOverLimit
                                ? '오늘 한도를 넘었어요. 남은 지출을 한번 점검해요.'
                                : '오늘 예산의 60% 이상을 사용했어요.',
                            style: AppTextStyles.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SectionHeader(
                  title: '오늘의 요약',
                  actionLabel: '자세히',
                  onAction: () =>
                      Navigator.pushNamed(context, AppRoutes.dailySummary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        icon: Icons.payments_outlined,
                        label: '오늘 지출',
                        value: Formatters.amount(budget.spentToday),
                        color: AppColors.categoryFood,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryTile(
                        icon: Icons.savings_outlined,
                        label: '오늘 절약',
                        value: Formatters.amount(budget.savedToday),
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Expanded(
                      child: _SummaryTile(
                        icon: Icons.restaurant_rounded,
                        label: '카테고리 1위',
                        value: '식비',
                        color: AppColors.categoryFood,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _SummaryTile(
                        icon: Icons.account_balance_wallet_outlined,
                        label: '잔여 예산',
                        value: Formatters.amount(budget.remainingToday),
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                AppCard(
                  color: AppColors.primarySoft,
                  borderColor: AppColors.primarySoft,
                  child: Row(
                    children: [
                      const PigMascot(size: 52),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '오늘의 한 줄 절약 팁',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryDeep,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '커피 한 잔을 텀블러로 바꾸면 이번 주 교통비를 만들 수 있어요.',
                              style: AppTextStyles.body,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const SectionHeader(title: '빠른 메뉴'),
                const SizedBox(height: 10),
                AppCard(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.detectedExpenses),
                  child: const _QuickMenuContent(
                    icon: Icons.notifications_active_outlined,
                    title: '감지된 결제 확인',
                    subtitle: '등록을 기다리는 결제 4건',
                  ),
                ),
                const SizedBox(height: 10),
                AppCard(
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.expenseStats),
                  child: const _QuickMenuContent(
                    icon: Icons.insights_rounded,
                    title: '지출 통계 보기',
                    subtitle: '이번 달 소비 흐름을 확인해요',
                  ),
                ),
                const SizedBox(height: 24),
                SectionHeader(
                  title: '맞춤 뉴스',
                  actionLabel: '더보기',
                  onAction: () {},
                ),
                const SizedBox(height: 8),
                for (var index = 0;
                    index < MockData.homeNews.length;
                    index++) ...[
                  _NewsListItem(news: MockData.homeNews[index]),
                  if (index != MockData.homeNews.length - 1)
                    const Divider(height: 14),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAccountMenu(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: Text(
          '${AuthSession.instance.currentUser?.name ?? '사용자'}님, 로그아웃할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
    if (shouldLogout != true || !context.mounted) return;

    await AuthSession.instance.logout();
  }
}

class _NewsListItem extends StatelessWidget {
  const _NewsListItem({required this.news});

  final HomeNews news;

  Color get _accentColor => switch (news.category) {
        '생활경제' => AppColors.categoryTransport,
        '금융' => AppColors.info,
        '절약' => AppColors.primary,
        _ => AppColors.primaryDeep,
      };

  @override
  Widget build(BuildContext context) {
    final accentColor = _accentColor;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 76,
          height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withValues(alpha: 0.18),
                accentColor.withValues(alpha: 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(news.icon, color: accentColor, size: 28),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                news.title,
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${news.category} · ${news.source} · ${news.timeAgo}',
                style: AppTextStyles.captionTiny,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: AppColors.textTertiary,
        ),
      ],
    );
  }
}

class _BudgetHeroCard extends StatelessWidget {
  const _BudgetHeroCard({required this.budget, required this.onSetting});

  final BudgetSummary budget;
  final VoidCallback onSetting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '오늘 사용 가능한 금액',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primarySoft,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      Formatters.amount(budget.remainingToday),
                      style: AppTextStyles.display.copyWith(
                        color: AppColors.surface,
                      ),
                    ),
                  ],
                ),
              ),
              const PigMascot(size: 64),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroMeta(
                label: '일일 한도',
                value: Formatters.amount(budget.dailyLimit),
              ),
              const SizedBox(width: 18),
              _HeroMeta(label: '월급날까지', value: 'D-${budget.dDay}'),
              const Spacer(),
              IconButton(
                tooltip: '금액 설정',
                onPressed: onSetting,
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.surface,
                  backgroundColor: AppColors.surface.withValues(alpha: 0.16),
                ),
                icon: const Icon(Icons.tune_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '주간 예산',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primarySoft,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${Formatters.amount(budget.weeklySpent)} / '
                    '${Formatters.amount(budget.weeklyBudget)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: budget.weeklyProgress,
              color: AppColors.surface,
              backgroundColor: AppColors.surface.withValues(alpha: 0.22),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.captionTiny.copyWith(
            color: AppColors.primarySoft,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.surface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(label, style: AppTextStyles.caption),
          const SizedBox(height: 3),
          Text(
            value,
            style: AppTextStyles.amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickMenuContent extends StatelessWidget {
  const _QuickMenuContent({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTextStyles.caption),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
      ],
    );
  }
}
