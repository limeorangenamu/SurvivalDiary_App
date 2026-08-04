import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/features/map/saving_map_page.dart';
import 'package:project_survival_diary/shared/widgets/pill_chip.dart';

void main() {
  testWidgets('지도는 MY 탭을 선택한 상태로 시작한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SavingMapPage()));

    final finder = find.widgetWithText(PillChip, 'MY');
    expect(finder, findsOneWidget);
    expect(tester.widget<PillChip>(finder).selected, isTrue);
    expect(find.text('전체'), findsNothing);
  });
}
