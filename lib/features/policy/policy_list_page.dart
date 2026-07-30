import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/pill_chip.dart';

class PolicyListPage extends StatefulWidget {
  const PolicyListPage({super.key, required this.condition});

  final PolicyFilterCondition condition;

  @override
  State<PolicyListPage> createState() => _PolicyListPageState();
}

class _PolicyListPageState extends State<PolicyListPage> {
  final List<Policy> _policies = [...MockData.policies];
  int _sortIndex = 0;

  List<Policy> get _visiblePolicies {
    final condition = widget.condition;
    final result = _policies.where((policy) {
      final matchesAge =
          condition.age >= policy.minAge && condition.age <= policy.maxAge;
      final matchesRegion = policy.eligibleRegions.contains('전국') ||
          policy.eligibleRegions.contains(condition.region);
      final matchesEmployment =
          policy.employmentStatuses.contains(condition.employmentStatus);
      final matchesIncome = condition.incomeRange == null ||
          condition.incomeRange == PolicyIncomeRange.noLimit ||
          policy.incomeRanges.contains(condition.incomeRange);
      final matchesCategory = condition.category == null ||
          policy.categoryType == condition.category;
      return matchesAge &&
          matchesRegion &&
          matchesEmployment &&
          matchesIncome &&
          matchesCategory;
    }).toList();

    if (_sortIndex == 1) {
      result.sort(
        (a, b) => _deadlineSortValue(a.deadline)
            .compareTo(_deadlineSortValue(b.deadline)),
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

  DateTime _deadlineSortValue(String? deadline) {
    final match =
        RegExp(r'(\d{4})\.(\d{2})\.(\d{2})').firstMatch(deadline ?? '');
    if (match == null) {
      return DateTime(9999);
    }
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }

  void _hidePolicy(Policy policy) {
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
    final policies = _visiblePolicies;
    return Scaffold(
      appBar: AppBar(title: const Text('맞춤 정책 결과')),
      body: Column(
        children: [
          Padding(
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
                            child: Text(
                              '선택한 조건',
                              style: AppTextStyles.sectionTitle,
                            ),
                          ),
                          TextButton(
                            key: const ValueKey('policy-edit-condition-button'),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('조건 수정'),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final label in _conditionLabels)
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
                  selectedIndex: _sortIndex,
                  onChanged: (value) => setState(() => _sortIndex = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: policies.isEmpty
                ? EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: '조건에 맞는 정책이 없어요',
                    description: '조건을 조금 넓히면 더 많은 지원 정책을 볼 수 있어요.',
                    actionLabel: '조건 수정',
                    onAction: () => Navigator.pop(context),
                  )
                : ListView.separated(
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
                          arguments: policy.id,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard({
    required this.policy,
    required this.onHide,
    required this.onTap,
  });

  final Policy policy;
  final VoidCallback onHide;
  final VoidCallback onTap;

  Color get _categoryColor => switch (policy.categoryType) {
        PolicyCategory.housing => AppColors.categoryFood,
        PolicyCategory.employment => AppColors.info,
        PolicyCategory.asset => AppColors.warning,
        PolicyCategory.culture => AppColors.categoryCafe,
        PolicyCategory.transport => AppColors.categoryTransport,
      };

  String get _supportLabel {
    final amount = policy.supportAmount;
    return amount == null ? '지원 내용 확인' : Formatters.compactAmount(amount);
  }

  String get _deadlineLabel {
    final deadline = policy.deadline;
    if (deadline == null) {
      return '신청 기간 확인 필요';
    }
    if (deadline == '상시 접수' || deadline == '예산 소진 시까지') {
      return deadline;
    }
    return '신청 마감 ${deadline.replaceAll(' 마감', '')}';
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColor;
    return AppCard(
      key: ValueKey('policy-card-${policy.id}'),
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
                  child: Icon(policy.icon, color: categoryColor, size: 20),
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
                        key: ValueKey('policy-menu-${policy.id}'),
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
                        _deadlineLabel,
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
