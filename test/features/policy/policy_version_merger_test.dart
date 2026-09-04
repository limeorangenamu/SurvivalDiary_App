import 'package:flutter_test/flutter_test.dart';
import 'package:project_survival_diary/features/policy/data/policy_models.dart';
import 'package:project_survival_diary/features/policy/policy_version_merger.dart';

void main() {
  test('같은 공고의 최신 마감본을 페이지 순서와 무관하게 선택한다', () {
    final old = _policy('old', '2026-07-02T18:09:55', 'ALWAYS');
    final closed = _policy('closed', '2026-07-24T10:27:10', 'CLOSED');
    expect(mergePolicyVersions([old, closed]), [closed]);
    expect(mergePolicyVersions([closed, old]), [closed]);
  });

  test('같은 날에 수정된 상태도 시각을 버리지 않고 비교한다', () {
    final old = _policy('old', '2026-07-24T09:00:00', 'ALWAYS');
    final closed = _policy('closed', '2026-07-24T10:27:10', 'CLOSED');
    expect(closed.sourceUpdatedAt!.hour, 10);
    expect(closed.sourceUpdatedAt!.minute, 27);
    expect(mergePolicyVersions([old, closed]), [closed]);
  });

  test('재모집된 최신 상시본을 이전 마감 상태로 되돌리지 않는다', () {
    final closed = _policy('closed', '2026-07-24T10:27:10', 'CLOSED');
    final reopened = _policy('new', '2026-08-01T10:00:00', 'ALWAYS');
    expect(mergePolicyVersions([closed, reopened]), [reopened]);
  });

  test('중복 근거가 없으면 제목이 같아도 서로 다른 정책을 유지한다', () {
    final a = _policy('a', '2026-07-02T18:09:55', 'ALWAYS', key: null);
    final b = _policy('b', '2026-07-24T10:27:10', 'CLOSED', key: null);
    expect(mergePolicyVersions([a, b, a]), [a, b]);
  });

  test('새 메타데이터가 없거나 잘못돼도 목록 전체를 불러오지 못하는 오류는 내지 않는다', () {
    final a = _policy('a', null, 'ALWAYS');
    final b = _policy('b', '날짜 미상', 'CLOSED');
    expect(a.sourceUpdatedAt, isNull);
    expect(b.sourceUpdatedAt, isNull);
    expect(mergePolicyVersions([a, b]), [a, b]);
  });

  test('같은 정책 번호의 제목이나 링크가 수정돼도 카드는 하나만 유지한다', () {
    final old =
        _policy('same-id', '2026-07-02T18:09:55', 'ALWAYS', key: 'old-key');
    final changed =
        _policy('same-id', '2026-07-24T10:27:10', 'CLOSED', key: 'new-key');
    expect(mergePolicyVersions([old, changed]), [changed]);
  });
}

PolicySummary _policy(String id, String? updatedAt, String type,
        {String? key = 'same-application'}) =>
    PolicySummary.fromJson({
      'policyId': id,
      'title': '같은 정책명',
      'category': '일자리',
      'summary': '정책 요약',
      'supportText': '지원 내용',
      'target': '청년',
      'agency': '운영 기관',
      'applicationPeriodType': type,
      'canonicalPolicyKey': key,
      'sourceUpdatedAt': updatedAt,
    });
