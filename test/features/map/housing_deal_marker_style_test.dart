import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/features/map/housing_deal_marker_style.dart';

void main() {
  test('단독다가구와 오피스텔은 서로 다른 마커를 사용한다', () {
    final singleFamily = HousingDealMarkerStyle.fromPropertyType('단독/다가구');
    final officetel = HousingDealMarkerStyle.fromPropertyType('오피스텔');

    expect(singleFamily.color, isNot(officetel.color));
    expect(singleFamily.icon, Icons.home_work_rounded);
    expect(officetel.icon, Icons.apartment_rounded);
  });
}
