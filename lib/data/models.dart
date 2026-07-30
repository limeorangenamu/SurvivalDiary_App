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

enum PolicyEmploymentStatus { employed, jobSeeker, unemployed, student }

extension PolicyEmploymentStatusExtension on PolicyEmploymentStatus {
  String get label => switch (this) {
        PolicyEmploymentStatus.employed => '재직 중',
        PolicyEmploymentStatus.jobSeeker => '구직 중',
        PolicyEmploymentStatus.unemployed => '미취업',
        PolicyEmploymentStatus.student => '학생',
      };
}

enum PolicyIncomeRange { below50, below100, below150, noLimit }

extension PolicyIncomeRangeExtension on PolicyIncomeRange {
  String get label => switch (this) {
        PolicyIncomeRange.below50 => '중위소득 50% 이하',
        PolicyIncomeRange.below100 => '중위소득 100% 이하',
        PolicyIncomeRange.below150 => '중위소득 150% 이하',
        PolicyIncomeRange.noLimit => '소득 무관',
      };
}

enum PolicyCategory { housing, employment, asset, culture, transport }

extension PolicyCategoryExtension on PolicyCategory {
  String get label => switch (this) {
        PolicyCategory.housing => '주거',
        PolicyCategory.employment => '취업',
        PolicyCategory.asset => '자산형성',
        PolicyCategory.culture => '문화',
        PolicyCategory.transport => '교통',
      };
}

class PolicyFilterCondition {
  const PolicyFilterCondition({
    required this.age,
    required this.regionCode,
    required this.region,
    required this.employmentStatus,
    this.districtCode,
    this.district,
    this.incomeRange,
    this.category,
  });

  final int age;
  final String regionCode;
  final String region;
  final String? districtCode;
  final String? district;
  final PolicyEmploymentStatus employmentStatus;
  final PolicyIncomeRange? incomeRange;
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

class Policy {
  const Policy({
    required this.id,
    required this.category,
    required this.categoryType,
    required this.title,
    required this.summary,
    required this.supportAmount,
    required this.supportText,
    required this.deadline,
    required this.target,
    required this.agency,
    required this.applyMethod,
    required this.documents,
    required this.icon,
    required this.minAge,
    required this.maxAge,
    required this.eligibleRegionCodes,
    required this.employmentStatuses,
    required this.incomeRanges,
    this.officialUrl,
    this.contact,
  });

  final String id;
  final String category;
  final PolicyCategory categoryType;
  final String title;
  final String summary;
  final int? supportAmount;
  final String supportText;
  final String? deadline;
  final String target;
  final String agency;
  final String applyMethod;
  final List<String> documents;
  final IconData icon;
  final int minAge;
  final int maxAge;
  final List<String> eligibleRegionCodes;
  final List<PolicyEmploymentStatus> employmentStatuses;
  final List<PolicyIncomeRange> incomeRanges;
  final String? officialUrl;
  final String? contact;
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
