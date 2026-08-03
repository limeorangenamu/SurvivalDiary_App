import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_card.dart';
import 'data/policy_models.dart';

class PolicyExternalLinkConfirmPage extends StatelessWidget {
  const PolicyExternalLinkConfirmPage({super.key, required this.arguments});

  final PolicyExternalLinkArguments arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _ExternalLinkAppBar(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(
            Icons.open_in_new_rounded,
            size: 54,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            '외부 공식 사이트로 이동할까요?',
            style: AppTextStyles.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${arguments.title} 신청 조건과 최신 공고는 주관 기관의 '
            '공식 사이트에서 최종 확인해 주세요.',
            style: AppTextStyles.bodyMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('이동할 주소', style: AppTextStyles.caption),
                const SizedBox(height: 6),
                Text(arguments.officialUrl, style: AppTextStyles.body),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const AppCard(
            color: AppColors.warningSoft,
            borderColor: AppColors.warningSoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.warning),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '현재는 화면 흐름을 확인하는 목업 단계로, '
                    '버튼을 눌러도 실제 브라우저는 열리지 않습니다.',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const ValueKey('policy-open-external-button'),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('외부 브라우저 연결은 다음 단계에서 제공해요.')),
            ),
            icon: const Icon(Icons.open_in_new_rounded),
            label: const Text('공식 사이트 열기'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('정책 상세로 돌아가기'),
          ),
        ],
      ),
    );
  }
}

class _ExternalLinkAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ExternalLinkAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('공식 페이지 이동'));
  }
}
