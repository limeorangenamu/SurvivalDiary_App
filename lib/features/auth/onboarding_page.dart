import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';

/// 첫 진입(미로그인) 화면 — 서비스 소개 슬라이드 + SNS 로그인.
/// SNS 로그인·이메일 가입은 인증 연동 이슈(#33)에서 실제 동작을 붙인다.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showPreparingMessage(String provider) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$provider 로그인은 준비 중이에요.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    const slides = MockData.onboardingSlides;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            _DotsIndicator(count: slides.length, currentIndex: _currentIndex),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) =>
                    _SlideView(slide: slides[index]),
              ),
            ),
            _AuthBottomArea(onSnsPressed: _showPreparingMessage),
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

class _AuthBottomArea extends StatelessWidget {
  const _AuthBottomArea({required this.onSnsPressed});

  final void Function(String provider) onSnsPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'SNS 계정으로 3초 만에 시작해요!',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SnsCircleButton(
                key: const ValueKey('sns-kakao-button'),
                background: AppColors.snsKakao,
                onPressed: () => onSnsPressed('카카오'),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  size: 26,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 20),
              _SnsCircleButton(
                key: const ValueKey('sns-naver-button'),
                background: AppColors.snsNaver,
                onPressed: () => onSnsPressed('네이버'),
                child: Text(
                  'N',
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextButton(
            key: const ValueKey('email-login-button'),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.login),
            child: Text(
              '이메일로 로그인',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
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

class _SnsCircleButton extends StatelessWidget {
  const _SnsCircleButton({
    super.key,
    required this.background,
    required this.onPressed,
    required this.child,
  });

  final Color background;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 58,
          height: 58,
          child: Center(child: child),
        ),
      ),
    );
  }
}
