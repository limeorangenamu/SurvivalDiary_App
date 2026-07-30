# 청년정책 지역 코드 계약

## 1. 목적

앱의 시·도 및 시·군·구 선택값을 화면 표시 문자열과 백엔드 요청 코드로 분리한다.
정책 검색 API 연동 시 앱이 한글 지역명을 임의의 식별자로 사용하지 않도록 하는 것이 목적이다.

- 기준일: 2026-07-30
- 앱 적용 범위: 전국 17개 시·도와 하위 시·군·구
- 관련 백엔드 요청 필드: `regionCode`, `districtCode`

## 2. 기준 자료

- [행정표준코드관리시스템 법정동코드 목록](https://www.code.go.kr/stdcode/regCodeL.do)
- [행정안전부 2026년 지방자치단체 행정구역 및 인구 현황](https://www.mois.go.kr/frt/bbs/type001/commonSelectBoardList.do?bbsId=BBSMSTR_000000000055)

앱의 지역 목록은 UI 개발과 MockData 필터를 위한 스냅샷이다.
행정구역 개편이 발생하면 행정표준코드관리시스템의 현존 코드를 다시 확인해 갱신한다.

## 3. 코드 규칙

### 시·도

- `regionCode`: 법정동 코드 앞 2자리
- `region`: 사용자에게 표시할 시·도 이름

예시:

```text
11 / 서울특별시
26 / 부산광역시
41 / 경기도
51 / 강원특별자치도
52 / 전북특별자치도
```

### 시·군·구

- `districtCode`: 법정동 코드 앞 5자리
- `district`: 사용자에게 표시할 시·군·구 이름
- 시·군·구는 선택값이며 선택하지 않으면 `null`을 전달한다.
- 세종특별자치시는 현재 앱 단계에서 별도 시·군·구 선택 없이 `districtCode`를 `null`로 전달한다.

예시:

```text
11680 / 강남구
26350 / 해운대구
41130 / 성남시
50130 / 서귀포시
```

## 4. 앱 모델

```text
PolicyRegionOption
  code
  name
  districts

PolicyDistrictOption
  code
  name

PolicyFilterCondition
  age
  regionCode
  region
  districtCode
  district
  employmentStatus
  incomeRange
  category
```

표시 이름은 UI 요약에 사용하고 코드는 필터 및 백엔드 query parameter에 사용한다.

## 5. 백엔드 요청 계약

```http
GET /api/policies
  ?age=27
  &regionCode=11
  &districtCode=11680
  &employmentStatus=JOB_SEEKING
```

백엔드 구현 시 다음 규칙을 유지한다.

- `regionCode`는 필수 2자리 문자열이다.
- `districtCode`는 선택 5자리 문자열이다.
- `districtCode`가 전달되면 앞 2자리가 `regionCode`와 일치해야 한다.
- 알 수 없거나 폐지된 코드는 400 입력 오류로 처리한다.
- 앱 표시 이름을 검색 조건이나 영구 식별자로 사용하지 않는다.
- 전국 정책은 응답 데이터의 지역 범위로 표현하며 요청 코드에 `ALL`을 사용하지 않는다.

## 6. 데이터 제공 방식

1차 API 연동에서는 코드가 안정적이라는 전제로 앱 스냅샷을 사용한다.
백엔드와 웹까지 같은 선택지의 실시간 동기화가 필요해지면 다음 API 도입을 검토한다.

```http
GET /api/policies/filter-options
```

불필요한 네트워크 요청을 피하기 위해 백엔드 구현 전에는 endpoint를 확정하지 않는다.

## 7. 검증 기준

- [x] 전국 17개 시·도 코드가 중복 없이 존재한다.
- [x] 모든 시·도 코드는 숫자 2자리다.
- [x] 모든 시·군·구 코드는 숫자 5자리다.
- [x] 시·군·구 코드 앞 2자리가 상위 시·도 코드와 일치한다.
- [x] 서울특별시 25개 구가 제공된다.
- [x] 세종특별자치시는 시·군·구 미선택 상태를 지원한다.
- [x] 정책 필터는 표시 이름이 아닌 `regionCode`로 지역을 비교한다.

## 8. 백엔드 개발 진입 조건

다음 항목에 팀이 동의하면 백엔드 정책 검색 계약 구현을 시작할 수 있다.

- [ ] `regionCode` 2자리 및 `districtCode` 5자리 형식 승인
- [ ] 세종특별자치시의 `districtCode = null` 처리 승인
- [ ] 폐지·미등록 코드의 400 오류 처리 승인
- [ ] 앱 정적 스냅샷 유지 또는 `/filter-options` API 도입 여부 결정
