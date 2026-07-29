import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/formatters.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';

class PolicyDetailPage extends StatelessWidget {
  const PolicyDetailPage({super.key, required this.policy});

  final Policy policy;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('정책 상세')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
        children: [
          AppCard(
            color: AppColors.primarySoft,
            borderColor: AppColors.primarySoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(policy.icon, color: AppColors.primary, size: 30),
                    const SizedBox(width: 10),
                    Text(
                      policy.category,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(policy.title, style: AppTextStyles.title),
                const SizedBox(height: 8),
                Text(policy.summary, style: AppTextStyles.bodyMuted),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryValue(
                        label: '예상 지원액',
                        value: Formatters.compactAmount(policy.supportAmount),
                      ),
                    ),
                    Expanded(
                      child: _SummaryValue(
                        label: '신청 기한',
                        value: policy.deadline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
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
            icon: Icons.how_to_reg_outlined,
            title: '신청 방법',
            content: policy.applyMethod,
          ),
          const SizedBox(height: 10),
          AppCard(
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
                for (final document in policy.documents)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(document, style: AppTextStyles.body),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
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
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('신청 안내는 목업 화면이에요.')),
                  ),
                  child: const Text('신청 안내 보기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
