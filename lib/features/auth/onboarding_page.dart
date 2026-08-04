import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import 'data/auth_api_client.dart';
import 'data/social_auth_service.dart';
import 'widgets/email_login_form.dart';

/// 첫 진입(미로그인) 화면 — 서비스 소개 슬라이드 + SNS 로그인.
/// SNS 로그인·이메일 가입은 인증 연동 이슈(#33)에서 실제 동작을 붙인다.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  final _socialAuthService = SocialAuthService();
  int _currentIndex = 0;
  SocialAuthProvider? _submittingProvider;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skipToAuth() {
    _controller.animateToPage(
      MockData.onboardingSlides.length,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  Future<void> _socialLogin(SocialAuthProvider provider) async {
    if (_submittingProvider != null) return;
    setState(() => _submittingProvider = provider);
    try {
      await _socialAuthService.login(provider);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.root,
        (route) => false,
      );
    } on AuthApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _submittingProvider = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    const slides = MockData.onboardingSlides;
    final pageCount = slides.length + 1;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _DotsIndicator(
                      count: pageCount,
                      currentIndex: _currentIndex,
                    ),
                  ),
                  if (_currentIndex < slides.length)
                    TextButton(
                      key: const ValueKey('onboarding-skip-button'),
                      onPressed: _skipToAuth,
                      child: Text(
                        '건너뛰기',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 76),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pageCount,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) => index < slides.length
                    ? _SlideView(slide: slides[index])
                    : _OnboardingAuthPage(
                        submittingProvider: _submittingProvider,
                        onSocialLogin: _socialLogin,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == currentIndex ? 18 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == currentIndex ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 28),
          Text(
            slide.titleTop,
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            slide.titleMain,
            style: AppTextStyles.title.copyWith(fontSize: 23),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          Expanded(child: _SlidePreview(slide: slide)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// 스토어 스크린샷 느낌의 목업 프리뷰 — 실제 화면 캡처 에셋으로 교체 예정 자리표시자.
class _SlidePreview extends StatelessWidget {
  const _SlidePreview({required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 0.62,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.scaffold,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border, width: 4),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                color: slide.color,
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(slide.icon, size: 20, color: AppColors.surface),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        slide.previewTitle,
                        style: AppTextStyles.sectionTitle
                            .copyWith(color: AppColors.surface, fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    // 화면이 좁아도 overflow 없이 잘리도록 스크롤 불가 리스트로 배치
                    ListView(
                      padding: const EdgeInsets.all(12),
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (final point in slide.points) ...[
                          _PreviewPointCard(text: point, color: slide.color),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                    Positioned(
                      right: 10,
                      bottom: 6,
                      child: Text(
                        '🐷',
                        style: AppTextStyles.title.copyWith(fontSize: 28),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewPointCard extends StatelessWidget {
  const _PreviewPointCard({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingAuthPage extends StatelessWidget {
  const _OnboardingAuthPage({
    required this.submittingProvider,
    required this.onSocialLogin,
  });

  final SocialAuthProvider? submittingProvider;
  final ValueChanged<SocialAuthProvider> onSocialLogin;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '다시 만나서 반가워요',
            textAlign: TextAlign.center,
            style: AppTextStyles.title.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 6),
          const Text(
            '이메일로 로그인하거나 SNS 계정으로 바로 시작하세요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 24),
          EmailLoginForm(
            compact: true,
            onLoginSuccess: () => Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRoutes.root, (route) => false),
            onSignupPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.signup),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('또는', style: AppTextStyles.caption),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'SNS 계정으로 간편하게 시작해요',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SocialLoginButton(
                  key: const ValueKey('sns-kakao-button'),
                  label: '카카오',
                  background: AppColors.snsKakao,
                  foreground: AppColors.textPrimary,
                  isLoading: submittingProvider == SocialAuthProvider.kakao,
                  onPressed: submittingProvider == null
                      ? () => onSocialLogin(SocialAuthProvider.kakao)
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SocialLoginButton(
                  key: const ValueKey('sns-naver-button'),
                  label: '네이버',
                  background: AppColors.snsNaver,
                  foreground: AppColors.surface,
                  isLoading: submittingProvider == SocialAuthProvider.naver,
                  onPressed: submittingProvider == null
                      ? () => onSocialLogin(SocialAuthProvider.naver)
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton(
            key: const ValueKey('browse-without-login-button'),
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.root),
            child: Text(
              '로그인 없이 둘러보기',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final Color background;
  final Color foreground;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
        ),
        onPressed: onPressed,
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            : Text(
                label == '네이버' ? 'N' : '●',
                style: AppTextStyles.body.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w800,
                ),
              ),
        label: Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
