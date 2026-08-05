import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/core/services/public_facility_api_service.dart';
import 'package:project_survival_diary/features/map/widgets/public_facility_map_card.dart';

void main() {
  testWidgets('공공시설 카드에서 요금과 거리 및 길찾기를 제공한다', (tester) async {
    var directionsTapCount = 0;
    var detailTapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 270,
              height: 158,
              child: PublicFacilityMapCard(
                facility: _facility,
                onDirectionsPressed: () => directionsTapCount++,
                onTap: () => detailTapCount++,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('청년센터 세미나실'), findsOneWidget);
    expect(find.text('회의실'), findsOneWidget);
    expect(find.text('무료'), findsOneWidget);
    expect(find.text('320m'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('public-facility-directions-button')),
    );
    await tester.pump();
    expect(directionsTapCount, 1);

    await tester.tap(find.byKey(const ValueKey('public-facility-card')));
    await tester.pump();
    expect(detailTapCount, 1);
  });
}

const _facility = PublicFacility(
  id: 'facility-id',
  name: '청년센터 세미나실',
  locationName: '청년센터',
  category: '회의실',
  address: '서울특별시 종로구 세종대로 1',
  phone: '02-000-0000',
  latitude: 37.57,
  longitude: 126.98,
  distanceMeters: 320,
  paid: false,
  fee: '무료',
  weekdayHours: '09:00~18:00',
  weekendHours: '10:00~17:00',
  closedDays: '연중무휴',
  institution: '서울특별시',
  department: '청년정책과',
  homepageUrl: 'https://example.com',
  imageUrl: '',
  capacity: '20',
  area: '50',
  amenities: '와이파이',
  applicationMethod: '온라인',
  referenceDate: '2026-08-01',
);
