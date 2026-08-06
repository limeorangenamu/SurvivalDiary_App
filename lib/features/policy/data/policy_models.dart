import '../../../data/models.dart';

enum PolicyEligibilityStatus { matched, checkRequired }

enum PolicyRecommendationStatus { recommended, checkRequired, discover }

enum PolicyMatchSignal {
  age,
  region,
  district,
  workStatus,
  jobSeeking,
  educationStatus,
  interestEmployment,
  interestHousing,
  interestEducation,
  interestWelfareCulture,
  interestParticipationRights,
  interestAssetBuilding,
  interestTransport,
}

enum PolicySupportAmountType { fixed, maximum, monthly, monthlyMaximum }

enum PolicyApplicationPeriodType {
  fixed,
  always,
  closed,
  untilBudget,
  unknown,
}

enum PolicyOfficialLinkType {
  applicationCandidate,
  loginRequired,
  institutionHome,
  unknown,
  unavailable,
}

class PolicyPreference {
  const PolicyPreference({
    required this.saved,
    required this.age,
    required this.regionCode,
    required this.districtCode,
    required this.workStatus,
    required this.jobSeeking,
    required this.educationStatus,
    required this.interests,
  });

  factory PolicyPreference.fromJson(Map<String, dynamic> json) {
    final saved = json['saved'];
    final age = json['age'];
    if (saved is! bool || (age != null && age is! num)) {
      throw const FormatException();
    }

    final regionCode = _nullableString(json, 'regionCode');
    if (saved && regionCode == null) {
      throw const FormatException();
    }

    final workStatus = _policyWorkStatus(
      json['workStatus'],
      legacyEmploymentStatus: json['employmentStatus'],
    );
    final educationStatus = _policyEducationStatus(
      json['educationStatus'],
      legacyEmploymentStatus: json['employmentStatus'],
    );
    final interests = _policyInterests(
      json['interests'],
      legacyCategory: json['category'],
    );

    return PolicyPreference(
      saved: saved,
      age: (age as num?)?.toInt(),
      regionCode: regionCode,
      districtCode: _nullableString(json, 'districtCode'),
      workStatus: workStatus,
      jobSeeking: _nullableBool(
        json['jobSeeking'],
        legacyEmploymentStatus: json['employmentStatus'],
      ),
      educationStatus: educationStatus,
      interests: interests,
    );
  }

  final bool saved;
  final int? age;
  final String? regionCode;
  final String? districtCode;
  final PolicyWorkStatus? workStatus;
  final bool? jobSeeking;
  final PolicyEducationStatus? educationStatus;
  final Set<PolicyInterest> interests;
}

class PolicySearchResult {
  const PolicySearchResult({
    required this.items,
    required this.partialResult,
    required this.checkedProviderPages,
    required this.nextPage,
  });

  factory PolicySearchResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final partialResult = json['partialResult'];
    final checkedProviderPages = json['checkedProviderPages'];
    final nextPage = json['nextPage'];
    if (rawItems is! List ||
        partialResult is! bool ||
        checkedProviderPages is! num ||
        (nextPage != null && nextPage is! num)) {
      throw const FormatException();
    }

    return PolicySearchResult(
      items: rawItems.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException();
        }
        return PolicySummary.fromJson(item);
      }).toList(),
      partialResult: partialResult,
      checkedProviderPages: checkedProviderPages.toInt(),
      nextPage: (nextPage as num?)?.toInt(),
    );
  }

  final List<PolicySummary> items;
  final bool partialResult;
  final int checkedProviderPages;
  final int? nextPage;
}

class HiddenPolicyResult {
  const HiddenPolicyResult({
    required this.items,
    required this.page,
    required this.totalElements,
    required this.hasNext,
  });

  factory HiddenPolicyResult.fromJson(Map<String, dynamic> json) {
    final content = json['content'];
    final page = json['page'];
    final totalElements = json['totalElements'];
    final hasNext = json['hasNext'];
    if (content is! List ||
        page is! num ||
        totalElements is! num ||
        hasNext is! bool) {
      throw const FormatException();
    }

    return HiddenPolicyResult(
      items: content.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException();
        }
        return HiddenPolicySummary.fromJson(item);
      }).toList(),
      page: page.toInt(),
      totalElements: totalElements.toInt(),
      hasNext: hasNext,
    );
  }

  final List<HiddenPolicySummary> items;
  final int page;
  final int totalElements;
  final bool hasNext;
}

class HiddenPolicySummary {
  const HiddenPolicySummary({
    required this.policyId,
    required this.title,
    required this.category,
    required this.shortSummary,
    required this.hiddenAt,
  });

  factory HiddenPolicySummary.fromJson(Map<String, dynamic> json) {
    return HiddenPolicySummary(
      policyId: _requiredString(json, 'policyId'),
      title: _requiredString(json, 'title'),
      category: _nullableString(json, 'category'),
      shortSummary: _nullableString(json, 'shortSummary'),
      hiddenAt: _requiredDateTime(json, 'hiddenAt'),
    );
  }

  final String policyId;
  final String title;
  final String? category;
  final String? shortSummary;
  final DateTime hiddenAt;
}

class PolicySummary {
  const PolicySummary({
    required this.policyId,
    required this.category,
    required this.categoryType,
    required this.title,
    required this.summary,
    this.shortSummary,
    required this.supportAmount,
    required this.supportAmountType,
    required this.supportText,
    required this.applicationPeriodText,
    required this.applicationPeriodType,
    required this.applicationStartDate,
    required this.applicationEndDate,
    required this.target,
    required this.agency,
    required this.eligibilityStatus,
    required this.eligibilityReasons,
    required this.recommendationStatus,
    required this.recommendationReasons,
    this.matchSignals = const [],
  });

  factory PolicySummary.fromJson(Map<String, dynamic> json) {
    final eligibilityStatus = _eligibilityStatus(json['eligibilityStatus']);
    final eligibilityReasons = _stringList(json, 'eligibilityReasons');
    return PolicySummary(
      policyId: _requiredString(json, 'policyId'),
      category: _requiredString(json, 'category'),
      categoryType: _policyCategory(json['categoryType']),
      title: _requiredString(json, 'title'),
      summary: _requiredString(json, 'summary'),
      shortSummary: _nullableString(json, 'shortSummary'),
      supportAmount: _nullableInt(json, 'supportAmount'),
      supportAmountType: _supportAmountType(json['supportAmountType']),
      supportText: _requiredString(json, 'supportText'),
      applicationPeriodText: _nullableString(json, 'applicationPeriodText'),
      applicationPeriodType: _applicationPeriodType(
        json['applicationPeriodType'],
      ),
      applicationStartDate: _nullableDate(json, 'applicationStartDate'),
      applicationEndDate: _nullableDate(json, 'applicationEndDate'),
      target: _requiredString(json, 'target'),
      agency: _requiredString(json, 'agency'),
      eligibilityStatus: eligibilityStatus,
      eligibilityReasons: eligibilityReasons,
      recommendationStatus: _recommendationStatus(
        json['recommendationStatus'],
        legacyStatus: eligibilityStatus,
      ),
      recommendationReasons: json['recommendationReasons'] == null
          ? eligibilityReasons
          : _stringList(json, 'recommendationReasons'),
      matchSignals: _policyMatchSignals(json['matchSignals']),
    );
  }

  final String policyId;
  final String category;
  final PolicyCategory? categoryType;
  final String title;
  final String summary;
  final String? shortSummary;
  final int? supportAmount;
  final PolicySupportAmountType? supportAmountType;
  final String supportText;
  final String? applicationPeriodText;
  final PolicyApplicationPeriodType? applicationPeriodType;
  final DateTime? applicationStartDate;
  final DateTime? applicationEndDate;
  final String target;
  final String agency;
  final PolicyEligibilityStatus eligibilityStatus;
  final List<String> eligibilityReasons;
  final PolicyRecommendationStatus recommendationStatus;
  final List<String> recommendationReasons;
  final List<PolicyMatchSignal> matchSignals;
}

class PolicyDetail {
  const PolicyDetail({
    required this.policyId,
    required this.category,
    required this.categoryType,
    required this.title,
    required this.description,
    required this.supportAmount,
    required this.supportAmountType,
    required this.supportText,
    required this.applicationPeriodText,
    required this.applicationPeriodType,
    required this.applicationStartDate,
    required this.applicationEndDate,
    required this.target,
    required this.agency,
    required this.operatingAgency,
    required this.applicationMethod,
    required this.documents,
    required this.officialUrl,
    required this.officialLinkType,
    required this.referenceUrls,
  });

  factory PolicyDetail.fromJson(Map<String, dynamic> json) {
    final officialUrl = _nullableString(json, 'officialUrl');
    return PolicyDetail(
      policyId: _requiredString(json, 'policyId'),
      category: _requiredString(json, 'category'),
      categoryType: _policyCategory(json['categoryType']),
      title: _requiredString(json, 'title'),
      description: _requiredString(json, 'description'),
      supportAmount: _nullableInt(json, 'supportAmount'),
      supportAmountType: _supportAmountType(json['supportAmountType']),
      supportText: _requiredString(json, 'supportText'),
      applicationPeriodText: _nullableString(json, 'applicationPeriodText'),
      applicationPeriodType: _applicationPeriodType(
        json['applicationPeriodType'],
      ),
      applicationStartDate: _nullableDate(json, 'applicationStartDate'),
      applicationEndDate: _nullableDate(json, 'applicationEndDate'),
      target: _requiredString(json, 'target'),
      agency: _requiredString(json, 'agency'),
      operatingAgency: _requiredString(json, 'operatingAgency'),
      applicationMethod: _requiredString(json, 'applicationMethod'),
      documents: _stringList(json, 'documents'),
      officialUrl: officialUrl,
      officialLinkType: _officialLinkType(
        json['officialLinkType'],
        hasUrl: officialUrl != null,
      ),
      referenceUrls: _stringList(json, 'referenceUrls'),
    );
  }

  final String policyId;
  final String category;
  final PolicyCategory? categoryType;
  final String title;
  final String description;
  final int? supportAmount;
  final PolicySupportAmountType? supportAmountType;
  final String supportText;
  final String? applicationPeriodText;
  final PolicyApplicationPeriodType? applicationPeriodType;
  final DateTime? applicationStartDate;
  final DateTime? applicationEndDate;
  final String target;
  final String agency;
  final String operatingAgency;
  final String applicationMethod;
  final List<String> documents;
  final String? officialUrl;
  final PolicyOfficialLinkType officialLinkType;
  final List<String> referenceUrls;
}

class PolicyDetailArguments {
  const PolicyDetailArguments({
    required this.policyId,
    required this.eligibilityStatus,
    required this.eligibilityReasons,
    this.recommendationStatus = PolicyRecommendationStatus.discover,
    this.recommendationReasons = const [],
    this.summary,
  });

  final String policyId;
  final PolicyEligibilityStatus eligibilityStatus;
  final List<String> eligibilityReasons;
  final PolicyRecommendationStatus recommendationStatus;
  final List<String> recommendationReasons;
  final PolicySummary? summary;
}

enum PolicyDetailAction { hide }

enum PolicyExternalLinkType { application, reference }

class PolicyExternalLinkArguments {
  const PolicyExternalLinkArguments({
    required this.title,
    required this.url,
    required this.type,
    this.officialLinkType = PolicyOfficialLinkType.unknown,
  });

  final String title;
  final String url;
  final PolicyExternalLinkType type;
  final PolicyOfficialLinkType officialLinkType;
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException();
  }
  return value.trim();
}

String? _nullableString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw const FormatException();
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _nullableInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! num) {
    throw const FormatException();
  }
  return value.toInt();
}

DateTime? _nullableDate(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw const FormatException();
  }
  final parsed = DateTime.tryParse(value.trim());
  if (parsed == null) {
    throw const FormatException();
  }
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime _requiredDateTime(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw const FormatException();
  }
  return DateTime.parse(value);
}

PolicySupportAmountType? _supportAmountType(Object? value) => switch (value) {
      'FIXED' => PolicySupportAmountType.fixed,
      'MAXIMUM' => PolicySupportAmountType.maximum,
      'MONTHLY' => PolicySupportAmountType.monthly,
      'MONTHLY_MAXIMUM' => PolicySupportAmountType.monthlyMaximum,
      _ => null,
    };

PolicyApplicationPeriodType? _applicationPeriodType(Object? value) =>
    switch (value) {
      'FIXED' => PolicyApplicationPeriodType.fixed,
      'ALWAYS' => PolicyApplicationPeriodType.always,
      'CLOSED' => PolicyApplicationPeriodType.closed,
      'UNTIL_BUDGET' => PolicyApplicationPeriodType.untilBudget,
      'UNKNOWN' => PolicyApplicationPeriodType.unknown,
      _ => null,
    };

PolicyOfficialLinkType _officialLinkType(Object? value,
        {required bool hasUrl}) =>
    switch (value) {
      'APPLICATION_CANDIDATE' => PolicyOfficialLinkType.applicationCandidate,
      'LOGIN_REQUIRED' => PolicyOfficialLinkType.loginRequired,
      'INSTITUTION_HOME' => PolicyOfficialLinkType.institutionHome,
      'UNAVAILABLE' => PolicyOfficialLinkType.unavailable,
      'UNKNOWN' => PolicyOfficialLinkType.unknown,
      _ => hasUrl
          ? PolicyOfficialLinkType.unknown
          : PolicyOfficialLinkType.unavailable,
    };

List<String> _stringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List || value.any((item) => item is! String)) {
    throw const FormatException();
  }
  return value.cast<String>().where((item) => item.trim().isNotEmpty).toList();
}

PolicyCategory? _policyCategory(Object? value) => switch (value) {
      'EMPLOYMENT' => PolicyCategory.employment,
      'HOUSING' => PolicyCategory.housing,
      'EDUCATION' => PolicyCategory.education,
      'WELFARE_CULTURE' || 'CULTURE' => PolicyCategory.welfareCulture,
      'PARTICIPATION_RIGHTS' => PolicyCategory.participationRights,
      null => null,
      _ => null,
    };

PolicyWorkStatus? _policyWorkStatus(
  Object? value, {
  required Object? legacyEmploymentStatus,
}) =>
    switch (value ?? legacyEmploymentStatus) {
      'EMPLOYED' => PolicyWorkStatus.employed,
      'SELF_EMPLOYED' => PolicyWorkStatus.selfEmployed,
      'JOB_SEEKING' || 'UNEMPLOYED' => PolicyWorkStatus.unemployed,
      'FREELANCER' => PolicyWorkStatus.freelancer,
      'DAILY_WORKER' => PolicyWorkStatus.dailyWorker,
      'PROSPECTIVE_FOUNDER' => PolicyWorkStatus.prospectiveFounder,
      'SHORT_TERM_WORKER' => PolicyWorkStatus.shortTermWorker,
      'FARMER' => PolicyWorkStatus.farmer,
      'OTHER' => PolicyWorkStatus.other,
      'STUDENT' || null => null,
      _ => throw const FormatException(),
    };

PolicyEducationStatus? _policyEducationStatus(
  Object? value, {
  required Object? legacyEmploymentStatus,
}) =>
    switch (value ?? (legacyEmploymentStatus == 'STUDENT' ? 'STUDENT' : null)) {
      'STUDENT' => PolicyEducationStatus.student,
      'ON_LEAVE' => PolicyEducationStatus.onLeave,
      'GRADUATED' => PolicyEducationStatus.graduated,
      'NOT_STUDENT' => PolicyEducationStatus.notStudent,
      'OTHER' => PolicyEducationStatus.other,
      null => null,
      _ => throw const FormatException(),
    };

bool? _nullableBool(
  Object? value, {
  required Object? legacyEmploymentStatus,
}) {
  if (value == null) {
    return legacyEmploymentStatus == 'JOB_SEEKING' ? true : null;
  }
  if (value is! bool) {
    throw const FormatException();
  }
  return value;
}

Set<PolicyInterest> _policyInterests(
  Object? value, {
  required Object? legacyCategory,
}) {
  if (value == null) {
    final legacy = _policyInterest(legacyCategory);
    return legacy == null ? const {} : {legacy};
  }
  if (value is! List || value.any((item) => item is! String)) {
    throw const FormatException();
  }
  return value.map(_policyInterest).whereType<PolicyInterest>().toSet();
}

PolicyInterest? _policyInterest(Object? value) => switch (value) {
      'EMPLOYMENT' => PolicyInterest.employment,
      'HOUSING' => PolicyInterest.housing,
      'EDUCATION' => PolicyInterest.education,
      'WELFARE_CULTURE' || 'CULTURE' => PolicyInterest.welfareCulture,
      'PARTICIPATION_RIGHTS' => PolicyInterest.participationRights,
      'ASSET_BUILDING' || 'ASSET' => PolicyInterest.assetBuilding,
      'TRANSPORT' => PolicyInterest.transport,
      null => null,
      _ => throw const FormatException(),
    };

PolicyEligibilityStatus _eligibilityStatus(Object? value) => switch (value) {
      'MATCHED' => PolicyEligibilityStatus.matched,
      'CHECK_REQUIRED' => PolicyEligibilityStatus.checkRequired,
      _ => throw const FormatException(),
    };

PolicyRecommendationStatus _recommendationStatus(
  Object? value, {
  required PolicyEligibilityStatus legacyStatus,
}) =>
    switch (value) {
      'RECOMMENDED' => PolicyRecommendationStatus.recommended,
      'CHECK_REQUIRED' => PolicyRecommendationStatus.checkRequired,
      'DISCOVER' => PolicyRecommendationStatus.discover,
      null when legacyStatus == PolicyEligibilityStatus.checkRequired =>
        PolicyRecommendationStatus.checkRequired,
      null => PolicyRecommendationStatus.discover,
      _ => throw const FormatException(),
    };

List<PolicyMatchSignal> _policyMatchSignals(Object? value) {
  if (value == null) {
    return const [];
  }
  if (value is! List || value.any((item) => item is! String)) {
    throw const FormatException();
  }
  return value
      .map(_policyMatchSignal)
      .whereType<PolicyMatchSignal>()
      .toSet()
      .toList();
}

PolicyMatchSignal? _policyMatchSignal(Object? value) => switch (value) {
      'AGE' => PolicyMatchSignal.age,
      'REGION' => PolicyMatchSignal.region,
      'DISTRICT' => PolicyMatchSignal.district,
      'WORK_STATUS' => PolicyMatchSignal.workStatus,
      'JOB_SEEKING' => PolicyMatchSignal.jobSeeking,
      'EDUCATION_STATUS' => PolicyMatchSignal.educationStatus,
      'INTEREST_EMPLOYMENT' => PolicyMatchSignal.interestEmployment,
      'INTEREST_HOUSING' => PolicyMatchSignal.interestHousing,
      'INTEREST_EDUCATION' => PolicyMatchSignal.interestEducation,
      'INTEREST_WELFARE_CULTURE' => PolicyMatchSignal.interestWelfareCulture,
      'INTEREST_PARTICIPATION_RIGHTS' =>
        PolicyMatchSignal.interestParticipationRights,
      'INTEREST_ASSET_BUILDING' => PolicyMatchSignal.interestAssetBuilding,
      'INTEREST_TRANSPORT' => PolicyMatchSignal.interestTransport,
      _ => null,
    };
