import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/option_picker_sheet.dart';
import '../../shared/widgets/pill_chip.dart';

class PolicyListPage extends StatefulWidget {
  const PolicyListPage({super.key});

  @override
  State<PolicyListPage> createState() => _PolicyListPageState();
}

class _PolicyListPageState extends State<PolicyListPage> {
  final List<Policy> _policies = [...MockData.policies];
  String? _age;
  String? _region;
  String? _employment;
  int _sortIndex = 0;

  List<Policy> get _visiblePolicies {
    if (_age == '35세 이상' || _region == '부산') {
      return [];
    }
    var result = [..._policies];
    if (_employment == '재직 중') {
      result = result.where((item) => item.category != '취업').toList();
    } else if (_employment == '미취업') {
      result = result
          .where((item) => item.category == '취업' || item.category == '주거')
          .toList();
    }
    if (_sortIndex == 1) {
      result.sort((a, b) => a.deadline.compareTo(b.deadline));
    } else if (_sortIndex == 2) {
      result.sort((a, b) => b.supportAmount.compareTo(a.supportAmount));
    }
    return result;
  }

  Future<void> _pickFilter({
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) async {
    final result = await showOptionPickerSheet<String>(
      context: context,
      title: title,
      options: options,
      labelBuilder: (value) => value,
      selected: selected,
    );
    if (result != null && mounted) {
      setState(() => onSelected(result));
    }
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

  @override
  Widget build(BuildContext context) {
    final policies = _visiblePolicies;
    return Scaffold(
      appBar: AppBar(
        title: const Text('청년 맞춤 정책'),
        actions: [
          IconButton(
            tooltip: '필터 초기화',
            onPressed: () => setState(() {
              _age = null;
              _region = null;
              _employment = null;
              _sortIndex = 0;
            }),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      LabeledFilterChip(
                        label: '나이',
                        value: _age ?? '전체',
                        isActive: _age != null,
                        onTap: () => _pickFilter(
                          title: '나이를 선택해 주세요',
                          options: const [
                            '19~24세',
                            '25~29세',
                            '30~34세',
                            '35세 이상',
                          ],
                          selected: _age,
                          onSelected: (value) => _age = value,
                        ),
                      ),
                      const SizedBox(width: 8),
                      LabeledFilterChip(
                        label: '지역',
                        value: _region ?? '전체',
                        isActive: _region != null,
                        onTap: () => _pickFilter(
                          title: '지역을 선택해 주세요',
                          options: const ['서울', '경기', '부산'],
                          selected: _region,
                          onSelected: (value) => _region = value,
                        ),
                      ),
                      const SizedBox(width: 8),
                      LabeledFilterChip(
                        label: '취업',
                        value: _employment ?? '전체',
                        isActive: _employment != null,
                        onTap: () => _pickFilter(
                          title: '취업 상태를 선택해 주세요',
                          options: const ['재직 중', '미취업', '구직 중'],
                          selected: _employment,
                          onSelected: (value) => _employment = value,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SortToggle(
                  options: const ['최신순', '마감임박순', '지원금액순'],
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
                    description: '필터를 조금 넓히면 더 많은 지원 정책을 볼 수 있어요.',
                    actionLabel: '필터 초기화',
                    onAction: () => setState(() {
                      _age = null;
                      _region = null;
                      _employment = null;
                    }),
                  )
                : ListView.separated(
                    key: const PageStorageKey('policy-list-scroll'),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    itemCount: policies.length + 1,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == policies.length) {
                        return FilledButton(
                          key: const ValueKey('more-policies-button'),
                          onPressed: () {},
                          child: const Text('더 많은 정책 보기'),
                        );
                      }
                      final policy = policies[index];
                      return _PolicyCard(
                        policy: policy,
                        onHide: () => _hidePolicy(policy),
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.policyDetail,
                          arguments: policy,
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

  Color get _categoryColor => switch (policy.category) {
        '주거' => AppColors.categoryFood,
        '취업' => AppColors.info,
        '자산형성' => AppColors.warning,
        '문화' => AppColors.categoryCafe,
        _ => AppColors.primary,
      };

  String get _deadlineLabel {
    if (policy.deadline == '상시 접수' || policy.deadline == '예산 소진 시까지') {
      return policy.deadline;
    }
    return '신청 마감 ${policy.deadline.replaceAll(' 마감', '')}';
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
                    Text(
                      Formatters.compactAmount(policy.supportAmount),
                      style: AppTextStyles.amount.copyWith(
                        color: AppColors.primary,
                        fontSize: 17,
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
