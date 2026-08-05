import 'package:flutter/material.dart';

import '../../core/router/app_routes.dart';
import '../../core/services/housing_rent_api_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/mock_data.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/option_picker_sheet.dart';

class HousingRegionPage extends StatefulWidget {
  const HousingRegionPage({super.key});

  @override
  State<HousingRegionPage> createState() => _HousingRegionPageState();
}

class _HousingRegionPageState extends State<HousingRegionPage> {
  String? _province;
  String? _district;
  String? _neighborhood;

  bool get _isComplete =>
      _province != null && _district != null && _neighborhood != null;

  String? get _lawdCode {
    final province = _province;
    final district = _district;
    final neighborhood = _neighborhood;
    if (province == null || district == null || neighborhood == null) {
      return null;
    }
    const neighborhoodCodes = {
      '경기도|성남시|정자동': '41135',
      '경기도|성남시|서현동': '41135',
      '경기도|성남시|야탑동': '41135',
      '경기도|수원시|인계동': '41115',
      '경기도|수원시|영통동': '41117',
      '경기도|수원시|매탄동': '41117',
    };
    final neighborhoodCode =
        neighborhoodCodes['$province|$district|$neighborhood'];
    if (neighborhoodCode != null) {
      return neighborhoodCode;
    }
    for (final region in MockData.policyRegions) {
      if (region.name != province) {
        continue;
      }
      for (final option in region.districts) {
        if (option.name == district) {
          return option.code;
        }
      }
    }
    return null;
  }

  Future<void> _selectProvince() async {
    final result = await showOptionPickerSheet<String>(
      context: context,
      title: '시·도를 선택해 주세요',
      options: MockData.regions.keys.toList(),
      labelBuilder: (value) => value,
      selected: _province,
    );
    if (result != null && mounted) {
      setState(() {
        _province = result;
        _district = null;
        _neighborhood = null;
      });
    }
  }

  Future<void> _selectDistrict() async {
    if (_province == null) {
      return;
    }
    final result = await showOptionPickerSheet<String>(
      context: context,
      title: '시·군·구를 선택해 주세요',
      options: MockData.regions[_province]!.keys.toList(),
      labelBuilder: (value) => value,
      selected: _district,
    );
    if (result != null && mounted) {
      setState(() {
        _district = result;
        _neighborhood = null;
      });
    }
  }

  Future<void> _selectNeighborhood() async {
    if (_province == null || _district == null) {
      return;
    }
    final result = await showOptionPickerSheet<String>(
      context: context,
      title: '읍·면·동을 선택해 주세요',
      options: MockData.regions[_province]![_district]!,
      labelBuilder: (value) => value,
      selected: _neighborhood,
    );
    if (result != null && mounted) {
      setState(() => _neighborhood = result);
    }
  }

  void _search() {
    final lawdCode = _lawdCode;
    if (lawdCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('선택한 지역의 법정동 코드를 확인하지 못했어요.')),
      );
      return;
    }
    final region = '$_province $_district $_neighborhood';
    Navigator.pushNamed(
      context,
      AppRoutes.housingDeal,
      arguments: HousingRentSearchCondition(
        region: region,
        lawdCode: lawdCode,
        neighborhood: _neighborhood!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('주거 실거래 지역 선택')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const AppCard(
                      color: AppColors.primarySoft,
                      borderColor: AppColors.primarySoft,
                      child: Row(
                        children: [
                          Icon(
                            Icons.apartment_rounded,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '지역을 세 단계로 선택하면 최근 3개월의 실제 거래를 보여드려요.',
                              style: AppTextStyles.body,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _RegionPicker(
                      key: const ValueKey('province-picker'),
                      step: '1',
                      label: '시·도',
                      value: _province,
                      enabled: true,
                      onTap: _selectProvince,
                    ),
                    const SizedBox(height: 12),
                    _RegionPicker(
                      key: const ValueKey('district-picker'),
                      step: '2',
                      label: '시·군·구',
                      value: _district,
                      enabled: _province != null,
                      onTap: _selectDistrict,
                    ),
                    const SizedBox(height: 12),
                    _RegionPicker(
                      key: const ValueKey('neighborhood-picker'),
                      step: '3',
                      label: '읍·면·동',
                      value: _neighborhood,
                      enabled: _district != null,
                      onTap: _selectNeighborhood,
                    ),
                    if (_isComplete) ...[
                      const SizedBox(height: 20),
                      AppCard(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '$_province $_district $_neighborhood',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                key: const ValueKey('housing-search-button'),
                onPressed: _isComplete ? _search : null,
                child: const Text('실거래 조회'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegionPicker extends StatelessWidget {
  const _RegionPicker({
    super.key,
    required this.step,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  final String step;
  final String label;
  final String? value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: enabled ? AppColors.surface : AppColors.surfaceAlt,
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: enabled ? AppColors.primarySoft : AppColors.border,
            foregroundColor:
                enabled ? AppColors.primaryDeep : AppColors.textTertiary,
            child: Text(step, style: AppTextStyles.caption),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.captionTiny),
                const SizedBox(height: 3),
                Text(
                  value ?? (enabled ? '$label 선택' : '이전 지역을 먼저 선택하세요'),
                  style: value == null
                      ? AppTextStyles.bodyMuted
                      : AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: enabled ? onTap : null,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
          ),
        ],
      ),
    );
  }
}
