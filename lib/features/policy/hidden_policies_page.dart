import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../auth/auth_session.dart';
import 'data/policy_api_client.dart';
import 'data/policy_models.dart';

typedef HiddenPolicyAccessTokenProvider = String? Function();

class HiddenPoliciesArguments {
  const HiddenPoliciesArguments({
    required this.apiClient,
    required this.accessTokenProvider,
  });

  final PolicyApiClient apiClient;
  final HiddenPolicyAccessTokenProvider accessTokenProvider;
}

class HiddenPoliciesPage extends StatefulWidget {
  HiddenPoliciesPage({
    super.key,
    HiddenPoliciesArguments? arguments,
    PolicyApiClient? apiClient,
    HiddenPolicyAccessTokenProvider? accessTokenProvider,
  })  : apiClient = arguments?.apiClient ?? apiClient ?? PolicyApiClient(),
        accessTokenProvider = arguments?.accessTokenProvider ??
            accessTokenProvider ??
            (() => AuthSession.instance.accessToken);

  final PolicyApiClient apiClient;
  final HiddenPolicyAccessTokenProvider accessTokenProvider;

  @override
  State<HiddenPoliciesPage> createState() => _HiddenPoliciesPageState();
}

class _HiddenPoliciesPageState extends State<HiddenPoliciesPage> {
  final Set<String> _restoringPolicyIds = {};

  List<HiddenPolicySummary> _policies = [];
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  String _requireAccessToken() {
    final accessToken = widget.accessTokenProvider();
    if (accessToken == null || accessToken.isEmpty) {
      throw const PolicyApiException(
        '관심 없음 정책을 보려면 먼저 로그인해 주세요.',
        type: PolicyApiErrorType.unauthorized,
      );
    }
    return accessToken;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.apiClient.getHiddenPolicies(
        accessToken: _requireAccessToken(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _policies = result.items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _restore(HiddenPolicySummary policy) async {
    if (_restoringPolicyIds.contains(policy.policyId)) {
      return;
    }
    setState(() => _restoringPolicyIds.add(policy.policyId));
    try {
      await widget.apiClient.restoreHiddenPolicy(
        accessToken: _requireAccessToken(),
        policyId: policy.policyId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _restoringPolicyIds.remove(policy.policyId);
        _policies.removeWhere((item) => item.policyId == policy.policyId);
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('추천 목록에 다시 표시할게요.')),
        );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _restoringPolicyIds.remove(policy.policyId));
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(_errorMessage(error))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관심 없음 정책')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          key: const ValueKey('hidden-policy-list'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 72),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              EmptyStateView(
                icon: Icons.error_outline_rounded,
                title: '목록을 불러오지 못했어요',
                description: _errorMessage(_error!),
                actionLabel: '다시 시도',
                onAction: _load,
              )
            else if (_policies.isEmpty)
              const EmptyStateView(
                icon: Icons.visibility_outlined,
                title: '관심 없음 정책이 없어요',
                description: '관심 없음으로 설정한 정책을 이곳에서 다시 확인하고 복구할 수 있어요.',
              )
            else ...[
              Text(
                '${_policies.length}개의 정책을 숨겨두었어요.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 12),
              for (var index = 0; index < _policies.length; index++) ...[
                _HiddenPolicyCard(
                  policy: _policies[index],
                  restoring:
                      _restoringPolicyIds.contains(_policies[index].policyId),
                  onRestore: () => _restore(_policies[index]),
                ),
                if (index < _policies.length - 1) const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _HiddenPolicyCard extends StatelessWidget {
  const _HiddenPolicyCard({
    required this.policy,
    required this.restoring,
    required this.onRestore,
  });

  final HiddenPolicySummary policy;
  final bool restoring;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: ValueKey('hidden-policy-${policy.policyId}'),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            policy.title,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (policy.shortSummary case final summary?
              when summary.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              summary,
              style: AppTextStyles.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  [
                    if (policy.category case final category?
                        when category.trim().isNotEmpty)
                      category,
                    '${Formatters.date(policy.hiddenAt)} 설정',
                  ].join(' · '),
                  style: AppTextStyles.captionTiny,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: ValueKey('restore-hidden-policy-${policy.policyId}'),
                onPressed: restoring ? null : onRestore,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: restoring
                    ? const SizedBox.square(
                        dimension: 15,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        '다시 보기',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primaryDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _errorMessage(Object error) {
  if (error is PolicyApiException) {
    return error.message;
  }
  return '잠시 후 다시 시도해 주세요.';
}
