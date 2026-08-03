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

  bool get _isApplication =>
      widget.arguments.type == PolicyExternalLinkType.application;

  String get _appBarTitle => _isApplication ? '신청 사이트 이동' : '참고 링크 이동';

  String get _headline =>
      _isApplication ? '신청 사이트로 이동할까요?' : '정책 안내 페이지로 이동할까요?';

  String get _description => _isApplication
      ? '${widget.arguments.title} 신청 조건과 최신 공고를 제공기관 사이트에서 '
          '최종 확인해 주세요.'
      : '${widget.arguments.title} 관련 참고 정보가 등록된 외부 페이지예요. '
          '실제 신청 사이트와 다를 수 있어요.';

  String get _addressLabel => _isApplication ? '신청 사이트 주소' : '참고 링크 주소';

  String get _notice => _isApplication
      ? '제공기관이 등록한 주소로 이동합니다. 기관 홈페이지나 로그인 화면이 '
          '열리면 정책명을 다시 검색해야 할 수 있어요.'
      : '정책 안내나 관련 기관 정보를 확인하는 참고 링크예요. 이 링크가 실제 '
          '신청 경로임을 보장하지 않아요.';

  String get _openButtonLabel => _isApplication ? '신청 사이트 열기' : '참고 링크 열기';

  Future<void> _openLink() async {
    if (_isOpening) {
      return;
    }
    setState(() => _isOpening = true);

    try {
      await widget.launcher.open(widget.arguments.url);
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
      appBar: _ExternalLinkAppBar(title: _appBarTitle),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(
            Icons.open_in_new_rounded,
            size: 54,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          Text(
            _headline,
            style: AppTextStyles.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _description,
            style: AppTextStyles.bodyMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_addressLabel, style: AppTextStyles.caption),
                const SizedBox(height: 6),
                Text(
                  widget.arguments.url,
                  style: AppTextStyles.body,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            color: AppColors.warningSoft,
            borderColor: AppColors.warningSoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '버튼을 누르면 생존일기를 벗어나 휴대폰의 기본 브라우저로 '
                    '이동합니다. $_notice',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const ValueKey('policy-open-external-button'),
            onPressed: _isOpening ? null : _openLink,
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
            label: Text(_isOpening ? '브라우저 여는 중' : _openButtonLabel),
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
  const _ExternalLinkAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}
