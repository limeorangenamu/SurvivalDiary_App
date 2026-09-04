import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/features/policy/data/policy_models.dart';
import 'package:project_survival_diary/features/policy/policy_application_period.dart';

void main() {
  final now = DateTime(2026, 5, 5, 23, 59);

  test('명시적으로 접수 마감이면 날짜가 없거나 미래여도 마감이다', () {
    for (final endDate in [null, DateTime(2026, 6, 1)]) {
      expect(
        isPolicyApplicationClosed(
          type: PolicyApplicationPeriodType.closed,
          endDate: endDate,
          now: now,
        ),
        isTrue,
      );
    }
  });

  test('어제 끝난 정책만 제외하고 오늘 마감은 당일 끝까지 표시한다', () {
    for (final day in [4, 5, 6]) {
      expect(
        isPolicyApplicationClosed(
          type: PolicyApplicationPeriodType.fixed,
          endDate: DateTime(2026, 5, day),
          now: now,
        ),
        day < 5,
      );
    }
  });

  test('상시·예산 소진·기간 미상·유형 누락은 종료일이 없으면 숨기지 않는다', () {
    for (final type in [
      PolicyApplicationPeriodType.always,
      PolicyApplicationPeriodType.untilBudget,
      PolicyApplicationPeriodType.unknown,
      null,
    ]) {
      expect(
        isPolicyApplicationClosed(type: type, endDate: null, now: now),
        isFalse,
      );
    }
  });

  test('서로 다른 연도의 신청 기간도 두 자리 연월일로 표시한다', () {
    expect(
      formatPolicyApplicationPeriod(
        type: PolicyApplicationPeriodType.fixed,
        startDate: DateTime(2026, 5, 5),
        endDate: DateTime(2027, 1, 9),
        text: '20260505~20270109',
      ),
      '26.05.05 ~ 27.01.09',
    );
  });

  test('하루만 신청할 수 있으면 날짜를 중복 표시하지 않는다', () {
    expect(
      formatPolicyApplicationPeriod(
        type: PolicyApplicationPeriodType.fixed,
        startDate: DateTime(2026, 5, 5),
        endDate: DateTime(2026, 5, 5),
        text: null,
      ),
      '26.05.05',
    );
  });

  test('시작일 또는 종료일만 있어도 확인된 날짜를 표시한다', () {
    expect(
      formatPolicyApplicationPeriod(
        type: null,
        startDate: null,
        endDate: DateTime(2026, 5, 5),
        text: null,
      ),
      '26.05.05까지',
    );
    expect(
      formatPolicyApplicationPeriod(
        type: null,
        startDate: DateTime(2026, 5, 5),
        endDate: null,
        text: null,
      ),
      '26.05.05부터',
    );
  });

  test('상시·마감·예산 소진 안내를 임의의 날짜로 바꾸지 않는다', () {
    final labels = {
      PolicyApplicationPeriodType.always: '상시 등록 · 공고 확인',
      PolicyApplicationPeriodType.closed: '접수 마감',
      PolicyApplicationPeriodType.untilBudget: '예산 소진 시까지',
      PolicyApplicationPeriodType.unknown: '신청 기간 확인 필요',
    };
    for (final entry in labels.entries) {
      expect(
        formatPolicyApplicationPeriod(
          type: entry.key,
          startDate: null,
          endDate: null,
          text: null,
        ),
        entry.value,
      );
    }
  });

  test('원문에만 날짜가 있어도 시간을 포함한 추가 안내를 유지한다', () {
    expect(
      formatPolicyApplicationPeriod(
        type: PolicyApplicationPeriodType.unknown,
        startDate: null,
        endDate: null,
        text: '1차 2026.5.5 09:00~2026/06/09 18:00 (예산 소진 시 조기 종료)',
      ),
      '1차 26.05.05 09:00 ~ 26.06.09 18:00 (예산 소진 시 조기 종료)',
    );
    expect(
      formatPolicyApplicationPeriodText('20260505~2026-06-09'),
      '26.05.05 ~ 26.06.09',
    );
  });

  test('잘못된 날짜나 기간 미정 문구는 추측하여 바꾸지 않는다', () {
    for (final text in ['2026.02.30', '2026-13-01', '기관별 일정 확인 필요']) {
      expect(formatPolicyApplicationPeriodText(text), text);
    }
  });

  test('상시 유형과 확정 날짜가 함께 오면 날짜를 우선 표시한다', () {
    expect(
      formatPolicyApplicationPeriod(
        type: PolicyApplicationPeriodType.always,
        startDate: DateTime(2026, 5, 1),
        endDate: DateTime(2026, 5, 5),
        text: '상시',
      ),
      '26.05.01 ~ 26.05.05',
    );
  });
}
