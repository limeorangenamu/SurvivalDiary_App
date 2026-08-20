import '../../data/models.dart';

class PlaceExpenseSummary {
  const PlaceExpenseSummary({
    required this.totalAmount,
    required this.paymentCount,
    required this.latestAmount,
    required this.latestDate,
  });

  final int totalAmount;
  final int paymentCount;
  final int latestAmount;
  final DateTime latestDate;
}

PlaceExpenseSummary? summarizeCardExpensesForPlace({
  required Iterable<Expense> expenses,
  required Iterable<String> placeNames,
}) {
  final normalizedPlaceNames = placeNames
      .map(_normalizeMerchantName)
      .where((name) => name.length >= 3)
      .toSet();
  if (normalizedPlaceNames.isEmpty) {
    return null;
  }

  final matches = expenses.where((expense) {
    if (expense.entryType != ExpenseEntryType.auto || expense.amount <= 0) {
      return false;
    }
    final merchantName = _normalizeMerchantName(expense.title);
    if (merchantName.length < 3) {
      return false;
    }
    return normalizedPlaceNames.any(
      (placeName) => _merchantMatchesPlace(merchantName, placeName),
    );
  }).toList(growable: false);
  if (matches.isEmpty) {
    return null;
  }

  final latest = matches.reduce(
    (current, candidate) =>
        candidate.date.isAfter(current.date) ? candidate : current,
  );
  return PlaceExpenseSummary(
    totalAmount: matches.fold(0, (total, expense) => total + expense.amount),
    paymentCount: matches.length,
    latestAmount: latest.amount,
    latestDate: latest.date,
  );
}

bool _merchantMatchesPlace(String merchantName, String placeName) {
  if (merchantName == placeName || merchantName.contains(placeName)) {
    return true;
  }
  if (!placeName.contains(merchantName) || merchantName.length < 5) {
    return false;
  }
  return merchantName.length / placeName.length >= 0.7;
}

String _normalizeMerchantName(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'\(주\)|주식회사|유한회사'), '')
      .replaceAll(RegExp(r'[^0-9a-z가-힣]'), '');
}
