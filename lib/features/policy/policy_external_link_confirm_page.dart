import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_card.dart';
import 'data/policy_external_link_launcher.dart';
import 'data/policy_models.dart';

class PolicyExternalLinkConfirmPage extends StatefulWidget {
  PolicyExternalLinkConfirmPage({
    super.key,
    required this.arguments,
    PolicyExternalLinkLauncher? launcher,
  }) : launcher = launcher ?? PolicyExternalLinkLauncher();

  final PolicyExternalLinkArguments arguments;
  final PolicyExternalLinkLauncher launcher;

  @override
  State<PolicyExternalLinkConfirmPage> createState() =>
      _PolicyExternalLinkConfirmPageState();
}

class _PolicyExternalLinkConfirmPageState
    extends State<PolicyExternalLinkConfirmPage> {
  bool _isOpening = false;

  Future<void> _openOfficialSite() async {
    if (_isOpening) {
      return;
    }
    setState(() => _isOpening = true);

    try {
      await widget.launcher.open(widget.arguments.officialUrl);
    } on PolicyExternalLinkException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isOpening = false);
      }
    }
  }

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
            '${widget.arguments.title} 신청 조건과 최신 공고는 주관 기관의 '
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
                Text(
                  widget.arguments.officialUrl,
                  style: AppTextStyles.body,
                ),
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
                    '버튼을 누르면 생존일기를 벗어나 휴대폰의 기본 브라우저로 이동합니다. '
                    '신청 조건과 최신 공고를 공식 사이트에서 다시 확인해 주세요.',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const ValueKey('policy-open-external-button'),
            onPressed: _isOpening ? null : _openOfficialSite,
            icon: _isOpening
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  )
                : const Icon(Icons.open_in_new_rounded),
            label: Text(_isOpening ? '브라우저 여는 중' : '공식 사이트 열기'),
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
