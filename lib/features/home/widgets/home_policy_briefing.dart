import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../../auth/auth_session.dart';
import '../../policy/data/policy_api_client.dart';
import '../../policy/data/policy_models.dart';
import '../../policy/policy_text_formatter.dart';

typedef HomePolicyAccessTokenProvider = String? Function();
typedef HomePolicyNowProvider = DateTime Function();

class HomePolicyBriefing extends StatefulWidget {
  const HomePolicyBriefing({
    super.key,
    this.apiClient,
    this.accessTokenProvider,
    this.nowProvider,
    this.refreshVersion = 0,
    required this.onOpenPolicies,
  });

  final PolicyApiClient? apiClient;
  final HomePolicyAccessTokenProvider? accessTokenProvider;
  final HomePolicyNowProvider? nowProvider;
  final int refreshVersion;
  final VoidCallback onOpenPolicies;

  @override
  State<HomePolicyBriefing> createState() => _HomePolicyBriefingState();
}

class _HomePolicyBriefingState extends State<HomePolicyBriefing>
    with AutomaticKeepAliveClientMixin<HomePolicyBriefing> {
  late final PolicyApiClient _defaultApiClient;
  int _requestGeneration = 0;
  List<PolicySummary> _policies = const [];
  Object? _error;
  bool _loading = true;
  bool _setupRequired = false;

  PolicyApiClient get _apiClient => widget.apiClient ?? _defaultApiClient;

  String? get _accessToken =>
      (widget.accessTokenProvider ?? () => AuthSession.instance.accessToken)();

  DateTime get _today {
    final value = (widget.nowProvider ?? DateTime.now)();
    return DateTime(value.year, value.month, value.day);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _defaultApiClient = PolicyApiClient();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant HomePolicyBriefing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshVersion != oldWidget.refreshVersion ||
        widget.apiClient != oldWidget.apiClient) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final generation = ++_requestGeneration;
    final accessToken = _accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _setupRequired = true;
        _policies = const [];
        _error = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final preference = await _apiClient.getPolicyPreference(
        accessToken: accessToken,
      );
      if (!preference.saved ||
          preference.age == null ||
          preference.regionCode == null) {
        if (!mounted || generation != _requestGeneration) {
          return;
        }
        setState(() {
          _loading = false;
          _setupRequired = true;
          _policies = const [];
        });
        return;
      }

      final result = await _apiClient.recommendPolicies(
        accessToken: accessToken,
        size: 20,
      );
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _loading = false;
        _setupRequired = false;
        _policies = _selectPreviewPolicies(result.items);
      });
    } catch (error) {
      if (!mounted || generation != _requestGeneration) {
        return;
      }
      setState(() {
        _loading = false;
        _error = error;
      });
    }
  }

  List<PolicySummary> _selectPreviewPolicies(List<PolicySummary> items) {
    final selected = <PolicySummary>[];
    final selectedIds = <String>{};

    void add(PolicySummary policy) {
      if (selected.length < 3 && selectedIds.add(policy.policyId)) {
        selected.add(policy);
      }
    }

    final recommended = items
        .where(
          (policy) =>
              policy.recommendationStatus ==
              PolicyRecommendationStatus.recommended,
        )
        .toList();
    if (recommended.isNotEmpty) {
      add(recommended.first);
    }

    final urgent = items.where((policy) {
      final endDate = policy.applicationEndDate;
      if (endDate == null) {
        return false;
      }
      final days = DateUtils.dateOnly(endDate).difference(_today).inDays;
      return days >= 0 && days <= 30;
    }).toList()
      ..sort(
        (a, b) => a.applicationEndDate!.compareTo(b.applicationEndDate!),
      );
    urgent.forEach(add);
    recommended.forEach(add);
    items.forEach(add);
    return selected;
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

    final index = _policies.indexWhere(
      (item) => item.policyId == policy.policyId,
    );
    if (index < 0) {
      return;
    }
    setState(() => _policies.removeAt(index));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${policy.title} 정책을 홈에서 숨겼어요.'),
          action: SnackBarAction(
            label: '실행취소',
            onPressed: () {
              if (!mounted ||
                  _policies.any((item) => item.policyId == policy.policyId)) {
                return;
              }
              setState(() => _policies.insert(index, policy));
            },
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: '놓치면 아쉬운 정책',
          subtitle: '저장한 조건과 신청 마감일을 함께 살폈어요.',
          actionLabel: '전체 보기',
          onAction: widget.onOpenPolicies,
        ),
        const SizedBox(height: 10),
        if (_loading)
          const _PolicyLoadingCard()
        else if (_setupRequired)
          _PolicySetupCard(onTap: widget.onOpenPolicies)
        else if (_error != null)
          _PolicyErrorCard(error: _error!, onRetry: _load)
        else if (_policies.isEmpty)
          _PolicyEmptyCard(onTap: widget.onOpenPolicies)
        else
          for (var index = 0; index < _policies.length; index++) ...[
            _HomePolicyCard(
              policy: _policies[index],
              emphasized: index == 0,
              today: _today,
              onTap: () => _openPolicy(_policies[index]),
            ),
            if (index != _policies.length - 1) const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _HomePolicyCard extends StatelessWidget {
  const _HomePolicyCard({
    required this.policy,
    required this.emphasized,
    required this.today,
    required this.onTap,
  });

  final PolicySummary policy;
  final bool emphasized;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final deadline = _deadlineLabel(policy.applicationEndDate, today);
    final reason =
        (policy.recommendationReasons.firstOrNull ?? policy.summary).trim();
    return Semantics(
      button: true,
      label: '${policy.title} 상세 보기',
      child: AppCard(
        key: ValueKey('home-policy-${policy.policyId}'),
        onTap: onTap,
        color: emphasized ? AppColors.primarySoft : AppColors.surface,
        borderColor: emphasized ? AppColors.primarySoft : AppColors.border,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (policy.recommendationStatus ==
                    PolicyRecommendationStatus.recommended)
                  const _PolicyTag(
                    label: '맞춤 추천',
                    foreground: AppColors.primaryDeep,
                    background: AppColors.surface,
                  ),
                if (deadline != null)
                  _PolicyTag(
                    label: deadline,
                    foreground: AppColors.warning,
                    background: AppColors.warningSoft,
                  ),
                _PolicyTag(
                  label: policy.category,
                  foreground: AppColors.textSecondary,
                  background: AppColors.surfaceAlt,
                ),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              policy.title,
              style: AppTextStyles.sectionTitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (reason.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text(
                reason,
                style: AppTextStyles.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.savings_outlined,
                  size: 17,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _supportLabel(policy),
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primaryDeep,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Row(
              children: [
                const Icon(
                  Icons.account_balance_outlined,
                  size: 15,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    policy.agency,
                    style: AppTextStyles.captionTiny,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '자세히',
                  style: AppTextStyles.captionTiny.copyWith(
                    color: AppColors.primaryDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 19,
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

class _PolicyTag extends StatelessWidget {
  const _PolicyTag({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 170),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionTiny.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _PolicySetupCard extends StatelessWidget {
  const _PolicySetupCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('home-policy-setup'),
      onTap: onTap,
      color: AppColors.primarySoft,
      borderColor: AppColors.primarySoft,
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '한 번만 조건을 알려주세요',
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  '다음부터 홈에서 내게 맞는 정책을 바로 보여드릴게요.',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _PolicyErrorCard extends StatelessWidget {
  const _PolicyErrorCard({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = error is PolicyApiException
        ? (error as PolicyApiException).message
        : '맞춤 정책을 불러오지 못했어요.';
    return AppCard(
      key: const ValueKey('home-policy-error'),
      color: AppColors.dangerSoft,
      borderColor: AppColors.dangerSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.danger),
              const SizedBox(width: 10),
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

class _PolicyEmptyCard extends StatelessWidget {
  const _PolicyEmptyCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('home-policy-empty'),
      onTap: onTap,
      child: const Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.textTertiary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '지금은 맞춤 결과가 없어요. 전체 정책을 둘러보세요.',
              style: AppTextStyles.caption,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ],
      ),
    );
  }
}

class _PolicyLoadingCard extends StatelessWidget {
  const _PolicyLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      key: ValueKey('home-policy-loading'),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '내게 맞는 정책을 살펴보고 있어요.',
              style: AppTextStyles.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
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

String? _deadlineLabel(DateTime? endDate, DateTime today) {
  if (endDate == null) {
    return null;
  }
  final days = DateUtils.dateOnly(endDate).difference(today).inDays;
  if (days < 0 || days > 30) {
    return null;
  }
  if (days == 0) {
    return '오늘 마감';
  }
  return 'D-$days';
}
