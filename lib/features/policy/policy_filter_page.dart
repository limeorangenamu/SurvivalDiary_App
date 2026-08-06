import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/option_picker_sheet.dart';
import '../auth/auth_session.dart';
import 'data/policy_api_client.dart';
import 'data/policy_models.dart';
import 'policy_list_page.dart';

class PolicyFilterPage extends StatefulWidget {
  const PolicyFilterPage({
    super.key,
    this.apiClient,
    this.accessTokenProvider,
  });

  final PolicyApiClient? apiClient;
  final PolicyAccessTokenProvider? accessTokenProvider;

  @override
  State<PolicyFilterPage> createState() => _PolicyFilterPageState();
}

class _PolicyFilterPageState extends State<PolicyFilterPage> {
  final _ageFormKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();

  late final PolicyApiClient _apiClient;
  late final PolicyAccessTokenProvider _accessTokenProvider;

  PolicyRegionOption? _region;
  PolicyDistrictOption? _district;
  PolicyWorkStatus? _workStatus;
  bool? _jobSeeking;
  PolicyEducationStatus? _educationStatus;
  Set<PolicyInterest> _savedInterests = const {};
  PolicyFilterCondition? _activeCondition;
  int? _profileAge;
  String? _loadMessage;
  int _step = 0;
  bool _isLoadingPreference = true;
  bool _isSubmitting = false;
  bool _showRegionError = false;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? PolicyApiClient();
    _accessTokenProvider =
        widget.accessTokenProvider ?? (() => AuthSession.instance.accessToken);
    _loadPreference();
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _loadPreference() async {
    final accessToken = _accessTokenProvider();
    if (accessToken == null || accessToken.isEmpty) {
      setState(() => _isLoadingPreference = false);
      return;
    }

    try {
      final preference = await _apiClient.getPolicyPreference(
        accessToken: accessToken,
      );
      if (!mounted) {
        return;
      }
      _profileAge = preference.age;
      if (preference.age != null) {
        _ageController.text = preference.age.toString();
      }
      final condition = _conditionFrom(preference);
      if (condition != null) {
        _applyCondition(condition);
      }
      setState(() {
        _activeCondition = condition;
        _showResults = condition != null;
        _isLoadingPreference = false;
        if (preference.saved && condition == null) {
          _loadMessage = '저장된 조건을 확인하지 못해 간단 설정을 다시 보여드려요.';
        }
      });
    } on PolicyApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingPreference = false;
        _loadMessage = '${error.message} 직접 조건을 설정할 수 있어요.';
      });
    }
  }

  PolicyFilterCondition? _conditionFrom(PolicyPreference preference) {
    if (!preference.saved ||
        preference.age == null ||
        preference.age! < 18 ||
        preference.age! > 39 ||
        preference.regionCode == null) {
      return null;
    }

    final region = MockData.policyRegions
        .where((option) => option.code == preference.regionCode)
        .firstOrNull;
    if (region == null) {
      return null;
    }

    final district = preference.districtCode == null
        ? null
        : region.districts
            .where((option) => option.code == preference.districtCode)
            .firstOrNull;
    if (preference.districtCode != null && district == null) {
      return null;
    }

    return PolicyFilterCondition(
      age: preference.age!,
      regionCode: region.code,
      region: region.name,
      districtCode: district?.code,
      district: district?.name,
      workStatus: preference.workStatus,
      jobSeeking: preference.jobSeeking,
      educationStatus: preference.educationStatus,
      interests: preference.interests,
    );
  }

  void _applyCondition(PolicyFilterCondition condition) {
    _ageController.text = condition.age.toString();
    _region = MockData.policyRegions
        .where((option) => option.code == condition.regionCode)
        .firstOrNull;
    _district = _region?.districts
        .where((option) => option.code == condition.districtCode)
        .firstOrNull;
    _workStatus = condition.workStatus;
    _jobSeeking = condition.jobSeeking;
    _educationStatus = condition.educationStatus;
    _savedInterests = condition.interests;
  }

  Future<T?> _pick<T>({
    required String title,
    required List<T> options,
    required String Function(T value) labelBuilder,
    T? selected,
  }) {
    return showOptionPickerSheet<T>(
      context: context,
      title: title,
      options: options,
      labelBuilder: labelBuilder,
      selected: selected,
    );
  }

  Future<void> _pickRegion() async {
    final value = await _pick<PolicyRegionOption>(
      title: '거주하는 시·도를 선택해 주세요',
      options: MockData.policyRegions,
      labelBuilder: (option) => option.name,
      selected: _region,
    );
    if (value != null && mounted) {
      setState(() {
        if (_region?.code != value.code) {
          _district = null;
        }
        _region = value;
        _showRegionError = false;
      });
    }
  }

  Future<void> _pickDistrict() async {
    final region = _region;
    if (region == null || region.districts.isEmpty) {
      return;
    }
    final options = [
      const _NullableOption<PolicyDistrictOption>(
        value: null,
        label: '시·도 전체',
      ),
      for (final district in region.districts)
        _NullableOption(value: district, label: district.name),
    ];
    final value = await _pick<_NullableOption<PolicyDistrictOption>>(
      title: '구·군을 선택해 주세요',
      options: options,
      labelBuilder: (option) => option.label,
      selected: options.firstWhere(
        (option) => option.value?.code == _district?.code,
        orElse: () => options.first,
      ),
    );
    if (value != null && mounted) {
      setState(() => _district = value.value);
    }
  }

  bool _validateFirstStep() {
    final age = int.tryParse(_ageController.text);
    final ageValid = _ageFormKey.currentState?.validate() ??
        (age != null && age >= 18 && age <= 39);
    setState(() => _showRegionError = _region == null);
    return ageValid && _region != null;
  }

  void _nextStep() {
    FocusScope.of(context).unfocus();
    if (_step == 0 && !_validateFirstStep()) {
      return;
    }
    if (_step < 2) {
      setState(() => _step++);
    }
  }

  void _previousStep() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  void _toggleEmployed() {
    setState(() {
      _workStatus = _workStatus == PolicyWorkStatus.employed
          ? null
          : PolicyWorkStatus.employed;
    });
  }

  void _toggleJobSeeking() {
    setState(() {
      final selected = _jobSeeking == true;
      _jobSeeking = selected ? null : true;
      if (!selected && _workStatus == null) {
        _workStatus = PolicyWorkStatus.unemployed;
      }
      if (selected && _workStatus == PolicyWorkStatus.unemployed) {
        _workStatus = null;
      }
    });
  }

  void _toggleStudent() {
    setState(() {
      _educationStatus = _educationStatus == PolicyEducationStatus.student
          ? null
          : PolicyEducationStatus.student;
    });
  }

  void _clearSituation() {
    setState(() {
      _workStatus = null;
      _jobSeeking = null;
      _educationStatus = null;
    });
  }

  PolicyFilterCondition get _condition => PolicyFilterCondition(
        age: int.parse(_ageController.text),
        regionCode: _region!.code,
        region: _region!.name,
        districtCode: _district?.code,
        district: _district?.name,
        workStatus: _workStatus,
        jobSeeking: _jobSeeking,
        educationStatus: _educationStatus,
        interests: _savedInterests,
      );

  Future<void> _saveAndRecommend() async {
    if (_isSubmitting || !_validateFirstStep()) {
      return;
    }
    final accessToken = _accessTokenProvider();
    if (accessToken == null || accessToken.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('맞춤 정책을 보려면 먼저 로그인해 주세요.')),
        );
      return;
    }

    final condition = _condition;
    setState(() => _isSubmitting = true);
    try {
      await _apiClient.savePolicyPreference(
        accessToken: accessToken,
        condition: condition,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _activeCondition = condition;
        _showResults = true;
        _isSubmitting = false;
        _loadMessage = null;
      });
    } on PolicyApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _editCondition() {
    setState(() {
      _step = 0;
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPreference) {
      return const Scaffold(
        appBar: _PolicyAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final activeCondition = _activeCondition;
    if (_showResults && activeCondition != null) {
      return PolicyListPage(
        key: ValueKey(
          'policy-briefing-${activeCondition.regionCode}-'
          '${activeCondition.districtCode}-${activeCondition.age}',
        ),
        condition: activeCondition,
        apiClient: _apiClient,
        accessTokenProvider: _accessTokenProvider,
        onEditCondition: _editCondition,
      );
    }

    return Scaffold(
      appBar: const _PolicyAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  key: const ValueKey('policy-setup-progress'),
                  value: (_step + 1) / 3,
                  minHeight: 5,
                  backgroundColor: AppColors.primarySoft,
                ),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: SingleChildScrollView(
                  key: ValueKey('policy-setup-step-$_step'),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: switch (_step) {
                    0 => _buildRegionStep(),
                    1 => _buildSituationStep(),
                    _ => _buildConfirmStep(),
                  },
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionStep() {
    return Form(
      key: _ageFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepLabel(step: 1),
          const SizedBox(height: 10),
          const Text('어디에 살고 있나요?', style: AppTextStyles.title),
          const SizedBox(height: 8),
          const Text(
            '나이와 거주 지역만 있으면 추천을 시작할 수 있어요.',
            style: AppTextStyles.bodyMuted,
          ),
          if (_loadMessage != null) ...[
            const SizedBox(height: 16),
            AppCard(
              color: AppColors.warningSoft,
              borderColor: AppColors.warningSoft,
              padding: const EdgeInsets.all(12),
              child: Text(_loadMessage!, style: AppTextStyles.caption),
            ),
          ],
          const SizedBox(height: 30),
          TextFormField(
            key: const ValueKey('policy-age-field'),
            controller: _ageController,
            readOnly: _profileAge != null,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: '나이',
              suffixText: '세',
              helperText: _profileAge == null ? null : '회원정보에서 자동으로 적용했어요.',
            ),
            validator: (value) {
              final age = int.tryParse(value ?? '');
              if (age == null) {
                return '나이를 입력해 주세요.';
              }
              if (age < 18 || age > 39) {
                return '현재 청년정책 조회 범위는 만 18~39세예요.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _SetupField(
            key: const ValueKey('policy-region-field'),
            label: '시·도',
            value: _region?.name,
            hint: '거주 지역 선택',
            errorText: _showRegionError ? '시·도를 선택해 주세요.' : null,
            onTap: _pickRegion,
          ),
          const SizedBox(height: 14),
          _SetupField(
            key: const ValueKey('policy-district-field'),
            label: '구·군',
            value: _region == null ? null : _district?.name ?? '시·도 전체',
            hint: _region == null ? '시·도를 먼저 선택해 주세요.' : '시·도 전체',
            enabled: _region?.districts.isNotEmpty ?? false,
            onTap: _pickDistrict,
          ),
        ],
      ),
    );
  }

  Widget _buildSituationStep() {
    final noSelection =
        _workStatus == null && _jobSeeking == null && _educationStatus == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepLabel(step: 2),
        const SizedBox(height: 10),
        const Text('지금 어떤 상황에 가까운가요?', style: AppTextStyles.title),
        const SizedBox(height: 8),
        const Text(
          '여러 개를 선택할 수 있고, 잘 모르겠다면 건너뛰어도 괜찮아요.',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          key: const ValueKey('policy-situation-options'),
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: itemWidth,
                  height: 52,
                  child: _SituationChip(
                    key: const ValueKey('policy-situation-employed'),
                    icon: Icons.work_outline_rounded,
                    label: '재직 중',
                    selected: _workStatus == PolicyWorkStatus.employed,
                    onSelected: (_) => _toggleEmployed(),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  height: 52,
                  child: _SituationChip(
                    key: const ValueKey('policy-situation-job-seeking'),
                    icon: Icons.search_rounded,
                    label: '구직 중',
                    selected: _jobSeeking == true,
                    onSelected: (_) => _toggleJobSeeking(),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  height: 52,
                  child: _SituationChip(
                    key: const ValueKey('policy-situation-student'),
                    icon: Icons.school_outlined,
                    label: '학생',
                    selected: _educationStatus == PolicyEducationStatus.student,
                    onSelected: (_) => _toggleStudent(),
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  height: 52,
                  child: _SituationChip(
                    key: const ValueKey('policy-situation-none'),
                    icon: Icons.remove_circle_outline_rounded,
                    label: '해당 없음',
                    selected: noSelection,
                    onSelected: (_) => _clearSituation(),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        const AppCard(
          color: AppColors.primarySoft,
          borderColor: AppColors.primarySoft,
          padding: EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  color: AppColors.primaryDeep),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '이 정보는 정책을 제외하는 데 쓰지 않고, 나와 관련된 정책을 먼저 보여주는 데 사용해요.',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    final labels = [
      '만 ${_ageController.text}세',
      _region?.name ?? '',
      _district?.name ?? '전체 지역',
      if (_workStatus != null) _workStatus!.label,
      if (_jobSeeking == true) '구직 중',
      if (_educationStatus != null) _educationStatus!.label,
    ].where((label) => label.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _StepLabel(step: 3),
        const SizedBox(height: 10),
        const Text('추천 준비가 끝났어요', style: AppTextStyles.title),
        const SizedBox(height: 8),
        const Text(
          '아래 조건으로 놓치기 쉬운 정책부터 찾아드릴게요.',
          style: AppTextStyles.bodyMuted,
        ),
        const SizedBox(height: 26),
        AppCard(
          color: AppColors.primarySoft,
          borderColor: AppColors.primarySoft,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primaryDeep,
                size: 30,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final label in labels)
                    Chip(
                      label: Text(label),
                      backgroundColor: AppColors.surface,
                      side: BorderSide.none,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '이 조건은 로그인한 계정에 자동으로 저장돼요.',
                style: AppTextStyles.caption,
              ),
            ],
          ),
        ),
        if (_isSubmitting) ...[
          const SizedBox(height: 20),
          const _RecommendationLoading(),
        ],
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_step > 0) ...[
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: _isSubmitting ? null : _previousStep,
                child: const Text('이전'),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              key: ValueKey(
                _step == 2 ? 'policy-recommend-button' : 'policy-setup-next',
              ),
              onPressed: _isSubmitting
                  ? null
                  : _step == 2
                      ? _saveAndRecommend
                      : _nextStep,
              child: Text(
                _isSubmitting
                    ? '정책을 찾는 중...'
                    : _step == 2
                        ? '내 정책 추천 보기'
                        : '다음',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicyAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _PolicyAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('맞춤 정책'));
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$step / 3',
      style: AppTextStyles.caption.copyWith(
        color: AppColors.primaryDeep,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SetupField extends StatelessWidget {
  const _SetupField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.enabled = true,
    this.errorText,
  });

  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;
  final bool enabled;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          enabled: enabled,
          suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
        child: Text(
          value ?? hint,
          style: value == null ? AppTextStyles.bodyMuted : AppTextStyles.body,
        ),
      ),
    );
  }
}

class _SituationChip extends StatelessWidget {
  const _SituationChip({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: Icon(
        icon,
        size: 18,
        color: selected ? AppColors.primaryDeep : AppColors.textSecondary,
      ),
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    );
  }
}

class _RecommendationLoading extends StatelessWidget {
  const _RecommendationLoading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(minHeight: 4),
        SizedBox(height: 12),
        Text('거주 지역과 나이에 맞는 정책을 확인하고 있어요.', style: AppTextStyles.caption),
      ],
    );
  }
}

class _NullableOption<T> {
  const _NullableOption({required this.value, required this.label});

  final T? value;
  final String label;
}
