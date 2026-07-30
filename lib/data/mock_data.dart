import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'models.dart';

class MockData {
  MockData._();

  static const budget = BudgetSummary(
    userName: '생존러',
    dailyLimit: 35000,
    remainingToday: 23500,
    spentToday: 11500,
    savedToday: 7000,
    dDay: 9,
    weeklyBudget: 245000,
    weeklySpent: 128500,
  );

  static const detectedExpenses = [
    DetectedExpense(
      id: 'detected-1',
      merchant: '스타벅스 강남점',
      amount: 5500,
      detectedTime: '오늘 09:42',
      source: '신한카드 알림',
      category: ExpenseCategory.cafe,
    ),
    DetectedExpense(
      id: 'detected-2',
      merchant: 'CU 역삼타워점',
      amount: 3800,
      detectedTime: '오늘 08:15',
      source: '토스 결제 알림',
      category: ExpenseCategory.food,
    ),
    DetectedExpense(
      id: 'detected-3',
      merchant: '서울교통공사',
      amount: 1400,
      detectedTime: '어제 19:08',
      source: '티머니 알림',
      category: ExpenseCategory.transport,
    ),
    DetectedExpense(
      id: 'detected-4',
      merchant: '다이소 신논현점',
      amount: 12000,
      detectedTime: '어제 17:21',
      source: 'KB국민카드 알림',
      category: ExpenseCategory.shopping,
    ),
  ];

  static final expenses = [
    Expense(
      id: 'expense-1',
      title: '김밥과 라면',
      amount: 6500,
      date: DateTime(2026, 7, 27),
      category: ExpenseCategory.food,
      memo: '점심 식사',
    ),
    Expense(
      id: 'expense-2',
      title: '아이스 아메리카노',
      amount: 5000,
      date: DateTime(2026, 7, 27),
      category: ExpenseCategory.cafe,
    ),
    Expense(
      id: 'expense-3',
      title: '버스',
      amount: 1500,
      date: DateTime(2026, 7, 26),
      category: ExpenseCategory.transport,
    ),
  ];

  static const categoryStats = [
    CategoryStat(category: ExpenseCategory.food, amount: 287000, ratio: 0.42),
    CategoryStat(category: ExpenseCategory.cafe, amount: 116000, ratio: 0.17),
    CategoryStat(
      category: ExpenseCategory.transport,
      amount: 98000,
      ratio: 0.14,
    ),
    CategoryStat(
      category: ExpenseCategory.shopping,
      amount: 132000,
      ratio: 0.19,
    ),
    CategoryStat(category: ExpenseCategory.etc, amount: 55000, ratio: 0.08),
  ];

  static const monthlyCompare = [
    MonthlyCompare(label: '식비', previous: 310000, current: 287000),
    MonthlyCompare(label: '카페', previous: 94000, current: 116000),
    MonthlyCompare(label: '교통', previous: 105000, current: 98000),
    MonthlyCompare(label: '쇼핑', previous: 89000, current: 132000),
  ];

  static const trendValues = [74.0, 62.0, 81.0, 55.0, 68.0, 48.0, 57.0];

  static const policies = [
    Policy(
      id: 'policy-1',
      category: '주거',
      categoryType: PolicyCategory.housing,
      title: '청년 월세 지원',
      summary: '월세 부담이 큰 무주택 청년에게 매월 임차료를 지원해요.',
      supportAmount: 2400000,
      supportText: '월 최대 20만원, 최대 12개월',
      deadline: '2026.08.20 마감',
      target: '만 19~34세, 부모와 별도 거주하는 무주택 청년',
      agency: '국토교통부 · 관할 주민센터',
      applyMethod: '복지로 온라인 또는 주소지 주민센터 방문 신청',
      documents: ['임대차계약서', '최근 3개월 월세 이체 내역', '가족관계증명서'],
      icon: Icons.home_work_rounded,
      minAge: 19,
      maxAge: 34,
      eligibleRegions: ['전국'],
      employmentStatuses: PolicyEmploymentStatus.values,
      incomeRanges: [PolicyIncomeRange.below50, PolicyIncomeRange.below100],
      officialUrl: 'https://www.bokjiro.go.kr',
      contact: '국토교통부 상담센터 1599-0001',
    ),
    Policy(
      id: 'policy-2',
      category: '취업',
      categoryType: PolicyCategory.employment,
      title: '구직활동 지원금',
      summary: '취업 준비 중인 청년의 구직활동 비용을 최대 6개월 지원해요.',
      supportAmount: 3000000,
      supportText: '월 최대 50만원, 최대 6개월',
      deadline: '상시 접수',
      target: '만 18~34세 미취업 청년 중 기준중위소득 요건 충족자',
      agency: '고용노동부',
      applyMethod: '고용24에서 구직촉진수당 신청',
      documents: ['취업지원 신청서', '소득·재산 확인 동의서'],
      icon: Icons.work_outline_rounded,
      minAge: 18,
      maxAge: 34,
      eligibleRegions: ['전국'],
      employmentStatuses: [
        PolicyEmploymentStatus.jobSeeker,
        PolicyEmploymentStatus.unemployed,
      ],
      incomeRanges: [
        PolicyIncomeRange.below50,
        PolicyIncomeRange.below100,
        PolicyIncomeRange.below150,
      ],
      officialUrl: 'https://www.work24.go.kr',
      contact: '고용노동부 고객상담센터 1350',
    ),
    Policy(
      id: 'policy-3',
      category: '자산형성',
      categoryType: PolicyCategory.asset,
      title: '청년내일저축계좌',
      summary: '매월 저축하면 정부지원금을 더해 목돈 마련을 도와줘요.',
      supportAmount: 10800000,
      supportText: '근로소득장려금 최대 1,080만원',
      deadline: '2026.08.05 마감',
      target: '근로 중인 만 19~34세 청년, 소득·재산 요건 충족자',
      agency: '보건복지부',
      applyMethod: '복지로 또는 읍면동 주민센터 신청',
      documents: ['재직증명서', '소득금액증명원', '저축동의서'],
      icon: Icons.savings_rounded,
      minAge: 19,
      maxAge: 34,
      eligibleRegions: ['전국'],
      employmentStatuses: [PolicyEmploymentStatus.employed],
      incomeRanges: [
        PolicyIncomeRange.below50,
        PolicyIncomeRange.below100,
        PolicyIncomeRange.below150,
      ],
      officialUrl: 'https://www.bokjiro.go.kr',
      contact: '보건복지상담센터 129',
    ),
    Policy(
      id: 'policy-4',
      category: '문화',
      categoryType: PolicyCategory.culture,
      title: '청년 문화예술패스',
      summary: '공연과 전시 관람에 쓸 수 있는 문화비를 지원해요.',
      supportAmount: 150000,
      supportText: '공연·전시 관람비 최대 15만원',
      deadline: '예산 소진 시까지',
      target: '국내 거주 19세 청년',
      agency: '문화체육관광부',
      applyMethod: '협력 예매처에서 본인 인증 후 신청',
      documents: ['본인 명의 휴대전화'],
      icon: Icons.theater_comedy_rounded,
      minAge: 19,
      maxAge: 19,
      eligibleRegions: ['전국'],
      employmentStatuses: PolicyEmploymentStatus.values,
      incomeRanges: PolicyIncomeRange.values,
      officialUrl: 'https://youthculturepass.or.kr',
    ),
    Policy(
      id: 'policy-5',
      category: '교통',
      categoryType: PolicyCategory.transport,
      title: '청년 교통비 지원',
      summary: '대중교통 이용액 일부를 환급해 생활비 부담을 낮춰요.',
      supportAmount: null,
      supportText: '이용 금액에 따라 환급',
      deadline: null,
      target: '서울 거주 만 19~24세 청년',
      agency: '서울특별시',
      applyMethod: '청년몽땅정보통에서 교통카드 등록',
      documents: ['주민등록초본', '교통카드 번호'],
      icon: Icons.directions_subway_rounded,
      minAge: 19,
      maxAge: 24,
      eligibleRegions: ['서울특별시'],
      employmentStatuses: PolicyEmploymentStatus.values,
      incomeRanges: PolicyIncomeRange.values,
    ),
  ];

  static Policy? policyById(String id) {
    for (final policy in policies) {
      if (policy.id == id) {
        return policy;
      }
    }
    return null;
  }

  static const places = [
    SavingPlace(
      id: 'place-1',
      name: '행복한 밥상',
      type: PlaceType.goodPrice,
      address: '서울 강남구 테헤란로 21길 8',
      distanceMeters: 280,
      baseFee: 7000,
      operatingHours: '평일 11:00~20:30',
      phone: '02-555-2048',
      rating: 4.7,
      offsetX: 0.25,
      offsetY: 0.32,
    ),
    SavingPlace(
      id: 'place-2',
      name: '역삼1동 주민센터',
      type: PlaceType.publicFacility,
      address: '서울 강남구 역삼로7길 16',
      distanceMeters: 460,
      baseFee: 0,
      operatingHours: '평일 09:00~18:00',
      phone: '02-3423-8620',
      rating: 4.3,
      offsetX: 0.68,
      offsetY: 0.22,
    ),
    SavingPlace(
      id: 'place-3',
      name: '역삼문화공원 공영주차장',
      type: PlaceType.publicParking,
      address: '서울 강남구 테헤란로7길 22',
      distanceMeters: 620,
      baseFee: 1800,
      operatingHours: '매일 00:00~24:00',
      phone: '02-2176-0900',
      rating: 4.1,
      offsetX: 0.73,
      offsetY: 0.7,
    ),
    SavingPlace(
      id: 'place-4',
      name: '강남 청년센터',
      type: PlaceType.publicFacility,
      address: '서울 강남구 봉은사로 320',
      distanceMeters: 850,
      baseFee: 0,
      operatingHours: '화~토 10:00~21:00',
      phone: '02-2226-8080',
      rating: 4.8,
      offsetX: 0.35,
      offsetY: 0.76,
    ),
  ];

  static final housingDeals = [
    HousingDeal(
      id: 'deal-1',
      propertyName: '역삼 청년주택',
      dealType: '전세',
      amount: 235000000,
      dealDate: DateTime(2026, 7, 18),
      area: 29.8,
      floor: 8,
    ),
    HousingDeal(
      id: 'deal-2',
      propertyName: '테헤란 스테이',
      dealType: '월세',
      amount: 850000,
      dealDate: DateTime(2026, 6, 29),
      area: 24.1,
      floor: 5,
    ),
    HousingDeal(
      id: 'deal-3',
      propertyName: '강남 센트럴빌',
      dealType: '매매',
      amount: 515000000,
      dealDate: DateTime(2026, 5, 11),
      area: 41.2,
      floor: 12,
    ),
  ];

  static const posts = [
    CommunityPost(
      id: 'post-1',
      author: '도시락요정',
      authorEmoji: '🍱',
      timeAgo: '12분 전',
      category: '절약 인증',
      title: '주 3회 도시락으로 한 달 18만원 아꼈어요',
      body:
          '처음부터 거창하게 준비하지 않고 냉동밥과 전날 반찬을 활용했어요. 점심값이 눈에 띄게 줄고 식단도 더 규칙적이 됐습니다.',
      hashtags: ['도시락', '식비절약', '직장인'],
      likeCount: 128,
      commentCount: 23,
      hasImage: true,
    ),
    CommunityPost(
      id: 'post-2',
      author: '초록카드',
      authorEmoji: '🚌',
      timeAgo: '1시간 전',
      category: '정보 공유',
      title: '교통카드 환급, 등록 여부 꼭 확인하세요',
      body:
          '카드를 쓰기만 하면 자동인 줄 알았는데 전용 앱에 먼저 등록해야 했어요. 지난달부터 환급받아 커피값 정도는 절약 중입니다.',
      hashtags: ['교통카드', '환급', '생활비'],
      likeCount: 84,
      commentCount: 17,
      hasImage: false,
    ),
    CommunityPost(
      id: 'post-3',
      author: '동네탐험가',
      authorEmoji: '🗺️',
      timeAgo: '어제',
      category: '자유게시판',
      title: '회사 근처 착한가격업소 세 곳 후기',
      body: '가격만 저렴한 게 아니라 양도 넉넉했어요. 점심시간에는 붐비니 11시 40분쯤 가는 걸 추천합니다.',
      hashtags: ['착한가격업소', '점심', '강남'],
      likeCount: 203,
      commentCount: 41,
      hasImage: true,
    ),
    CommunityPost(
      id: 'post-4',
      author: '월세탈출',
      authorEmoji: '🏠',
      timeAgo: '2일 전',
      category: '정보 공유',
      title: '청년 월세 지원 승인받은 과정 공유해요',
      body: '계약서와 이체 내역을 미리 PDF로 준비하니 신청이 금방 끝났어요. 심사에는 약 한 달 정도 걸렸습니다.',
      hashtags: ['월세지원', '청년정책', '신청후기'],
      likeCount: 316,
      commentCount: 68,
      hasImage: false,
    ),
    CommunityPost(
      id: 'post-5',
      author: '통장지킴이',
      authorEmoji: '💬',
      timeAgo: '3일 전',
      category: '질문',
      title: '월급날 전에 생활비가 부족할 때 어떻게 관리하세요?',
      body: '고정비를 제외하고 주간 예산을 나눠 쓰고 있는데 마지막 주가 늘 빠듯해요. 다들 어떤 방식으로 관리하는지 궁금합니다.',
      hashtags: ['생활비', '예산관리', '질문'],
      likeCount: 47,
      commentCount: 32,
      hasImage: false,
    ),
  ];

  static const notifications = [
    AppNotification(
      id: 'notification-1',
      title: '새 결제가 감지됐어요',
      body: '스타벅스 강남점 5,500원을 지출 내역에 추가할까요?',
      timeAgo: '8분 전',
      isUnread: true,
      icon: Icons.notifications_active_rounded,
    ),
    AppNotification(
      id: 'notification-2',
      title: '이번 주 예산을 확인해 보세요',
      body: '주간 예산의 52%를 사용했어요. 지금 흐름이 좋아요!',
      timeAgo: '2시간 전',
      isUnread: true,
      icon: Icons.pie_chart_rounded,
    ),
    AppNotification(
      id: 'notification-3',
      title: '관심 정책 마감이 가까워요',
      body: '청년내일저축계좌 접수가 9일 뒤 마감돼요.',
      timeAgo: '어제',
      isUnread: false,
      icon: Icons.event_available_rounded,
    ),
  ];

  static const homeNews = [
    HomeNews(
      id: 'news-1',
      category: '생활경제',
      title: '소비자물가 2개월 연속 상승…석유류·외식비 부담 커져',
      source: '생존뉴스',
      timeAgo: '2시간 전',
      icon: Icons.shopping_cart_outlined,
    ),
    HomeNews(
      id: 'news-2',
      category: '금융',
      title: '기준금리 연 3.50% 동결…생활비 부담은 계속',
      source: '금융저널',
      timeAgo: '4시간 전',
      icon: Icons.account_balance_rounded,
    ),
    HomeNews(
      id: 'news-3',
      category: '절약',
      title: '주 3회 도시락 챙기면 한 달 식비 얼마나 줄까',
      source: '살림리포트',
      timeAgo: '6시간 전',
      icon: Icons.lunch_dining_outlined,
    ),
    HomeNews(
      id: 'news-4',
      category: '트렌드',
      title: '똑똑한 절약부터 보험 추천까지, AI 핀테크 확산',
      source: '테크이코노미',
      timeAgo: '8시간 전',
      icon: Icons.smart_toy_outlined,
    ),
  ];

  static const regions = {
    '서울특별시': {
      '강남구': ['역삼동', '논현동', '삼성동'],
      '마포구': ['서교동', '합정동', '망원동'],
    },
    '경기도': {
      '성남시': ['정자동', '서현동', '야탑동'],
      '수원시': ['인계동', '영통동', '매탄동'],
    },
    '부산광역시': {
      '해운대구': ['우동', '중동', '좌동'],
      '수영구': ['광안동', '민락동', '남천동'],
    },
  };

  static const onboardingSlides = [
    OnboardingSlide(
      titleTop: '결제 알림을 감지해 자동으로',
      titleMain: '기록되는 절약 일기',
      icon: Icons.savings_rounded,
      color: AppColors.primary,
      previewTitle: '오늘의 절약 일기',
      points: ['오늘 사용 가능 12,000원', '스타벅스 4,500원 자동 기록', '이번 주 3일 절약 성공 🎉'],
    ),
    OnboardingSlide(
      titleTop: '나이·지역·상황에 딱 맞는',
      titleMain: '청년 정책 맞춤 추천',
      icon: Icons.campaign_rounded,
      color: AppColors.info,
      previewTitle: '나를 위한 정책',
      points: ['청년 월세 지원 월 20만원', '청년도약계좌 만기 5,000만원', '신청 마감 D-7 알림'],
    ),
    OnboardingSlide(
      titleTop: '내 주변 착한가격·공공시설을',
      titleMain: '절약 지도로 한눈에',
      icon: Icons.map_rounded,
      color: AppColors.warning,
      previewTitle: '우리 동네 절약 지도',
      points: ['착한가격업소 백반 6,000원', '공영주차장 30분 500원', '주거 실거래가 바로 조회'],
    ),
    OnboardingSlide(
      titleTop: '아끼는 사람들이 모여 있는',
      titleMain: '절약 커뮤니티',
      icon: Icons.forum_rounded,
      color: AppColors.categoryCafe,
      previewTitle: '절약 인증 게시판',
      points: ['한 달 식비 20만원 도전기', '무지출 챌린지 7일차 인증', '자취생 공과금 아끼는 꿀팁'],
    ),
  ];
}
