import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models.dart';
import '../auth/auth_session.dart';
import '../diary/notification_detection/notification_expense_repository.dart';
import 'data/home_api_client.dart';
import 'widgets/home_policy_briefing.dart';
import 'home_widget_editor_page.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/pig_mascot.dart';
import '../../shared/widgets/section_header.dart';

const _newsPerPage = 4;
const _newsPreviewSize = 20;
const _newsPageGap = 12.0;

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.refreshVersion = 0,
    this.onOpenPolicies,
    this.onOpenDiaryStats,
  });

  final int refreshVersion;
  final VoidCallback? onOpenPolicies;
  final ValueChanged<bool>? onOpenDiaryStats;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final _detectedExpenseRepository = NotificationExpenseRepository.instance;
  final _homeApiClient = HomeApiClient();
  BudgetSummary? _budget;
  String? _errorMessage;
  List<HomeNews> _news = const [];
  String? _newsErrorMessage;
  bool _isNewsLoading = true;
  int _newsPageIndex = 0;
  late final AnimationController _newsDragController;
  double _newsViewportWidth = 0;
  int _policyRefreshVersion = 0;
  List<String> _widgetOrder = [...defaultHomeWidgetOrder];
  List<String> _hiddenWidgets = [];

  @override
  void initState() {
    super.initState();
    _newsDragController = AnimationController.unbounded(vsync: this);
    _detectedExpenseRepository.addListener(_handleDetectedExpensesChanged);
    unawaited(_detectedExpenseRepository.start());
    _loadSummary();
    _loadNews();
  }

  @override
  void didUpdateWidget(covariant HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshVersion != oldWidget.refreshVersion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_refreshHome(refreshPolicies: false));
        }
      });
    }
  }

  @override
  void dispose() {
    _newsDragController.dispose();
    _detectedExpenseRepository.removeListener(_handleDetectedExpensesChanged);
    super.dispose();
  }

  void _handleDetectedExpensesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadSummary() async {
    final token = AuthSession.instance.accessToken;
    if (token == null) return;

    try {
      final summary = await _homeApiClient.getSummary(accessToken: token);
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

  Future<void> _loadNews() async {
    final token = AuthSession.instance.accessToken;
    if (token == null) return;

    if (mounted) {
      setState(() {
        _isNewsLoading = true;
        _newsErrorMessage = null;
      });
    }

    try {
      final news = await _homeApiClient.getRecommendedNews(
        accessToken: token,
        size: _newsPreviewSize,
      );
      if (!mounted) return;
      setState(() {
        _news = news;
        _newsPageIndex = 0;
        _isNewsLoading = false;
      });
    } on HomeApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _newsErrorMessage = error.message;
        _isNewsLoading = false;
      });
    }
  }

  Future<void> _refreshHome({bool refreshPolicies = true}) async {
    if (mounted && refreshPolicies) {
      setState(() => _policyRefreshVersion++);
    }
    await Future.wait([
      _loadSummary(),
      _loadNews(),
      _detectedExpenseRepository.refresh(),
    ]);
  }

  Future<void> _openNews(HomeNews news) async {
    final uri = Uri.tryParse(news.sourceUrl);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      _showNewsLinkError();
      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) _showNewsLinkError();
    } on Exception {
      if (mounted) _showNewsLinkError();
    }
  }

  void _showNewsLinkError() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('뉴스 링크를 열 수 없어요. 잠시 후 다시 시도해 주세요.')),
    );
  }

  void _changeNewsPage(int direction, int pageCount) {
    final nextPage = _newsPageIndex + direction;
    if (nextPage < 0 || nextPage >= pageCount) return;
    unawaited(_settleNewsPage(direction, pageCount));
  }

  void _startNewsDrag(DragStartDetails _) {
    if (_newsDragController.isAnimating) return;
    _newsDragController.value = 0;
  }

  void _updateNewsDrag(DragUpdateDetails details, int pageCount) {
    if (_newsDragController.isAnimating) return;

    final delta = details.primaryDelta ?? 0;
    final nextOffset = _newsDragController.value + delta;
    final isDraggingPastFirst = nextOffset > 0 && _newsPageIndex == 0;
    final isDraggingPastLast =
        nextOffset < 0 && _newsPageIndex == pageCount - 1;

    _newsDragController.value = isDraggingPastFirst || isDraggingPastLast
        ? _newsDragController.value + (delta * 0.28)
        : nextOffset;
  }

  void _finishNewsDrag(DragEndDetails details, int pageCount) {
    final velocity = details.primaryVelocity ?? 0;
    final dragOffset = _newsDragController.value;
    final distanceThreshold = _newsViewportWidth * 0.16;
    final hasEnoughDistance = dragOffset.abs() >= distanceThreshold;
    final hasEnoughVelocity = velocity.abs() >= 350;
    if (!hasEnoughDistance && !hasEnoughVelocity) {
      unawaited(_resetNewsDrag());
      return;
    }

    final direction =
        hasEnoughVelocity ? (velocity < 0 ? 1 : -1) : (dragOffset < 0 ? 1 : -1);
    final nextPage = _newsPageIndex + direction;
    if (nextPage < 0 || nextPage >= pageCount) {
      unawaited(_resetNewsDrag());
      return;
    }

    unawaited(_settleNewsPage(direction, pageCount));
  }

  Future<void> _settleNewsPage(int direction, int pageCount) async {
    if (_newsDragController.isAnimating || _newsViewportWidth <= 0) return;

    final nextPage = _newsPageIndex + direction;
    if (nextPage < 0 || nextPage >= pageCount) {
      await _resetNewsDrag();
      return;
    }

    final pageExtent = _newsViewportWidth + _newsPageGap;
    final targetOffset = -direction * pageExtent;
    final remainingRatio =
        ((targetOffset - _newsDragController.value).abs() / pageExtent)
            .clamp(0.0, 1.0);
    await _newsDragController.animateTo(
      targetOffset,
      duration: Duration(milliseconds: 160 + (100 * remainingRatio).round()),
      curve: Curves.easeOutCubic,
    );
    if (!mounted) return;

    setState(() {
      _newsPageIndex = nextPage;
      _newsDragController.value = 0;
    });
  }

  Future<void> _resetNewsDrag() async {
    if (_newsDragController.value == 0) return;
    await _newsDragController.animateTo(
      0,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openBudgetSetting() async {
    final savedAmount =
        await Navigator.pushNamed(context, AppRoutes.budgetSetting);
    if (savedAmount is int && mounted) {
      await _loadSummary();
    }
  }

  Future<void> _openDetectedExpenses() async {
    await Navigator.pushNamed(context, AppRoutes.detectedExpenses);
    if (!mounted) return;
    await _refreshHome();
  }

  Future<void> _openWidgetEditor() async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.homeWidgetEditor,
      arguments: HomeWidgetEditorArguments(
          order: _widgetOrder, hidden: _hiddenWidgets),
    );
    if (result is HomeWidgetEditorArguments && mounted) {
      setState(() {
        _widgetOrder = result.order;
        _hiddenWidgets = result.hidden;
      });
    }
  }

  Future<void> _openExpenseStats() async {
    await Navigator.pushNamed(context, AppRoutes.expenseStats);
    if (!mounted) return;
    await _loadSummary();
  }

  Future<void> _openProfile() async {
    await Navigator.pushNamed(context, AppRoutes.profile);
    if (!mounted) return;
    await _loadSummary();
  }

  void _openPolicies() {
    widget.onOpenPolicies?.call();
  }

  Widget _summaryTile(String id, BudgetSummary budget) => switch (id) {
        'today_spent' => _SummaryTile(
            icon: Icons.payments_outlined,
            label: '오늘 지출',
            value: Formatters.amount(budget.spentToday),
            color: AppColors.categoryFood,
            onTap: () => Navigator.pushNamed(context, AppRoutes.dailySummary,
                arguments: 'today')),
        'daily_usage' => _SummaryTile(
            icon: Icons.donut_small_rounded,
            label: '일일 예산 사용률',
            value: '${budget.dailyUsagePercent}%',
            color: AppColors.primary,
            onTap: () => widget.onOpenDiaryStats?.call(true)),
        'top_category' => _SummaryTile(
            icon: budget.monthlyTopCategory?.icon ?? Icons.category_outlined,
            label: '카테고리 1위',
            value: budget.monthlyTopCategory?.label ?? '아직 없음',
            color: budget.monthlyTopCategory?.color ?? AppColors.textTertiary,
            onTap: () => Navigator.pushNamed(context, AppRoutes.dailySummary,
                arguments: 'monthly-category')),
        'daily_remaining' => _SummaryTile(
            icon: Icons.account_balance_wallet_outlined,
            label: '일일 잔여 예산',
            value: Formatters.amount(budget.remainingToday),
            color: AppColors.info,
            onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.budgetSetting,
                  arguments: 'daily',
                )),
        'monthly_usage' => _SummaryTile(
            icon: Icons.calendar_month_outlined,
            label: '월간 예산 사용률',
            value: '${budget.monthlyUsagePercent}%',
            color: AppColors.primary,
            onTap: () => widget.onOpenDiaryStats?.call(false)),
        'monthly_remaining' => _SummaryTile(
            icon: Icons.wallet_outlined,
            label: '월간 잔여 예산',
            value: Formatters.amount(budget.remainingMonth),
            color: AppColors.info,
            onTap: () => Navigator.pushNamed(
                  context,
                  AppRoutes.budgetSetting,
                  arguments: 'monthly',
                )),
        _ => const SizedBox.shrink(),
      };

  @override
  Widget build(BuildContext context) {
    final budget = _budget ??
        BudgetSummary.empty(
          userName: AuthSession.instance.currentUser?.displayName ?? '',
        );
    final newsPages = _paginateNews(_news);
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refreshHome,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      IconButton(
                        key: const ValueKey('account-button'),
                        tooltip: '마이페이지',
                        onPressed: _openProfile,
                        icon: const Icon(Icons.account_circle_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _BudgetHeroCard(
                    budget: budget,
                    onSetting: _openBudgetSetting,
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
                  if (_widgetOrder.isEmpty)
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
                            icon: Icons.donut_small_rounded,
                            label: '예산 사용률',
                            value: '${budget.dailyUsagePercent}%',
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 10),
                  if (_widgetOrder.isEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryTile(
                            icon: budget.topCategory?.icon ??
                                Icons.category_outlined,
                            label: '카테고리 1위',
                            value: budget.topCategory?.label ?? '아직 없음',
                            color: budget.topCategory?.color ??
                                AppColors.textTertiary,
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
                  const SizedBox(height: 10),
                  if (_widgetOrder.isEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryTile(
                            icon: Icons.calendar_month_outlined,
                            label: '월간 예산 사용률',
                            value: '${budget.monthlyUsagePercent}%',
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SummaryTile(
                            icon: Icons.wallet_outlined,
                            label: '월간 잔여 예산',
                            value: Formatters.amount(budget.remainingMonth),
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                  if (_widgetOrder.isNotEmpty) ...[
                    LayoutBuilder(
                      builder: (context, constraints) => Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final id in _widgetOrder)
                            if (!_hiddenWidgets.contains(id))
                              SizedBox(
                                width: (constraints.maxWidth - 10) / 2,
                                child: _summaryTile(id, budget),
                              ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _openWidgetEditor,
                      icon: const Icon(Icons.settings_outlined),
                      label: const Text('화면 편집'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  HomePolicyBriefing(
                    refreshVersion: _policyRefreshVersion,
                    onOpenPolicies: _openPolicies,
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
                    onTap: _openDetectedExpenses,
                    child: _QuickMenuContent(
                      icon: Icons.notifications_active_outlined,
                      badgeCount: _detectedExpenseRepository.items.length,
                      title: '감지된 결제 확인',
                      subtitle: _detectedExpenseRepository.items.isEmpty
                          ? '확인이 필요한 결제가 없어요'
                          : '등록을 기다리는 결제 ${_detectedExpenseRepository.items.length}건',
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppCard(
                    onTap: _openExpenseStats,
                    child: const _QuickMenuContent(
                      icon: Icons.insights_rounded,
                      title: '지출 통계 보기',
                      subtitle: '이번 달 소비 흐름을 확인해요',
                    ),
                  ),
                  const SizedBox(height: 24),
                  _NewsSectionHeader(
                    currentPage: _newsPageIndex,
                    pageCount: newsPages.length,
                    onPrevious: () => _changeNewsPage(-1, newsPages.length),
                    onNext: () => _changeNewsPage(1, newsPages.length),
                  ),
                  const SizedBox(height: 8),
                  if (_isNewsLoading)
                    const _NewsStateCard.loading()
                  else if (_newsErrorMessage != null)
                    _NewsStateCard.error(
                      message: _newsErrorMessage!,
                      onRetry: _loadNews,
                    )
                  else if (_news.isEmpty)
                    const _NewsStateCard.empty()
                  else
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onHorizontalDragStart: _startNewsDrag,
                      onHorizontalDragUpdate: (details) =>
                          _updateNewsDrag(details, newsPages.length),
                      onHorizontalDragEnd: (details) =>
                          _finishNewsDrag(details, newsPages.length),
                      onHorizontalDragCancel: () => unawaited(_resetNewsDrag()),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final pageWidth = constraints.maxWidth;
                          _newsViewportWidth = pageWidth;

                          return ClipRect(
                            child: AnimatedBuilder(
                              animation: _newsDragController,
                              builder: (context, _) {
                                final dragOffset = _newsDragController.value;
                                final neighborDirection =
                                    dragOffset < 0 ? 1 : -1;
                                final neighborIndex =
                                    _newsPageIndex + neighborDirection;
                                final hasNeighbor = neighborIndex >= 0 &&
                                    neighborIndex < newsPages.length;

                                return Stack(
                                  alignment: Alignment.topLeft,
                                  children: [
                                    Transform.translate(
                                      offset: Offset(dragOffset, 0),
                                      child: _NewsPage(
                                        news: newsPages[_newsPageIndex],
                                        onOpenNews: _openNews,
                                      ),
                                    ),
                                    if (hasNeighbor && dragOffset != 0)
                                      Transform.translate(
                                        offset: Offset(
                                          dragOffset +
                                              (neighborDirection *
                                                  (pageWidth + _newsPageGap)),
                                          0,
                                        ),
                                        child: _NewsPage(
                                          news: newsPages[neighborIndex],
                                          onOpenNews: _openNews,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsSectionHeader extends StatelessWidget {
  const _NewsSectionHeader({
    required this.currentPage,
    required this.pageCount,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int pageCount;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('맞춤 뉴스', style: AppTextStyles.sectionTitle),
              SizedBox(height: 3),
              Text(
                '청년의 지갑에 도움 되는 기사를 모았어요.',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        if (pageCount > 1) ...[
          _NewsPageButton(
            tooltip: '이전 뉴스 페이지',
            icon: Icons.chevron_left_rounded,
            enabled: currentPage > 0,
            onPressed: onPrevious,
          ),
          SizedBox(
            width: 42,
            child: Text(
              '${currentPage + 1} / $pageCount',
              style: AppTextStyles.captionTiny.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _NewsPageButton(
            tooltip: '다음 뉴스 페이지',
            icon: Icons.chevron_right_rounded,
            enabled: currentPage < pageCount - 1,
            onPressed: onNext,
          ),
        ] else
          const Icon(
            Icons.newspaper_outlined,
            color: AppColors.primary,
          ),
      ],
    );
  }
}

class _NewsPageButton extends StatelessWidget {
  const _NewsPageButton({
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 20),
    );
  }
}

class _NewsPage extends StatelessWidget {
  const _NewsPage({
    super.key,
    required this.news,
    required this.onOpenNews,
  });

  final List<HomeNews> news;
  final Future<void> Function(HomeNews news) onOpenNews;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < news.length; index++) ...[
          _NewsListItem(
            news: news[index],
            onTap: () => unawaited(onOpenNews(news[index])),
          ),
          if (index != news.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _NewsListItem extends StatelessWidget {
  const _NewsListItem({required this.news, required this.onTap});

  final HomeNews news;
  final VoidCallback onTap;

  Color get _iconColor => switch (news.category) {
        '금융' => AppColors.newsInfo,
        '절약' => AppColors.newsSaving,
        '정책' || '트렌드' => AppColors.newsPurple,
        _ => AppColors.newsPrimary,
      };

  Color get _iconBackgroundColor => switch (news.category) {
        '금융' => AppColors.newsInfoSoft,
        '절약' => AppColors.newsSavingSoft,
        '정책' || '트렌드' => AppColors.newsPurpleSoft,
        _ => AppColors.newsPrimarySoft,
      };

  @override
  Widget build(BuildContext context) {
    final iconColor = _iconColor;
    final iconBackgroundColor = _iconBackgroundColor;
    return AppCard(
      onTap: onTap,
      radius: 14,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(news.icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.category.trim().isEmpty ? '생활경제' : news.category,
                    style: AppTextStyles.captionTiny.copyWith(
                      color: iconColor,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    news.title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (news.summary.trim().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      news.summary,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${news.source} · ${news.timeAgo}',
                    style: AppTextStyles.captionTiny,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            size: 21,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

List<List<HomeNews>> _paginateNews(List<HomeNews> news) {
  return List.generate(
    (news.length / _newsPerPage).ceil(),
    (pageIndex) {
      final start = pageIndex * _newsPerPage;
      final requestedEnd = start + _newsPerPage;
      final end = requestedEnd < news.length ? requestedEnd : news.length;
      return news.sublist(start, end);
    },
    growable: false,
  );
}

class _NewsStateCard extends StatelessWidget {
  const _NewsStateCard.loading()
      : message = '관심사에 맞는 뉴스를 고르고 있어요.',
        icon = Icons.hourglass_top_rounded,
        onRetry = null;

  const _NewsStateCard.empty()
      : message = '지금 보여드릴 맞춤 뉴스가 없어요.',
        icon = Icons.article_outlined,
        onRetry = null;

  const _NewsStateCard.error({required this.message, required this.onRetry})
      : icon = Icons.error_outline_rounded;

  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMuted,
            ),
          ),
          if (onRetry != null)
            IconButton(
              tooltip: '다시 시도',
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
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
              _HeroMeta(
                label: '오늘 지출',
                value: Formatters.amount(budget.spentToday),
              ),
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
                '월간 잔여율',
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
                    '${budget.monthlyRemainingPercent}%',
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
              value: budget.monthlyRemainingProgress,
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
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
    this.badgeCount = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
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
            if (badgeCount > 0)
              Positioned(
                right: -7,
                top: -7,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 22,
                    minHeight: 22,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
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
