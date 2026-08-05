import '../../data/mock_data.dart';

String? housingLawdCodeFor({
  required String province,
  required String district,
}) {
  final normalizedProvince = province.trim();
  final normalizedDistrict = district.trim();
  if (normalizedProvince.isEmpty || normalizedDistrict.isEmpty) {
    return null;
  }
  for (final region in MockData.policyRegions) {
    final provinceMatches = region.name == normalizedProvince ||
        region.name.startsWith(normalizedProvince) ||
        normalizedProvince.startsWith(region.name);
    if (!provinceMatches) {
      continue;
    }
    for (final option in region.districts) {
      if (option.name == normalizedDistrict) {
        return option.code;
      }
    }
  }
  return null;
}
