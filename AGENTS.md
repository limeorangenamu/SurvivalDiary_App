# AGENTS.md

## 프로젝트 개요

- 생존일기는 지출 기록, 예산 관리, 절약 정보 탐색, 청년·생활 정책 탐색, 커뮤니티 정보 공유를 돕는 앱이다.
- 이 저장소는 Flutter 모바일 앱만 담당한다. Spring Boot API와 웹 프론트엔드 변경은 각각의 저장소에서 작업한다.
- 참고 이미지는 화면 흐름, 여백, 애니메이션을 위한 참고 자료이며 서비스의 경제·절약·정책 목적에 맞게 해석한다.

## 저장소 정보

- Repository: `https://github.com/limeorangenamu/SurvivalDiary_App`
- 주요 경로: `lib/`, `test/`
- API 주소는 `lib/core/config/app_config.dart`에서 관리한다.

## 작업 규칙

- 작업 전 `README.md`, 관련 GitHub Issue, 기존 구현을 확인한다.
- 브랜치는 `{name}/{type}/{task}` 형식을 사용한다. 예: `alex/feat/email-login`.
- 한 브랜치에는 하나의 기능 또는 하나의 이슈 범위만 담는다.
- `main`에 직접 커밋하거나 푸시하지 않는다. 작업 브랜치를 푸시하고 `main` 대상 PR로 반영한다.
- 커밋 메시지와 PR 제목·본문은 한글로 작성한다. Conventional Commit 접두사(`feat:`, `fix:`, `docs:` 등)를 사용할 때에도 접두사 뒤 설명은 한글로 쓴다.
- 생성 파일, 비밀값, 로컬 설정 파일은 커밋하지 않는다.

## 앱 구현 규칙

- 인증 요청은 `features/auth/data/`에 두고, 화면은 `features/auth/`에 둔다.
- API 실패, 입력 오류, 로딩 상태를 사용자에게 명확히 표시한다.
- 버튼, 입력창, 카드, 선택 항목의 텍스트가 작은 화면에서 잘리거나 의도치 않게 줄바꿈되지 않도록 확인한다.
- 고정된 UI 요소에는 반응형 제약을 두어 상태 변화로 레이아웃이 흔들리지 않게 한다.

## 검증

- 변경 전후 `flutter analyze`와 관련 `flutter test`를 실행한다.
- 회원가입·로그인처럼 API를 바꾸는 작업은 요청·응답 파싱 테스트를 추가한다.
