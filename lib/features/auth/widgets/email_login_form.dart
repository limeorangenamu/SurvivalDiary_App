import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../auth_session.dart';
import '../data/auth_api_client.dart';

class EmailLoginForm extends StatefulWidget {
  const EmailLoginForm({
    super.key,
    required this.onLoginSuccess,
    required this.onSignupPressed,
    this.compact = false,
  });

  final VoidCallback onLoginSuccess;
  final VoidCallback onSignupPressed;
  final bool compact;

  @override
  State<EmailLoginForm> createState() => _EmailLoginFormState();
}

class _EmailLoginFormState extends State<EmailLoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await AuthSession.instance.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) widget.onLoginSuccess();
    } on AuthApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const ValueKey('login-email-field'),
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: '이메일'),
            validator: (value) {
              final email = value?.trim() ?? '';
              return email.isEmpty || !email.contains('@')
                  ? '올바른 이메일을 입력해 주세요.'
                  : null;
            },
          ),
          SizedBox(height: widget.compact ? 12 : 20),
          TextFormField(
            key: const ValueKey('login-password-field'),
            controller: _passwordController,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _login(),
            decoration: InputDecoration(
              labelText: '비밀번호',
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
                onPressed: () => setState(
                  () => _obscurePassword = !_obscurePassword,
                ),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) =>
                (value?.isEmpty ?? true) ? '비밀번호를 입력해 주세요.' : null,
          ),
          SizedBox(height: widget.compact ? 16 : 32),
          SizedBox(
            height: widget.compact ? 48 : 56,
            child: FilledButton(
              key: const ValueKey('login-submit-button'),
              onPressed: _isSubmitting ? null : _login,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('로그인'),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            key: const ValueKey('login-signup-button'),
            onPressed: widget.onSignupPressed,
            child: Text(
              '계정이 없으신가요? 이메일로 회원가입',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
