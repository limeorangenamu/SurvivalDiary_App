[🌐 웹 포트폴리오 보러가기](https://developer-portfolio.changy.workers.dev/)

# 생존일기 (Survival Diary)

청년의 경제적 자립을 지원하는 Flutter 기반 생활금융 Android 앱.

절약 정보 · 나이/자금상황별 정부 정책 추천 · 커뮤니티 · 가계부를 제공하고,
결제 **푸시 알림을 감지**해 자동으로 가계부에 기록한 뒤 월 지출 계획과 절약 개선안을 추천한다.

> ### 현재 저장소 상태: UI 프로토타입 (뷰 단만 존재)
>
> 화면과 페이지 전환만 구현되어 있고 **비즈니스 로직·백엔드·영속화는 전부 없다.**
> 팀원 분배를 쉽게 하려고 뷰를 먼저 만들어 둔 단계이며, 기능 구현은 GitHub 이슈 단위로 나눈다.
> 웹 서비스는 이 저장소에 포함하지 않으며 추후 Spring Boot와 React 기반의 별도 프로젝트로 구현할 예정이다.
> 정확한 구현/미구현 경계는 [AGENTS.md](AGENTS.md) 7절 참조.

| 검증 항목 | 상태 |
|---|---|
| `flutter analyze` | 통과 (무경고) |
| `flutter test` | 통과 (위젯 7건) |
| `flutter build apk` | 로컬 환경 이슈 있음 → [트러블슈팅](#트러블슈팅) |

---

## 목차

- [빠른 시작](#빠른-시작)
- [프로젝트 구조](#프로젝트-구조)
- [화면 · 담당 분배표](#화면--담당-분배표)
- [기능 범위](#기능-범위)
- [작업 규칙](#작업-규칙)
- [트러블슈팅](#트러블슈팅)

---

## 빠른 시작

### 요구 사항

- **Flutter 3.27 이상** (Dart 3.6+) — `Color.withValues` 등 최신 API 사용. 개발 검증 버전은 3.44.8
- Android Studio + Flutter/Dart 플러그인
- Android SDK, 에뮬레이터 또는 실기기

### 1. 클론 후 의존성 설치

```bash
flutter pub get
```

### 2. 플랫폼 스캐폴딩 (필요 시)

`android/` 폴더가 저장소에 없다면 생성한다.

```bash
flutter create --org com.survivaldiary --project-name project_survival_diary --platforms=android .
```

> **주의** — Flutter 3.44 기준 `flutter create` 는 기존 `lib/` 와 `pubspec.yaml` 을 덮어쓰지 않지만,
> 버전에 따라 덮어쓸 수 있다. **실행 전에 반드시 커밋하거나 백업**할 것.
> `lib/` 가 커밋되지 않은 상태라면 `git checkout` 으로 복구할 수 없다.
>
> 이때 생성되는 `test/widget_test.dart` 는 존재하지 않는 `MyApp` 을 참조한다. 덮어써진 경우 되돌린다.

### 3. 실행

에뮬레이터/기기 확인:

```bash
flutter devices
```

Android:

```bash
flutter run -d <device-id>
```

### Android Studio에서 실행

1. **File → Open** → `pubspec.yaml` 이 바로 보이는 프로젝트 루트 선택
   (상위 workspace 폴더나 `lib/` 를 열면 Flutter 프로젝트로 인식하지 못한다)
2. 우측 상단 기기 드롭다운에서 에뮬레이터 선택
3. 실행 구성 드롭다운에서 `main.dart` 선택 → **▶** (`Shift+F10`)

`main.dart` 실행 구성이 보이지 않으면 아래를 순서대로 확인한다.

- Settings → Plugins → Flutter 설치 여부
- Settings → Languages & Frameworks → Flutter → SDK 경로 지정
- Run → Edit Configurations → `+` → Flutter → Dart entrypoint `lib\main.dart`
- File → Invalidate Caches / Restart

---

## 프로젝트 구조

```
lib/
├─ main.dart                     앱 진입점
├─ app.dart                      MaterialApp · 테마 · 라우터 연결
├─ core/
│  ├─ theme/                     컬러 토큰 · 타이포 스케일 · ThemeData
│  ├─ router/                    라우트 상수 · onGenerateRoute 테이블
│  └─ utils/formatters.dart      금액 · 날짜 포매터 (intl 미사용)
├─ data/
│  ├─ models.dart                화면 공용 모델 + enum extension
│  └─ mock_data.dart             더미 데이터 — API 연동 시 이 파일만 교체
├─ shared/widgets/               전 기능 공용 위젯
└─ features/
   ├─ root/                      하단 네비게이션 5탭 셸
   ├─ home/                      홈 대시보드 · 오늘의 요약 · 알림
   ├─ diary/                     지출 등록 · 통계 · 한도 설정
   ├─ policy/                    청년 정책 목록 · 상세
   ├─ map/                       절약 지도 · 장소 상세 · 주거 실거래
   └─ community/                 커뮤니티 목록 · 상세 · 글쓰기
```

`features/<기능>/` 폴더가 담당자 분배 단위다. `cupertino_icons` 외 추가 UI 패키지는 사용하지 않으며,
차트와 지도까지 `CustomPainter` 로 직접 구현했다.

### 하단 네비게이션 5탭

```
홈 · 일기 · 정책 · 지도 · 커뮤니티
```

`RootShell` 이 `IndexedStack` 으로 5탭을 유지하므로 탭을 옮겨도 스크롤·입력 상태가 보존된다.
상세 화면은 루트 Navigator 위에 push 된다.

---

## 화면 · 담당 분배표

| # | 화면 | 파일 | 대응 흐름 |
|---|---|---|---|
| 1 | 홈 대시보드 | `features/home/home_page.dart` | 절약 일기 |
| 1-1 | 오늘의 요약 상세 | `features/home/daily_summary_page.dart` | 절약 일기 |
| 1-2 | 알림 | `features/home/notification_page.dart` | 공통 |
| 1-3 | 사용 가능 금액 설정 | `features/diary/budget_setting_page.dart` | 절약 일기 |
| 2 | 지출 등록 | `features/diary/expense_add_page.dart` | 절약 일기 |
| 2-1 | 감지된 결제 목록 | `features/diary/detected_expense_page.dart` | 절약 일기 |
| 3 | 지출 통계 | `features/diary/expense_stats_page.dart` | 절약 일기 |
| 4 | 청년 정책 추천 | `features/policy/policy_list_page.dart` | 청년정책 |
| 4-1 | 정책 상세 | `features/policy/policy_detail_page.dart` | 청년정책 |
| 5 | 절약 지도 | `features/map/saving_map_page.dart` | 절약 지도 |
| 5-1 | 장소 상세 | `features/map/place_detail_page.dart` | 절약 지도 |
| 5-2 | 지역 선택 | `features/map/housing_region_page.dart` | 주거 실거래 |
| 5-3 | 실거래 내역 | `features/map/housing_deal_page.dart` | 주거 실거래 |
| 6 | 커뮤니티 | `features/community/community_page.dart` | 커뮤니티 조회 |
| 6-1 | 게시글 상세 | `features/community/post_detail_page.dart` | 커뮤니티 조회 |
| 6-2 | 글쓰기 | `features/community/post_write_page.dart` | 커뮤니티 작성 |

작업 단위는 **GitHub 이슈 27건**으로 등록되어 있다.
라벨 체계는 우선순위 `P0`/`P1`/`P2` + 흐름별 `flow:*` + `common` 이며,
`P0` 공통 이슈 4건은 다른 기능 작업의 선행 조건이다.

---

## 기능 범위

### 포함

일일 지출 한도 · 알림 기반 자동 지출 감지 · 직접 지출 등록 · 카테고리 통계 · 월별 비교 ·
정책 필터/목록/상세/관심없음 · 지도 필터/정렬/장소 상세 · 주거지 선택/실거래 조회 ·
커뮤니티 목록/상세/작성

### 제외

로그인 · 회원가입 · AI 추천 · 정책 자동 신청 · 길찾기 · 예약 · 결제 ·
좋아요 · 댓글 · 팔로우 · 신고 · 채팅 · Spring Boot 백엔드 · React 웹 애플리케이션

### 교체 예정 자리표시자

| 항목 | 현재 | 교체 대상 |
|---|---|---|
| 지도 | `features/map/widgets/map_canvas.dart` (CustomPainter 목업) | 네이버/카카오/Google 지도 SDK |
| 차트 | `trend_line_chart.dart`, `monthly_compare_chart.dart` (직접 구현) | 필요 시 `fl_chart` |
| 마스코트 | `shared/widgets/pig_mascot.dart` (이모지) | `assets/images/` 디자인 에셋 |
| 데이터 | `data/mock_data.dart` | API 연동 Repository |

---

## 작업 규칙

전체 규칙과 디자인 토큰 표는 **[AGENTS.md](AGENTS.md)** 에 정리되어 있다.
AI 코딩 도구(ChatGPT Codex, Claude Code)도 이 파일을 참조한다.

핵심만 요약하면:

1. **색상은 `AppColors` 상수만.** 화면 파일에 `Color(0x...)` 금지.
   투명도는 `AppColors.primary.withValues(alpha: 0.14)` 로 파생.
2. **텍스트는 `AppTextStyles`** + `.copyWith()`.
3. **화면 추가** = `AppRoutes` 상수 등록 → `AppRouter` 연결 → 페이지 생성.
4. **더미 데이터는 `MockData` 에만.**
5. **외부 패키지 추가는 사전 합의.** 지도·차트·상태관리 패키지는 사용하지 않는다.
6. `lib/` 내부는 상대 경로 import. `package:` import 는 `test/` 에서만.
7. 커밋 전 `flutter analyze` 무경고 + `flutter test` 통과.

> Flutter에는 CSS가 없다. `.css` 파일을 놓을 자리가 없고 스타일은 모두 Dart 코드다.
> CSS 개념과의 대응 관계는 [AGENTS.md](AGENTS.md) 4-4절 참조.

---

## 트러블슈팅

### Gradle 빌드 실패 — `PKIX path building failed`

```
Caused by: sun.security.validator.ValidatorException: PKIX path building failed:
unable to find valid certification path to requested target
    at org.gradle.wrapper.Install.createDist
```

**원인**: 안티바이러스(Avast 등)의 HTTPS 스캔이 TLS 트래픽을 가로채 자체 인증서로 재서명한다.
Windows 인증서 저장소에는 그 루트 CA가 등록되어 있어 브라우저와 `flutter pub get` 은 정상이지만,
**Gradle이 쓰는 Java는 Windows 저장소가 아니라 JDK 내부 `cacerts` 만 본다.** 거기엔 없으므로 검증에 실패한다.

Gradle 배포판을 내려받는 첫 단계에서 막히므로, Android Studio에서 ▶를 눌러도 컴파일 전에 죽는다.

**해결 (셋 중 하나)**

1. **임시 중지 (가장 빠름)** — 트레이의 백신 아이콘 우클릭 → 실드 10분 중지 → `flutter run` 실행.
   Gradle·라이브러리 캐시가 한 번 채워지면 이후 빌드는 재다운로드가 거의 없다.

2. **HTTPS 스캔 끄기 (영구)** — Avast → 설정 → 보호 → 코어 실드 → 웹 실드 → `HTTPS 스캔 사용` 해제.
   npm·git·Maven 등 다른 도구의 동일 문제도 함께 해결된다.

3. **JDK truststore 에 CA 등록 (백신 유지)** — 일반 PowerShell:

   ```powershell
   $c = Get-ChildItem Cert:\LocalMachine\Root | Where-Object { $_.Subject -match 'Avast' }
   Export-Certificate -Cert $c -FilePath "$env:USERPROFILE\avast-root.cer"
   ```

   이어서 **관리자 권한** PowerShell:

   ```powershell
   & "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -importcert -trustcacerts -noprompt -alias avast-web-shield -file "$env:USERPROFILE\avast-root.cer" -keystore "C:\Program Files\Android\Android Studio\jbr\lib\security\cacerts" -storepass changeit
   ```

   Android Studio 업데이트로 `jbr` 이 교체되면 다시 실행해야 한다.
   `-Djavax.net.ssl.trustStoreType=WINDOWS-ROOT` JVM 옵션은 JetBrains Runtime 21에서 동작하지 않는다 (검증 완료).

### Flutter SDK 설치 위치

`C:\Program Files\` 아래에 설치하지 말 것. Flutter는 첫 실행 시 `bin\cache\dart-sdk` 를 직접 내려받는데,
쓰기 권한이 없어 실패하고 "Dart SDK를 찾을 수 없다"는 증상으로 나타난다.
`C:\src\flutter` 처럼 사용자 권한으로 쓸 수 있는 경로를 사용한다.

**Dart SDK는 별도로 설치하지 않는다.** Flutter SDK 안에 포함되어 있고, 따로 설치하면 버전이 어긋난다.

### `flutter doctor -verbose` 가 `-e` 옵션 오류를 낸다

긴 옵션은 대시 두 개다. `flutter doctor --verbose` 또는 `flutter doctor -v`.

### 프로젝트 폴더명과 패키지명이 다르다

저장소 폴더명은 `SurvivalDiary_App`, 패키지명은 `project_survival_diary` 다. **정상이며 문제되지 않는다.**
Dart 패키지명은 폴더가 아니라 `pubspec.yaml` 의 `name:` 을 따르고, `lib/` 내부는 전부 상대 경로 import 다.

**패키지명을 바꾸지 말 것.** `android/` 의 `namespace`·`applicationId`(`com.survivaldiary.project_survival_diary`)와
Kotlin 소스 경로까지 연쇄로 수정해야 하는데 얻는 이득이 표기 일치뿐이다.
