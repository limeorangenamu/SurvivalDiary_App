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
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();

  late final PolicyApiClient _apiClient;
  late final PolicyAccessTokenProvider _accessTokenProvider;

  PolicyRegionOption? _region;
  PolicyDistrictOption? _district;
  PolicyWorkStatus? _workStatus;
  bool? _jobSeeking;
  PolicyEducationStatus? _educationStatus;
  final Set<PolicyInterest> _interests = {};
  PolicyCategory? _category;
  PolicyFilterCondition? _activeCondition;
  int? _profileAge;
  String? _preferenceLoadMessage;
  bool _isLoadingPreference = true;
  bool _isSubmitting = false;
  bool _showSelectionErrors = false;
  bool _saveAsDefault = true;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _apiClient = widget.apiClient ?? PolicyApiClient();
    _accessTokenProvider =
        widget.accessTokenProvider ?? (() => AuthSession.instance.accessToken);
    _saveAsDefault = _hasAccessToken;
    _loadPreference();
  }

  bool get _hasAccessToken {
    final token = _accessTokenProvider();
    return token != null && token.isNotEmpty;
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

      final condition = _conditionFrom(preference);
      _profileAge = preference.age;
      if (condition != null) {
        _applyCondition(condition);
      }
      setState(() {
        _activeCondition = condition;
        _showResults = condition != null;
        _isLoadingPreference = false;
        if (preference.saved && condition == null) {
          _preferenceLoadMessage = preference.age == null
              ? '회원 정보에 생년월일이 없어 나이를 한 번 입력해 주세요.'
              : '저장된 지역 정보를 확인할 수 없어 조건을 다시 선택해 주세요.';
        }
      });
    } on PolicyApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingPreference = false;
        _preferenceLoadMessage = '${error.message} 직접 조건을 입력할 수 있어요.';
      });
    }
  }

  PolicyFilterCondition? _conditionFrom(PolicyPreference preference) {
    if (!preference.saved ||
        preference.age == null ||
        preference.age! < 18 ||
        preference.age! > 39 ||
        preference.regionCode == null) {
      if (preference.age != null) {
        _ageController.text = preference.age.toString();
      }
      return null;
    }

    PolicyRegionOption? region;
    for (final option in MockData.policyRegions) {
      if (option.code == preference.regionCode) {
        region = option;
        break;
      }
    }
    if (region == null) {
      return null;
    }

    PolicyDistrictOption? district;
    if (preference.districtCode != null) {
      for (final option in region.districts) {
        if (option.code == preference.districtCode) {
          district = option;
          break;
        }
      }
      if (district == null) {
        return null;
      }
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
    _interests
      ..clear()
      ..addAll(condition.interests);
    _category = condition.category;
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
      title: '시·도를 선택해 주세요',
      options: MockData.policyRegions,
      labelBuilder: (option) => option.name,
      selected: _region,
    );
    if (value != null && mounted) {
      setState(() {
        if (_region != value) {
          _district = null;
        }
        _region = value;
      });
    }
  }

  Future<void> _pickDistrict() async {
    final region = _region;
    if (region == null || region.districts.isEmpty) {
      return;
    }
    final options = [
      const _OptionalOption<PolicyDistrictOption>(value: null, label: '시·도 전체'),
      for (final district in region.districts)
        _OptionalOption(value: district, label: district.name),
    ];
    final value = await _pick<_OptionalOption<PolicyDistrictOption>>(
      title: '구·군을 선택해 주세요',
      options: options,
      labelBuilder: (option) => option.label,
      selected: options.firstWhere(
        (option) => option.value == _district,
        orElse: () => options.first,
      ),
    );
    if (value != null && mounted) {
      setState(() => _district = value.value);
    }
  }

  Future<void> _pickWorkStatus() async {
    final options = [
      const _OptionalOption<PolicyWorkStatus>(value: null, label: '잘 모르겠어요'),
      for (final status in PolicyWorkStatus.values)
        _OptionalOption(value: status, label: status.label),
    ];
    final value = await _pick<_OptionalOption<PolicyWorkStatus>>(
      title: '근로 상태를 선택해 주세요',
      options: options,
      labelBuilder: (option) => option.label,
      selected: options.firstWhere(
        (option) => option.value == _workStatus,
        orElse: () => options.first,
      ),
    );
    if (value != null && mounted) {
      setState(() => _workStatus = value.value);
    }
  }

  Future<void> _pickJobSeeking() async {
    const options = [
      _OptionalOption<bool>(value: null, label: '선택하지 않음'),
      _OptionalOption(value: true, label: '구직 중'),
      _OptionalOption(value: false, label: '구직 중이 아님'),
    ];
    final value = await _pick<_OptionalOption<bool>>(
      title: '현재 구직 중인가요?',
      options: options,
      labelBuilder: (option) => option.label,
      selected: options.firstWhere(
        (option) => option.value == _jobSeeking,
        orElse: () => options.first,
      ),
    );
    if (value != null && mounted) {
      setState(() => _jobSeeking = value.value);
    }
  }

  Future<void> _pickEducationStatus() async {
    final options = [
      const _OptionalOption<PolicyEducationStatus>(
        value: null,
        label: '잘 모르겠어요',
      ),
      for (final status in PolicyEducationStatus.values)
        _OptionalOption(value: status, label: status.label),
    ];
    final value = await _pick<_OptionalOption<PolicyEducationStatus>>(
      title: '교육 상태를 선택해 주세요',
      options: options,
      labelBuilder: (option) => option.label,
      selected: options.firstWhere(
        (option) => option.value == _educationStatus,
        orElse: () => options.first,
      ),
    );
    if (value != null && mounted) {
      setState(() => _educationStatus = value.value);
    }
  }

  Future<void> _pickCategory() async {
    final options = [
      const _OptionalOption<PolicyCategory>(value: null, label: '전체'),
      for (final category in PolicyCategory.values)
        _OptionalOption(value: category, label: category.label),
    ];
    final value = await _pick<_OptionalOption<PolicyCategory>>(
      title: '관심 정책 분야를 선택해 주세요',
      options: options,
      labelBuilder: (option) => option.label,
      selected: options.firstWhere(
        (option) => option.value == _category,
        orElse: () => options.first,
      ),
    );
    if (value != null && mounted) {
      setState(() => _category = value.value);
    }
  }

  Future<void> _findPolicies() async {
    if (_isSubmitting) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _showSelectionErrors = true);

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid || _region == null) {
      return;
    }

    final accessToken = _accessTokenProvider();
    if (accessToken == null || accessToken.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('정책을 조회하려면 먼저 로그인해 주세요.')));
      return;
    }

    final condition = PolicyFilterCondition(
      age: int.parse(_ageController.text),
      regionCode: _region!.code,
      region: _region!.name,
      districtCode: _district?.code,
      district: _district?.name,
      workStatus: _workStatus,
      jobSeeking: _jobSeeking,
      educationStatus: _educationStatus,
      interests: Set.unmodifiable(_interests),
      category: _category,
    );

    setState(() => _isSubmitting = true);
    try {
      if (_saveAsDefault) {
        await _apiClient.savePolicyPreference(
          accessToken: accessToken,
          condition: condition,
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _activeCondition = condition;
        _showResults = true;
        _preferenceLoadMessage = null;
      });
    } on PolicyApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _editCondition() {
    setState(() {
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPreference) {
      return const Scaffold(
        appBar: _PolicyFilterAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final activeCondition = _activeCondition;
    if (_showResults && activeCondition != null) {
      return PolicyListPage(
        key: ValueKey(
          'saved-policy-${activeCondition.regionCode}-'
          '${activeCondition.districtCode}-${activeCondition.category}',
        ),
        condition: activeCondition,
        apiClient: _apiClient,
        accessTokenProvider: _accessTokenProvider,
        onEditCondition: _editCondition,
      );
    }

    return Scaffold(
      appBar: const _PolicyFilterAppBar(),
      body: Form(
        key: _formKey,
        child: ListView(
          key: const PageStorageKey('policy-filter-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            const Text('내 상황에 맞는 정책을 찾아볼까요?', style: AppTextStyles.title),
            const SizedBox(height: 8),
            const Text(
              '나이와 거주 지역을 기준으로 넓게 찾고, 선택 정보는 추천 순서에 반영해요.',
              style: AppTextStyles.bodyMuted,
            ),
            if (_preferenceLoadMessage != null) ...[
              const SizedBox(height: 14),
              AppCard(
                color: AppColors.warningSoft,
                borderColor: AppColors.warningSoft,
                padding: const EdgeInsets.all(12),
                child: Text(
                  _preferenceLoadMessage!,
                  style: AppTextStyles.caption,
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('policy-age-field'),
              controller: _ageController,
              readOnly: _profileAge != null,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: '나이 *',
                hintText: '만 나이를 입력해 주세요',
                suffixText: '세',
                helperText: _profileAge == null ? null : '회원 생년월일 기준',
              ),
              validator: (value) {
                final age = int.tryParse(value ?? '');
                if (age == null) {
                  return '나이를 입력해 주세요.';
                }
                if (age < 18 || age > 39) {
                  return '만 18~39세 범위로 입력해 주세요.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            _SelectionField(
              key: const ValueKey('policy-region-field'),
              label: '시·도 *',
              value: _region?.name,
              hint: '거주 지역을 선택해 주세요',
              errorText: _showSelectionErrors && _region == null
                  ? '시·도를 선택해 주세요.'
                  : null,
              onTap: _pickRegion,
            ),
            const SizedBox(height: 14),
            _SelectionField(
              key: const ValueKey('policy-district-field'),
              label: '구·군',
              value: _region == null ? null : _district?.name ?? '시·도 전체',
              hint: _region == null
                  ? '시·도를 먼저 선택해 주세요'
                  : _region!.districts.isEmpty
                      ? '시·도 전체'
                      : '시·도 전체',
              enabled: _region?.districts.isNotEmpty ?? false,
              onTap: _pickDistrict,
            ),
            const SizedBox(height: 14),
            _SelectionField(
              key: const ValueKey('policy-work-status-field'),
              label: '근로 상태',
              value: _workStatus?.label ?? '잘 모르겠어요',
              hint: '잘 모르겠어요',
              onTap: _pickWorkStatus,
            ),
            const SizedBox(height: 14),
            _SelectionField(
              key: const ValueKey('policy-job-seeking-field'),
              label: '구직 여부',
              value: switch (_jobSeeking) {
                true => '구직 중',
                false => '구직 중이 아님',
                null => '선택하지 않음',
              },
              hint: '선택하지 않음',
              onTap: _pickJobSeeking,
            ),
            const SizedBox(height: 14),
            _SelectionField(
              key: const ValueKey('policy-education-status-field'),
              label: '교육 상태',
              value: _educationStatus?.label ?? '잘 모르겠어요',
              hint: '잘 모르겠어요',
              onTap: _pickEducationStatus,
            ),
            const SizedBox(height: 14),
            _SelectionField(
              key: const ValueKey('policy-category-field'),
              label: '지금 둘러볼 정책 분야',
              value: _category?.label ?? '전체',
              hint: '전체',
              onTap: _pickCategory,
            ),
            const SizedBox(height: 18),
            const Text('관심 주제', style: AppTextStyles.sectionTitle),
            const SizedBox(height: 6),
            const Text(
              '복수 선택할 수 있으며, 선택하지 않아도 모든 분야를 확인할 수 있어요.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 10),
            Wrap(
              key: const ValueKey('policy-interest-options'),
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final interest in PolicyInterest.values)
                  FilterChip(
                    key: ValueKey('policy-interest-${interest.name}'),
                    label: Text(interest.label),
                    selected: _interests.contains(interest),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _interests.add(interest);
                        } else {
                          _interests.remove(interest);
                        }
                      });
                    },
                  ),
              ],
            ),
            if (_hasAccessToken) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                key: const ValueKey('policy-save-default-checkbox'),
                value: _saveAsDefault,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  '이 조건을 기본 조건으로 저장',
                  style: AppTextStyles.body,
                ),
                subtitle: const Text(
                  '다음부터 조건을 다시 입력하지 않고 추천을 확인할 수 있어요.',
                  style: AppTextStyles.caption,
                ),
                onChanged: (value) =>
                    setState(() => _saveAsDefault = value ?? false),
              ),
            ],
            const SizedBox(height: 8),
            const AppCard(
              color: AppColors.primarySoft,
              borderColor: AppColors.primarySoft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: AppColors.primaryDeep,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '기본 조건은 로그인한 계정에 저장되며 맞춤 정책 조회에만 사용합니다. '
                      '소득은 기본 조건으로 저장하지 않으며, 다른 사용자에게 공개되지 않습니다.',
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: FilledButton(
            key: const ValueKey('policy-search-button'),
            onPressed: _isSubmitting ? null : _findPolicies,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _saveAsDefault && _hasAccessToken ? '저장하고 정책 찾기' : '정책 찾기',
                  ),
          ),
        ),
      ),
    );
  }
}

class _PolicyFilterAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _PolicyFilterAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('청년 정책 조건'));
  }
}

class _OptionalOption<T> {
  const _OptionalOption({required this.value, required this.label});

  final T? value;
  final String label;
}

class _SelectionField extends StatelessWidget {
  const _SelectionField({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;
  final String? errorText;
  final bool enabled;

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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
