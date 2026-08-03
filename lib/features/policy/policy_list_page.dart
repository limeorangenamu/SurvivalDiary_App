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
  }) : apiClient = apiClient ?? PolicyApiClient(),
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
  late Future<PolicySearchResult> _resultFuture;
  List<PolicySummary> _policies = [];
  int _sortIndex = 0;

  @override
  void initState() {
    super.initState();
    _resultFuture = _loadPolicies();
  }

  Future<PolicySearchResult> _loadPolicies() async {
    final accessToken = widget.accessTokenProvider();
    if (accessToken == null || accessToken.isEmpty) {
      throw const PolicyApiException(
        '정책을 조회하려면 먼저 로그인해 주세요.',
        type: PolicyApiErrorType.unauthorized,
      );
    }
    final result = await widget.apiClient.searchPolicies(
      accessToken: accessToken,
      condition: widget.condition,
    );
    _policies = [...result.items];
    return result;
  }

  void _retry() {
    final resultFuture = _loadPolicies();
    setState(() {
      _resultFuture = resultFuture;
    });
  }

  void _editCondition() {
    final onEditCondition = widget.onEditCondition;
    if (onEditCondition != null) {
      onEditCondition();
      return;
    }
    Navigator.pop(context);
  }

  List<PolicySummary> get _visiblePolicies {
    final result = [..._policies];
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
    final index = _policies.indexOf(policy);
    setState(() => _policies.remove(policy));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${policy.title}을 추천에서 숨겼어요.'),
        action: SnackBarAction(
          label: '실행취소',
          onPressed: () {
            if (!_policies.contains(policy)) {
              setState(() => _policies.insert(index, policy));
            }
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
      condition.employmentStatus.label,
      if (condition.incomeRange != null) condition.incomeRange!.label,
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
          ),
          Expanded(
            child: FutureBuilder<PolicySearchResult>(
              future: _resultFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _PolicyLoadError(
                    error: snapshot.error,
                    onRetry: _retry,
                  );
                }

                final result = snapshot.requireData;
                final policies = _visiblePolicies;
                if (policies.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: '조건에 맞는 정책이 없어요',
                    description: '조건을 조금 넓히면 더 많은 지원 정책을 볼 수 있어요.',
                    actionLabel: '조건 수정',
                    onAction: _editCondition,
                  );
                }
                return Column(
                  children: [
                    if (result.partialResult)
                      _PartialResultNotice(
                        checkedProviderPages: result.checkedProviderPages,
                      ),
                    Expanded(
                      child: ListView.separated(
                        key: const PageStorageKey('policy-list-scroll'),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                        itemCount: policies.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final policy = policies[index];
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
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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
  });

  final List<String> conditionLabels;
  final int sortIndex;
  final ValueChanged<int> onSortChanged;
  final VoidCallback onEditCondition;

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

class _PartialResultNotice extends StatelessWidget {
  const _PartialResultNotice({required this.checkedProviderPages});

  final int checkedProviderPages;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: AppCard(
        color: AppColors.warningSoft,
        borderColor: AppColors.warningSoft,
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '제공처 $checkedProviderPages페이지까지 확인한 결과예요. '
                '조건에 맞는 정책이 더 있을 수 있어요.',
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
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

  Color get _categoryColor => switch (policy.categoryType) {
    PolicyCategory.housing => AppColors.categoryFood,
    PolicyCategory.employment => AppColors.info,
    PolicyCategory.asset => AppColors.warning,
    PolicyCategory.culture => AppColors.categoryCafe,
    PolicyCategory.transport => AppColors.categoryTransport,
    null => AppColors.categoryEtc,
  };

  IconData get _categoryIcon => switch (policy.categoryType) {
    PolicyCategory.housing => Icons.home_work_outlined,
    PolicyCategory.employment => Icons.work_outline_rounded,
    PolicyCategory.asset => Icons.savings_outlined,
    PolicyCategory.culture => Icons.palette_outlined,
    PolicyCategory.transport => Icons.directions_bus_outlined,
    null => Icons.policy_outlined,
  };

  String get _supportLabel {
    final amount = policy.supportAmount;
    return amount == null ? '지원 내용 확인' : Formatters.compactAmount(amount);
  }

  String get _periodLabel => policy.applicationPeriodText ?? '신청 기간 확인 필요';

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor;
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
                  child: Icon(_categoryIcon, color: categoryColor, size: 20),
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
