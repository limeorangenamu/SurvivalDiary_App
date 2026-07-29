import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';

/// 이메일 회원가입 — 한 번에 한 항목씩 질문하고, 새 질문이 fade로 나타나며
/// 이전 답변들을 아래로 밀어낸다. 이미 입력한 값은 언제든 탭해서 수정할 수 있고,
/// 아직 묻지 않은 항목은 보이지 않는다. 모든 입력 후 확인 화면을 거쳐 가입한다.
///
/// 입력 항목·검증 규칙은 users 테이블(서버 SignupRequest)과 동일:
/// 필수 email/password/name, 선택 birth_date/gender/region. 실제 API 연동은 #33.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

enum _SignupStep { email, password, name, birthDate, gender, region }

extension _SignupStepX on _SignupStep {
  String get label => switch (this) {
        _SignupStep.email => '이메일',
        _SignupStep.password => '비밀번호',
        _SignupStep.name => '이름',
        _SignupStep.birthDate => '생년월일 (8자리)',
        _SignupStep.gender => '성별',
        _SignupStep.region => '거주 지역',
      };

  bool get isOptional => switch (this) {
        _SignupStep.birthDate || _SignupStep.gender || _SignupStep.region =>
          true,
        _ => false,
      };
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  static const _steps = _SignupStep.values;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nameController = TextEditingController();
  final _birthController = TextEditingController();

  Gender? _gender;
  String? _region;

  /// 지금까지 도달한 단계 수. `_steps.length`가 되면 최종 확인 화면.
  int _furthest = 0;

  /// 이전 답변을 수정 중일 때 해당 단계 인덱스. null이면 정상 진행.
  int? _editing;

  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  )..forward();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nameController.dispose();
    _birthController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool get _inReview => _furthest >= _steps.length && _editing == null;

  _SignupStep get _activeStep =>
      _steps[_editing ?? _furthest.clamp(0, _steps.length - 1)];

  // ── 검증 (서버 SignupRequest와 동일 규칙) ──────────────────────────

  bool get _emailValid => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
      .hasMatch(_emailController.text.trim());

  bool get _passwordValid {
    final password = _passwordController.text;
    return password.length >= 8 &&
        password.length <= 64 &&
        password.contains(RegExp('[A-Za-z]')) &&
        password.contains(RegExp('[0-9]'));
  }

  bool get _passwordConfirmed =>
      _passwordConfirmController.text == _passwordController.text;

  bool get _nameValid {
    final name = _nameController.text.trim();
    return name.isNotEmpty && name.length <= 50;
  }

  DateTime? get _birthDate {
    final digits = _birthController.text;
    if (digits.length != 8) return null;
    final year = int.parse(digits.substring(0, 4));
    final month = int.parse(digits.substring(4, 6));
    final day = int.parse(digits.substring(6, 8));
    final date = DateTime(year, month, day);
    final valid = date.year == year && date.month == month && date.day == day;
    if (!valid || year < 1900 || date.isAfter(DateTime.now())) return null;
    return date;
  }

  bool _isStepValid(_SignupStep step) => switch (step) {
        _SignupStep.email => _emailValid,
        _SignupStep.password => _passwordValid && _passwordConfirmed,
        _SignupStep.name => _nameValid,
        _SignupStep.birthDate => _birthDate != null,
        _SignupStep.gender => _gender != null,
        _SignupStep.region => _region != null,
      };

  // ── 진행 ──────────────────────────────────────────────────────────

  void _confirmActive() {
    if (!_isStepValid(_activeStep)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      if (_editing != null) {
        _editing = null;
      } else {
        _furthest++;
      }
    });
    _fadeController.forward(from: 0);
  }

  void _skipActive() {
    FocusScope.of(context).unfocus();
    setState(() {
      switch (_activeStep) {
        case _SignupStep.birthDate:
          _birthController.clear();
        case _SignupStep.gender:
          _gender = null;
        case _SignupStep.region:
          _region = null;
        default:
          return;
      }
      _furthest++;
    });
    _fadeController.forward(from: 0);
  }

  void _startEdit(int stepIndex) {
    setState(() => _editing = stepIndex);
    _fadeController.forward(from: 0);
  }

  void _handleBack() {
    if (_editing != null) {
      setState(() => _editing = null);
      return;
    }
    if (_furthest == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _furthest--);
    _fadeController.forward(from: 0);
  }

  void _submitSignup() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('회원가입이 완료됐어요! (서버 연동 전 미리보기)')),
      );
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.root, (route) => false);
  }

  // ── 값 표시 ───────────────────────────────────────────────────────

  String? _displayValue(_SignupStep step) => switch (step) {
        _SignupStep.email => _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        _SignupStep.password =>
          _passwordController.text.isEmpty ? null : '●●●●●●●●',
        _SignupStep.name => _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        _SignupStep.birthDate => _birthDate == null
            ? null
            : '${_birthController.text.substring(0, 4)}.'
                '${_birthController.text.substring(4, 6)}.'
                '${_birthController.text.substring(6, 8)}',
        _SignupStep.gender => _gender?.label,
        _SignupStep.region => _region,
      };

  String get _questionTitle {
    if (_inReview) return '정보가 모두 맞나요?';
    final name = _nameController.text.trim().isEmpty
        ? null
        : _nameController.text.trim();
    return switch (_activeStep) {
      _SignupStep.email => '만나서 반가워요!\n로그인에 사용할 이메일을 알려주세요',
      _SignupStep.password => '로그인에 사용할\n비밀번호를 정해주세요',
      _SignupStep.name => '정말 반갑습니다!\n어떻게 불러드리면 될까요?',
      _SignupStep.birthDate =>
        name == null ? '생년월일을 알려주세요' : '$name님의 생년월일을 알려주세요',
      _SignupStep.gender => '성별은 어떻게 되시나요?',
      _SignupStep.region => '어느 지역에 살고 계세요?',
    };
  }

  // ── 화면 ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                key: const ValueKey('signup-back-button'),
                onPressed: _handleBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  Text(
                    _questionTitle,
                    style: AppTextStyles.title.copyWith(height: 1.35),
                  ),
                  const SizedBox(height: 32),
                  if (_inReview)
                    ..._buildReviewRows()
                  else
                    ..._buildWizardBlocks(),
                ],
              ),
            ),
            _buildBottomArea(),
          ],
        ),
      ),
    );
  }

  /// 최신 단계가 맨 위(fade 등장), 이전 답변들이 아래로 밀려 쌓인다.
  List<Widget> _buildWizardBlocks() {
    final visibleMax =
        _furthest < _steps.length ? _furthest : _steps.length - 1;
    final activeIndex = _editing ?? visibleMax;
    return [
      for (var i = visibleMax; i >= 0; i--)
        if (i == activeIndex)
          FadeTransition(
            opacity: _fadeController,
            child: _buildActiveInput(_steps[i]),
          )
        else
          _SummaryRow(
            stepName: _steps[i].name,
            label: _steps[i].label,
            value: _displayValue(_steps[i]),
            onTap: () => _startEdit(i),
          ),
    ];
  }

  List<Widget> _buildReviewRows() {
    return [
      const Text('항목을 누르면 수정할 수 있어요.', style: AppTextStyles.caption),
      const SizedBox(height: 8),
      for (var i = _steps.length - 1; i >= 0; i--)
        _SummaryRow(
          stepName: _steps[i].name,
          label: _steps[i].label,
          value: _displayValue(_steps[i]),
          onTap: () => _startEdit(i),
        ),
    ];
  }

  Widget _buildActiveInput(_SignupStep step) {
    final child = switch (step) {
      _SignupStep.email => _LabeledField(
          label: step.label,
          errorText: _emailController.text.isNotEmpty && !_emailValid
              ? '올바른 이메일 형식이 아니에요.'
              : null,
          child: TextField(
            key: const ValueKey('signup-email-field'),
            controller: _emailController,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'example@email.com'),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _confirmActive(),
          ),
        ),
      _SignupStep.password => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _LabeledField(
              label: step.label,
              errorText: _passwordController.text.isNotEmpty && !_passwordValid
                  ? '영문과 숫자를 모두 포함해 8~64자로 입력해 주세요.'
                  : null,
              child: TextField(
                key: const ValueKey('signup-password-field'),
                controller: _passwordController,
                autofocus: true,
                obscureText: true,
                decoration:
                    const InputDecoration(hintText: '영문+숫자 포함 8~64자'),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 16),
            _LabeledField(
              label: '비밀번호 확인',
              errorText: _passwordConfirmController.text.isNotEmpty &&
                      !_passwordConfirmed
                  ? '비밀번호가 일치하지 않아요.'
                  : null,
              child: TextField(
                key: const ValueKey('signup-password-confirm-field'),
                controller: _passwordConfirmController,
                obscureText: true,
                decoration:
                    const InputDecoration(hintText: '비밀번호를 한 번 더 입력'),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _confirmActive(),
              ),
            ),
          ],
        ),
      _SignupStep.name => _LabeledField(
          label: step.label,
          errorText: _nameController.text.trim().length > 50
              ? '이름은 50자 이내로 입력해 주세요.'
              : null,
          child: TextField(
            key: const ValueKey('signup-name-field'),
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(hintText: '이름 또는 닉네임'),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _confirmActive(),
          ),
        ),
      _SignupStep.birthDate => _LabeledField(
          label: step.label,
          errorText: _birthController.text.length == 8 && _birthDate == null
              ? '올바른 날짜가 아니에요.'
              : null,
          helperText: '생년월일은 맞춤 정책 추천에 사용돼요.',
          child: TextField(
            key: const ValueKey('signup-birth-field'),
            controller: _birthController,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              hintText: '19990214',
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _confirmActive(),
          ),
        ),
      _SignupStep.gender => _SelectorField(
          fieldKey: const ValueKey('signup-gender-selector'),
          label: step.label,
          value: _gender?.label,
          onTap: _pickGender,
        ),
      _SignupStep.region => _SelectorField(
          fieldKey: const ValueKey('signup-region-selector'),
          label: step.label,
          value: _region,
          onTap: _pickRegion,
        ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: child,
    );
  }

  Widget _buildBottomArea() {
    final showSkip = !_inReview && _editing == null && _activeStep.isOptional;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        children: [
          if (showSkip)
            TextButton(
              key: const ValueKey('signup-skip-button'),
              onPressed: _skipActive,
              child: Text(
                '나중에 입력할게요',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: _inReview
                ? FilledButton(
                    key: const ValueKey('signup-submit-button'),
                    onPressed: _submitSignup,
                    child: const Text('확인했어요'),
                  )
                : FilledButton(
                    key: const ValueKey('signup-next-button'),
                    onPressed:
                        _isStepValid(_activeStep) ? _confirmActive : null,
                    child: Text(_editing != null ? '수정 완료' : '확인'),
                  ),
          ),
        ],
      ),
    );
  }

  // ── 선택형 입력 바텀시트 ──────────────────────────────────────────

  Future<void> _pickGender() async {
    final selected = await showModalBottomSheet<Gender>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('성별은 어떻게 되시나요?', style: AppTextStyles.title),
            const SizedBox(height: 20),
            Row(
              children: [
                for (final gender in Gender.values) ...[
                  Expanded(
                    child: _GenderCard(
                      key: ValueKey('signup-gender-${gender.name}'),
                      gender: gender,
                      selected: _gender == gender,
                      onTap: () => Navigator.of(context).pop(gender),
                    ),
                  ),
                  if (gender != Gender.values.last) const SizedBox(width: 10),
                ],
              ],
            ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _gender = selected);
  }

  Future<void> _pickRegion() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('어느 지역에 살고 계세요?', style: AppTextStyles.title),
            const SizedBox(height: 16),
            for (final region in MockData.regions.keys)
              _RegionTile(
                key: ValueKey('signup-region-$region'),
                name: region,
                selected: _region == region,
                onTap: () => Navigator.of(context).pop(region),
              ),
          ],
        ),
      ),
    );
    if (selected != null) setState(() => _region = selected);
  }
}

/// 이미 답변한 항목 — 회색 라벨 + 값. 탭하면 다시 수정할 수 있다.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.stepName,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String stepName;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: ValueKey('signup-summary-$stepName'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.captionTiny),
            const SizedBox(height: 5),
            Text(
              value ?? '입력 안 함',
              style: AppTextStyles.body.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: value == null
                    ? AppColors.textTertiary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.errorText,
    this.helperText,
  });

  final String label;
  final Widget child;
  final String? errorText;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 6),
        child,
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: AppTextStyles.caption.copyWith(color: AppColors.danger),
          ),
        ] else if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(helperText!, style: AppTextStyles.caption),
        ],
      ],
    );
  }
}

/// 바텀시트로 값을 고르는 항목(성별·지역)의 자리 표시 필드.
class _SelectorField extends StatelessWidget {
  const _SelectorField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final Key fieldKey;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: fieldKey,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? '선택해 주세요',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: value == null
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderCard extends StatelessWidget {
  const _GenderCard({
    super.key,
    required this.gender,
    required this.selected,
    required this.onTap,
  });

  final Gender gender;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (gender) {
      Gender.male => Icons.male_rounded,
      Gender.female => Icons.female_rounded,
      Gender.other => Icons.person_rounded,
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 34,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              gender.label,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionTile extends StatelessWidget {
  const _RegionTile({
    super.key,
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          name,
          style: AppTextStyles.body.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
