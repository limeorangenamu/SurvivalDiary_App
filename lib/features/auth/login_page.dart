import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'widgets/email_login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(backgroundColor: AppColors.surface),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('이메일로 로그인', style: AppTextStyles.display),
              const SizedBox(height: 12),
              const Text(
                '가입한 이메일과 비밀번호를 입력해 주세요.',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 44),
              EmailLoginForm(
                onLoginSuccess: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.root, (route) => false),
                onSignupPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.signup),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
