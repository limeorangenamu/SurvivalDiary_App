import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum ExpenseCategory { food, cafe, transport, shopping, etc }

extension ExpenseCategoryExtension on ExpenseCategory {
  String get label => switch (this) {
        ExpenseCategory.food => '식비',
        ExpenseCategory.cafe => '카페',
        ExpenseCategory.transport => '교통',
        ExpenseCategory.shopping => '쇼핑',
        ExpenseCategory.etc => '기타',
      };

  IconData get icon => switch (this) {
        ExpenseCategory.food => Icons.restaurant_rounded,
        ExpenseCategory.cafe => Icons.local_cafe_rounded,
        ExpenseCategory.transport => Icons.directions_bus_rounded,
        ExpenseCategory.shopping => Icons.shopping_bag_rounded,
        ExpenseCategory.etc => Icons.more_horiz_rounded,
      };

  Color get color => switch (this) {
        ExpenseCategory.food => AppColors.categoryFood,
        ExpenseCategory.cafe => AppColors.categoryCafe,
        ExpenseCategory.transport => AppColors.categoryTransport,
        ExpenseCategory.shopping => AppColors.categoryShopping,
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
  });

  final String userName;
  final int dailyLimit;
  final int remainingToday;
  final int spentToday;
  final int savedToday;
  final int dDay;
  final int weeklyBudget;
  final int weeklySpent;

  factory BudgetSummary.empty({String userName = ''}) => BudgetSummary(
        userName: userName,
        dailyLimit: 0,
        remainingToday: 0,
        spentToday: 0,
        savedToday: 0,
        dDay: 0,
        weeklyBudget: 0,
        weeklySpent: 0,
      );

  double get dailyProgress =>
      dailyLimit == 0 ? 0 : (spentToday / dailyLimit).clamp(0, 1);
  double get weeklyProgress =>
      weeklyBudget == 0 ? 0 : (weeklySpent / weeklyBudget).clamp(0, 1);
  bool get isNearLimit => dailyProgress >= 0.6 && dailyProgress < 1;
  bool get isOverLimit => spentToday >= dailyLimit;
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

enum PolicyEducationStatus { student, onLeave, graduated, notStudent, other }

extension PolicyEducationStatusExtension on PolicyEducationStatus {
  String get label => switch (this) {
        PolicyEducationStatus.student => '재학 중',
        PolicyEducationStatus.onLeave => '휴학 중',
        PolicyEducationStatus.graduated => '졸업',
        PolicyEducationStatus.notStudent => '학생이 아님',
        PolicyEducationStatus.other => '기타',
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
    this.educationStatus,
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
  final PolicyEducationStatus? educationStatus;
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

class HousingDeal {
  const HousingDeal({
    required this.id,
    required this.propertyName,
    required this.dealType,
    required this.amount,
    required this.dealDate,
    required this.area,
    required this.floor,
  });

  final String id;
  final String propertyName;
  final String dealType;
  final int amount;
  final DateTime dealDate;
  final double area;
  final int floor;
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
    required this.source,
    required this.timeAgo,
    required this.icon,
  });

  final String id;
  final String category;
  final String title;
  final String source;
  final String timeAgo;
  final IconData icon;
}
