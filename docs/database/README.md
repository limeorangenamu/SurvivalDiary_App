# 생존일기 MySQL 데이터베이스 가이드

ERD(한글 컬럼)를 영어 snake_case로 변환한 정본 스키마는 [schema.sql](schema.sql) 이다.
백엔드(Spring Boot) 저장소가 생기면 이 폴더를 그대로 옮긴다.

---

## 1. MySQL 환경 구축

### 방법 A. Docker (권장 — 팀원 간 환경 통일)

```bash
docker run -d --name survival-diary-db \
  -e MYSQL_ROOT_PASSWORD=root1234 \
  -e MYSQL_DATABASE=survival_diary \
  -e TZ=Asia/Seoul \
  -p 3306:3306 \
  mysql:8.4 \
  --character-set-server=utf8mb4 \
  --collation-server=utf8mb4_unicode_ci
```

### 방법 B. 로컬 설치

1. [MySQL 8.x Community Server](https://dev.mysql.com/downloads/mysql/) 설치 (Windows는 MySQL Installer)
2. 설치 시 문자셋을 `utf8mb4` 로 지정

### 스키마 적용

```bash
mysql -u root -p < schema.sql
```

적용 확인:

```sql
USE survival_diary;
SHOW TABLES;          -- 16개 테이블
SELECT * FROM categories;  -- 기본 카테고리 5건
```

### 앱 전용 계정 생성 (root 사용 금지)

```sql
CREATE USER 'survival_app'@'%' IDENTIFIED BY '비밀번호변경필수';
GRANT SELECT, INSERT, UPDATE, DELETE ON survival_diary.* TO 'survival_app'@'%';
FLUSH PRIVILEGES;
```

---

## 2. ERD → 영어 컬럼 변환 규칙

- 테이블명: 복수형 snake_case (`users`, `post_images`)
- 컬럼명: snake_case, 날짜는 `_date`(DATE) / `_at`(DATETIME) 접미사
- enum성 값은 VARCHAR + 대문자 코드 (`AUTO`/`MANUAL`, `USER`/`ADMIN`) — JPA `@Enumerated(EnumType.STRING)` 대응
- 금액은 원 단위 INT, 좌표는 `DECIMAL(10,7)`

| ERD (한글) | 테이블 | 주요 변환 |
|---|---|---|
| 사용자 | `users` | 이름→`name`, 생년월일→`birth_date`, 성별→`gender`, 지역→`region`, 가입일→`created_at`, 회원타입→`role` |
| 사용자 프로필 | `user_profiles` | 나이→**제거** (`birth_date`에서 계산), 취업상태→`employment_status`, 직업→`job`, 소개→`bio`, 프로필 이미지→`profile_image_url` |
| 절약 일기 예산 | `budgets` | 날짜→`budget_date`, 사용 가능 금액→`amount`, 알림 기준 비율→`alert_ratio`, 생성일→`created_at` |
| 지출 내역 | `expenses` | 금액→`amount`, 지출일시→`spent_at`, 내용(메모)→`memo`, 결제수단→`payment_method`, 등록방식→`entry_type`, 영수증 이미지→`receipt_image_url` |
| 카테고리 | `categories` | 카테고리명→`name`, 상위카테고리→`parent_category_id`, 아이콘→`icon`, 색상→`color` |
| 알림 | `notifications` | 타입→`type`, 제목→`title`, 내용→`content`, 읽음 여부→`is_read`, 생성일→`created_at` |
| 청년정책 | `policies` | 지원대상→`support_target`, 지원내용→`support_content`, 지원금→`support_amount`, 신청기간→`apply_start_date`/`apply_end_date`, 주관기관→`agency`, 상세 링크→`detail_url` |
| 정책 대상 조건 | `policy_targets` | 나이 조건→`min_age`/`max_age`, 취업 상태→`employment_status`, 기타 조건→`other_conditions` |
| 정책 관심 | `policy_interests` | 저장일→`created_at`, 상태→`status` |
| 장소 | `places` | 장소명→`name`, 장소 유형→`place_type`, 위도/경도→`latitude`/`longitude`, 전화번호→`phone` |
| 장소 가격 정보 | `place_prices` | 가격→`price`, 기준일→`base_date` |
| 사용자 위치 설정 | `user_locations` | 주소→`address`, 등록일→`created_at` |
| 커뮤니티 게시글 | `posts` | 제목→`title`, 내용→`content`, 카테고리→`category`, 작성일→`created_at`, 조회수→`view_count` |
| (신규) 게시글 이미지 | `post_images` | 에디터 이미지 다중 첨부용 — 아래 3절 |
| 댓글 | `comments` | 내용→`content`, 작성일→`created_at` |
| 게시글 좋아요 | `post_likes` | 등록일→`created_at`, `(post_id, user_id)` UNIQUE로 중복 방지 |

---

## 3. 에디터 이미지 처리 설계

### 원칙: DB에는 이미지 파일이 아니라 **URL만** 저장한다

에디터에서 이미지를 base64로 content에 인라인하면 글 하나가 수 MB로 부풀고
목록 조회 성능이 무너진다. 파일은 스토리지(서버 디스크 → 추후 S3/NCP Object Storage)에 두고,
DB에는 경로만 기록한다.

### 저장 흐름

```
1. 사용자가 에디터에 이미지를 드롭
2. 클라이언트 → POST /api/images (multipart) 즉시 업로드
3. 서버: 파일 저장 후 URL 반환 (예: /uploads/2026/07/uuid.jpg)
4. 에디터가 content에 <img src="URL"> 삽입
5. 글 등록 시:
   - posts.content ← 에디터 HTML 전체
   - post_images  ← 사용된 이미지 URL을 행 단위로 INSERT (여러 장 = 여러 행)
```

### 이미지가 여러 장이어도 되는가? → 된다

`post_images` 가 게시글과 **1:N** 관계라서 장수 제한이 없다.
글 1건에 이미지 10장이면 `post_images` 에 10행이 들어간다.

### content에 URL이 이미 있는데 post_images 테이블이 왜 또 필요한가

| 필요 상황 | post_images 없이 | post_images 있으면 |
|---|---|---|
| 목록 썸네일 | 글마다 HTML 파싱해서 첫 `<img>` 추출 | `sort_order = 0` 한 행 조회 |
| 고아 이미지 정리 (업로드 후 글 미등록/이미지 삭제) | 전체 글 HTML 스캔 | 테이블 대조로 배치 삭제 |
| 스토리지 이전 (로컬→S3) | 모든 글 content 일괄 치환만 의존 | URL 목록 확보 후 안전하게 이전 |
| 글 삭제 시 파일 삭제 | HTML 파싱 필요 | `ON DELETE CASCADE` + 삭제 훅 |

---

## 4. 백엔드 연동 (Spring Boot)

`application.yml` 예시:

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/survival_diary?serverTimezone=Asia/Seoul&characterEncoding=UTF-8
    username: survival_app
    password: ${DB_PASSWORD}     # 환경변수로 주입, 커밋 금지
    driver-class-name: com.mysql.cj.jdbc.Driver
  jpa:
    hibernate:
      ddl-auto: validate         # 스키마 정본은 schema.sql — JPA가 DDL을 만들지 않게 한다
    properties:
      hibernate:
        format_sql: true
```

- 스키마 변경은 schema.sql 직접 수정이 아니라 **Flyway/Liquibase 마이그레이션**으로 관리 권장
  (`V1__init.sql` 로 시작)

---

## 5. 역할 분담 (전체 아키텍처에서 이 DB의 위치)

```
Flutter 앱 ── 로컬 SQLite(오프라인 가계부: 지출·예산·알림 감지)
     │                          │ 동기화
     └─────────┐                ↓
               ├──> Spring Boot API ──> MySQL (이 스키마)
React 웹 ──────┘    (JWT 인증 + USER/ADMIN 권한)
```

- MySQL은 **서버 단일 정본** — 웹/앱이 같은 API를 통해 공용 사용
- 앱 로컬 SQLite는 오프라인 캐시/우선 기록용이며 별도 작업 (drift 도입 이슈)
