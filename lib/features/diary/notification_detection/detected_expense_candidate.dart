import '../../../data/models.dart';

class DetectedExpenseCandidate {
  const DetectedExpenseCandidate({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.detectedAt,
    required this.source,
    required this.sourcePackage,
    required this.category,
    required this.confidence,
  });

  final String id;
  final String merchant;
  final int amount;
  final DateTime detectedAt;
  final String source;
  final String sourcePackage;
  final ExpenseCategory category;
  final double confidence;

  bool get needsReview => confidence < 0.8;

  DetectedExpenseCandidate copyWith({
    String? merchant,
    int? amount,
    ExpenseCategory? category,
    double? confidence,
  }) {
    return DetectedExpenseCandidate(
      id: id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      detectedAt: detectedAt,
      source: source,
      sourcePackage: sourcePackage,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
    );
  }

  factory DetectedExpenseCandidate.fromPlatformMap(
    Map<Object?, Object?> map,
  ) {
    final categoryName = map['category'] as String? ?? 'etc';
    return DetectedExpenseCandidate(
      id: map['id']! as String,
      merchant: map['merchant']! as String,
      amount: (map['amount']! as num).toInt(),
      detectedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['detectedAt']! as num).toInt(),
      ),
      source: map['source']! as String,
      sourcePackage: map['sourcePackage']! as String,
      category: ExpenseCategory.values.firstWhere(
        (category) => category.name == categoryName,
        orElse: () => ExpenseCategory.etc,
      ),
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.7,
    );
  }
}
