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

typedef PolicyDetailAccessTokenProvider = String? Function();
typedef PolicyDetailNowProvider = DateTime Function();

class PolicyDetailPage extends StatefulWidget {
  PolicyDetailPage({
    super.key,
    required this.arguments,
    PolicyApiClient? apiClient,
    PolicyDetailAccessTokenProvider? accessTokenProvider,
    this.nowProvider,
  })  : apiClient = apiClient ?? PolicyApiClient(),
        accessTokenProvider =
            accessTokenProvider ?? (() => AuthSession.instance.accessToken);

  final PolicyDetailArguments arguments;
  final PolicyApiClient apiClient;
  final PolicyDetailAccessTokenProvider accessTokenProvider;
  final PolicyDetailNowProvider? nowProvider;

  @override
  State<PolicyDetailPage> createState() => _PolicyDetailPageState();
}

class _PolicyDetailPageState extends State<PolicyDetailPage> {
  late Future<PolicyDetail> _detailFuture;

  PolicyDetail? get _fallbackDetail {
    final summary = widget.arguments.summary;
    if (summary == null) {
      return null;
    }
    return PolicyDetail(
      policyId: summary.policyId,
      category: summary.category,
      categoryType: summary.categoryType,
      title: summary.title,
      description: summary.summary,
      supportAmount: summary.supportAmount,
      supportAmountType: summary.supportAmountType,
      supportText: summary.supportText,
      applicationPeriodText: summary.applicationPeriodText,
      applicationPeriodType: summary.applicationPeriodType,
      applicationStartDate: summary.applicationStartDate,
      applicationEndDate: summary.applicationEndDate,
      target: summary.target,
      agency: summary.agency,
      operatingAgency: summary.agency,
      applicationMethod: '상세 조회 후 확인할 수 있어요.',
      documents: const [],
      officialUrl: null,
      officialLinkType: PolicyOfficialLinkType.unavailable,
      referenceUrls: const [],
    );
  }

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDetail();
  }

  Future<PolicyDetail> _loadDetail() {
    final accessToken = widget.accessTokenProvider();
    if (accessToken == null || accessToken.isEmpty) {
      return Future.error(
        const PolicyApiException(
          '정책을 조회하려면 먼저 로그인해 주세요.',
          type: PolicyApiErrorType.unauthorized,
        ),
      );
    }
    return widget.apiClient.getPolicyDetail(
      accessToken: accessToken,
      policyId: widget.arguments.policyId,
    );
  }

  void _retry() {
    final detailFuture = _loadDetail();
    setState(() {
      _detailFuture = detailFuture;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PolicyDetail>(
      future: _detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          final fallbackDetail = _fallbackDetail;
          if (fallbackDetail != null) {
            return _PolicyDetailContent(
              policy: fallbackDetail,
              arguments: widget.arguments,
              now: (widget.nowProvider ?? DateTime.now)(),
              notice: '목록에서 받은 기본 정보를 먼저 보여드리고 있어요. 상세 정보는 불러오는 대로 갱신됩니다.',
            );
          }
          return const Scaffold(
            appBar: _PolicyDetailAppBar(),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          final fallbackDetail = _fallbackDetail;
          if (fallbackDetail != null) {
            final error = snapshot.error;
            final message = error is PolicyApiException
                ? error.message
                : '정책 상세를 불러오지 못했어요.';
            return _PolicyDetailContent(
              policy: fallbackDetail,
              arguments: widget.arguments,
              now: (widget.nowProvider ?? DateTime.now)(),
              notice: '$message 목록에서 받은 기본 정보를 대신 보여드리고 있어요.',
              onRetry: _retry,
            );
          }
          return _PolicyDetailErrorPage(
            error: snapshot.error,
            onRetry: _retry,
          );
        }
        return _PolicyDetailContent(
          policy: snapshot.requireData,
          arguments: widget.arguments,
          now: (widget.nowProvider ?? DateTime.now)(),
        );
      },
    );
  }
}

class _PolicyDetailContent extends StatelessWidget {
  const _PolicyDetailContent({
    required this.policy,
    required this.arguments,
    required this.now,
    this.notice,
    this.onRetry,
  });

  final PolicyDetail policy;
  final PolicyDetailArguments arguments;
  final DateTime now;
  final String? notice;
  final VoidCallback? onRetry;

  IconData get _categoryIcon => switch (policy.categoryType) {
        PolicyCategory.employment => Icons.work_outline_rounded,
        PolicyCategory.housing => Icons.home_work_outlined,
        PolicyCategory.education => Icons.school_outlined,
        PolicyCategory.welfareCulture => Icons.volunteer_activism_outlined,
        PolicyCategory.participationRights => Icons.campaign_outlined,
        null => Icons.policy_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final referenceUrls = policy.referenceUrls
        .where((url) => url != policy.officialUrl)
        .toList(growable: false);
    final reasons = arguments.recommendationReasons.isEmpty
        ? arguments.eligibilityReasons
        : arguments.recommendationReasons;
    final showRecommendation =
        arguments.recommendationStatus != PolicyRecommendationStatus.discover &&
            (reasons.isNotEmpty ||
                arguments.eligibilityStatus ==
                    PolicyEligibilityStatus.checkRequired);

    return Scaffold(
      appBar: const _PolicyDetailAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          if (notice != null) ...[
            _PolicyDetailNotice(message: notice!, onRetry: onRetry),
            const SizedBox(height: 10),
          ],
          AppCard(
            color: AppColors.primarySoft,
            borderColor: AppColors.primarySoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_categoryIcon, color: AppColors.primary, size: 18),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          policy.category,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryDeep,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(policy.title, style: AppTextStyles.title),
                const SizedBox(height: 8),
                Text(policy.description, style: AppTextStyles.bodyMuted),
              ],
            ),
          ),
          if (showRecommendation) ...[
            const SizedBox(height: 10),
            _RecommendationNotice(
              status: arguments.recommendationStatus,
              reasons: reasons,
            ),
          ],
          const SizedBox(height: 18),
          _PolicyOverviewCard(policy: policy, now: now),
          const SizedBox(height: 10),
          _ApplicationPreparationSection(
            applicationMethod: policy.applicationMethod,
            documents: policy.documents,
          ),
          const SizedBox(height: 10),
          _AgencySection(
            agency: policy.agency,
            operatingAgency: policy.operatingAgency,
          ),
          if (referenceUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            _ReferenceLinksSection(
              policyTitle: policy.title,
              referenceUrls: referenceUrls,
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('policy-hide-from-detail-button'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => Navigator.pop(
                    context,
                    PolicyDetailAction.hide,
                  ),
                  child: const Text('목록 숨기기'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  key: const ValueKey('policy-application-guide-button'),
                  onPressed: policy.officialUrl == null
                      ? null
                      : () => Navigator.pushNamed(
                            context,
                            AppRoutes.policyExternalLinkConfirm,
                            arguments: PolicyExternalLinkArguments(
                              title: policy.title,
                              url: policy.officialUrl!,
                              type: PolicyExternalLinkType.application,
                              officialLinkType: policy.officialLinkType,
                            ),
                          ),
                  child: Text(
                    policy.officialUrl == null
                        ? '온라인 신청 경로 없음'
                        : _applicationButtonLabel(policy.officialLinkType),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PolicyDetailNotice extends StatelessWidget {
  const _PolicyDetailNotice({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('policy-detail-fallback-notice'),
      color: AppColors.primarySoft,
      borderColor: AppColors.primarySoft,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primaryDeep),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppTextStyles.caption)),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ],
      ),
    );
  }
}

class _PolicyOverviewCard extends StatelessWidget {
  const _PolicyOverviewCard({required this.policy, required this.now});

  final PolicyDetail policy;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final supportAmount = policy.supportAmount;
    final deadline = _deadlinePresentation(policy.applicationEndDate, now);
    final periodLabel = _applicationPeriodLabel(policy);
    return AppCard(
      key: const ValueKey('policy-overview-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('한눈에 보기', style: AppTextStyles.sectionTitle),
          const SizedBox(height: 14),
          _OverviewRow(
            icon: Icons.payments_outlined,
            label: supportAmount == null
                ? '지원 혜택'
                : _supportAmountTitle(policy.supportAmountType),
            value: supportAmount == null
                ? policy.supportText
                : Formatters.compactAmount(supportAmount),
            description: supportAmount == null ? null : policy.supportText,
          ),
          const Divider(height: 24),
          _OverviewRow(
            icon: Icons.event_available_outlined,
            label: '신청 기간',
            value: periodLabel,
            description: periodLabel == policy.applicationPeriodText
                ? null
                : policy.applicationPeriodText,
            badge: deadline,
          ),
          const Divider(height: 24),
          _OverviewRow(
            icon: Icons.person_outline_rounded,
            label: '지원 대상',
            value: policy.target,
          ),
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.description,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? description;
  final _DeadlinePresentation? badge;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.primary, size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label, style: AppTextStyles.caption)),
                  if (badge != null) _DeadlineBadge(presentation: badge!),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
              if (description != null && description!.trim() != value) ...[
                const SizedBox(height: 4),
                Text(description!, style: AppTextStyles.caption),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DeadlineBadge extends StatelessWidget {
  const _DeadlineBadge({required this.presentation});

  final _DeadlinePresentation presentation;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('policy-deadline-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: presentation.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        presentation.label,
        style: AppTextStyles.captionTiny.copyWith(
          color: presentation.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RecommendationNotice extends StatelessWidget {
  const _RecommendationNotice({required this.status, required this.reasons});

  final PolicyRecommendationStatus status;
  final List<String> reasons;

  String get _title => switch (status) {
        PolicyRecommendationStatus.recommended => '나에게 맞는 이유',
        PolicyRecommendationStatus.checkRequired => '신청 전에 확인할 조건',
        PolicyRecommendationStatus.discover => '함께 살펴볼 정책',
      };

  Color get _color => switch (status) {
        PolicyRecommendationStatus.recommended => AppColors.primaryDeep,
        PolicyRecommendationStatus.checkRequired => AppColors.warning,
        PolicyRecommendationStatus.discover => AppColors.textSecondary,
      };

  Color get _background => switch (status) {
        PolicyRecommendationStatus.recommended => AppColors.primarySoft,
        PolicyRecommendationStatus.checkRequired => AppColors.warningSoft,
        PolicyRecommendationStatus.discover => AppColors.surfaceAlt,
      };

  IconData get _icon => switch (status) {
        PolicyRecommendationStatus.recommended => Icons.auto_awesome_rounded,
        PolicyRecommendationStatus.checkRequired => Icons.fact_check_outlined,
        PolicyRecommendationStatus.discover => Icons.explore_outlined,
      };

  Key get _key => switch (status) {
        PolicyRecommendationStatus.recommended =>
          const ValueKey('policy-recommendation-notice'),
        PolicyRecommendationStatus.checkRequired =>
          const ValueKey('policy-eligibility-notice'),
        PolicyRecommendationStatus.discover =>
          const ValueKey('policy-discover-notice'),
      };

  @override
  Widget build(BuildContext context) {
    final displayReasons =
        reasons.isEmpty ? const ['입력한 조건과 관련된 정책으로 함께 살펴볼 수 있어요.'] : reasons;
    return AppCard(
      key: _key,
      color: _background,
      borderColor: _background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, color: _color),
              const SizedBox(width: 8),
              Text(
                _title,
                style: AppTextStyles.sectionTitle.copyWith(color: _color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final (index, reason) in displayReasons.indexed) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    status == PolicyRecommendationStatus.checkRequired
                        ? Icons.info_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    color: _color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(child: Text(reason, style: AppTextStyles.caption)),
              ],
            ),
            if (index != displayReasons.length - 1) const SizedBox(height: 7),
          ],
        ],
      ),
    );
  }
}

class _ApplicationPreparationSection extends StatelessWidget {
  const _ApplicationPreparationSection({
    required this.applicationMethod,
    required this.documents,
  });

  final String applicationMethod;
  final List<String> documents;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      key: const ValueKey('policy-application-preparation'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.how_to_reg_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('신청 준비', style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 14),
          const Text('신청 방법', style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(applicationMethod, style: AppTextStyles.bodyMuted),
          const Divider(height: 24),
          const Text('제출 서류', style: AppTextStyles.caption),
          const SizedBox(height: 7),
          if (documents.isEmpty)
            const Text(
              '필요한 서류는 공식 공고에서 확인해 주세요.',
              style: AppTextStyles.bodyMuted,
            )
          else
            for (final document in documents) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(document, style: AppTextStyles.body)),
                ],
              ),
              if (document != documents.last) const SizedBox(height: 7),
            ],
        ],
      ),
    );
  }
}

class _AgencySection extends StatelessWidget {
  const _AgencySection({required this.agency, required this.operatingAgency});

  final String agency;
  final String operatingAgency;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('담당 기관', style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 12),
          _AgencyRow(label: '주관', value: agency),
          const SizedBox(height: 8),
          _AgencyRow(label: '운영', value: operatingAgency),
        ],
      ),
    );
  }
}

class _AgencyRow extends StatelessWidget {
  const _AgencyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          padding: const EdgeInsets.symmetric(vertical: 3),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(label, style: AppTextStyles.captionTiny),
        ),
        const SizedBox(width: 9),
        Expanded(child: Text(value, style: AppTextStyles.bodyMuted)),
      ],
    );
  }
}

class _ReferenceLinksSection extends StatelessWidget {
  const _ReferenceLinksSection({
    required this.policyTitle,
    required this.referenceUrls,
  });

  final String policyTitle;
  final List<String> referenceUrls;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.link_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('참고 링크', style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '정책 안내나 관련 기관 정보를 확인하는 링크예요. 실제 신청 경로와 '
            '다를 수 있어요.',
            style: AppTextStyles.caption,
          ),
          const SizedBox(height: 12),
          for (final (index, url) in referenceUrls.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: ValueKey('policy-reference-link-$index'),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.policyExternalLinkConfirm,
                    arguments: PolicyExternalLinkArguments(
                      title: policyTitle,
                      url: url,
                      type: PolicyExternalLinkType.reference,
                      officialLinkType: PolicyOfficialLinkType.unknown,
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(_linkLabel(url)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _linkLabel(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.host.isNotEmpty) {
      return '${uri.host} 참고 링크';
    }
    return '참고 링크 열기';
  }
}

class _PolicyDetailErrorPage extends StatelessWidget {
  const _PolicyDetailErrorPage({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final apiError = error is PolicyApiException
        ? error! as PolicyApiException
        : const PolicyApiException(
            '정책 상세를 불러오지 못했어요.',
            type: PolicyApiErrorType.server,
          );
    final isNotFound = apiError.type == PolicyApiErrorType.notFound;
    return Scaffold(
      appBar: const _PolicyDetailAppBar(),
      body: EmptyStateView(
        icon:
            isNotFound ? Icons.find_in_page_outlined : Icons.cloud_off_rounded,
        title: isNotFound ? '정책 정보를 찾을 수 없어요' : '정책 상세를 불러오지 못했어요',
        description: isNotFound ? '목록으로 돌아가 다른 정책을 선택해 주세요.' : apiError.message,
        actionLabel: isNotFound ? '목록으로 돌아가기' : '다시 시도',
        onAction: isNotFound ? () => Navigator.pop(context) : onRetry,
      ),
    );
  }
}

class _PolicyDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _PolicyDetailAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('정책 상세'));
  }
}

String _supportAmountTitle(PolicySupportAmountType? type) => switch (type) {
      PolicySupportAmountType.maximum => '최대 지원액',
      PolicySupportAmountType.monthly => '월 지원액',
      PolicySupportAmountType.monthlyMaximum => '월 최대 지원액',
      PolicySupportAmountType.fixed || null => '지원 금액',
    };

String _applicationPeriodLabel(PolicyDetail policy) =>
    switch (policy.applicationPeriodType) {
      PolicyApplicationPeriodType.always => '상시 신청',
      PolicyApplicationPeriodType.closed => '접수 마감',
      PolicyApplicationPeriodType.untilBudget => '예산 소진 시까지',
      PolicyApplicationPeriodType.fixed ||
      PolicyApplicationPeriodType.unknown ||
      null =>
        policy.applicationPeriodText ?? '신청 기간 확인 필요',
    };

String _applicationButtonLabel(PolicyOfficialLinkType type) => switch (type) {
      PolicyOfficialLinkType.applicationCandidate => '신청 페이지 확인',
      PolicyOfficialLinkType.loginRequired => '로그인 후 신청 확인',
      PolicyOfficialLinkType.institutionHome => '기관 홈페이지 확인',
      PolicyOfficialLinkType.unknown => '신청 사이트 확인',
      PolicyOfficialLinkType.unavailable => '온라인 신청 경로 없음',
    };

_DeadlinePresentation? _deadlinePresentation(
  DateTime? endDate,
  DateTime now,
) {
  if (endDate == null) {
    return null;
  }
  final today = DateUtils.dateOnly(now);
  final deadline = DateUtils.dateOnly(endDate);
  final days = deadline.difference(today).inDays;
  if (days < 0) {
    return const _DeadlinePresentation(
      label: '접수 마감',
      foreground: AppColors.danger,
      background: AppColors.dangerSoft,
    );
  }
  if (days == 0) {
    return const _DeadlinePresentation(
      label: '오늘 마감',
      foreground: AppColors.warning,
      background: AppColors.warningSoft,
    );
  }
  if (days <= 30) {
    return _DeadlinePresentation(
      label: 'D-$days',
      foreground: AppColors.warning,
      background: AppColors.warningSoft,
    );
  }
  return _DeadlinePresentation(
    label: '${endDate.month}/${endDate.day} 마감',
    foreground: AppColors.primaryDeep,
    background: AppColors.primarySoft,
  );
}

class _DeadlinePresentation {
  const _DeadlinePresentation({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
}
