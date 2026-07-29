# AGENTS.md — 생존일기 (Survival Diary)

AI 코딩 도구(ChatGPT Codex, Claude Code 등)가 이 저장소에서 작업할 때 참조하는 정본 문서.
사람이 읽는 개요는 `README.md`, 이 문서는 **작업 규칙과 구조**에 집중한다.

---

## 1. 프로젝트 정의

| 항목 | 내용 |
|---|---|
| 서비스 | 청년의 경제적 자립을 지원하는 생활금융 앱 |
| 핵심 기능 | 절약 정보 · 나이/자금상황별 정부 정책 추천 · 커뮤니티 · 가계부 |
| 차별 기능 | 결제 **푸시 알림을 감지**해 자동으로 가계부에 기록하고, 월 지출 계획·절약 개선안을 추천 |
| 현재 상태 | **UI 프로토타입 (뷰 단만 존재). 백엔드·영속화·인증 전부 없음** |
| 스택 | Flutter 3.44+ / Dart 3.12+ |
| 외부 의존성 | 없음 (`cupertino_icons` 만) — 차트·지도까지 직접 구현 |

패키지명은 `project_survival_diary` 다. 폴더명이 `project_survival_diary_demo` 로 바뀌었지만
`pubspec.yaml` 의 `name:` 은 변경하지 않았다. **패키지명을 바꾸지 말 것** (android namespace·applicationId 연쇄 수정 발생).

---

## 2. 작업 규칙 (필수 준수)

1. **색상은 `AppColors` 상수만 사용.** 화면 파일에 `Color(0x...)` 리터럴 금지.
   투명도가 필요하면 새 상수를 추가하지 말고 `AppColors.primary.withValues(alpha: 0.14)` 로 파생시킨다.
2. **텍스트는 `AppTextStyles` 사용.** 변형은 `.copyWith()` 로만. 화면에서 `TextStyle(...)` 직접 생성 지양.
3. **화면 추가 순서**: `AppRoutes` 에 상수 등록 → `AppRouter.onGenerateRoute` 에 연결 → 페이지 파일 생성.
4. **데이터는 `MockData` 에만 둔다.** 화면 파일에 더미 상수를 새로 만들지 말 것.
5. **외부 패키지 추가는 사전 합의 필요.** 현재 의존성 0을 유지 중이다.
6. **import 규칙**: `lib/` 내부는 상대 경로. `package:project_survival_diary/...` 는 `test/` 에서만.
7. **한국어**: UI 문자열·주석 모두 한국어. 코드 식별자는 영어.
8. **기능 구현 금지 (현 단계)**: 이 저장소는 뷰 분배용이다. 상태관리·API·DB 도입은 해당 이슈 담당자가 진행한다.
9. 변경 후 반드시 `flutter analyze` 무경고를 확인한다. `analysis_options.yaml` 이 `prefer_const_constructors` 를 켜둔 상태다.

---

## 3. 디렉터리 구조

```
lib/
├─ main.dart                          진입점 (SystemChrome 설정 + runApp)
├─ app.dart                           MaterialApp · 테마 · 라우터 · textScaler 제한
├─ core/
│  ├─ theme/app_colors.dart           컬러 토큰 (단일 소스)
│  ├─ theme/app_text_styles.dart      타이포 스케일
│  ├─ theme/app_theme.dart            ThemeData (컴포넌트 기본값)
│  ├─ router/app_routes.dart          라우트 이름 상수
│  ├─ router/app_router.dart          onGenerateRoute 테이블
│  └─ utils/formatters.dart           금액·날짜 포매터 (intl 미사용)
├─ data/
│  ├─ models.dart                     모델 + enum extension (label/icon/color)
│  └─ mock_data.dart                  전 화면 더미 데이터
├─ shared/widgets/                    기능 간 공용 위젯
└─ features/<기능>/
   ├─ *_page.dart                     화면 1개 = 파일 1개
   └─ widgets/                        해당 기능 전용 위젯
```

`features/` 하위 폴더가 담당자 분배 단위다. 기능 간 위젯 공유가 필요하면 `shared/widgets/` 로 올린다.

---

## 4. 디자인 토큰

### 4-1. 컬러 — `core/theme/app_colors.dart`

`AppColors._()` private 생성자로 인스턴스화를 막은 순수 네임스페이스 클래스. 전부 `static const`.

| 그룹 | 상수 | 값 | 용도 |
|---|---|---|---|
| 브랜드 | `primary` | `#17A67C` | 주 버튼, 강조, 선택 상태 |
| | `primaryDark` | `#0E8763` | 예산 카드 그라디언트 끝 |
| | `primaryDeep` | `#0B6B4F` | soft 배경 위 텍스트 |
| | `primarySoft` | `#E6F5EF` | 강조 영역 배경, 태그 |
| 표면 | `scaffold` | `#F6F7F8` | 화면 배경 |
| | `surface` | `#FFFFFF` | 카드·AppBar·바텀네비 |
| | `surfaceAlt` | `#F7F8F9` | 비활성 입력, 보조 칩 |
| | `border` | `#ECEEF0` | 카드 1px 테두리 |
| | `divider` | `#F1F2F4` | 구분선, 차트 그리드 |
| 텍스트 | `textPrimary` | `#1A1D1F` | 본문·제목 |
| | `textSecondary` | `#6F767E` | 보조 설명 |
| | `textTertiary` | `#9EA3A8` | 비활성, 아이콘 |
| 상태 | `danger` / `dangerSoft` | `#E5484D` / `#FDECEC` | 한도 초과, 증가 지표 |
| | `warning` / `warningSoft` | `#F5A524` / `#FFF6E5` | 한도 임박, 별점 |
| | `info` | `#3E9AE0` | 현재 위치, 리포트 |
| 카테고리 | `categoryFood` | `#FF6B6B` | 식비 |
| | `categoryCafe` | `#EE6C9C` | 카페 |
| | `categoryTransport` | `#3FA9D8` | 교통 |
| | `categoryShopping` | `#FFC145` | 쇼핑 |
| | `categoryEtc` | `#9EA3A8` | 기타 |
| 지도 핀 | `pinGoodPrice` / `pinPublic` / `pinParking` | 착한가격업소 / 공공시설 / 공영주차장 |

카테고리 색은 화면에서 직접 참조하지 않고 **`ExpenseCategory` enum extension** 을 경유한다:

```dart
Icon(category.icon, color: category.color)   // label / icon / color 를 enum이 함께 보유
```

카테고리를 추가·변경할 때는 `models.dart` 의 enum 과 extension 만 수정하면 전 화면에 반영된다.

**하드코딩 예외 (의도된 것 — 확장하지 말 것)**

| 위치 | 이유 |
|---|---|
| `mock_data.dart` 아바타·썸네일 색 | 테마가 아니라 **데이터**. 실서비스에선 이미지 URL로 교체 |
| `map_canvas.dart` 배경·블록·도로 | 지도 SDK 교체 시 파일 통째로 삭제될 목업 전용 |
| `pig_mascot.dart`, `saving_tip_card.dart` 마스코트 배경 | 이미지 에셋 교체 예정 자리표시자 |

### 4-2. 타이포 — `core/theme/app_text_styles.dart`

| 상수 | 크기 / 굵기 | 용도 |
|---|---|---|
| `display` | 32 / w800 | 미사용 예비 |
| `title` | 22 / w700 | 화면 대제목, 큰 금액 |
| `sectionTitle` | 16 / w700 | 섹션 헤더, 카드 제목 |
| `body` | 14 / w500 | 본문 |
| `bodyMuted` | 14 / w500 (secondary) | 보조 본문 |
| `caption` | 12 / w500 (secondary) | 라벨, 설명 |
| `captionTiny` | 11 / w500 (tertiary) | 메타 정보, 해시태그 |
| `amount` | 18 / w700 | 금액 강조 |
| `button` | 15 / w700 (white) | 버튼 라벨 |

### 4-3. 형태 규칙

| 요소 | 값 |
|---|---|
| 화면 좌우 패딩 | `16` |
| 카드 radius | `16` (`AppCard` 기본값) |
| 버튼 · 입력필드 radius | `12` |
| 칩 radius | `999` (완전 라운드) |
| 예산 히어로 카드 radius | `18` |
| 경고 배너 · 팁 카드 radius | `14` |
| 카드 테두리 | `1px` `AppColors.border` |
| 버튼 높이 | `52` (기본) / `44` (카드 내부) |
| 하단 네비 높이 | `62` + SafeArea |

`app_theme.dart` 의 `ThemeData` 가 AppBar·FilledButton·InputDecoration·Divider·BottomNav 기본값을
전역 지정하므로, 화면에서 같은 스타일을 다시 선언하지 않는다.

### 4-4. CSS 대응 관계 (웹 출신 기여자용)

Flutter에는 CSS가 없다. DOM·셀렉터·스타일시트가 존재하지 않고 렌더 엔진이 캔버스에 직접 그린다.

| CSS | 이 프로젝트 |
|---|---|
| `:root` 커스텀 프로퍼티 | `AppColors` / `AppTextStyles` 상수 |
| reset + 컴포넌트 기본 스타일 | `AppTheme.light` (`ThemeData`) |
| 재사용 클래스 | `shared/widgets/` 위젯 |
| 캐스케이딩 / 상속 | `InheritedWidget` (`Theme.of(context)`) |
| `rgba()` / `color-mix()` | `Color.withValues(alpha:)` |
| flexbox | `Row` / `Column` / `Expanded` / `Flexible` |
| `position: absolute` | `Stack` / `Positioned` |
| `flex-wrap` | `Wrap` |

`web/index.html` 에 CSS를 넣을 수는 있으나 **앱 로딩 전 껍데기 페이지**에만 적용되고 위젯에는 영향이 없다.

---

## 5. 라우팅

`app.dart` → `onGenerateRoute: AppRouter.onGenerateRoute`. 인자는 `settings.arguments` 로 모델을 그대로 전달한다.

| 라우트 상수 | 화면 | 인자 |
|---|---|---|
| `root` (`/`) | `RootShell` (하단 네비 5탭) | — |
| `notification` | 알림 목록 | — |
| `dailySummary` | 오늘의 요약 상세 | — |
| `budgetSetting` | 사용 가능 금액 설정 | — |
| `expenseStats` | 지출 통계 | — |
| `detectedExpenses` | 감지된 결제 전체 목록 | — |
| `policyDetail` | 정책 상세 | `Policy` |
| `placeDetail` | 장소 상세 | `SavingPlace` |
| `housingRegion` | 지역 선택 | — |
| `housingDeal` | 실거래 내역 | `String?` (지역명) |
| `postDetail` | 게시글 상세 | `CommunityPost` |
| `postWrite` | 글쓰기 | — |

### 하단 네비게이션

`RootShell` 이 `IndexedStack` 으로 5탭을 유지해 탭 전환 시 스크롤·입력 상태가 보존된다.
탭 인덱스는 `AppTab` enum 순서와 1:1 대응한다.

```
0 홈(HomePage) · 1 일기(ExpenseAddPage) · 2 정책(PolicyListPage) · 3 지도(SavingMapPage) · 4 커뮤니티(CommunityPage)
```

상세 화면은 루트 Navigator 위에 push 된다. 셸 밖에서 탭을 바꿀 때는 `RootShell.goToTab(context, index)`
(루트까지 pop 후 탭 전환). 탭 페이지의 AppBar 뒤로가기는 `goToTab(context, 0)` 으로 홈에 돌아간다.

`AppBottomNav` 에 `onTap` 을 주지 않으면 위 동작이 기본값이라, push 된 화면(`expenseStats`)에서도
같은 위젯을 그대로 재사용할 수 있다.

---

## 6. 모델 — `data/models.dart`

| 모델 | 용도 |
|---|---|
| `ExpenseCategory` (enum) | 식비/카페/교통/쇼핑/기타 + `label`·`icon`·`color` extension |
| `BudgetSummary` | 홈 예산 요약. `weeklyProgress`·`isNearLimit`·`isOverLimit` 파생 게터 보유 |
| `DetectedExpense` | 알림에서 감지된 결제 |
| `Expense` | 저장된 지출 1건 |
| `CategoryStat` | 카테고리별 통계 행 |
| `MonthlyCompare` | 전월/당월 비교 1그룹 |
| `Policy` | 청년 정책 |
| `PlaceType` (enum) | 착한가격업소/공공시설/공영주차장 + `label`·`icon`·`color` |
| `SavingPlace` | 지도 장소. `offsetX`/`offsetY` 는 목업 지도용 0~1 비율 좌표 |
| `HousingDeal` | 부동산 실거래 1건 |
| `CommunityPost` | 게시글 |
| `AppNotification` | 알림 항목 |

모델에 `fromJson`/`toJson` 은 없다. API 연동 이슈(#4)에서 추가한다.

---

## 7. 구현 / 미구현 경계

**중요: 이 저장소는 화면과 페이지 전환만 있다. 비즈니스 로직·영속화·네트워크는 전무하다.**

### 동작하는 것 (UI 로컬 state 수준)

- 하단 네비 5탭 전환, 모든 상세 화면 push/pop
- 지출 등록 폼: 카테고리 선택, 텍스트 입력, 날짜 피커 → **저장은 스낵바만 표시**
- 정책 "관심 없음" → 목록에서 실제 제거 + 실행취소 스낵바 (메모리상)
- 지도: 장소 유형 필터링, 거리순/가격순 정렬, 핀 선택 → 하단 카드 전환 (실제 동작)
- 지역 선택: 상위 변경 시 하위 초기화, 3단계 모두 선택 전까지 조회 버튼 비활성 (실제 동작)
- 글쓰기: 카테고리/제목/내용 필수 입력 검증 (실제 동작) → **등록은 스낵바만**
- 지출 통계 월 선택기: 표시 월만 변경 (데이터는 고정)
- 커뮤니티 탭: 인기/최신은 동일 목록의 정순/역순, 팔로잉은 빈 상태 화면

### 없는 것

로그인·회원가입 / API 통신 / 로컬 DB / 상태관리 라이브러리 / 푸시 알림 수신 /
실제 지도 SDK / 정책 필터의 실제 필터링(선택값 저장만) / 좋아요·댓글·팔로우·신고·채팅 /
AI 추천 / 정책 자동 신청 / 길찾기 / 예약 / 결제

### 교체 예정 자리표시자

| 파일 | 교체 대상 |
|---|---|
| `features/map/widgets/map_canvas.dart` | 네이버/카카오/Google 지도 SDK |
| `features/diary/widgets/trend_line_chart.dart`, `monthly_compare_chart.dart` | 필요 시 `fl_chart` |
| `shared/widgets/pig_mascot.dart` | `assets/images/` 디자인 에셋 |
| `data/mock_data.dart` | Repository 구현체 |

---

## 8. 명령어

작업 후 아래 두 개는 반드시 통과시킨다.

```bash
flutter analyze
```

```bash
flutter test
```

실행:

```bash
flutter run -d chrome
```

Android 실행은 `android/` 스캐폴딩이 필요하다. 로컬 환경 이슈는 `README.md` 트러블슈팅 참조.

---

## 9. 이슈 트래커

작업 단위는 GitHub 이슈로 분배되어 있다 (`ligr00vefe/project_survival_diary_demo`, 29건).
라벨 체계: 우선순위 `P0`/`P1`/`P2` + 흐름 `flow:diary`/`flow:policy`/`flow:map`/`flow:housing`/`flow:community` + `common`.

`P0`(#1–4)은 다른 모든 작업의 선행 조건이다. 기능 이슈에 착수하기 전 해당 흐름의 P0가 끝났는지 확인한다.

---

## Git branch ownership rule

- Jade Cohen / ligr00vefe@naver.com 작업자는 `kimin`으로 식별한다.
- 모든 작업 브랜치는 반드시 `{name}/{type}/{task}` 형식을 사용한다.
- kimin 작업 브랜치는 반드시 `kimin/{type}/{task}` 형식을 사용한다.
- 허용 예시: `kimin/feat/signup-ui`, `kimin/fix/auth-route`, `kimin/chore/initial-app-snapshot`.
- `main`에는 절대 직접 커밋하거나 직접 push하지 않는다.
- 모든 변경 사항은 작업 브랜치에 push한 뒤 PR로만 `main`에 반영한다.
- 커밋 메시지는 Conventional Commits 형식을 사용한다. 예: `feat: add email signup ui`.
