import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/widgets/app_card.dart';
import 'data/auth_api_client.dart';
import 'data/signup_request.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key, AuthApiClient? authApiClient})
      : _authApiClient = authApiClient;

  final AuthApiClient? _authApiClient;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _regionController = TextEditingController();

  late final AuthApiClient _authApiClient;
  String? _selectedGender;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authApiClient = widget._authApiClient ?? AuthApiClient();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _authApiClient.signup(
        SignupRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          birthDate: _parseBirthDate(_birthDateController.text.trim()),
          gender: _selectedGender,
          region: _emptyToNull(_regionController.text.trim()),
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('회원가입이 완료됐어요.')));
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.root,
        (route) => false,
      );
    } on AuthApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('서버에 연결할 수 없어요. 백엔드 서버를 확인해 주세요.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  DateTime? _parseBirthDate(String value) {
    if (value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  String? _emptyToNull(String value) => value.isEmpty ? null : value;

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이메일로 시작하기')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
          children: [
            const Text('생활비 절약을 시작해볼까요?', style: AppTextStyles.title),
            const SizedBox(height: 8),
            const Text(
              '입력한 계정 정보는 Survival Diary 백엔드 서버에 저장돼요.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      key: const ValueKey('signup-email-field'),
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: '이메일'),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('signup-password-field'),
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        suffixIcon: IconButton(
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('signup-name-field'),
                      controller: _nameController,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(labelText: '이름'),
                      validator: _validateName,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('signup-birth-date-field'),
                      controller: _birthDateController,
                      keyboardType: TextInputType.datetime,
                      decoration: const InputDecoration(
                        labelText: '생년월일',
                        hintText: '2000-03-15',
                      ),
                      validator: _validateBirthDate,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('signup-gender-field'),
                      initialValue: _selectedGender,
                      decoration: const InputDecoration(labelText: '성별'),
                      items: const [
                        DropdownMenuItem(value: 'MALE', child: Text('남성')),
                        DropdownMenuItem(value: 'FEMALE', child: Text('여성')),
                        DropdownMenuItem(value: 'OTHER', child: Text('기타')),
                      ],
                      onChanged: (value) => setState(
                        () => _selectedGender = value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('signup-region-field'),
                      controller: _regionController,
                      decoration: const InputDecoration(
                        labelText: '지역',
                        hintText: '서울',
                      ),
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      key: const ValueKey('signup-submit-button'),
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('회원가입 완료'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed:
                  _isSubmitting ? null : () => Navigator.of(context).pop(),
              child: Text(
                '다른 방법으로 시작하기',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return '이메일을 입력해 주세요.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return '올바른 이메일 형식으로 입력해 주세요.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8 || password.length > 64) {
      return '비밀번호는 8~64자로 입력해 주세요.';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      return '비밀번호에는 영문과 숫자가 각각 1개 이상 필요해요.';
    }
    return null;
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return '이름을 입력해 주세요.';
    }
    if (name.length > 50) {
      return '이름은 50자 이내로 입력해 주세요.';
    }
    return null;
  }

  String? _validateBirthDate(String? value) {
    final birthDate = value?.trim() ?? '';
    if (birthDate.isEmpty) {
      return null;
    }
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(birthDate) ||
        DateTime.tryParse(birthDate) == null) {
      return '생년월일은 YYYY-MM-DD 형식으로 입력해 주세요.';
    }
    return null;
  }
}
