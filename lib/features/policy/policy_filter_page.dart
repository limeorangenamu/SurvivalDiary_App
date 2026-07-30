import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/router/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/option_picker_sheet.dart';

class PolicyFilterPage extends StatefulWidget {
  const PolicyFilterPage({super.key});

  @override
  State<PolicyFilterPage> createState() => _PolicyFilterPageState();
}

class _PolicyFilterPageState extends State<PolicyFilterPage> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();

  String? _region;
  String? _district;
  PolicyEmploymentStatus? _employmentStatus;
  PolicyIncomeRange? _incomeRange;
  PolicyCategory? _category;
  bool _showSelectionErrors = false;

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
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
    final value = await _pick<String>(
      title: '시·도를 선택해 주세요',
      options: MockData.regions.keys.toList(),
      labelBuilder: (option) => option,
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
    if (region == null) {
      return;
    }
    final value = await _pick<String>(
      title: '구·군을 선택해 주세요',
      options: MockData.regions[region]!.keys.toList(),
      labelBuilder: (option) => option,
      selected: _district,
    );
    if (value != null && mounted) {
      setState(() => _district = value);
    }
  }

  Future<void> _pickEmploymentStatus() async {
    final value = await _pick<PolicyEmploymentStatus>(
      title: '취업 상태를 선택해 주세요',
      options: PolicyEmploymentStatus.values,
      labelBuilder: (option) => option.label,
      selected: _employmentStatus,
    );
    if (value != null && mounted) {
      setState(() => _employmentStatus = value);
    }
  }

  Future<void> _pickIncomeRange() async {
    final value = await _pick<PolicyIncomeRange>(
      title: '소득 조건을 선택해 주세요',
      options: PolicyIncomeRange.values,
      labelBuilder: (option) => option.label,
      selected: _incomeRange,
    );
    if (value != null && mounted) {
      setState(() => _incomeRange = value);
    }
  }

  Future<void> _pickCategory() async {
    final value = await _pick<PolicyCategory>(
      title: '관심 정책 분야를 선택해 주세요',
      options: PolicyCategory.values,
      labelBuilder: (option) => option.label,
      selected: _category,
    );
    if (value != null && mounted) {
      setState(() => _category = value);
    }
  }

  void _findPolicies() {
    FocusScope.of(context).unfocus();
    setState(() => _showSelectionErrors = true);

    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid || _region == null || _employmentStatus == null) {
      return;
    }

    Navigator.pushNamed(
      context,
      AppRoutes.policyResults,
      arguments: PolicyFilterCondition(
        age: int.parse(_ageController.text),
        region: _region!,
        district: _district,
        employmentStatus: _employmentStatus!,
        incomeRange: _incomeRange,
        category: _category,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('청년 정책 조건')),
      body: Form(
        key: _formKey,
        child: ListView(
          key: const PageStorageKey('policy-filter-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            const Text(
              '내 상황에 맞는 정책을 찾아볼까요?',
              style: AppTextStyles.title,
            ),
            const SizedBox(height: 8),
            const Text(
              '필수 조건 3가지를 입력하면 관련 정책을 추천해 드려요.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const ValueKey('policy-age-field'),
              controller: _ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: '나이 *',
                hintText: '만 나이를 입력해 주세요',
                suffixText: '세',
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
              value: _region,
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
              value: _district,
              hint: _region == null ? '시·도를 먼저 선택해 주세요' : '구·군을 선택해 주세요',
              enabled: _region != null,
              onTap: _pickDistrict,
            ),
            const SizedBox(height: 14),
            _SelectionField(
              key: const ValueKey('policy-employment-field'),
              label: '취업 상태 *',
              value: _employmentStatus?.label,
              hint: '현재 상태를 선택해 주세요',
              errorText: _showSelectionErrors && _employmentStatus == null
                  ? '취업 상태를 선택해 주세요.'
                  : null,
              onTap: _pickEmploymentStatus,
            ),
            const SizedBox(height: 14),
            _SelectionField(
              key: const ValueKey('policy-income-field'),
              label: '소득 조건',
              value: _incomeRange?.label,
              hint: '선택하지 않아도 돼요',
              onTap: _pickIncomeRange,
            ),
            const SizedBox(height: 14),
            _SelectionField(
              key: const ValueKey('policy-category-field'),
              label: '정책 분야',
              value: _category?.label,
              hint: '관심 분야를 선택해 주세요',
              onTap: _pickCategory,
            ),
            const SizedBox(height: 20),
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
                      '선택한 조건은 맞춤 정책 화면을 구성하는 데만 사용하며, '
                      '현재 단계에서는 서버나 기기에 저장하지 않습니다.',
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
            onPressed: _findPolicies,
            child: const Text('정책 찾기'),
          ),
        ),
      ),
    );
  }
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
        ),
      ),
    );
  }
}
