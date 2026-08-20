import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/core/services/public_parking_api_service.dart';
import 'package:project_survival_diary/features/map/widgets/public_parking_map_card.dart';
import 'package:project_survival_diary/features/map/place_expense_summary.dart';

void main() {
  testWidgets('공영주차장 배너에서 찜 버튼을 제공한다', (tester) async {
    var favoriteTapCount = 0;
    final parkingLot = PublicParkingLot.fromJson({
      'id': 'parking-1',
      'name': '역삼 공영주차장',
      'parkingType': '노외',
      'address': '서울 강남구',
      'free': true,
      'distanceMeters': 250,
    });
    final spendingSummary = PlaceExpenseSummary(
      totalAmount: 4000,
      paymentCount: 2,
      latestAmount: 2000,
      latestDate: DateTime(2026, 8, 20),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 270,
            height: 184,
            child: PublicParkingMapCard(
              parkingLot: parkingLot,
              isFavorite: false,
              onFavoritePressed: () => favoriteTapCount++,
              onDirectionsPressed: () {},
              onTap: () {},
              spendingSummary: spendingSummary,
            ),
          ),
        ),
      ),
    );

    expect(find.text('여기서 총 4,000원'), findsOneWidget);
    expect(find.text('2회'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('public-parking-favorite-button')),
    );

    expect(favoriteTapCount, 1);
  });
}
