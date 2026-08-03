# 앱 청년정책 기능 구현 계획

## 1. 문서 목적

이 문서는 Flutter 앱의 청년정책 기능을 단계별로 구현하기 위한 실행 계획이다.
1차로 MockData 기반 UI 흐름을 완성했고, 2차로 실제 백엔드 API 목록·상세 조회를 연결했다.

- 최초 작성일: 2026-07-30
- 최근 갱신일: 2026-08-03
- 대상 저장소: `limeorangenamu/SurvivalDiary_App`
- 관련 이슈:
  - [#8 청년정책 조건 입력 화면 구성](https://github.com/limeorangenamu/SurvivalDiary_App/issues/8)
  - [#9 맞춤 정책 목록·상세·공식 페이지 이동 흐름 구성](https://github.com/limeorangenamu/SurvivalDiary_App/issues/9)

## 구현 결과

- 1차 작업 브랜치: `limeorangenamu/feat/policy-filter-flow`
- 2차 작업 브랜치: `limeorangenamu/feat/policy-api-integration`
- 구현 상태: 앱 이슈 #8, #9의 UI 흐름 및 실제 정책 목록·상세 API 연동 완료
- 지역 조건: 전국 17개 시·도와 시·군·구 선택 및 공식 코드 분리 완료
- API 연동: 인증된 사용자의 조건을 `POST /api/policies/search`로 전송하고 정책 ID로 상세 조회
- 정책 API·화면 테스트: 13개 통과
- 조건 저장과 실제 외부 브라우저 실행은 후속 단계로 유지
- 지역 코드 계약: `docs/policy/region-code-contract.md`

## 2. 1차 UI 구현 범위

### 포함

- 나이, 지역, 구·군, 취업 상태, 소득 조건, 정책 분야 입력 UI
- 필수값 검증과 개인정보 안내
- 조건 입력 → 정책 목록 → 정책 상세 → 공식 페이지 이동 확인 흐름
- MockData를 사용한 조건별 결과, 빈 결과, 정렬 상태
- 마감일과 지원금이 없는 경우의 대체 문구
- 기존 관심 없음 처리와 실행 취소 동작 유지
- 좁은 화면에서의 텍스트 잘림과 overflow 검증

### 제외

- Spring Boot API 호출
- 사용자 조건 서버 저장
- 로컬 DB와 상태 관리 라이브러리 도입
- 실제 신청 자격 판정
- 실제 정책 신청
- 외부 브라우저 실행
- API 키 또는 비밀값 저장

## 3. 1차 구현 전 코드 기준

현재 정책 탭은 `PolicyListPage`를 바로 표시한다.

- `lib/features/root/root_shell.dart`
  - 정책 탭에서 `PolicyListPage` 사용
- `lib/features/policy/policy_list_page.dart`
  - MockData 목록, 나이·지역·취업 필터, 정렬, 관심 없음 구현
- `lib/features/policy/policy_detail_page.dart`
  - 상세 정보와 신청 안내 목업 구현
- `lib/data/models.dart`
  - `Policy` 모델 존재
- `lib/data/mock_data.dart`
  - 정책 더미 데이터 존재
- `lib/core/router/app_routes.dart`
  - 정책 상세 라우트만 존재
- `lib/core/router/app_router.dart`
  - 상세 화면에 `Policy` 객체 전체를 전달

현재 화면을 버리지 않고 조건 입력 화면과 이동 구조를 앞에 추가한다.

## 4. 목표 화면 흐름

```text
정책 탭
  ↓
PolicyFilterPage
  ↓ 정책 찾기
PolicyListPage
  ↓ 정책 선택
PolicyDetailPage
  ↓ 신청 안내 보기
PolicyExternalLinkConfirmPage
```

1차 구현에서는 마지막 확인 화면까지만 이동한다. 실제 외부 브라우저는 열지 않는다.

## 5. 권장 모델

### PolicyFilterCondition

공통 정책 데이터 계약을 한곳에서 확인할 수 있도록 `lib/data/models.dart`에 다음 값을 정의한다.

```text
age
region
district
employmentStatus
incomeRange
category
```

구현 원칙:

- 나이는 `int`로 보관한다.
- 지역과 구·군은 화면 표시 문자열과 내부 식별값을 분리할 수 있게 작성한다.
- 취업 상태, 소득 구간, 정책 분야는 enum과 한국어 label extension 사용을 권장한다.
- `PolicyListPage`에는 개별 문자열 여러 개가 아니라 `PolicyFilterCondition` 하나를 전달한다.
- 실제 API 연동 전까지 조건은 메모리에만 유지한다.

### Policy 모델 보완

현재 필드를 유지하되 다음 후속 API 필드를 고려한다.

```text
id: String
supportAmount: int?
supportText: String
deadline: String?
officialUrl: String?
contact: String?
```

1차 작업에서 API 모델 전체를 미리 구현하지 않는다. 다만 지원금과 마감이 없을 수 있다는 전제는 UI에 반영한다.

## 6. 단계별 구현

### 단계 0. 작업 시작 준비

- [x] 기존 `lib/core/config/app_config.dart` 수정사항의 내용을 확인한다.
- [x] 기존 변경을 덮어쓰지 않고 커밋 범위에서 제외한다.
- [x] 현재 `main` 기준 코드와 로컬 상태를 확인한다.
- [x] `{name}/feat/policy-filter-flow` 형식의 작업 브랜치를 만든다.
- [ ] #8과 #9를 한 PR로 처리할지, 이슈별 PR로 분리할지 팀과 합의한다.

권장 분리:

1. `{name}/feat/policy-filter-flow` — #8
2. `{name}/feat/policy-result-detail-flow` — #9

### 단계 1. 조건 모델과 라우트 구성

- [x] `PolicyFilterCondition`을 추가한다.
- [x] 취업 상태, 소득 구간, 정책 분야 선택값을 정의한다.
- [x] `AppRoutes`에 정책 결과 화면과 외부 이동 확인 화면 라우트를 추가한다.
- [x] `AppRouter`에 각 화면을 연결한다.
- [x] 정책 상세 화면에 전체 `Policy` 대신 `policyId`를 전달하도록 정리한다.
- [x] 잘못된 라우트 인자일 때 빈 화면이나 예외 대신 안내 화면을 표시한다.

권장 라우트:

```text
/policy-results
/policy-detail
/policy-external-link-confirm
```

### 단계 2. 조건 입력 화면 구현

- [x] `PolicyFilterPage`를 생성한다.
- [x] 만 18~39세 나이 입력 UI를 만든다.
- [x] 시·도 선택 후 구·군 선택 UI가 활성화되도록 한다.
- [x] 취업 상태를 선택한다.
- [x] 소득 구간을 선택한다.
- [x] 정책 분야를 선택한다.
- [x] 필수값 미선택 시 각 항목 아래에 인라인 오류를 표시한다.
- [x] 정책 찾기 버튼을 누르면 `PolicyFilterCondition`을 목록 화면에 전달한다.
- [x] 다음 개인정보 안내를 화면에 표시한다.

권장 안내 문구:

> 선택한 조건은 맞춤 정책 화면을 구성하는 데만 사용하며, 현재 단계에서는 서버나 기기에 저장하지 않습니다.

필수값 권장안:

- 필수: 나이, 시·도, 취업 상태
- 선택: 구·군, 소득 구간, 정책 분야

선택지와 필수 여부가 팀 결정과 달라지면 구현 전에 이 문서를 갱신한다.

### 단계 3. 정책 목록 화면 연결

- [x] `PolicyListPage`가 `PolicyFilterCondition`을 받도록 변경한다.
- [x] 선택 조건을 상단 요약 칩으로 표시한다.
- [x] 조건 수정 버튼으로 조건 입력 화면에 돌아간다.
- [x] MockData의 나이·지역·취업·소득·분야 메타데이터로 결과를 필터링한다.
- [x] 필터 결과가 없을 때 빈 결과 화면을 표시한다.
- [x] 빈 결과와 조건 수정 동작에서 조건 화면으로 돌아간다.
- [x] 추천순, 마감 임박순, 지원금순 UI를 유지한다.
- [x] 마감일이 없는 정책은 마감 임박순의 마지막에 배치한다.
- [x] 지원금이 없는 정책은 지원금순의 마지막에 배치한다.
- [x] 관심 없음과 실행 취소가 필터 결과에서도 정상 동작하는지 확인한다.

MockData 필터는 실제 자격 판정처럼 표현하지 않는다.

권장 문구:

> 입력한 조건과 관련된 정책을 보여드려요. 실제 신청 자격은 공식 공고에서 확인해 주세요.

### 단계 4. 상세와 외부 이동 확인 화면 구현

- [x] 목록에서 선택한 정책 ID로 상세 데이터를 찾는다.
- [x] 없는 ID는 “정책 정보를 찾을 수 없어요” 상태로 처리한다.
- [x] 정책명, 분야, 대상, 지원 내용, 지원금, 신청 기간, 주관 기관, 신청 방법, 제출 서류를 표시한다.
- [x] 지원금이 없으면 “지원 내용 확인”을 표시한다.
- [x] 마감일이 없으면 “신청 기간 확인 필요”를 표시한다.
- [x] 공식 URL이 없으면 신청 안내 버튼을 비활성화한다.
- [x] 신청 안내 버튼을 누르면 외부 이동 확인 화면으로 이동한다.
- [x] 확인 화면에 외부 사이트임을 명확히 표시한다.
- [x] 1차 구현에서는 확인 버튼을 눌러도 브라우저를 열지 않고 목업 안내를 표시한다.

### 단계 5. 위젯 테스트 작성

- [x] 필수 조건 미선택 시 이동하지 않는지 테스트한다.
- [x] 정상 조건 입력 후 목록 화면으로 이동하는지 테스트한다.
- [x] 조건 요약이 목록에 표시되는지 테스트한다.
- [x] 빈 결과 상태를 테스트한다.
- [x] 목록에서 상세 화면으로 이동하는지 테스트한다.
- [x] 없는 정책 ID 상태를 테스트한다.
- [x] 지원금·마감일 누락 대체 문구를 테스트한다.
- [x] 외부 이동 확인 화면까지 이동하는지 테스트한다.
- [x] 관심 없음과 실행 취소를 테스트한다.

### 단계 6. 정적 분석과 수동 검증

- [x] `dart format`을 실행한다.
- [x] `dart analyze`가 경고 없이 통과한다.
- [x] `flutter test --no-pub` 전체 20개 테스트가 통과한다.
- [x] 320×568 테스트 화면에서 주요 탭에 overflow가 없는지 확인한다.
- [x] 긴 지역명과 구·군명이 ellipsis로 안전하게 표시되도록 제한한다.
- [x] 정책 탭을 이동했다 돌아와도 입력 상태가 유지되는지 테스트한다.

### 단계 6.5. 전국 지역 데이터와 백엔드 코드 계약 보완

- [x] 지도 기능의 읍·면·동 MockData와 정책 지역 데이터를 분리한다.
- [x] 전국 17개 시·도 선택지를 제공한다.
- [x] 시·도에 속한 시·군·구 선택지를 제공한다.
- [x] 시·도 2자리 코드와 시·군·구 5자리 코드를 표시 이름과 분리한다.
- [x] 세종특별자치시처럼 별도 시·군·구가 없는 상태를 처리한다.
- [x] 정책 MockData 지역 필터를 표시 이름 대신 코드로 비교한다.
- [x] 백엔드 요청 및 검증 규칙을 별도 계약 문서로 기록한다.
- [x] 지역 코드 형식과 중복을 테스트한다.

### 단계 7. PR 준비

- [x] 변경 범위가 정책 기능과 필요한 최소 라우트 파일에 한정됐는지 확인한다.
- [x] API 호출이나 저장 기능이 포함되지 않았는지 확인한다.
- [x] 이슈 번호와 테스트 결과를 PR 본문에 기록한다.
- [x] Conventional Commit을 사용한다.

커밋 예시:

```text
feat(policy): add policy filter flow
feat(policy): add policy result and detail flow
test(policy): cover policy navigation states
```

## 7. 예상 생성·수정 파일

```text
lib/features/policy/policy_filter_page.dart
lib/features/policy/policy_list_page.dart
lib/features/policy/policy_detail_page.dart
lib/features/policy/policy_external_link_confirm_page.dart
lib/core/router/app_routes.dart
lib/core/router/app_router.dart
lib/features/root/root_shell.dart
lib/data/models.dart
lib/data/mock_data.dart
test/features/policy/...
```

공통 테마나 공통 위젯 변경이 필요하면 정책 PR에 큰 변경을 섞지 말고 별도 커밋 또는 별도 이슈로 분리한다.

## 8. 완료 조건

- [x] #8의 조건 입력 항목과 검증 상태가 모두 구현됐다.
- [x] #9의 목록·상세·외부 이동 확인 흐름이 연결됐다.
- [x] 실제 API, 저장, 신청 기능처럼 오해할 표현이 없다.
- [x] nullable 지원금과 마감일을 안전하게 표시한다.
- [x] `flutter analyze`와 `flutter test`가 통과한다.
- [x] 다른 기능 폴더의 불필요한 변경이 없다.

## 9. 후속 백엔드 연동 시 교체 지점

백엔드 API가 준비되면 다음 순서로 교체한다.

1. [x] 백엔드 `PolicySummary`, `PolicyDetail`, 필터 코드 계약을 확인한다.
2. [x] MockData용 `Policy`와 분리된 API용 `PolicySummary`, `PolicyDetail` 모델을 추가한다.
3. [x] 정책 전용 API client를 추가한다.
4. [x] 정책 목록·상세·외부 확인 화면의 MockData 직접 참조를 API 결과로 교체한다.
5. [x] 로딩, 인증 실패, 외부 API 장애, 재시도, `partialResult` 상태를 추가한다.
6. [x] `CHECK_REQUIRED` 정책의 확인 안내와 사유를 목록·상세 화면에 표시한다.
7. [ ] 실제 외부 링크 실행 범위를 별도 이슈로 확정한다.

API 연동 작업에서는 `API_BASE_URL` 설정을 사용하고 비밀값을 앱에 포함하지 않는다.

확정된 1차 백엔드 계약:

```text
POST /api/policies/search
  → ApiResponse<PolicySearchResponse>
  → items: PolicySummary[]
  → partialResult
  → checkedProviderPages

GET /api/policies/{policyId}
  → ApiResponse<PolicyDetail>
```

두 endpoint 모두 로그인 사용자의 액세스 토큰이 필요하다.
온통청년 인증키는 백엔드 서버에서만 관리하며 앱에는 포함하지 않는다.

## 10. 2차 실제 API 연동 구현

### 단계 1. API 계약 모델 분리

- [x] 목록 응답 `PolicySummary`와 상세 응답 `PolicyDetail`을 분리한다.
- [x] `supportAmount`, `applicationPeriodText`, `categoryType`, `officialUrl`의 null을 허용한다.
- [x] `MATCHED`, `CHECK_REQUIRED` 자격 상태와 확인 사유를 변환한다.
- [x] 잘못된 JSON은 빈 데이터로 처리하지 않고 응답 형식 오류로 구분한다.

### 단계 2. 인증된 API 요청 구현

- [x] 화면이 `AuthSession`에서 액세스 토큰을 읽는다.
- [x] 화면이 토큰과 검색 조건을 `PolicyApiClient`에 전달한다.
- [x] 검색 조건 enum을 백엔드 대문자 코드로 변환한다.
- [x] 요청 헤더에 `Authorization: Bearer {accessToken}`을 추가한다.
- [x] 온통청년 인증키는 앱 요청이나 로그에 포함하지 않는다.
- [x] 네트워크 연결 실패와 15초 응답 지연을 재시도 가능한 오류로 처리한다.

### 단계 3. 목록 화면 실제 연동

- [x] 앱의 MockData 정책 필터를 제거하고 `POST /api/policies/search` 결과를 표시한다.
- [x] 서버가 반환한 추천 순서를 기본 순서로 유지한다.
- [x] 마감임박순과 지원금액순 정렬을 실제 응답 필드에 적용한다.
- [x] 빈 결과, 로딩, 로그인 필요, 서버 오류, 재시도 상태를 표시한다.
- [x] `partialResult=true`이면 확인한 제공처 페이지 수와 추가 결과 가능성을 안내한다.
- [x] `CHECK_REQUIRED`이면 목록 카드에 신청 자격 확인 필요를 표시한다.
- [x] 관심 없음과 실행 취소를 메모리 상태로 유지한다.

### 단계 4. 상세 화면 실제 연동

- [x] 목록에서 정책 ID와 자격 판정 정보를 상세 화면으로 전달한다.
- [x] `GET /api/policies/{policyId}`로 상세를 조회한다.
- [x] 상세 조회 로딩, 404, 인증 실패, 서버 오류와 재시도를 처리한다.
- [x] 자격 확인 사유, 운영 기관, 제출 서류, 참고 URL을 표시한다.
- [x] 공식 URL이 있을 때만 외부 이동 확인 버튼을 활성화한다.
- [x] 외부 이동 확인 화면은 상세 응답의 정책명과 공식 URL을 전달받는다.

### 단계 5. 테스트와 검증

- [x] 검색 요청 본문, Bearer 토큰, 응답 파싱을 테스트한다.
- [x] nullable 필드와 잘못된 응답 계약을 테스트한다.
- [x] 조건 입력 → 목록 → 상세 → 외부 확인 흐름을 테스트한다.
- [x] 부분 결과, 자격 확인 필요, 빈 결과, 404, 재시도, 로그인 누락을 테스트한다.
- [x] 관심 없음과 실행 취소가 API 목록에서도 유지되는지 테스트한다.
- [x] 정책 API·화면 테스트 13개가 통과한다.
- [x] `flutter analyze` 결과를 확인한다.
  - 정책 변경 파일에는 문제가 없다.
  - 최신 `main`의 `saving_map_page.dart`에 사용되지 않는 `_HousingSummaryCard` 경고 1건이 남아 있다.
- [x] 전체 `flutter test --no-pub` 결과를 확인한다.
  - 정책 변경과 관련된 테스트는 모두 통과했다.
  - 최신 `main` 기준 전체 결과는 24개 통과, 정책 외 테스트 3개 실패다.
  - 일기 화면에서 `결제 알림에서 찾았어요` 문구와 `edit-detected-detected-1` 키를 찾지 못한다.
  - 지도 화면에서 `map-scroll` 키를 찾지 못한다.
  - 위 실패는 이번 정책 작업 범위에서 수정하지 않는다.

### 요청부터 응답까지의 데이터 흐름

```text
PolicyFilterCondition
  → PolicyListPage가 AuthSession 액세스 토큰 확인
  → PolicyApiClient.searchPolicies
  → POST /api/policies/search
  → PolicySearchResult와 PolicySummary 변환
  → 목록 표시
  → PolicyDetailArguments로 정책 ID와 자격 판정 전달
  → PolicyApiClient.getPolicyDetail
  → GET /api/policies/{policyId}
  → PolicyDetail 변환
  → 상세 및 공식 페이지 이동 확인 화면 표시
```

### 생성·수정 파일

```text
lib/features/policy/data/policy_models.dart
lib/features/policy/data/policy_api_client.dart
lib/features/policy/policy_list_page.dart
lib/features/policy/policy_detail_page.dart
lib/features/policy/policy_external_link_confirm_page.dart
lib/core/router/app_router.dart
test/features/policy/policy_api_client_test.dart
test/features/policy/policy_flow_test.dart
test/widget_test.dart
docs/policy/implementation-plan.md
```

### 남은 위험과 후속 작업

- 액세스 토큰은 현재 메모리에만 보관하므로 앱을 다시 시작하면 재로그인이 필요하다.
- 서버의 실제 정책 상세 성공 응답은 운영 환경에서 한 번 더 확인해야 한다.
- `applicationPeriodText`가 제공처 원문이므로 모든 날짜 표현을 정확하게 정렬하지 못할 수 있다.
- 실제 외부 브라우저 열기는 이번 단계에 포함하지 않았다.
- 검색 조건 저장, 페이지 추가 조회, 관심 없음 서버 저장은 별도 설계가 필요하다.
