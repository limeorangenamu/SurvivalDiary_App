-- ============================================================
-- 생존일기 (Survival Diary) MySQL 스키마
-- MySQL 8.x / utf8mb4 기준
-- ERD의 한글 컬럼을 전부 영어 snake_case로 변환한 정본 DDL.
-- 실행: mysql -u root -p < schema.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS survival_diary
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE survival_diary;

-- ------------------------------------------------------------
-- 1. 사용자 / 계정
-- ------------------------------------------------------------

-- 사용자 (User)
CREATE TABLE users (
  user_id     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email       VARCHAR(255)    NOT NULL COMMENT '로그인 이메일',
  password    VARCHAR(255)    NOT NULL COMMENT 'BCrypt 해시 저장 (평문 금지)',
  name        VARCHAR(50)     NOT NULL COMMENT '이름',
  birth_date  DATE            NULL     COMMENT '생년월일 (나이는 여기서 계산)',
  gender      VARCHAR(10)     NULL     COMMENT 'MALE / FEMALE / OTHER',
  region      VARCHAR(50)     NULL     COMMENT '지역',
  role        VARCHAR(20)     NOT NULL DEFAULT 'USER' COMMENT '회원타입: USER / ADMIN',
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '가입일',
  PRIMARY KEY (user_id),
  UNIQUE KEY uk_users_email (email)
) COMMENT '사용자';

-- 사용자 프로필 (UserProfile) — users와 1:1
CREATE TABLE user_profiles (
  profile_id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id            BIGINT UNSIGNED NOT NULL,
  employment_status  VARCHAR(30)     NULL COMMENT '취업상태: EMPLOYED / JOB_SEEKING / STUDENT 등',
  job                VARCHAR(50)     NULL COMMENT '직업',
  bio                VARCHAR(500)    NULL COMMENT '소개',
  profile_image_url  VARCHAR(500)    NULL COMMENT '프로필 이미지 경로/URL',
  PRIMARY KEY (profile_id),
  UNIQUE KEY uk_user_profiles_user (user_id),
  CONSTRAINT fk_user_profiles_user FOREIGN KEY (user_id)
    REFERENCES users (user_id) ON DELETE CASCADE
) COMMENT '사용자 프로필 (ERD의 나이 컬럼은 users.birth_date에서 계산하므로 제거)';

-- 사용자 위치 설정 (UserLocation)
CREATE TABLE user_locations (
  location_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id     BIGINT UNSIGNED NOT NULL,
  address     VARCHAR(255)    NOT NULL COMMENT '주소',
  latitude    DECIMAL(10, 7)  NOT NULL COMMENT '위도',
  longitude   DECIMAL(10, 7)  NOT NULL COMMENT '경도',
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
  PRIMARY KEY (location_id),
  KEY idx_user_locations_user (user_id),
  CONSTRAINT fk_user_locations_user FOREIGN KEY (user_id)
    REFERENCES users (user_id) ON DELETE CASCADE
) COMMENT '사용자 위치 설정';

-- ------------------------------------------------------------
-- 2. 절약 일기 (예산 / 지출 / 카테고리)
-- ------------------------------------------------------------

-- 카테고리 (Category) — user_id가 NULL이면 공통 기본 카테고리
CREATE TABLE categories (
  category_id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id            BIGINT UNSIGNED NULL COMMENT 'NULL = 시스템 기본 카테고리, 값 있으면 사용자 정의',
  parent_category_id BIGINT UNSIGNED NULL COMMENT '상위 카테고리 (선택)',
  name               VARCHAR(50)     NOT NULL COMMENT '카테고리명',
  icon               VARCHAR(50)     NULL COMMENT '아이콘 식별자',
  color              VARCHAR(9)      NULL COMMENT '색상 HEX (#RRGGBB)',
  PRIMARY KEY (category_id),
  KEY idx_categories_user (user_id),
  CONSTRAINT fk_categories_user FOREIGN KEY (user_id)
    REFERENCES users (user_id) ON DELETE CASCADE,
  CONSTRAINT fk_categories_parent FOREIGN KEY (parent_category_id)
    REFERENCES categories (category_id) ON DELETE SET NULL
) COMMENT '지출 카테고리';

-- 절약 일기 예산 (Budget)
CREATE TABLE budgets (
  budget_id   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id     BIGINT UNSIGNED NOT NULL,
  budget_date DATE            NOT NULL COMMENT '날짜 (일 단위 예산)',
  amount      INT UNSIGNED    NOT NULL COMMENT '사용 가능 금액 (원)',
  alert_ratio TINYINT UNSIGNED NOT NULL DEFAULT 80 COMMENT '알림 기준 비율 (%)',
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
  PRIMARY KEY (budget_id),
  UNIQUE KEY uk_budgets_user_date (user_id, budget_date),
  CONSTRAINT fk_budgets_user FOREIGN KEY (user_id)
    REFERENCES users (user_id) ON DELETE CASCADE
) COMMENT '예산';

-- 지출 내역 (Expense)
CREATE TABLE expenses (
  expense_id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id           BIGINT UNSIGNED NOT NULL,
  category_id       BIGINT UNSIGNED NOT NULL,
  amount            INT UNSIGNED    NOT NULL COMMENT '금액 (원)',
  spent_at          DATETIME        NOT NULL COMMENT '지출일시',
  memo              VARCHAR(200)    NULL COMMENT '내용 (메모)',
  payment_method    VARCHAR(30)     NULL COMMENT '결제수단: CARD / CASH / TRANSFER 등',
  entry_type        VARCHAR(10)     NOT NULL DEFAULT 'MANUAL' COMMENT '등록방식: AUTO(알림 감지) / MANUAL(직접)',
  receipt_image_url VARCHAR(500)    NULL COMMENT '영수증 이미지 경로 (선택)',
  created_at        DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
  PRIMARY KEY (expense_id),
  KEY idx_expenses_user_spent (user_id, spent_at),
  KEY idx_expenses_category (category_id),
  CONSTRAINT fk_expenses_user FOREIGN KEY (user_id)
    REFERENCES users (user_id) ON DELETE CASCADE,
  CONSTRAINT fk_expenses_category FOREIGN KEY (category_id)
    REFERENCES categories (category_id)
) COMMENT '지출 내역';

-- 알림 (Notification)
CREATE TABLE notifications (
  notification_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id         BIGINT UNSIGNED NOT NULL,
  type            VARCHAR(20)     NOT NULL COMMENT '타입: BUDGET / POLICY / COMMUNITY 등',
  title           VARCHAR(100)    NOT NULL COMMENT '제목',
  content         VARCHAR(500)    NULL COMMENT '내용',
  is_read         TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '읽음 여부',
  created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성일',
  PRIMARY KEY (notification_id),
  KEY idx_notifications_user (user_id, is_read),
  CONSTRAINT fk_notifications_user FOREIGN KEY (user_id)
    REFERENCES users (user_id) ON DELETE CASCADE
) COMMENT '알림';

-- ------------------------------------------------------------
-- 3. 청년 정책
-- ------------------------------------------------------------

-- 청년정책 (Policy)
CREATE TABLE policies (
  policy_id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  title            VARCHAR(200)    NOT NULL COMMENT '제목',
  description      TEXT            NULL COMMENT '설명',
  support_target   VARCHAR(500)    NULL COMMENT '지원대상',
  support_content  TEXT            NULL COMMENT '지원내용',
  support_amount   INT UNSIGNED    NULL COMMENT '지원금 (원, 예상)',
  apply_start_date DATE            NULL COMMENT '신청기간 시작',
  apply_end_date   DATE            NULL COMMENT '신청기간 종료',
  agency           VARCHAR(100)    NULL COMMENT '주관기관',
  detail_url       VARCHAR(500)    NULL COMMENT '상세 링크',
  created_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
  PRIMARY KEY (policy_id),
  KEY idx_policies_apply_end (apply_end_date)
) COMMENT '청년정책';

-- 정책 대상 조건 (PolicyTarget)
CREATE TABLE policy_targets (
  target_id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  policy_id         BIGINT UNSIGNED NOT NULL,
  min_age           TINYINT UNSIGNED NULL COMMENT '나이 조건 (최소)',
  max_age           TINYINT UNSIGNED NULL COMMENT '나이 조건 (최대)',
  region            VARCHAR(50)      NULL COMMENT '지역',
  employment_status VARCHAR(30)      NULL COMMENT '취업 상태',
  other_conditions  VARCHAR(500)     NULL COMMENT '기타 조건',
  PRIMARY KEY (target_id),
  KEY idx_policy_targets_policy (policy_id),
  CONSTRAINT fk_policy_targets_policy FOREIGN KEY (policy_id)
    REFERENCES policies (policy_id) ON DELETE CASCADE
) COMMENT '정책 대상 조건';

-- 정책 관심 (PolicyInterest)
CREATE TABLE policy_interests (
  interest_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id     BIGINT UNSIGNED NOT NULL,
  policy_id   BIGINT UNSIGNED NOT NULL,
  status      VARCHAR(20)     NOT NULL DEFAULT 'INTERESTED' COMMENT '상태: INTERESTED(관심) / PLANNED(신청예정) / APPLIED(신청완료)',
  created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '저장일',
  PRIMARY KEY (interest_id),
  UNIQUE KEY uk_policy_interests (user_id, policy_id),
  CONSTRAINT fk_policy_interests_user FOREIGN KEY (user_id)
    REFERENCES users (user_id) ON DELETE CASCADE,
  CONSTRAINT fk_policy_interests_policy FOREIGN KEY (policy_id)
    REFERENCES policies (policy_id) ON DELETE CASCADE
) COMMENT '정책 관심';

-- ------------------------------------------------------------
-- 4. 절약 지도 (장소)
-- ------------------------------------------------------------

-- 장소 (Place)
CREATE TABLE places (
  place_id   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name       VARCHAR(100)    NOT NULL COMMENT '장소명',
  place_type VARCHAR(20)     NOT NULL COMMENT '장소 유형: GOOD_PRICE(착한가격업소) / PUBLIC_FACILITY(공공시설) / PUBLIC_PARKING(공영주차장)',
  latitude   DECIMAL(10, 7)  NOT NULL COMMENT '위도',
  longitude  DECIMAL(10, 7)  NOT NULL COMMENT '경도',
  address    VARCHAR(255)    NOT NULL COMMENT '주소',
  phone      VARCHAR(20)     NULL COMMENT '전화번호',
  PRIMARY KEY (place_id),
  KEY idx_places_type (place_type),
  KEY idx_places_location (latitude, longitude)
) COMMENT '장소';

-- 장소 가격 정보 (PlacePrice)
CREATE TABLE place_prices (
  price_id  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  place_id  BIGINT UNSIGNED NOT NULL,
  price     INT UNSIGNED    NOT NULL COMMENT '가격 (원)',
  base_date DATE            NOT NULL COMMENT '기준일',
  PRIMARY KEY (price_id),
  KEY idx_place_prices_place (place_id),
  CONSTRAINT fk_place_prices_place FOREIGN KEY (place_id)
    REFERENCES places (place_id) ON DELETE CASCADE
) COMMENT '장소 가격 정보';

-- ------------------------------------------------------------
-- 5. 커뮤니티
-- ------------------------------------------------------------

-- 커뮤니티 게시글 (Post)
-- content에는 에디터가 생성한 HTML(이미지 <img src="URL"> 포함)을 저장한다.
-- 이미지 파일 자체(base64)는 절대 넣지 않는다 — 파일은 스토리지에, DB에는 URL만.
CREATE TABLE posts (
  post_id    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id    BIGINT UNSIGNED NOT NULL,
  category   VARCHAR(30)     NOT NULL COMMENT '게시글 카테고리',
  title      VARCHAR(200)    NOT NULL COMMENT '제목',
  content    MEDIUMTEXT      NOT NULL COMMENT '내용 (에디터 HTML, 최대 16MB)',
  view_count INT UNSIGNED    NOT NULL DEFAULT 0 COMMENT '조회수',
  created_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '작성일',
  updated_at DATETIME        NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정일',
  PRIMARY KEY (post_id),
  KEY idx_posts_user (user_id),
  KEY idx_posts_category_created (category, created_at),
  CONSTRAINT fk_posts_user FOREIGN KEY (user_id)
    REFERENCES users (user_id) ON DELETE CASCADE
) COMMENT '커뮤니티 게시글';

-- 게시글 이미지 (PostImage) — 게시글 1건 : 이미지 N장
-- 에디터로 업로드된 이미지의 URL을 행 단위로 기록한다.
-- content 안에도 <img> 태그로 URL이 들어가지만, 이 테이블이 있어야
-- 고아 이미지 정리 / 대표 썸네일 추출 / 스토리지 이전이 가능하다.
CREATE TABLE post_images (
  image_id   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  post_id    BIGINT UNSIGNED NOT NULL,
  image_url  VARCHAR(500)    NOT NULL COMMENT '이미지 URL 또는 스토리지 경로',
  sort_order INT UNSIGNED    NOT NULL DEFAULT 0 COMMENT '표시 순서 (0 = 대표/썸네일)',
  created_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '업로드일',
  PRIMARY KEY (image_id),
  KEY idx_post_images_post (post_id),
  CONSTRAINT fk_post_images_post FOREIGN KEY (post_id)
    REFERENCES posts (post_id) ON DELETE CASCADE
) COMMENT '게시글 이미지 (1:N)';

-- 댓글 (Comment)
CREATE TABLE comments (
  comment_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  post_id    BIGINT UNSIGNED NOT NULL,
  user_id    BIGINT UNSIGNED NOT NULL,
  content    VARCHAR(1000)   NOT NULL COMMENT '내용',
  created_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '작성일',
  PRIMARY KEY (comment_id),
  KEY idx_comments_post (post_id),
  KEY idx_comments_user (user_id),
  CONSTRAINT fk_comments_post FOREIGN KEY (post_id)
    REFERENCES posts (post_id) ON DELETE CASCADE,
  CONSTRAINT fk_comments_user FOREIGN KEY (user_id)
    REFERENCES users (user_id) ON DELETE CASCADE
) COMMENT '댓글';

-- 게시글 좋아요 (PostLike)
CREATE TABLE post_likes (
  like_id    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  post_id    BIGINT UNSIGNED NOT NULL,
  user_id    BIGINT UNSIGNED NOT NULL,
  created_at DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일',
  PRIMARY KEY (like_id),
  UNIQUE KEY uk_post_likes (post_id, user_id),
  CONSTRAINT fk_post_likes_post FOREIGN KEY (post_id)
    REFERENCES posts (post_id) ON DELETE CASCADE,
  CONSTRAINT fk_post_likes_user FOREIGN KEY (user_id)
    REFERENCES users (user_id) ON DELETE CASCADE
) COMMENT '게시글 좋아요 (같은 글 중복 좋아요 방지 UNIQUE)';

-- ------------------------------------------------------------
-- 6. 기본 시드 데이터
-- ------------------------------------------------------------

-- 앱의 ExpenseCategory enum과 동일한 시스템 기본 카테고리
INSERT INTO categories (user_id, name, icon, color) VALUES
  (NULL, '식비', 'restaurant', '#FF6B6B'),
  (NULL, '카페', 'local_cafe', '#EE6C9C'),
  (NULL, '교통', 'directions_bus', '#3FA9D8'),
  (NULL, '쇼핑', 'shopping_bag', '#FFC145'),
  (NULL, '기타', 'more_horiz', '#9EA3A8');
