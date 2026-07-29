class Formatters {
  Formatters._();

  static String amount(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[index]);
    }
    return '${value < 0 ? '-' : ''}${buffer.toString()}원';
  }

  static String compactAmount(int value) {
    if (value >= 100000000) {
      final eok = value / 100000000;
      return '${eok.toStringAsFixed(eok % 1 == 0 ? 0 : 1)}억원';
    }
    if (value >= 10000) {
      final man = value / 10000;
      return '${man.toStringAsFixed(man % 1 == 0 ? 0 : 1)}만원';
    }
    return amount(value);
  }

  static String date(DateTime value) =>
      '${value.year}.${_two(value.month)}.${_two(value.day)}';

  static String shortDate(DateTime value) => '${value.month}/${value.day}';

  static String percent(double value) =>
      '${(value * 100).round().clamp(0, 999)}%';

  static String _two(int value) => value.toString().padLeft(2, '0');
}
