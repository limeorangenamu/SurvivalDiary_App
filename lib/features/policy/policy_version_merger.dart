import 'data/policy_models.dart';

/// 페이지 순서와 무관하게 같은 공고의 최신 등록본을 유지한다.
/// 서버가 중복 근거를 주지 않은 예전 응답은 정책 번호만으로 구분한다.
List<PolicySummary> mergePolicyVersions(Iterable<PolicySummary> policies) {
  final byId = <String, PolicySummary>{};
  for (final policy in policies) {
    final previous = byId[policy.policyId];
    if (previous == null || _isNewer(policy, previous)) {
      byId[policy.policyId] = policy;
    }
  }
  final latest = <String, PolicySummary>{};
  for (final policy in byId.values) {
    final canonicalKey = policy.canonicalPolicyKey;
    final key = canonicalKey != null &&
            canonicalKey.isNotEmpty &&
            policy.sourceUpdatedAt != null
        ? 'canonical:$canonicalKey'
        : 'id:${policy.policyId}';
    final previous = latest[key];
    if (previous == null || _isNewer(policy, previous)) {
      latest[key] = policy;
    }
  }
  return latest.values.toList();
}

bool _isNewer(PolicySummary policy, PolicySummary previous) =>
    policy.sourceUpdatedAt != null &&
    (previous.sourceUpdatedAt == null ||
        policy.sourceUpdatedAt!.isAfter(previous.sourceUpdatedAt!));
