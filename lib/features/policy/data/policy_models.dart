import '../../../data/models.dart';

enum PolicyEligibilityStatus { matched, checkRequired }

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

class PolicySummary {
  const PolicySummary({
    required this.policyId,
    required this.category,
    required this.categoryType,
    required this.title,
    required this.summary,
    required this.supportAmount,
    required this.supportText,
    required this.applicationPeriodText,
    required this.target,
    required this.agency,
    required this.eligibilityStatus,
    required this.eligibilityReasons,
  });

  factory PolicySummary.fromJson(Map<String, dynamic> json) {
    return PolicySummary(
      policyId: _requiredString(json, 'policyId'),
      category: _requiredString(json, 'category'),
      categoryType: _policyCategory(json['categoryType']),
      title: _requiredString(json, 'title'),
      summary: _requiredString(json, 'summary'),
      supportAmount: _nullableInt(json, 'supportAmount'),
      supportText: _requiredString(json, 'supportText'),
      applicationPeriodText: _nullableString(json, 'applicationPeriodText'),
      target: _requiredString(json, 'target'),
      agency: _requiredString(json, 'agency'),
      eligibilityStatus: _eligibilityStatus(json['eligibilityStatus']),
      eligibilityReasons: _stringList(json, 'eligibilityReasons'),
    );
  }

  final String policyId;
  final String category;
  final PolicyCategory? categoryType;
  final String title;
  final String summary;
  final int? supportAmount;
  final String supportText;
  final String? applicationPeriodText;
  final String target;
  final String agency;
  final PolicyEligibilityStatus eligibilityStatus;
  final List<String> eligibilityReasons;
}

class PolicyDetail {
  const PolicyDetail({
    required this.policyId,
    required this.category,
    required this.categoryType,
    required this.title,
    required this.description,
    required this.supportAmount,
    required this.supportText,
    required this.applicationPeriodText,
    required this.target,
    required this.agency,
    required this.operatingAgency,
    required this.applicationMethod,
    required this.documents,
    required this.officialUrl,
    required this.referenceUrls,
  });

  factory PolicyDetail.fromJson(Map<String, dynamic> json) {
    return PolicyDetail(
      policyId: _requiredString(json, 'policyId'),
      category: _requiredString(json, 'category'),
      categoryType: _policyCategory(json['categoryType']),
      title: _requiredString(json, 'title'),
      description: _requiredString(json, 'description'),
      supportAmount: _nullableInt(json, 'supportAmount'),
      supportText: _requiredString(json, 'supportText'),
      applicationPeriodText: _nullableString(json, 'applicationPeriodText'),
      target: _requiredString(json, 'target'),
      agency: _requiredString(json, 'agency'),
      operatingAgency: _requiredString(json, 'operatingAgency'),
      applicationMethod: _requiredString(json, 'applicationMethod'),
      documents: _stringList(json, 'documents'),
      officialUrl: _nullableString(json, 'officialUrl'),
      referenceUrls: _stringList(json, 'referenceUrls'),
    );
  }

  final String policyId;
  final String category;
  final PolicyCategory? categoryType;
  final String title;
  final String description;
  final int? supportAmount;
  final String supportText;
  final String? applicationPeriodText;
  final String target;
  final String agency;
  final String operatingAgency;
  final String applicationMethod;
  final List<String> documents;
  final String? officialUrl;
  final List<String> referenceUrls;
}

class PolicyDetailArguments {
  const PolicyDetailArguments({
    required this.policyId,
    required this.eligibilityStatus,
    required this.eligibilityReasons,
  });

  final String policyId;
  final PolicyEligibilityStatus eligibilityStatus;
  final List<String> eligibilityReasons;
}

enum PolicyExternalLinkType { application, reference }

class PolicyExternalLinkArguments {
  const PolicyExternalLinkArguments({
    required this.title,
    required this.url,
    required this.type,
  });

  final String title;
  final String url;
  final PolicyExternalLinkType type;
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
