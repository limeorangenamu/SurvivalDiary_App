import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../auth/auth_session.dart';
import 'data/policy_api_client.dart';
import 'data/policy_models.dart';
import 'hidden_policies_page.dart';
import 'policy_text_formatter.dart';

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
  final _searchController = TextEditingController();
  final Set<String> _hiddenPolicyIds = {};

  List<PolicySummary> _policies = [];
  Object? _error;
  int? _nextPage;
  int _generation = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String _keyword = '';
  PolicyCategory? _category;
  _PolicySort _sort = _PolicySort.recommendation;

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
    final generation = ++_generation;
    late final String accessToken;
    try {
      accessToken = _requireAccessToken();
    } on PolicyApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
      return;
    }

    setState(() {
      _policies = [];
      _nextPage = null;
      _error = null;
      _loading = true;
    });

    try {
      final result = await widget.apiClient.recommendPolicies(
        accessToken: accessToken,
        category: _category,
        keyword: _keyword,
      );
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _policies = result.items
            .where((policy) => !_hiddenPolicyIds.contains(policy.policyId))
            .toList();
        _nextPage = result.nextPage;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final page = _nextPage;
    if (page == null || _loadingMore) {
      return;
    }

    late final String accessToken;
    try {
      accessToken = _requireAccessToken();
    } on PolicyApiException catch (error) {
      setState(() => _error = error);
      return;
    }

    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final result = await widget.apiClient.recommendPolicies(
        accessToken: accessToken,
        category: _category,
        keyword: _keyword,
        page: page,
      );
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        final ids = _policies.map((policy) => policy.policyId).toSet();
        for (final policy in result.items) {
          if (!_hiddenPolicyIds.contains(policy.policyId) &&
              ids.add(policy.policyId)) {
            _policies.add(policy);
          }
        }
        _nextPage = result.nextPage;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted || generation != _generation) {
        return;
      }
      setState(() {
        _error = error;
        _loadingMore = false;
      });
    }
  }

  void _search() {
    final keyword = _searchController.text.trim();
    if (keyword == _keyword) {
      return;
    }
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

  void _selectCategory(PolicyCategory? category) {
    if (_category == category) {
      return;
    }
    setState(() => _category = category);
    unawaited(_reload());
  }

  Future<void> _hidePolicy(PolicySummary policy) async {
    if (_hiddenPolicyIds.contains(policy.policyId)) {
      return;
    }
    setState(() {
      _hiddenPolicyIds.add(policy.policyId);
      _policies.removeWhere((item) => item.policyId == policy.policyId);
    });

    try {
      await widget.apiClient.hidePolicy(
        accessToken: _requireAccessToken(),
        policy: policy,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _hiddenPolicyIds.remove(policy.policyId);
        if (_policies.every((item) => item.policyId != policy.policyId)) {
          _policies.add(policy);
        }
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_policyErrorMessage(error))));
      return;
    }

    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${policy.title} 정책을 목록에서 숨겼어요.'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: '실행취소',
            onPressed: () {
              unawaited(_restoreHiddenPolicy(policy));
            },
          ),
        ),
      );
  }

  Future<void> _restoreHiddenPolicy(PolicySummary policy) async {
    try {
      await widget.apiClient.restoreHiddenPolicy(
        accessToken: _requireAccessToken(),
        policyId: policy.policyId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _hiddenPolicyIds.remove(policy.policyId);
        if (_policies.every((item) => item.policyId != policy.policyId)) {
          _policies.add(policy);
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_policyErrorMessage(error))));
    }
  }

  Future<void> _openHiddenPolicies() async {
    await Navigator.pushNamed<dynamic>(
      context,
      AppRoutes.hiddenPolicies,
      arguments: HiddenPoliciesArguments(
        apiClient: widget.apiClient,
        accessTokenProvider: widget.accessTokenProvider,
      ),
    );
    if (!mounted) {
      return;
    }
    _hiddenPolicyIds.clear();
    await _reload();
  }

  Future<void> _openPolicy(PolicySummary policy) async {
    final action = await Navigator.pushNamed<dynamic>(
      context,
      AppRoutes.policyDetail,
      arguments: PolicyDetailArguments(
        policyId: policy.policyId,
        eligibilityStatus: policy.eligibilityStatus,
        eligibilityReasons: policy.eligibilityReasons,
        recommendationStatus: policy.recommendationStatus,
        recommendationReasons: policy.recommendationReasons,
        summary: policy,
      ),
    );
    if (!mounted || action != PolicyDetailAction.hide) {
      return;
    }
    await _hidePolicy(policy);
  }

  List<PolicySummary> _sorted(Iterable<PolicySummary> policies) {
    final result = policies.toList();
    result.sort((a, b) {
      return switch (_sort) {
        _PolicySort.recommendation =>
          _recommendationRank(b).compareTo(_recommendationRank(a)),
        _PolicySort.deadline => _compareNullableDate(
            a.applicationEndDate,
            b.applicationEndDate,
          ),
        _PolicySort.support => _compareSupportAmount(a, b),
      };
    });
    return result;
  }

  int _compareSupportAmount(PolicySummary a, PolicySummary b) {
    final cadenceComparison = _supportCadenceRank(
      a,
    ).compareTo(_supportCadenceRank(b));
    if (cadenceComparison != 0) {
      return cadenceComparison;
    }
    return (b.supportAmount ?? -1).compareTo(a.supportAmount ?? -1);
  }

  int _supportCadenceRank(PolicySummary policy) {
    if (policy.supportAmount == null) {
      return 2;
    }
    return switch (policy.supportAmountType) {
      PolicySupportAmountType.monthly ||
      PolicySupportAmountType.monthlyMaximum =>
        1,
      PolicySupportAmountType.fixed ||
      PolicySupportAmountType.maximum ||
      null =>
        0,
    };
  }

  int _recommendationRank(PolicySummary policy) {
    final statusRank = switch (policy.recommendationStatus) {
      PolicyRecommendationStatus.recommended => 300,
      PolicyRecommendationStatus.checkRequired => 200,
      PolicyRecommendationStatus.discover => 100,
    };
    return statusRank + policy.recommendationReasons.length;
  }

  int _compareNullableDate(DateTime? a, DateTime? b) {
    final today = DateUtils.dateOnly(DateTime.now());
    final aGroup =
        a == null ? 2 : (DateUtils.dateOnly(a).isBefore(today) ? 1 : 0);
    final bGroup =
        b == null ? 2 : (DateUtils.dateOnly(b).isBefore(today) ? 1 : 0);
    if (aGroup != bGroup) {
      return aGroup.compareTo(bGroup);
    }
    if (a == null || b == null) {
      return 0;
    }
    return aGroup == 1 ? b.compareTo(a) : a.compareTo(b);
  }

  @override
  Widget build(BuildContext context) {
    final recommended = _sorted(
      _policies.where(
        (policy) =>
            policy.recommendationStatus ==
            PolicyRecommendationStatus.recommended,
      ),
    );
    final checkRequired = _sorted(
      _policies.where(
        (policy) =>
            policy.recommendationStatus ==
            PolicyRecommendationStatus.checkRequired,
      ),
    );
    final discover = _sorted(
      _policies.where(
        (policy) =>
            policy.recommendationStatus == PolicyRecommendationStatus.discover,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('맞춤 정책'),
        actions: [
          TextButton(
            key: const ValueKey('policy-hidden-list-button'),
            onPressed: _openHiddenPolicies,
            child: Text(
              '숨김 목록',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          key: const PageStorageKey('policy-briefing-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            _BriefingHeader(
              condition: widget.condition,
              recommendedCount: recommended.length,
              loading: _loading,
              searchController: _searchController,
              keyword: _keyword,
              category: _category,
              onEditCondition: widget.onEditCondition,
              onSearch: _search,
              onClearSearch: _clearSearch,
              onCategoryChanged: _selectCategory,
            ),
            const SizedBox(height: 14),
            if (_loading)
              const _PolicyLoading()
            else if (_error != null && _policies.isEmpty)
              _PolicyLoadError(error: _error, onRetry: _reload)
            else if (_policies.isEmpty)
              EmptyStateView(
                icon: Icons.search_off_rounded,
                title: _keyword.isEmpty ? '지금 보여드릴 정책이 없어요' : '검색 결과가 없어요',
                description: _keyword.isEmpty
                    ? '다른 분야를 선택하거나 잠시 후 다시 확인해 주세요.'
                    : '다른 정책명으로 다시 검색해 보세요.',
                actionLabel: _keyword.isEmpty ? '전체 정책 보기' : '검색 초기화',
                onAction: _keyword.isEmpty
                    ? () => _selectCategory(null)
                    : _clearSearch,
              )
            else if (_keyword.isNotEmpty)
              _PolicySection(
                key: const ValueKey('policy-search-results'),
                title: '“$_keyword” 검색 결과',
                subtitle: '${_policies.length}개의 정책을 찾았어요.',
                sort: _sort,
                onSortChanged: (value) => setState(() => _sort = value),
                policies: _sorted(_policies),
                cardBuilder: (policy) => _PolicyCompactCard(
                  policy: policy,
                  showStatus: policy.recommendationStatus !=
                      PolicyRecommendationStatus.discover,
                  onHide: () => unawaited(_hidePolicy(policy)),
                  onTap: () => _openPolicy(policy),
                ),
              )
            else ...[
              if (recommended.isNotEmpty)
                _RecommendedSection(
                  condition: widget.condition,
                  policies: recommended,
                  sort: _sort,
                  onSortChanged: (value) => setState(() => _sort = value),
                  onHide: _hidePolicy,
                  onTap: _openPolicy,
                ),
              if (recommended.isNotEmpty && checkRequired.isNotEmpty)
                const SizedBox(height: 26),
              if (checkRequired.isNotEmpty)
                _PolicySection(
                  key: const ValueKey('policy-check-section'),
                  title: '조건을 확인해 볼 정책',
                  subtitle: '관련성은 있지만 신청 전에 확인할 내용이 있어요.',
                  sort: recommended.isEmpty ? _sort : null,
                  onSortChanged: recommended.isEmpty
                      ? (value) => setState(() => _sort = value)
                      : null,
                  policies: checkRequired,
                  cardBuilder: (policy) => _PolicyCompactCard(
                    policy: policy,
                    showStatus: true,
                    onHide: () => unawaited(_hidePolicy(policy)),
                    onTap: () => _openPolicy(policy),
                  ),
                ),
              if ((recommended.isNotEmpty || checkRequired.isNotEmpty) &&
                  discover.isNotEmpty)
                const SizedBox(height: 26),
              if (discover.isNotEmpty)
                _PolicySection(
                  key: const ValueKey('policy-discover-section'),
                  title: '더 둘러볼 정책',
                  subtitle: '추천 조건과 관계없이 함께 확인할 수 있어요.',
                  sort: recommended.isEmpty && checkRequired.isEmpty
                      ? _sort
                      : null,
                  onSortChanged: recommended.isEmpty && checkRequired.isEmpty
                      ? (value) => setState(() => _sort = value)
                      : null,
                  policies: discover,
                  cardBuilder: (policy) => _PolicyCompactCard(
                    policy: policy,
                    showStatus: false,
                    onHide: () => unawaited(_hidePolicy(policy)),
                    onTap: () => _openPolicy(policy),
                  ),
                ),
            ],
            if (_error != null && _policies.isNotEmpty) ...[
              const SizedBox(height: 12),
              _InlineError(error: _error!, onRetry: _loadMore),
            ],
            if (_nextPage != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                key: const ValueKey('policy-load-more'),
                onPressed: _loadingMore ? null : _loadMore,
                icon: _loadingMore
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded),
                label: Text(_loadingMore ? '정책을 불러오는 중...' : '정책 더 보기'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BriefingHeader extends StatelessWidget {
  const _BriefingHeader({
    required this.condition,
    required this.recommendedCount,
    required this.loading,
    required this.searchController,
    required this.keyword,
    required this.category,
    required this.onEditCondition,
    required this.onSearch,
    required this.onClearSearch,
    required this.onCategoryChanged,
  });

  final PolicyFilterCondition condition;
  final int recommendedCount;
  final bool loading;
  final TextEditingController searchController;
  final String keyword;
  final PolicyCategory? category;
  final VoidCallback? onEditCondition;
  final VoidCallback onSearch;
  final VoidCallback onClearSearch;
  final ValueChanged<PolicyCategory?> onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    final conditionLabel = [
      condition.region,
      condition.district ?? '전체',
      '만 ${condition.age}세',
      if (condition.jobSeeking == true) '구직 중',
      if (condition.workStatus != null && condition.jobSeeking != true)
        condition.workStatus!.label,
      if (condition.educationLevel != null) condition.educationLevel!.label,
      if (condition.enrollmentStatus != null) condition.enrollmentStatus!.label,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loading
              ? '나에게 맞는 정책을 찾고 있어요'
              : recommendedCount > 0
                  ? '놓치면 아쉬운 정책이 $recommendedCount개 있어요'
                  : '오늘 확인할 정책을 모았어요',
          style: AppTextStyles.title,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                conditionLabel,
                style: AppTextStyles.bodyMuted,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onEditCondition != null)
              TextButton(
                key: const ValueKey('policy-edit-condition-button'),
                onPressed: onEditCondition,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('조건 수정'),
              ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          key: const ValueKey('policy-keyword-field'),
          controller: searchController,
          textInputAction: TextInputAction.search,
          maxLength: 50,
          onSubmitted: (_) => onSearch(),
          decoration: InputDecoration(
            hintText: '정책 이름을 검색해 보세요',
            counterText: '',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: keyword.isNotEmpty
                ? IconButton(
                    key: const ValueKey('policy-search-clear'),
                    onPressed: onClearSearch,
                    tooltip: '검색 초기화',
                    icon: const Icon(Icons.close_rounded),
                  )
                : IconButton(
                    key: const ValueKey('policy-keyword-search-button'),
                    onPressed: onSearch,
                    tooltip: '검색',
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          key: const ValueKey('policy-category-filter'),
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _CategoryChip(
                key: const ValueKey('policy-category-all'),
                label: '전체',
                selected: category == null,
                onSelected: () => onCategoryChanged(null),
              ),
              for (final value in PolicyCategory.values) ...[
                const SizedBox(width: 8),
                _CategoryChip(
                  key: ValueKey('policy-category-${value.name}'),
                  label: value.label,
                  selected: category == value,
                  onSelected: () => onCategoryChanged(value),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      labelStyle: AppTextStyles.caption.copyWith(
        color: selected ? AppColors.surface : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _RecommendedSection extends StatelessWidget {
  const _RecommendedSection({
    required this.condition,
    required this.policies,
    required this.sort,
    required this.onSortChanged,
    required this.onHide,
    required this.onTap,
  });

  final PolicyFilterCondition condition;
  final List<PolicySummary> policies;
  final _PolicySort sort;
  final ValueChanged<_PolicySort> onSortChanged;
  final ValueChanged<PolicySummary> onHide;
  final ValueChanged<PolicySummary> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('policy-recommended-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PolicySectionHeading(
          title: '내게 잘 맞는 정책',
          subtitle: '저장한 상황과 신청 조건이 잘 맞는 순서예요.',
          sort: sort,
          onSortChanged: onSortChanged,
        ),
        const SizedBox(height: 12),
        _PolicyHeroCard(
          condition: condition,
          policy: policies.first,
          onHide: () => onHide(policies.first),
          onTap: () => onTap(policies.first),
        ),
        for (final policy in policies.skip(1)) ...[
          const SizedBox(height: 10),
          _PolicyCompactCard(
            policy: policy,
            showStatus: true,
            onHide: () => onHide(policy),
            onTap: () => onTap(policy),
          ),
        ],
      ],
    );
  }
}

class _PolicySection extends StatelessWidget {
  const _PolicySection({
    super.key,
    required this.title,
    required this.subtitle,
    this.sort,
    this.onSortChanged,
    required this.policies,
    required this.cardBuilder,
  });

  final String title;
  final String subtitle;
  final _PolicySort? sort;
  final ValueChanged<_PolicySort>? onSortChanged;
  final List<PolicySummary> policies;
  final Widget Function(PolicySummary policy) cardBuilder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PolicySectionHeading(
          title: title,
          subtitle: subtitle,
          sort: sort,
          onSortChanged: onSortChanged,
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < policies.length; index++) ...[
          cardBuilder(policies[index]),
          if (index < policies.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _PolicySectionHeading extends StatelessWidget {
  const _PolicySectionHeading({
    required this.title,
    required this.subtitle,
    this.sort,
    this.onSortChanged,
  });

  final String title;
  final String subtitle;
  final _PolicySort? sort;
  final ValueChanged<_PolicySort>? onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.sectionTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (sort != null && onSortChanged != null) ...[
              const SizedBox(width: 10),
              _PolicySortMenu(sort: sort!, onChanged: onSortChanged!),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: AppTextStyles.caption,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _PolicySortMenu extends StatelessWidget {
  const _PolicySortMenu({required this.sort, required this.onChanged});

  final _PolicySort sort;
  final ValueChanged<_PolicySort> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_PolicySort>(
      key: const ValueKey('policy-sort-menu'),
      initialValue: sort,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final value in _PolicySort.values)
          PopupMenuItem(value: value, child: Text(value.label)),
      ],
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert_rounded, size: 17),
            const SizedBox(width: 3),
            Text(sort.label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _PolicyHeroCard extends StatelessWidget {
  const _PolicyHeroCard({
    required this.condition,
    required this.policy,
    required this.onHide,
    required this.onTap,
  });

  final PolicyFilterCondition condition;
  final PolicySummary policy;
  final VoidCallback onHide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${policy.title} 상세 보기',
      child: AppCard(
        key: ValueKey('policy-card-${policy.policyId}'),
        onTap: onTap,
        color: AppColors.primarySoft,
        borderColor: AppColors.primarySoft,
        padding: const EdgeInsets.all(18),
        radius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const _StatusBadge(
                        status: PolicyRecommendationStatus.recommended,
                      ),
                      if (policy.eligibilityStatus ==
                          PolicyEligibilityStatus.checkRequired)
                        const _StatusBadge(
                          status: PolicyRecommendationStatus.checkRequired,
                        ),
                      if (_deadlineBadge(policy.applicationEndDate)
                          case final label?)
                        Text(
                          label,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
                _HideMenu(policyId: policy.policyId, onHide: onHide),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              policy.title,
              style: AppTextStyles.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              _supportLabel(policy),
              style: AppTextStyles.sectionTitle.copyWith(
                color: AppColors.primaryDeep,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (policy.matchSignals.isNotEmpty) ...[
              const SizedBox(height: 10),
              _PolicyMatchSignalChips(
                condition: condition,
                signals: policy.matchSignals,
              ),
            ],
            if (policy.recommendationReasons.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 17,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        policy.recommendationReasons.first,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    policy.category,
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '자세히 보기',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.primaryDeep,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyMatchSignalChips extends StatelessWidget {
  const _PolicyMatchSignalChips({
    required this.condition,
    required this.signals,
  });

  final PolicyFilterCondition condition;
  final List<PolicyMatchSignal> signals;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final signal in signals.take(3))
          Container(
            key: ValueKey('policy-match-signal-${signal.name}'),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Text(
              _matchSignalLabel(signal, condition),
              style: AppTextStyles.captionTiny.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _PolicyCompactCard extends StatelessWidget {
  const _PolicyCompactCard({
    required this.policy,
    required this.showStatus,
    required this.onHide,
    required this.onTap,
  });

  final PolicySummary policy;
  final bool showStatus;
  final VoidCallback onHide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${policy.title} 상세 보기',
      child: AppCard(
        key: ValueKey('policy-card-${policy.policyId}'),
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        radius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    policy.title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _HideMenu(policyId: policy.policyId, onHide: onHide),
              ],
            ),
            if (showStatus) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _StatusBadge(status: policy.recommendationStatus),
                  if (policy.recommendationStatus ==
                          PolicyRecommendationStatus.recommended &&
                      policy.eligibilityStatus ==
                          PolicyEligibilityStatus.checkRequired) ...[
                    const SizedBox(width: 6),
                    const _StatusBadge(
                      status: PolicyRecommendationStatus.checkRequired,
                    ),
                  ],
                  if (policy.recommendationReasons.isNotEmpty) ...[
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        policy.recommendationReasons.first,
                        style: AppTextStyles.captionTiny,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 10),
            Text(
              _supportLabel(policy),
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Expanded(
                  child: _PolicyMetaText(
                    icon: Icons.category_outlined,
                    label: policy.category,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: _PolicyMetaText(
                    icon: Icons.schedule_rounded,
                    label: _deadlineBadge(policy.applicationEndDate) ??
                        _applicationPeriodLabel(policy),
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyMetaText extends StatelessWidget {
  const _PolicyMetaText({
    required this.icon,
    required this.label,
    this.alignEnd = false,
  });

  final IconData icon;
  final String label;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment:
          alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.captionTiny,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PolicyRecommendationStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, background) = switch (status) {
      PolicyRecommendationStatus.recommended => (
          '내게 추천',
          AppColors.primaryDeep,
          AppColors.surface
        ),
      PolicyRecommendationStatus.checkRequired => (
          '조건 확인 필요',
          AppColors.warning,
          AppColors.warningSoft
        ),
      PolicyRecommendationStatus.discover => (
          '',
          AppColors.textSecondary,
          AppColors.surfaceAlt
        ),
    };
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      key: ValueKey('policy-status-${status.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionTiny.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _HideMenu extends StatelessWidget {
  const _HideMenu({required this.policyId, required this.onHide});

  final String policyId;
  final VoidCallback onHide;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      key: ValueKey('policy-menu-$policyId'),
      tooltip: '정책 메뉴',
      padding: EdgeInsets.zero,
      onSelected: (value) {
        if (value == 'hide') {
          onHide();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'hide', child: Text('관심 없음')),
      ],
      child: const SizedBox(
        width: 28,
        height: 28,
        child: Align(
          alignment: Alignment.topRight,
          child: Icon(
            Icons.more_horiz_rounded,
            size: 19,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

class _PolicyLoading extends StatelessWidget {
  const _PolicyLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 52),
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('저장한 조건으로 정책을 정리하고 있어요.', style: AppTextStyles.bodyMuted),
        ],
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
        : '맞춤 정책을 불러오지 못했어요.';
    return EmptyStateView(
      icon: Icons.cloud_off_rounded,
      title: '정책 목록을 불러오지 못했어요',
      description: message,
      actionLabel: '다시 시도',
      onAction: onRetry,
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.error, required this.onRetry});

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: AppTextStyles.caption,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ),
        ],
      ),
    );
  }
}

enum _PolicySort { recommendation, deadline, support }

extension on _PolicySort {
  String get label => switch (this) {
        _PolicySort.recommendation => '추천순',
        _PolicySort.deadline => '마감 임박순',
        _PolicySort.support => '지원 금액순',
      };
}

String _policyErrorMessage(Object error) {
  if (error is PolicyApiException) {
    return error.message;
  }
  return '정책 정보를 처리하지 못했어요. 잠시 후 다시 시도해 주세요.';
}

String _matchSignalLabel(
  PolicyMatchSignal signal,
  PolicyFilterCondition condition,
) =>
    switch (signal) {
      PolicyMatchSignal.age => '만 ${condition.age}세',
      PolicyMatchSignal.region => '${condition.region} 거주',
      PolicyMatchSignal.district => '${condition.district ?? '시·군·구'} 거주',
      PolicyMatchSignal.workStatus => condition.workStatus?.label ?? '근로 상태 일치',
      PolicyMatchSignal.jobSeeking => '구직 중',
      PolicyMatchSignal.educationStatus => _educationSignalLabel(condition),
      PolicyMatchSignal.interestEmployment => '일자리 관심',
      PolicyMatchSignal.interestHousing => '주거 관심',
      PolicyMatchSignal.interestEducation => '교육 관심',
      PolicyMatchSignal.interestWelfareCulture => '복지·문화 관심',
      PolicyMatchSignal.interestParticipationRights => '참여·권리 관심',
      PolicyMatchSignal.interestAssetBuilding => '자산형성 관심',
      PolicyMatchSignal.interestTransport => '교통 관심',
    };

String _educationSignalLabel(PolicyFilterCondition condition) {
  final label = [
    condition.educationLevel?.label,
    condition.enrollmentStatus?.label,
  ].whereType<String>().join(' · ');
  return label.isEmpty ? '교육 조건 일치' : label;
}

String _supportLabel(PolicySummary policy) {
  final shortSummary = policy.shortSummary?.trim();
  if (shortSummary != null && shortSummary.isNotEmpty) {
    return shortSummary;
  }
  final amount = policy.supportAmount;
  if (amount != null) {
    final formatted = Formatters.compactAmount(amount);
    return switch (policy.supportAmountType) {
      PolicySupportAmountType.maximum => '최대 $formatted',
      PolicySupportAmountType.monthly => '월 $formatted',
      PolicySupportAmountType.monthlyMaximum => '월 최대 $formatted',
      PolicySupportAmountType.fixed || null => formatted,
    };
  }
  return compactPolicyText(
    policy.supportText,
    fallback: policy.summary,
  );
}

String _applicationPeriodLabel(PolicySummary policy) =>
    switch (policy.applicationPeriodType) {
      PolicyApplicationPeriodType.always => '상시 신청',
      PolicyApplicationPeriodType.closed => '접수 마감',
      PolicyApplicationPeriodType.untilBudget => '예산 소진 시까지',
      PolicyApplicationPeriodType.fixed ||
      PolicyApplicationPeriodType.unknown ||
      null =>
        policy.applicationPeriodText ?? '기간 확인 필요',
    };

String? _deadlineBadge(DateTime? deadline) {
  if (deadline == null) {
    return null;
  }
  final today = DateUtils.dateOnly(DateTime.now());
  final days = DateUtils.dateOnly(deadline).difference(today).inDays;
  if (days < 0) {
    return '마감';
  }
  if (days == 0) {
    return '오늘 마감';
  }
  return 'D-$days';
}
