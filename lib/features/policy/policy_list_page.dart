import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/pill_chip.dart';
import '../auth/auth_session.dart';
import 'data/policy_api_client.dart';
import 'data/policy_models.dart';

typedef PolicyAccessTokenProvider = String? Function();

class PolicyListPage extends StatefulWidget {
  PolicyListPage({
    super.key,
    required this.condition,
    PolicyApiClient? apiClient,
    PolicyAccessTokenProvider? accessTokenProvider,
    this.onEditCondition,
  })  : apiClient = apiClient ?? PolicyApiClient(),
        accessTokenProvider =
            accessTokenProvider ?? (() => AuthSession.instance.accessToken);

  final PolicyFilterCondition condition;
  final PolicyApiClient apiClient;
  final PolicyAccessTokenProvider accessTokenProvider;
  final VoidCallback? onEditCondition;

  @override
  State<PolicyListPage> createState() => _PolicyListPageState();
}

class _PolicyListPageState extends State<PolicyListPage> {
  final TextEditingController _searchController = TextEditingController();
  final Map<PolicyCategory, _PolicySectionState> _sections = {
    for (final category in PolicyCategory.values)
      category: _PolicySectionState(),
  };
  final Set<String> _hiddenPolicyIds = {};
  List<PolicySummary> _flatPolicies = [];
  Object? _screenError;
  Object? _flatError;
  int? _flatNextPage;
  bool _flatLoading = true;
  bool _flatLoadingMore = false;
  int _sortIndex = 0;
  int _loadGeneration = 0;
  String _keyword = '';

  bool get _isGrouped => widget.condition.category == null && _keyword.isEmpty;

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _requireAccessToken() {
    final accessToken = widget.accessTokenProvider();
    if (accessToken == null || accessToken.isEmpty) {
      throw const PolicyApiException(
        '정책을 조회하려면 먼저 로그인해 주세요.',
        type: PolicyApiErrorType.unauthorized,
      );
    }
    return accessToken;
  }

  Future<void> _reload() async {
    final generation = ++_loadGeneration;
    late final String accessToken;
    try {
      accessToken = _requireAccessToken();
    } on PolicyApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _screenError = error;
        _flatLoading = false;
      });
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() => _screenError = null);
    if (_isGrouped) {
      await _loadAllSections(accessToken, generation);
    } else {
      await _loadFlat(accessToken, reset: true, generation: generation);
    }
  }

  Future<void> _loadAllSections(String accessToken, int generation) async {
    setState(() {
      for (final state in _sections.values) {
        state
          ..items.clear()
          ..nextPage = null
          ..error = null
          ..loading = true
          ..loadingMore = false;
      }
    });
    await Future.wait(
      PolicyCategory.values.map(
        (category) => _loadSection(
          accessToken,
          category,
          reset: true,
          generation: generation,
        ),
      ),
    );
  }

  Future<void> _loadSection(
    String accessToken,
    PolicyCategory category, {
    required bool reset,
    required int generation,
  }) async {
    final state = _sections[category]!;
    final page = reset ? 1 : state.nextPage;
    if (page == null) {
      return;
    }
    if (!reset) {
      setState(() {
        state
          ..loadingMore = true
          ..error = null;
      });
    }

    try {
      final result = await widget.apiClient.searchPolicies(
        accessToken: accessToken,
        condition: widget.condition,
        category: category,
        page: page,
      );
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        final existingIds = state.items.map((item) => item.policyId).toSet();
        for (final policy in result.items) {
          if (!_hiddenPolicyIds.contains(policy.policyId) &&
              existingIds.add(policy.policyId)) {
            state.items.add(policy);
          }
        }
        state
          ..nextPage = result.nextPage
          ..error = null
          ..loading = false
          ..loadingMore = false;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        state
          ..error = error
          ..loading = false
          ..loadingMore = false;
      });
    }
  }

  Future<void> _loadFlat(
    String accessToken, {
    required bool reset,
    required int generation,
  }) async {
    final page = reset ? 1 : _flatNextPage;
    if (page == null) {
      return;
    }
    setState(() {
      if (reset) {
        _flatPolicies = [];
        _flatNextPage = null;
        _flatLoading = true;
      } else {
        _flatLoadingMore = true;
      }
      _flatError = null;
    });

    try {
      final result = await widget.apiClient.searchPolicies(
        accessToken: accessToken,
        condition: widget.condition,
        keyword: _keyword,
        page: page,
      );
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        final existingIds = _flatPolicies.map((item) => item.policyId).toSet();
        for (final policy in result.items) {
          if (!_hiddenPolicyIds.contains(policy.policyId) &&
              existingIds.add(policy.policyId)) {
            _flatPolicies.add(policy);
          }
        }
        _flatNextPage = result.nextPage;
        _flatLoading = false;
        _flatLoadingMore = false;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _flatError = error;
        _flatLoading = false;
        _flatLoadingMore = false;
      });
    }
  }

  void _retry() => unawaited(_reload());

  void _retrySection(PolicyCategory category) {
    late final String accessToken;
    try {
      accessToken = _requireAccessToken();
    } on PolicyApiException catch (error) {
      setState(() => _screenError = error);
      return;
    }
    unawaited(
      _loadSection(
        accessToken,
        category,
        reset: true,
        generation: _loadGeneration,
      ),
    );
  }

  void _loadMoreSection(PolicyCategory category) {
    late final String accessToken;
    try {
      accessToken = _requireAccessToken();
    } on PolicyApiException catch (error) {
      setState(() => _screenError = error);
      return;
    }
    unawaited(
      _loadSection(
        accessToken,
        category,
        reset: false,
        generation: _loadGeneration,
      ),
    );
  }

  void _loadMoreFlat() {
    late final String accessToken;
    try {
      accessToken = _requireAccessToken();
    } on PolicyApiException catch (error) {
      setState(() => _screenError = error);
      return;
    }
    unawaited(
      _loadFlat(
        accessToken,
        reset: false,
        generation: _loadGeneration,
      ),
    );
  }

  void _search() {
    FocusScope.of(context).unfocus();
    final keyword = _searchController.text.trim();
    setState(() => _keyword = keyword);
    unawaited(_reload());
  }

  void _clearSearch() {
    _searchController.clear();
    if (_keyword.isEmpty) {
      return;
    }
    setState(() => _keyword = '');
    unawaited(_reload());
  }

  void _editCondition() {
    final onEditCondition = widget.onEditCondition;
    if (onEditCondition != null) {
      onEditCondition();
      return;
    }
    Navigator.pop(context);
  }

  List<PolicySummary> _sortedPolicies(List<PolicySummary> source) {
    final result = [...source];
    if (_sortIndex == 1) {
      result.sort(
        (a, b) => _deadlineSortValue(
          a.applicationPeriodText,
        ).compareTo(_deadlineSortValue(b.applicationPeriodText)),
      );
    } else if (_sortIndex == 2) {
      result.sort((a, b) {
        final aAmount = a.supportAmount;
        final bAmount = b.supportAmount;
        if (aAmount == null && bAmount == null) {
          return 0;
        }
        if (aAmount == null) {
          return 1;
        }
        if (bAmount == null) {
          return -1;
        }
        return bAmount.compareTo(aAmount);
      });
    }
    return result;
  }

  DateTime _deadlineSortValue(String? period) {
    final matches = RegExp(
      r'(\d{4})[.\-/]?(\d{2})[.\-/]?(\d{2})',
    ).allMatches(period ?? '').toList();
    if (matches.isEmpty) {
      return DateTime(9999);
    }
    final match = matches.last;
    return DateTime.tryParse(
          '${match.group(1)}-${match.group(2)}-${match.group(3)}',
        ) ??
        DateTime(9999);
  }

  void _hidePolicy(PolicySummary policy) {
    final flatIndex = _flatPolicies.indexWhere(
      (item) => item.policyId == policy.policyId,
    );
    final sectionIndexes = <PolicyCategory, int>{};
    for (final entry in _sections.entries) {
      final index = entry.value.items.indexWhere(
        (item) => item.policyId == policy.policyId,
      );
      if (index >= 0) {
        sectionIndexes[entry.key] = index;
      }
    }
    setState(() {
      _hiddenPolicyIds.add(policy.policyId);
      _flatPolicies.removeWhere((item) => item.policyId == policy.policyId);
      for (final state in _sections.values) {
        state.items.removeWhere((item) => item.policyId == policy.policyId);
      }
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${policy.title}을 추천에서 숨겼어요.'),
        action: SnackBarAction(
          label: '실행취소',
          onPressed: () {
            setState(() {
              _hiddenPolicyIds.remove(policy.policyId);
              if (flatIndex >= 0 &&
                  !_flatPolicies.any(
                    (item) => item.policyId == policy.policyId,
                  )) {
                _flatPolicies.insert(
                  flatIndex.clamp(0, _flatPolicies.length),
                  policy,
                );
              }
              for (final entry in sectionIndexes.entries) {
                final items = _sections[entry.key]!.items;
                if (!items.any((item) => item.policyId == policy.policyId)) {
                  items.insert(entry.value.clamp(0, items.length), policy);
                }
              }
            });
          },
        ),
      ),
    );
  }

  List<String> get _conditionLabels {
    final condition = widget.condition;
    return [
      '만 ${condition.age}세',
      condition.region,
      if (condition.district != null) condition.district!,
      if (condition.workStatus != null) condition.workStatus!.label,
      if (condition.jobSeeking == true) '구직 중',
      if (condition.educationStatus != null) condition.educationStatus!.label,
      if (condition.category != null) condition.category!.label,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('맞춤 정책 결과')),
      body: Column(
        children: [
          _ConditionHeader(
            conditionLabels: _conditionLabels,
            sortIndex: _sortIndex,
            onSortChanged: (value) => setState(() => _sortIndex = value),
            onEditCondition: _editCondition,
            searchController: _searchController,
            onSearch: _search,
            onClearSearch: _clearSearch,
          ),
          Expanded(
            child: _screenError != null
                ? _PolicyLoadError(error: _screenError, onRetry: _retry)
                : _isGrouped
                    ? _buildGroupedList()
                    : _buildFlatList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    final shownPolicyIds = <String>{};
    return ListView(
      key: const PageStorageKey('policy-grouped-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        for (final category in PolicyCategory.values) ...[
          _PolicyCategorySection(
            category: category,
            policies: _sortedPolicies(
              _sections[category]!
                  .items
                  .where((policy) => shownPolicyIds.add(policy.policyId))
                  .toList(),
            ),
            state: _sections[category]!,
            onRetry: () => _retrySection(category),
            onLoadMore: () => _loadMoreSection(category),
            cardBuilder: _buildPolicyCard,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildFlatList() {
    if (_flatLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_flatError != null && _flatPolicies.isEmpty) {
      return _PolicyLoadError(error: _flatError, onRetry: _retry);
    }
    final policies = _sortedPolicies(_flatPolicies);
    if (policies.isEmpty) {
      if (_flatNextPage != null) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            const AppCard(
              color: AppColors.surfaceAlt,
              borderColor: AppColors.border,
              padding: EdgeInsets.all(14),
              child: Text(
                '이번 페이지에는 조건에 맞는 정책이 없어요. 다음 페이지도 확인해 보세요.',
                style: AppTextStyles.caption,
              ),
            ),
            const SizedBox(height: 12),
            _LoadMoreButton(
              key: const ValueKey('policy-load-more'),
              loading: _flatLoadingMore,
              onPressed: _loadMoreFlat,
            ),
          ],
        );
      }
      return EmptyStateView(
        icon: Icons.search_off_rounded,
        title: _keyword.isEmpty ? '조건에 맞는 정책이 없어요' : '검색 결과가 없어요',
        description: _keyword.isEmpty
            ? '조건을 조금 넓히면 더 많은 지원 정책을 볼 수 있어요.'
            : '다른 정책명으로 다시 검색해 보세요.',
        actionLabel: _keyword.isEmpty ? '조건 수정' : '검색 초기화',
        onAction: _keyword.isEmpty ? _editCondition : _clearSearch,
      );
    }
    return ListView(
      key: const PageStorageKey('policy-list-scroll'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        if (_flatError != null)
          _InlineLoadError(error: _flatError!, onRetry: _loadMoreFlat),
        for (var index = 0; index < policies.length; index++) ...[
          _buildPolicyCard(policies[index]),
          if (index < policies.length - 1) const SizedBox(height: 10),
        ],
        if (_flatNextPage != null) ...[
          const SizedBox(height: 12),
          _LoadMoreButton(
            key: const ValueKey('policy-load-more'),
            loading: _flatLoadingMore,
            onPressed: _loadMoreFlat,
          ),
        ],
      ],
    );
  }

  Widget _buildPolicyCard(PolicySummary policy) {
    return _PolicyCard(
      policy: policy,
      onHide: () => _hidePolicy(policy),
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.policyDetail,
        arguments: PolicyDetailArguments(
          policyId: policy.policyId,
          eligibilityStatus: policy.eligibilityStatus,
          eligibilityReasons: policy.eligibilityReasons,
        ),
      ),
    );
  }
}

class _ConditionHeader extends StatelessWidget {
  const _ConditionHeader({
    required this.conditionLabels,
    required this.sortIndex,
    required this.onSortChanged,
    required this.onEditCondition,
    required this.searchController,
    required this.onSearch,
    required this.onClearSearch,
  });

  final List<String> conditionLabels;
  final int sortIndex;
  final ValueChanged<int> onSortChanged;
  final VoidCallback onEditCondition;
  final TextEditingController searchController;
  final VoidCallback onSearch;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('선택한 조건', style: AppTextStyles.sectionTitle),
                    ),
                    TextButton(
                      key: const ValueKey('policy-edit-condition-button'),
                      onPressed: onEditCondition,
                      child: const Text('조건 수정'),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final label in conditionLabels)
                      Chip(
                        label: Text(label),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '입력한 조건과 관련된 정책을 보여드려요. '
            '실제 신청 자격은 공식 공고에서 확인해 주세요.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchController,
                  builder: (context, value, child) {
                    return TextField(
                      key: const ValueKey('policy-keyword-field'),
                      controller: searchController,
                      textInputAction: TextInputAction.search,
                      maxLength: 50,
                      onSubmitted: (_) => onSearch(),
                      decoration: InputDecoration(
                        labelText: '정책명 검색',
                        hintText: '예: 월세, 취업 지원',
                        counterText: '',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: value.text.isEmpty
                            ? null
                            : IconButton(
                                key: const ValueKey('policy-search-clear'),
                                tooltip: '검색어 지우기',
                                onPressed: onClearSearch,
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const ValueKey('policy-keyword-search-button'),
                onPressed: onSearch,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(72, 52),
                  maximumSize: const Size(88, 52),
                ),
                child: const Text('검색'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SortToggle(
            options: const ['추천순', '마감임박순', '지원금액순'],
            selectedIndex: sortIndex,
            onChanged: onSortChanged,
          ),
        ],
      ),
    );
  }
}

class _PolicySectionState {
  final List<PolicySummary> items = [];
  int? nextPage;
  Object? error;
  bool loading = false;
  bool loadingMore = false;
}

class _PolicyCategorySection extends StatelessWidget {
  const _PolicyCategorySection({
    required this.category,
    required this.policies,
    required this.state,
    required this.onRetry,
    required this.onLoadMore,
    required this.cardBuilder,
  });

  final PolicyCategory category;
  final List<PolicySummary> policies;
  final _PolicySectionState state;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final Widget Function(PolicySummary policy) cardBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey('policy-category-section-${category.name}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: _categoryColor(category).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _categoryIcon(category),
                color: _categoryColor(category),
                size: 19,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${category.label} 정책',
                style: AppTextStyles.sectionTitle,
              ),
            ),
            if (!state.loading)
              Text('${policies.length}개', style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: 10),
        if (state.loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 22),
              child: CircularProgressIndicator(),
            ),
          )
        else if (state.error != null && policies.isEmpty)
          _InlineLoadError(error: state.error!, onRetry: onRetry)
        else if (policies.isEmpty) ...[
          AppCard(
            color: AppColors.surfaceAlt,
            borderColor: AppColors.border,
            padding: const EdgeInsets.all(14),
            child: Text(
              state.nextPage == null
                  ? '현재 조건에 맞는 ${category.label} 정책이 없어요.'
                  : '이번 페이지에는 조건에 맞는 ${category.label} 정책이 없어요.',
              style: AppTextStyles.caption,
            ),
          ),
          if (state.nextPage != null) ...[
            const SizedBox(height: 10),
            _LoadMoreButton(
              key: ValueKey('policy-load-more-${category.name}'),
              loading: state.loadingMore,
              onPressed: onLoadMore,
            ),
          ],
        ] else ...[
          for (var index = 0; index < policies.length; index++) ...[
            cardBuilder(policies[index]),
            if (index < policies.length - 1) const SizedBox(height: 10),
          ],
          if (state.error != null) ...[
            const SizedBox(height: 10),
            _InlineLoadError(error: state.error!, onRetry: onLoadMore),
          ],
          if (state.nextPage != null) ...[
            const SizedBox(height: 10),
            _LoadMoreButton(
              key: ValueKey('policy-load-more-${category.name}'),
              loading: state.loadingMore,
              onPressed: onLoadMore,
            ),
          ],
        ],
      ],
    );
  }
}

class _InlineLoadError extends StatelessWidget {
  const _InlineLoadError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is PolicyApiException
        ? (error as PolicyApiException).message
        : '추가 정책을 불러오지 못했어요.';
    return AppCard(
      color: AppColors.dangerSoft,
      borderColor: AppColors.dangerSoft,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: AppTextStyles.caption)),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton(
      {super.key, required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.expand_more_rounded),
        label: Text(loading ? '불러오는 중' : '더보기'),
      ),
    );
  }
}

class _PolicyLoadError extends StatelessWidget {
  const _PolicyLoadError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is PolicyApiException
        ? (error! as PolicyApiException).message
        : '정책 목록을 불러오지 못했어요.';
    return EmptyStateView(
      icon: Icons.cloud_off_rounded,
      title: '정책 목록을 불러오지 못했어요',
      description: message,
      actionLabel: '다시 시도',
      onAction: onRetry,
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
    required this.policy,
    required this.onHide,
    required this.onTap,
  });

  final PolicySummary policy;
  final VoidCallback onHide;
  final VoidCallback onTap;

  String get _supportLabel {
    final amount = policy.supportAmount;
    return amount == null ? '지원 내용 확인' : Formatters.compactAmount(amount);
  }

  String get _periodLabel => policy.applicationPeriodText ?? '신청 기간 확인 필요';

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor(policy.categoryType);
    return AppCard(
      key: ValueKey('policy-card-${policy.policyId}'),
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      radius: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _categoryIcon(policy.categoryType),
                    color: categoryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  policy.category,
                  style: AppTextStyles.captionTiny,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        policy.title,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: PopupMenuButton<String>(
                        key: ValueKey('policy-menu-${policy.policyId}'),
                        tooltip: '정책 메뉴',
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'hide') {
                            onHide();
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'hide', child: Text('관심 없음')),
                        ],
                      ),
                    ),
                  ],
                ),
                if (policy.eligibilityStatus ==
                    PolicyEligibilityStatus.checkRequired) ...[
                  const SizedBox(height: 4),
                  Text(
                    '신청 자격 확인 필요',
                    key: ValueKey('policy-check-required-${policy.policyId}'),
                    style: AppTextStyles.captionTiny.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _supportLabel,
                        style: AppTextStyles.amount.copyWith(
                          color: AppColors.primary,
                          fontSize: 17,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('지원 예상', style: AppTextStyles.captionTiny),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _periodLabel,
                        style: AppTextStyles.captionTiny,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Color _categoryColor(PolicyCategory? category) => switch (category) {
      PolicyCategory.employment => AppColors.info,
      PolicyCategory.housing => AppColors.categoryFood,
      PolicyCategory.education => AppColors.warning,
      PolicyCategory.welfareCulture => AppColors.categoryCafe,
      PolicyCategory.participationRights => AppColors.categoryTransport,
      null => AppColors.categoryEtc,
    };

IconData _categoryIcon(PolicyCategory? category) => switch (category) {
      PolicyCategory.employment => Icons.work_outline_rounded,
      PolicyCategory.housing => Icons.home_work_outlined,
      PolicyCategory.education => Icons.school_outlined,
      PolicyCategory.welfareCulture => Icons.volunteer_activism_outlined,
      PolicyCategory.participationRights => Icons.campaign_outlined,
      null => Icons.policy_outlined,
    };
