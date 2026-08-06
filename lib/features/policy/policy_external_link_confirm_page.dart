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

  PolicyOfficialLinkType get _officialLinkType =>
      widget.arguments.officialLinkType;

  String get _appBarTitle => _isApplication ? '신청 사이트 이동' : '참고 링크 이동';

  String get _headline {
    if (!_isApplication) {
      return '정책 안내 페이지로 이동할까요?';
    }
    return switch (_officialLinkType) {
      PolicyOfficialLinkType.applicationCandidate => '신청 페이지 후보로 이동할까요?',
      PolicyOfficialLinkType.loginRequired => '로그인이 필요한 서비스입니다',
      PolicyOfficialLinkType.institutionHome => '기관 홈페이지로 이동할까요?',
      PolicyOfficialLinkType.unknown => '신청 사이트로 이동할까요?',
      PolicyOfficialLinkType.unavailable => '신청 경로를 확인할 수 없어요',
    };
  }

  String get _description {
    if (!_isApplication) {
      return '${widget.arguments.title} 관련 참고 정보가 등록된 외부 페이지예요. '
          '실제 신청 사이트와 다를 수 있어요.';
    }
    return switch (_officialLinkType) {
      PolicyOfficialLinkType.applicationCandidate =>
        '${widget.arguments.title} 신청 주소로 등록된 페이지예요. 최신 공고와 신청 조건을 최종 확인해 주세요.',
      PolicyOfficialLinkType.loginRequired =>
        '${widget.arguments.title} 신청 내용을 확인하려면 제공기관 계정 로그인이 필요할 수 있어요.',
      PolicyOfficialLinkType.institutionHome =>
        '${widget.arguments.title} 전용 신청 주소가 아닌 기관 홈페이지예요. 이동 후 정책명을 검색해 주세요.',
      PolicyOfficialLinkType.unknown =>
        '${widget.arguments.title} 신청 조건과 최신 공고를 제공기관 사이트에서 최종 확인해 주세요.',
      PolicyOfficialLinkType.unavailable =>
        '${widget.arguments.title} 온라인 신청 주소가 제공되지 않았어요.',
    };
  }

  String get _addressLabel {
    if (!_isApplication) {
      return '참고 링크 주소';
    }
    return switch (_officialLinkType) {
      PolicyOfficialLinkType.loginRequired => '로그인 사이트 주소',
      PolicyOfficialLinkType.institutionHome => '기관 홈페이지 주소',
      _ => '신청 사이트 주소',
    };
  }

  String get _notice {
    if (!_isApplication) {
      return '정책 안내나 관련 기관 정보를 확인하는 참고 링크예요. 이 링크가 실제 '
          '신청 경로임을 보장하지 않아요.';
    }
    return switch (_officialLinkType) {
      PolicyOfficialLinkType.applicationCandidate =>
        '제공기관이 신청 주소로 등록했지만 실제 접수 화면 또는 상세 안내 화면이 열릴 수 있어요.',
      PolicyOfficialLinkType.loginRequired =>
        '로그인 후 신청 메뉴가 바로 열리지 않으면 정책명을 다시 검색해 주세요.',
      PolicyOfficialLinkType.institutionHome =>
        '기관 홈페이지에서 정책명이나 담당 기관을 검색해 신청 경로를 찾아야 해요.',
      PolicyOfficialLinkType.unknown =>
        '제공기관이 등록한 주소이며 기관 홈페이지나 로그인 화면이 열릴 수 있어요.',
      PolicyOfficialLinkType.unavailable => '주소가 없어 외부 브라우저를 열 수 없어요.',
    };
  }

  String get _openButtonLabel {
    if (!_isApplication) {
      return '참고 링크 열기';
    }
    return switch (_officialLinkType) {
      PolicyOfficialLinkType.applicationCandidate => '신청 페이지 열기',
      PolicyOfficialLinkType.loginRequired => '로그인 페이지 열기',
      PolicyOfficialLinkType.institutionHome => '기관 홈페이지 열기',
      PolicyOfficialLinkType.unknown => '신청 사이트 열기',
      PolicyOfficialLinkType.unavailable => '신청 경로 없음',
    };
  }

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
            onPressed: _isOpening ||
                    _officialLinkType == PolicyOfficialLinkType.unavailable
                ? null
                : _openLink,
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
