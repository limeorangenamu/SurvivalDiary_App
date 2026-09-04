import 'data/policy_models.dart';

/// 마감일 당일까지는 표시하며, 기간을 알 수 없는 정책은 임의로 제외하지 않는다.
bool isPolicyApplicationClosed({
  required PolicyApplicationPeriodType? type,
  required DateTime? endDate,
  required DateTime now,
}) {
  if (type == PolicyApplicationPeriodType.closed) {
    return true;
  }
  if (endDate == null) {
    return false;
  }
  final today = DateTime(now.year, now.month, now.day);
  final deadline = DateTime(endDate.year, endDate.month, endDate.day);
  return deadline.isBefore(today);
}

String formatPolicyApplicationPeriod({
  required PolicyApplicationPeriodType? type,
  required DateTime? startDate,
  required DateTime? endDate,
  required String? text,
}) {
  switch (type) {
    case PolicyApplicationPeriodType.always:
      return '상시 신청';
    case PolicyApplicationPeriodType.closed:
      return '접수 마감';
    case PolicyApplicationPeriodType.untilBudget:
      return '예산 소진 시까지';
    case PolicyApplicationPeriodType.fixed:
    case PolicyApplicationPeriodType.unknown:
    case null:
      if (startDate != null && endDate != null) {
        final start = _shortDate(startDate);
        final end = _shortDate(endDate);
        return start == end ? start : '$start ~ $end';
      }
      if (text != null && text.trim().isNotEmpty) {
        return formatPolicyApplicationPeriodText(text);
      }
      if (endDate != null) {
        return '${_shortDate(endDate)}까지';
      }
      if (startDate != null) {
        return '${_shortDate(startDate)}부터';
      }
      return '신청 기간 확인 필요';
  }
}

/// 원문의 시간·추가 안내는 유지하고, 유효한 날짜 표기만 통일한다.
String formatPolicyApplicationPeriodText(String text) {
  return text
      .replaceAllMapped(
        RegExp(
          r'(?<!\d)(\d{4})(?:[.\-/](\d{1,2})[.\-/](\d{1,2})|(\d{2})(\d{2}))(?!\d)',
        ),
        (match) {
          final year = int.parse(match[1]!);
          final month = int.parse((match[2] ?? match[4])!);
          final day = int.parse((match[3] ?? match[5])!);
          final date = DateTime(year, month, day);
          if (date.year != year || date.month != month || date.day != day) {
            return match[0]!;
          }
          return _shortDate(date);
        },
      )
      .replaceAll(RegExp(r'\s*[~～]\s*'), ' ~ ')
      .trim();
}

String _shortDate(DateTime date) =>
    '${(date.year % 100).toString().padLeft(2, '0')}.'
    '${date.month.toString().padLeft(2, '0')}.'
    '${date.day.toString().padLeft(2, '0')}';
