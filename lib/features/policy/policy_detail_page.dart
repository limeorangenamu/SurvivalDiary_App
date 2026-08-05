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

class PolicyDetailPage extends StatefulWidget {
  PolicyDetailPage({
    super.key,
    required this.arguments,
    PolicyApiClient? apiClient,
    PolicyDetailAccessTokenProvider? accessTokenProvider,
  })  : apiClient = apiClient ?? PolicyApiClient(),
        accessTokenProvider =
            accessTokenProvider ?? (() => AuthSession.instance.accessToken);

  final PolicyDetailArguments arguments;
  final PolicyApiClient apiClient;
  final PolicyDetailAccessTokenProvider accessTokenProvider;

  @override
  State<PolicyDetailPage> createState() => _PolicyDetailPageState();
}

class _PolicyDetailPageState extends State<PolicyDetailPage> {
  late Future<PolicyDetail> _detailFuture;

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
          return const Scaffold(
            appBar: _PolicyDetailAppBar(),
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _PolicyDetailErrorPage(
            error: snapshot.error,
            onRetry: _retry,
          );
        }
        return _PolicyDetailContent(
          policy: snapshot.requireData,
          arguments: widget.arguments,
        );
      },
    );
  }
}

class _PolicyDetailContent extends StatelessWidget {
  const _PolicyDetailContent({required this.policy, required this.arguments});

  final PolicyDetail policy;
  final PolicyDetailArguments arguments;

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
    final supportAmount = policy.supportAmount;
    final supportAmountLabel = supportAmount == null
        ? policy.supportText
        : Formatters.compactAmount(supportAmount);
    final periodLabel = policy.applicationPeriodText ?? '신청 기간 확인 필요';
    final referenceUrls = policy.referenceUrls
        .where((url) => url != policy.officialUrl)
        .toList(growable: false);

    return Scaffold(
      appBar: const _PolicyDetailAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          if (arguments.recommendationStatus !=
                  PolicyRecommendationStatus.discover &&
              (arguments.recommendationReasons.isNotEmpty ||
                  arguments.eligibilityStatus ==
                      PolicyEligibilityStatus.checkRequired)) ...[
            _RecommendationNotice(
              status: arguments.recommendationStatus,
              reasons: arguments.recommendationReasons.isEmpty
                  ? arguments.eligibilityReasons
                  : arguments.recommendationReasons,
            ),
            const SizedBox(height: 10),
          ],
          AppCard(
            color: AppColors.primarySoft,
            borderColor: AppColors.primarySoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_categoryIcon, color: AppColors.primary, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        policy.category,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primaryDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(policy.title, style: AppTextStyles.title),
                const SizedBox(height: 8),
                Text(policy.description, style: AppTextStyles.bodyMuted),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _SummaryValue(
                        label: '예상 지원액',
                        value: supportAmountLabel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryValue(
                        label: '신청 기간',
                        value: periodLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _InfoSection(
            icon: Icons.payments_outlined,
            title: '지원 내용',
            content: policy.supportText,
          ),
          const SizedBox(height: 10),
          _InfoSection(
            icon: Icons.person_outline_rounded,
            title: '지원 대상',
            content: policy.target,
          ),
          const SizedBox(height: 10),
          _InfoSection(
            icon: Icons.account_balance_outlined,
            title: '주관 기관',
            content: policy.agency,
          ),
          const SizedBox(height: 10),
          _InfoSection(
            icon: Icons.business_outlined,
            title: '운영 기관',
            content: policy.operatingAgency,
          ),
          const SizedBox(height: 10),
          _InfoSection(
            icon: Icons.how_to_reg_outlined,
            title: '신청 방법',
            content: policy.applicationMethod,
          ),
          const SizedBox(height: 10),
          _DocumentsSection(documents: policy.documents),
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
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('추천 목록에서 숨겼어요.')),
                  ),
                  child: const Text('관심 없음'),
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
                            ),
                          ),
                  child: Text(
                    policy.officialUrl == null
                        ? '온라인 신청 링크 없음'
                        : '공식 신청 페이지로 이동',
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

class _RecommendationNotice extends StatelessWidget {
  const _RecommendationNotice({required this.status, required this.reasons});

  final PolicyRecommendationStatus status;
  final List<String> reasons;

  String get _title => switch (status) {
        PolicyRecommendationStatus.recommended => '이 정책을 추천하는 이유',
        PolicyRecommendationStatus.checkRequired => '신청 조건을 확인해 주세요',
        PolicyRecommendationStatus.discover => '함께 살펴볼 정책이에요',
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
        PolicyRecommendationStatus.recommended => Icons.recommend_outlined,
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
          const SizedBox(height: 8),
          Text(
            reasons.isEmpty
                ? '입력한 조건과 관련된 정책으로 함께 살펴볼 수 있어요.'
                : reasons.join('\n'),
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _DocumentsSection extends StatelessWidget {
  const _DocumentsSection({required this.documents});

  final List<String> documents;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('제출 서류', style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 12),
          if (documents.isEmpty)
            const Text(
              '필요한 서류는 공식 공고에서 확인해 주세요.',
              style: AppTextStyles.bodyMuted,
            )
          else
            for (final document in documents)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(document, style: AppTextStyles.body)),
                  ],
                ),
              ),
        ],
      ),
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

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.captionTiny),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.icon,
    required this.title,
    required this.content,
  });

  final IconData icon;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: AppTextStyles.bodyMuted),
        ],
      ),
    );
  }
}
