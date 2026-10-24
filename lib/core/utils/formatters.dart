abstract final class Formatters {
  /// 1200 -> "1,200"
  static String thousands(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }

  /// 42.6 -> "43%"
  static String percent(double value) => '${value.round()}%';

  /// 2026-11-04 -> "04/11/2026"
  static String date(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }
}

abstract final class EmailValidator {
  static final _pattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static bool isValid(String email) => _pattern.hasMatch(email.trim());
}
