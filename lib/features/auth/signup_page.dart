import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
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
  static const _reviewStep = 7;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _birthDateFormatter = _BirthDateInputFormatter();
  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _birthDateFocusNode = FocusNode();

  late final AuthApiClient _authApiClient;
  int _activeStep = 0;
  String? _selectedGender;
  final List<_SignupOption> _selectedInterests = [];
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _submissionError;
  int? _reviewEditingStep;

  static const _genderOptions = [
    _SignupOption(
      label: '남성',
      value: 'MALE',
      icon: Icons.male_rounded,
      color: AppColors.info,
    ),
    _SignupOption(
      label: '여성',
      value: 'FEMALE',
      icon: Icons.female_rounded,
      color: AppColors.categoryCafe,
    ),
  ];

  static const _interestOptions = [
    _SignupOption(
      label: '생활비 절약',
      value: 'LIVING_COST',
      icon: Icons.receipt_long_rounded,
      color: AppColors.primary,
    ),
    _SignupOption(
      label: '월세·주거비',
      value: 'HOUSING_COST',
      icon: Icons.home_work_rounded,
      color: AppColors.info,
    ),
    _SignupOption(
      label: '정부 정책',
      value: 'GOVERNMENT_POLICY',
      icon: Icons.article_rounded,
      color: AppColors.primaryDark,
    ),
    _SignupOption(
      label: '지원금·복지',
      value: 'BENEFIT',
      icon: Icons.volunteer_activism_rounded,
      color: AppColors.warning,
    ),
    _SignupOption(
      label: '가계부 관리',
      value: 'BUDGETING',
      icon: Icons.account_balance_wallet_rounded,
      color: AppColors.categoryShopping,
    ),
    _SignupOption(
      label: '식비 관리',
      value: 'FOOD_COST',
      icon: Icons.restaurant_rounded,
      color: AppColors.categoryFood,
    ),
    _SignupOption(
      label: '저축·투자',
      value: 'SAVING_INVESTMENT',
      icon: Icons.savings_rounded,
      color: AppColors.primaryDeep,
    ),
    _SignupOption(
      label: '부업·소득',
      value: 'SIDE_INCOME',
      icon: Icons.trending_up_rounded,
      color: AppColors.categoryCafe,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _authApiClient = widget._authApiClient ?? AuthApiClient();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _nameFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _birthDateFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final invalidStep = _firstInvalidStep();
    if (invalidStep != null) {
      setState(() => _activeStep = invalidStep);
      _showError(_validationMessage(invalidStep));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });
    try {
      await _authApiClient.signup(
        SignupRequest(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          phone: _phoneDigits,
          birthDate: _parseBirthDate(_birthDateDigits),
          gender: _selectedGender,
          signupInterests:
              _selectedInterests.map((interest) => interest.value).toList(),
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.signupSuccess,
        (route) => false,
      );
    } on AuthApiException catch (error) {
      _showError(error.message);
    } catch (_) {
      _showError('서버에 연결할 수 없어요. 백엔드 주소와 DB 상태를 확인해 주세요.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _moveNext() async {
    if (!_isStepValid(_activeStep)) {
      _showError(_validationMessage(_activeStep));
      return;
    }
    if (_reviewEditingStep != null) {
      _finishReviewEdit();
      return;
    }
    if (_activeStep < _reviewStep) {
      _advanceToStep(_activeStep + 1);
    } else {
      await _submit();
    }
  }

  void _moveBack() {
    if (_reviewEditingStep != null) {
      _finishReviewEdit();
      return;
    }
    if (_activeStep == 0) {
      Navigator.of(context).pop();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _activeStep -= 1);
  }

  void _advanceToStep(int step) {
    FocusScope.of(context).unfocus();
    setState(() => _activeStep = step);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _activeStep != step) {
        return;
      }
      switch (step) {
        case 1:
          _emailFocusNode.requestFocus();
          break;
        case 2:
          _passwordFocusNode.requestFocus();
          break;
        case 3:
          _birthDateFocusNode.requestFocus();
          break;
        case 4:
          _openGenderSheet(advanceAfterSelection: _reviewEditingStep == null);
          break;
        case 6:
          _phoneFocusNode.requestFocus();
          break;
      }
    });
  }

  int? _firstInvalidStep() {
    for (var step = 0; step < _reviewStep; step += 1) {
      if (!_isStepValid(step)) {
        return step;
      }
    }
    return null;
  }

  bool _isStepValid(int step) {
    switch (step) {
      case 0:
        final name = _nameController.text.trim();
        return name.isNotEmpty && name.length <= 50;
      case 1:
        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
            .hasMatch(_emailController.text.trim());
      case 2:
        return _passwordController.text.isNotEmpty;
      case 3:
        // TODO(kimin): 백엔드 정책 확정 후 비밀번호 복잡도 검사를 다시 연결합니다.
        return _parseBirthDate(_birthDateDigits) != null;
      case 4:
        return _selectedGender != null;
      case 5:
        return _selectedInterests.isNotEmpty;
      case 6:
        return _phoneDigits.length >= 10 && _phoneDigits.length <= 11;
      case _reviewStep:
        return _firstInvalidStep() == null;
      default:
        return false;
    }
  }

  String _validationMessage(int step) {
    switch (step) {
      case 0:
        return '이름을 입력해 주세요.';
      case 1:
        return '올바른 이메일 주소를 입력해 주세요.';
      case 2:
        return '전화번호를 숫자만 입력해 주세요.';
      case 3:
        return '비밀번호를 입력해 주세요.';
      case 4:
        return '생년월일 숫자 8자리를 입력해 주세요.';
      case 5:
        return '성별을 선택해 주세요.';
      case 6:
        return '관심사를 1개 이상 선택해 주세요.';
      default:
        return '입력값을 다시 확인해 주세요.';
    }
  }

  DateTime? _parseBirthDate(String digits) {
    if (digits.length != 8) {
      return null;
    }
    final year = int.tryParse(digits.substring(0, 4));
    final month = int.tryParse(digits.substring(4, 6));
    final day = int.tryParse(digits.substring(6, 8));
    if (year == null || month == null || day == null) {
      return null;
    }
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  String get _birthDateDigits =>
      _birthDateController.text.replaceAll(RegExp(r'\D'), '');

  String get _phoneDigits =>
      _phoneController.text.replaceAll(RegExp(r'\D'), '');

  String get _displayName {
    final name = _nameController.text.trim();
    return name.isEmpty ? '하이' : name;
  }

  String get _genderSummary {
    return _genderOptions
            .where((option) => option.value == _selectedGender)
            .firstOrNull
            ?.label ??
        '';
  }

  String get _interestSummary {
    if (_selectedInterests.isEmpty) {
      return '';
    }
    if (_selectedInterests.length == 1) {
      return _selectedInterests.first.label;
    }
    return '${_selectedInterests.first.label} 외 ${_selectedInterests.length - 1}건';
  }

  String get _allInterestLabels {
    if (_selectedInterests.isEmpty) {
      return '미선택';
    }
    return _selectedInterests.map((interest) => interest.label).join(', ');
  }

  List<int> get _visibleSteps {
    if (_activeStep == _reviewStep) {
      return const [_reviewStep];
    }
    return List<int>.generate(_activeStep + 1, (index) => index)
        .reversed
        .toList();
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _submissionError = message);
  }

  Future<void> _openGenderSheet({bool advanceAfterSelection = false}) async {
    final selected = await showModalBottomSheet<_SignupOption>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _SingleSelectSheet(
        title: '성별은 어떻게 되시나요?',
        options: _genderOptions,
        selectedValue: _selectedGender,
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() => _selectedGender = selected.value);
    if (_reviewEditingStep != null) {
      _finishReviewEdit();
      return;
    }
    if (advanceAfterSelection && _activeStep == 4) {
      _advanceToStep(5);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _activeStep == 5) {
          _openInterestSheet(advanceAfterSelection: true);
        }
      });
    }
  }

  Future<void> _openInterestSheet({bool advanceAfterSelection = false}) async {
    final selected = await showModalBottomSheet<List<_SignupOption>>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _MultiSelectSheet(
        title: '관심 있는 경제 정보를 골라주세요',
        options: _interestOptions,
        selected: _selectedInterests,
      ),
    );
    if (selected == null || !mounted) {
      return;
    }
    setState(() {
      _selectedInterests
        ..clear()
        ..addAll(selected);
    });
    if (_reviewEditingStep != null) {
      _finishReviewEdit();
      return;
    }
    if (advanceAfterSelection && _activeStep == 5) {
      _advanceToStep(6);
    }
  }

  void _editStep(int step) {
    setState(() => _reviewEditingStep = step);
    _advanceToStep(step);
  }

  void _editInterests() {
    setState(() => _reviewEditingStep = 5);
    _openInterestSheet();
  }

  void _finishReviewEdit() {
    FocusScope.of(context).unfocus();
    setState(() {
      _reviewEditingStep = null;
      _activeStep = _reviewStep;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final visibleSteps = _visibleSteps;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 20, 2),
              child: Row(
                children: [
                  IconButton(
                    key: const ValueKey('signup-back-button'),
                    tooltip: '이전',
                    onPressed: _isSubmitting ? null : _moveBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const Spacer(),
                  Text(
                    '${(_activeStep + 1).clamp(1, _reviewStep + 1)}/8',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  if (_submissionError != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.dangerSoft,
                        border: Border.all(
                          color: AppColors.danger.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _submissionError!,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.danger),
                      ),
                    ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemBuilder: (context, index) {
                        final step = visibleSteps[index];
                        return _AnimatedSignupSection(
                          key: ValueKey('signup-step-$step'),
                          child: _sectionForStep(step),
                        );
                      },
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 34),
                      itemCount: visibleSteps.length,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                bottomInset > 0 ? 12 : 24,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  key: const ValueKey('signup-submit-button'),
                  onPressed: _isSubmitting ? null : _moveNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    foregroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: AppTextStyles.button.copyWith(fontSize: 18),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.surface,
                          ),
                        )
                      : Text(_activeStep == _reviewStep ? '회원가입' : '다음'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionForStep(int step) {
    switch (step) {
      case 0:
        return _QuestionSection(
          title: '정말 반갑습니다!\n어떻게 불러드리면 될까요?',
          child: _LargeTextField(
            key: const ValueKey('signup-name-field'),
            label: '이름',
            hintText: '이름',
            controller: _nameController,
            focusNode: _nameFocusNode,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            onSubmitted: (_) => _activeStep == 0 ? _moveNext() : null,
          ),
        );
      case 1:
        return _QuestionSection(
          title: '$_displayName님의 이메일을 알려주세요',
          child: _LargeTextField(
            key: const ValueKey('signup-email-field'),
            label: '이메일',
            hintText: 'example@email.com',
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => _activeStep == 1 ? _moveNext() : null,
          ),
        );
      case 2:
        return _QuestionSection(
          title: '로그인에 사용할\n비밀번호를 입력해 주세요',
          child: _LargeTextField(
            key: const ValueKey('signup-password-field'),
            label: '비밀번호',
            hintText: '비밀번호',
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? '비밀번호 보기' : '비밀번호 숨기기',
              onPressed: () => setState(() {
                _obscurePassword = !_obscurePassword;
              }),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
            ),
            onSubmitted: (_) => _activeStep == 2 ? _moveNext() : null,
          ),
        );
      case 3:
        return _QuestionSection(
          title: '$_displayName님의 생일을 알려주세요',
          subtitle: '숫자 8자리만 입력하면 1999.09.09처럼 표시돼요.',
          child: _LargeTextField(
            key: const ValueKey('signup-birth-date-field'),
            label: '생년월일 8자리',
            hintText: '1999.09.09',
            controller: _birthDateController,
            focusNode: _birthDateFocusNode,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
              _birthDateFormatter,
            ],
            onSubmitted: (_) => _activeStep == 3 ? _moveNext() : null,
          ),
        );
      case 4:
        return _QuestionSection(
          title: '성별은 어떻게 되시나요?',
          subtitle: '아래 선택창에서 고르면 이 칸에는 문자로 표시돼요.',
          child: _PickerField(
            key: const ValueKey('signup-gender-field'),
            label: '성별',
            value: _genderSummary,
            hintText: '성별',
            onTap: _openGenderSheet,
          ),
        );
      case 5:
        return _QuestionSection(
          title: '어떤 경제 정보가 필요하신가요?',
          subtitle: '청년, 가정, 중년, 자취생에게 자주 필요한 관심사를 골랐어요.',
          child: _PickerField(
            key: const ValueKey('signup-interest-field'),
            label: '관심사',
            value: _interestSummary,
            hintText: '관심사',
            onTap: _openInterestSheet,
          ),
        );
      case 6:
        return _QuestionSection(
          title: '전화번호를 알려주세요',
          subtitle: '숫자만 입력해 주세요. 앱에서는 전화번호를 자동으로 가져오지 않습니다.',
          child: _LargeTextField(
            key: const ValueKey('signup-phone-field'),
            label: '전화번호',
            hintText: '01012345678',
            controller: _phoneController,
            focusNode: _phoneFocusNode,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            onSubmitted: (_) => _activeStep == 6 ? _moveNext() : null,
          ),
        );
      default:
        return _ReviewPanel(
          name: _displayName,
          email: _emailController.text.trim(),
          phone: _phoneController.text,
          birthDate: _birthDateController.text,
          gender: _genderSummary.isEmpty ? '미선택' : _genderSummary,
          interestSummary: _interestSummary,
          allInterests: _allInterestLabels,
          onEditName: () => _editStep(0),
          onEditEmail: () => _editStep(1),
          onEditPassword: () => _editStep(2),
          onEditBirthDate: () => _editStep(3),
          onEditGender: () => _editStep(4),
          onEditInterests: _editInterests,
          onEditPhone: () => _editStep(6),
        );
    }
  }
}

class _QuestionSection extends StatelessWidget {
  const _QuestionSection({
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.display.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          Text(
            subtitle!,
            style: AppTextStyles.bodyMuted.copyWith(fontSize: 16),
          ),
        ],
        const SizedBox(height: 28),
        child,
      ],
    );
  }
}

class _AnimatedSignupSection extends StatefulWidget {
  const _AnimatedSignupSection({super.key, required this.child});

  final Widget child;

  @override
  State<_AnimatedSignupSection> createState() => _AnimatedSignupSectionState();
}

class _AnimatedSignupSectionState extends State<_AnimatedSignupSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _offset = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(_opacity);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class _LargeTextField extends StatelessWidget {
  const _LargeTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.suffixIcon,
    this.inputFormatters,
    this.onSubmitted,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      onSubmitted: onSubmitted,
      cursorColor: AppColors.primary,
      style: AppTextStyles.display.copyWith(fontSize: 26),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        suffixIcon: suffixIcon,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: AppTextStyles.body.copyWith(
          color: AppColors.primary,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
        hintStyle: AppTextStyles.display.copyWith(
          color: AppColors.textTertiary,
          fontSize: 26,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.hintText,
    required this.onTap,
  });

  final String label;
  final String value;
  final String hintText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = value.isEmpty ? hintText : value;
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
          labelStyle: AppTextStyles.body.copyWith(
            color: AppColors.primary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.border, width: 1.5),
          ),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.display.copyWith(
            color:
                value.isEmpty ? AppColors.textTertiary : AppColors.textPrimary,
            fontSize: 26,
          ),
        ),
      ),
    );
  }
}

class _SingleSelectSheet extends StatelessWidget {
  const _SingleSelectSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
  });

  final String title;
  final List<_SignupOption> options;
  final String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: title,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          mainAxisExtent: 150,
        ),
        itemCount: options.length,
        itemBuilder: (context, index) {
          final option = options[index];
          return _OptionCard(
            option: option,
            selected: option.value == selectedValue,
            onTap: () => Navigator.pop(context, option),
          );
        },
      ),
    );
  }
}

class _MultiSelectSheet extends StatefulWidget {
  const _MultiSelectSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<_SignupOption> options;
  final List<_SignupOption> selected;

  @override
  State<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<_MultiSelectSheet> {
  late final Set<String> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = widget.selected.map((option) => option.value).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: widget.title,
      bottom: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          onPressed: () {
            final selected = widget.options
                .where((option) => _selectedValues.contains(option.value))
                .toList();
            Navigator.pop(context, selected);
          },
          child: Text('확인 ${_selectedValues.length}개'),
        ),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          mainAxisExtent: 150,
        ),
        itemCount: widget.options.length,
        itemBuilder: (context, index) {
          final option = widget.options[index];
          return _OptionCard(
            option: option,
            selected: _selectedValues.contains(option.value),
            onTap: () {
              setState(() {
                if (_selectedValues.contains(option.value)) {
                  _selectedValues.remove(option.value);
                } else {
                  _selectedValues.add(option.value);
                }
              });
            },
          );
        },
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.child,
    this.bottom,
  });

  final String title;
  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style: AppTextStyles.display.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 22),
            Flexible(child: child),
            if (bottom != null) ...[
              const SizedBox(height: 18),
              bottom!,
            ],
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _SignupOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _AnimatedSignupSection(
      child: Material(
        color: AppColors.surface,
        elevation: selected ? 6 : 2,
        shadowColor: AppColors.textPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: option.color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(option.icon, color: option.color, size: 34),
                ),
                const SizedBox(height: 16),
                Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.amount.copyWith(fontSize: 19),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({
    required this.name,
    required this.email,
    required this.phone,
    required this.birthDate,
    required this.gender,
    required this.interestSummary,
    required this.allInterests,
    required this.onEditName,
    required this.onEditEmail,
    required this.onEditPhone,
    required this.onEditPassword,
    required this.onEditBirthDate,
    required this.onEditGender,
    required this.onEditInterests,
  });

  final String name;
  final String email;
  final String phone;
  final String birthDate;
  final String gender;
  final String interestSummary;
  final String allInterests;
  final VoidCallback onEditName;
  final VoidCallback onEditEmail;
  final VoidCallback onEditPhone;
  final VoidCallback onEditPassword;
  final VoidCallback onEditBirthDate;
  final VoidCallback onEditGender;
  final VoidCallback onEditInterests;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '정보가 모두 맞나요?',
          style: AppTextStyles.display.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 52),
        _ReviewRow(label: '전화번호', value: phone, onTap: onEditPhone),
        _ReviewRow(
          label: '관심사',
          value: interestSummary.isEmpty ? '미선택' : interestSummary,
          helper: allInterests,
          onTap: onEditInterests,
        ),
        _ReviewRow(label: '성별', value: gender, onTap: onEditGender),
        _ReviewRow(
          label: '생년월일',
          value: birthDate,
          onTap: onEditBirthDate,
        ),
        _ReviewRow(label: '비밀번호', value: '입력됨', onTap: onEditPassword),
        _ReviewRow(label: '이메일', value: email, onTap: onEditEmail),
        _ReviewRow(label: '이름', value: name, onTap: onEditName),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.helper,
  });

  final String label;
  final String value;
  final String? helper;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyMuted.copyWith(fontSize: 16),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.amount.copyWith(fontSize: 20),
                  ),
                  if (helper != null && helper!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      helper!,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignupOption {
  const _SignupOption({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _BirthDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length && index < 8; index += 1) {
      if (index == 4 || index == 6) {
        buffer.write('.');
      }
      buffer.write(digits[index]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
