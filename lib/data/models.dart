import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum ExpenseCategory { food, cafe, transport, shopping, leisure, etc }

extension ExpenseCategoryExtension on ExpenseCategory {
  String get label => switch (this) {
        ExpenseCategory.food => '식비',
        ExpenseCategory.cafe => '카페',
        ExpenseCategory.transport => '교통',
        ExpenseCategory.shopping => '쇼핑',
        ExpenseCategory.leisure => '여가',
        ExpenseCategory.etc => '기타',
      };

  IconData get icon => switch (this) {
        ExpenseCategory.food => Icons.restaurant_rounded,
        ExpenseCategory.cafe => Icons.local_cafe_rounded,
        ExpenseCategory.transport => Icons.directions_bus_rounded,
        ExpenseCategory.shopping => Icons.shopping_bag_rounded,
        ExpenseCategory.leisure => Icons.sports_esports_rounded,
        ExpenseCategory.etc => Icons.more_horiz_rounded,
      };

  Color get color => switch (this) {
        ExpenseCategory.food => AppColors.categoryFood,
        ExpenseCategory.cafe => AppColors.categoryCafe,
        ExpenseCategory.transport => AppColors.categoryTransport,
        ExpenseCategory.shopping => AppColors.categoryShopping,
        ExpenseCategory.leisure => AppColors.categoryLeisure,
        ExpenseCategory.etc => AppColors.categoryEtc,
      };
}

class BudgetSummary {
  const BudgetSummary({
    required this.userName,
    required this.dailyLimit,
    required this.remainingToday,
    required this.spentToday,
    required this.savedToday,
    required this.dDay,
    required this.weeklyBudget,
    required this.weeklySpent,
    this.monthlyBudget = 0,
    this.monthlySpent = 0,
    required this.topCategory,
    this.monthlyTopCategory,
  });

  final String userName;
  final int dailyLimit;
  final int remainingToday;
  final int spentToday;
  final int savedToday;
  final int dDay;
  final int weeklyBudget;
  final int weeklySpent;
  final int monthlyBudget;
  final int monthlySpent;
  final ExpenseCategory? topCategory;
  final ExpenseCategory? monthlyTopCategory;

  factory BudgetSummary.empty({String userName = ''}) => BudgetSummary(
        userName: userName,
        dailyLimit: 0,
        remainingToday: 0,
        spentToday: 0,
        savedToday: 0,
        dDay: 0,
        weeklyBudget: 0,
        weeklySpent: 0,
        monthlyBudget: 0,
        monthlySpent: 0,
        topCategory: null,
        monthlyTopCategory: null,
      );

  double get dailyProgress =>
      dailyLimit == 0 ? 0 : (spentToday / dailyLimit).clamp(0, 1);
  double get weeklyProgress =>
      weeklyBudget == 0 ? 0 : (weeklySpent / weeklyBudget).clamp(0, 1);
  double get monthlyProgress =>
      monthlyBudget == 0 ? 0 : (monthlySpent / monthlyBudget).clamp(0, 1);
  double get monthlyRemainingProgress => monthlyBudget == 0
      ? 0
      : ((monthlyBudget - monthlySpent) / monthlyBudget).clamp(0, 1);
  int get dailyUsagePercent => dailyLimit == 0
      ? 0
      : ((spentToday / dailyLimit) * 100).round().clamp(0, 999).toInt();
  int get monthlyUsagePercent => monthlyBudget == 0
      ? 0
      : ((monthlySpent / monthlyBudget) * 100).round().clamp(0, 999).toInt();
  int get monthlyRemainingPercent => monthlyBudget == 0
      ? 0
      : (((monthlyBudget - monthlySpent) / monthlyBudget) * 100)
          .round()
          .clamp(0, 100)
          .toInt();
  int get remainingMonth => (monthlyBudget - monthlySpent).clamp(0, 1 << 31);
  bool get isNearLimit => dailyProgress >= 0.6 && dailyProgress < 1;
  bool get isOverLimit => dailyLimit > 0 && spentToday >= dailyLimit;
}

class DetectedExpense {
  const DetectedExpense({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.detectedTime,
    required this.source,
    required this.category,
  });

  final String id;
  final String merchant;
  final int amount;
  final String detectedTime;
  final String source;
  final ExpenseCategory category;
}

class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    this.memo,
  });

  final String id;
  final String title;
  final int amount;
  final DateTime date;
  final ExpenseCategory category;
  final String? memo;
}

class CategoryStat {
  const CategoryStat({
    required this.category,
    required this.amount,
    required this.ratio,
  });

  final ExpenseCategory category;
  final int amount;
  final double ratio;
}

class MonthlyCompare {
  const MonthlyCompare({
    required this.label,
    required this.previous,
    required this.current,
  });

  final String label;
  final int previous;
  final int current;
}

enum PolicyWorkStatus {
  employed,
  selfEmployed,
  unemployed,
  freelancer,
  dailyWorker,
  prospectiveFounder,
  shortTermWorker,
  farmer,
  other,
}

extension PolicyWorkStatusExtension on PolicyWorkStatus {
  String get label => switch (this) {
        PolicyWorkStatus.employed => '재직자',
        PolicyWorkStatus.selfEmployed => '자영업자',
        PolicyWorkStatus.unemployed => '미취업자',
        PolicyWorkStatus.freelancer => '프리랜서',
        PolicyWorkStatus.dailyWorker => '일용근로자',
        PolicyWorkStatus.prospectiveFounder => '예비창업자',
        PolicyWorkStatus.shortTermWorker => '단기근로자',
        PolicyWorkStatus.farmer => '영농종사자',
        PolicyWorkStatus.other => '기타',
      };
}

enum PolicyEducationLevel {
  middleSchoolOrLess,
  highSchool,
  collegeTwoThreeYear,
  universityFourYear,
  graduateSchool,
  other,
}

extension PolicyEducationLevelExtension on PolicyEducationLevel {
  String get label => switch (this) {
        PolicyEducationLevel.middleSchoolOrLess => '중학교 졸업 이하',
        PolicyEducationLevel.highSchool => '고등학교',
        PolicyEducationLevel.collegeTwoThreeYear => '2·3년제 대학',
        PolicyEducationLevel.universityFourYear => '4년제 대학',
        PolicyEducationLevel.graduateSchool => '대학원 이상',
        PolicyEducationLevel.other => '기타 교육 과정',
      };
}

enum PolicyEnrollmentStatus {
  enrolled,
  onLeave,
  expectedGraduation,
  graduated,
  droppedOut,
  notApplicable,
}

extension PolicyEnrollmentStatusExtension on PolicyEnrollmentStatus {
  String get label => switch (this) {
        PolicyEnrollmentStatus.enrolled => '재학 중',
        PolicyEnrollmentStatus.onLeave => '휴학 중',
        PolicyEnrollmentStatus.expectedGraduation => '졸업 예정',
        PolicyEnrollmentStatus.graduated => '졸업',
        PolicyEnrollmentStatus.droppedOut => '중퇴',
        PolicyEnrollmentStatus.notApplicable => '해당 없음',
      };
}

enum PolicyCategory {
  employment,
  housing,
  education,
  welfareCulture,
  participationRights,
}

extension PolicyCategoryExtension on PolicyCategory {
  String get label => switch (this) {
        PolicyCategory.employment => '일자리·창업',
        PolicyCategory.housing => '주거',
        PolicyCategory.education => '교육·역량',
        PolicyCategory.welfareCulture => '복지·문화',
        PolicyCategory.participationRights => '참여·권리',
      };
}

enum PolicyInterest {
  employment,
  housing,
  education,
  welfareCulture,
  participationRights,
  assetBuilding,
  transport,
}

extension PolicyInterestExtension on PolicyInterest {
  String get label => switch (this) {
        PolicyInterest.employment => '일자리·창업',
        PolicyInterest.housing => '주거',
        PolicyInterest.education => '교육·역량',
        PolicyInterest.welfareCulture => '복지·문화',
        PolicyInterest.participationRights => '참여·권리',
        PolicyInterest.assetBuilding => '자산형성·금융',
        PolicyInterest.transport => '교통',
      };
}

class PolicyFilterCondition {
  const PolicyFilterCondition({
    required this.age,
    required this.regionCode,
    required this.region,
    this.districtCode,
    this.district,
    this.workStatus,
    this.jobSeeking,
    this.educationLevel,
    this.enrollmentStatus,
    this.interests = const {},
    this.category,
  });

  final int age;
  final String regionCode;
  final String region;
  final String? districtCode;
  final String? district;
  final PolicyWorkStatus? workStatus;
  final bool? jobSeeking;
  final PolicyEducationLevel? educationLevel;
  final PolicyEnrollmentStatus? enrollmentStatus;
  final Set<PolicyInterest> interests;
  final PolicyCategory? category;
}

class PolicyDistrictOption {
  const PolicyDistrictOption({required this.code, required this.name});

  final String code;
  final String name;
}

class PolicyRegionOption {
  const PolicyRegionOption({
    required this.code,
    required this.name,
    required this.districts,
  });

  final String code;
  final String name;
  final List<PolicyDistrictOption> districts;
}

enum PlaceType { goodPrice, publicFacility, publicParking }

extension PlaceTypeExtension on PlaceType {
  String get label => switch (this) {
        PlaceType.goodPrice => '착한가격업소',
        PlaceType.publicFacility => '공공시설',
        PlaceType.publicParking => '공영주차장',
      };

  IconData get icon => switch (this) {
        PlaceType.goodPrice => Icons.storefront_rounded,
        PlaceType.publicFacility => Icons.account_balance_rounded,
        PlaceType.publicParking => Icons.local_parking_rounded,
      };

  Color get color => switch (this) {
        PlaceType.goodPrice => AppColors.pinGoodPrice,
        PlaceType.publicFacility => AppColors.pinPublic,
        PlaceType.publicParking => AppColors.pinParking,
      };
}

class SavingPlace {
  const SavingPlace({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.distanceMeters,
    required this.baseFee,
    required this.operatingHours,
    required this.phone,
    required this.rating,
    required this.offsetX,
    required this.offsetY,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final PlaceType type;
  final String address;
  final int distanceMeters;
  final int baseFee;
  final String operatingHours;
  final String phone;
  final double rating;
  final double offsetX;
  final double offsetY;
  final double latitude;
  final double longitude;
}

class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.author,
    required this.authorEmoji,
    required this.timeAgo,
    required this.category,
    required this.title,
    required this.body,
    required this.hashtags,
    required this.likeCount,
    required this.commentCount,
    required this.hasImage,
    this.imageUrls = const [],
    this.imageAlignment = 'center',
    this.isLiked = false,
    this.isBookmarked = false,
    this.createdAt,
    this.isOwner = false,
    this.contentJson,
    this.authorRole = 'USER',
    this.commentsDisabled = false,
    this.commentsHidden = false,
  });

  final String id;
  final String author;
  final String authorEmoji;
  final String timeAgo;
  final String category;
  final String title;
  final String body;
  final List<String> hashtags;
  final int likeCount;
  final int commentCount;
  final bool hasImage;
  final List<String> imageUrls;
  final String imageAlignment;
  final bool isLiked;
  final bool isBookmarked;
  final DateTime? createdAt;
  final bool isOwner;
  final String? contentJson;
  final String authorRole;
  final bool commentsDisabled;
  final bool commentsHidden;
  bool get isAdminAuthor => authorRole == 'ADMIN';

  CommunityPost copyWith({
    int? likeCount,
    int? commentCount,
    bool? isLiked,
    bool? isBookmarked,
  }) {
    return CommunityPost(
      id: id,
      author: author,
      authorEmoji: authorEmoji,
      timeAgo: timeAgo,
      category: category,
      title: title,
      body: body,
      hashtags: hashtags,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      hasImage: hasImage,
      imageUrls: imageUrls,
      imageAlignment: imageAlignment,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt,
      isOwner: isOwner,
      contentJson: contentJson,
      authorRole: authorRole,
      commentsDisabled: commentsDisabled,
      commentsHidden: commentsHidden,
    );
  }
}

class CommunityComment {
  const CommunityComment({
    required this.id,
    required this.author,
    required this.content,
    required this.timeAgo,
    required this.createdAt,
    required this.isOwner,
  });

  final String id;
  final String author;
  final String content;
  final String timeAgo;
  final DateTime? createdAt;
  final bool isOwner;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timeAgo,
    required this.isUnread,
    required this.icon,
  });

  final String id;
  final String title;
  final String body;
  final String timeAgo;
  final bool isUnread;
  final IconData icon;
}

class OnboardingSlide {
  const OnboardingSlide({
    required this.titleTop,
    required this.titleMain,
    required this.icon,
    required this.color,
    required this.previewTitle,
    required this.points,
  });

  final String titleTop;
  final String titleMain;
  final IconData icon;
  final Color color;
  final String previewTitle;
  final List<String> points;
}

class HomeNews {
  const HomeNews({
    required this.id,
    required this.category,
    required this.title,
    required this.summary,
    required this.source,
    required this.sourceUrl,
    required this.publishedAt,
    required this.recommendationReason,
  });

  factory HomeNews.fromJson(Map<String, dynamic> json) {
    return HomeNews(
      id: (json['newsId'] as num).toInt(),
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      source: json['source'] as String? ?? '',
      sourceUrl: json['sourceUrl'] as String? ?? '',
      publishedAt: DateTime.parse(json['publishedAt'] as String),
      recommendationReason: json['recommendationReason'] as String? ?? '',
    );
  }

  final int id;
  final String category;
  final String title;
  final String summary;
  final String source;
  final String sourceUrl;
  final DateTime publishedAt;
  final String recommendationReason;

  IconData get icon => switch (category) {
        '생활경제' => Icons.shopping_bag_outlined,
        '금융' => Icons.account_balance_outlined,
        '절약' => Icons.lightbulb_outline_rounded,
        '정책' => Icons.newspaper_outlined,
        '트렌드' => Icons.auto_awesome_rounded,
        _ => Icons.article_outlined,
      };

  String get timeAgo {
    final difference = DateTime.now().difference(publishedAt);
    if (difference.isNegative || difference.inMinutes < 1) return '방금 전';
    if (difference.inHours < 1) return '${difference.inMinutes}분 전';
    if (difference.inDays < 1) return '${difference.inHours}시간 전';
    if (difference.inDays < 7) return '${difference.inDays}일 전';
    return '${publishedAt.month}월 ${publishedAt.day}일';
  }
}
