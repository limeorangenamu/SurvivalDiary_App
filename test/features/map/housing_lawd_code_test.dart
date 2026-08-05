import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/features/map/housing_lawd_code.dart';

void main() {
  test('지도 지역명을 국토교통부 법정동 코드로 변환한다', () {
    expect(
      housingLawdCodeFor(province: '부산광역시', district: '부산진구'),
      '26230',
    );
    expect(
      housingLawdCodeFor(province: '서울특별시', district: '강남구'),
      '11680',
    );
    expect(
      housingLawdCodeFor(province: '알 수 없음', district: '알 수 없음'),
      isNull,
    );
  });
}
