/// Montos siempre en centavos y como enteros (RF-DON-05). Nunca double.
abstract final class Money {
  static const minDonationCents = 2000; // $20.00 MXN (BR-05)
  static const maxDonationCents = 1000000; // $10,000.00 MXN (BR-06)

  /// 10000 -> "$100.00 MXN"
  static String format(int cents, {bool withCurrency = true}) {
    final negative = cents < 0;
    final abs = cents.abs();
    final pesos = abs ~/ 100;
    final centavos = (abs % 100).toString().padLeft(2, '0');
    final text = '\$${_thousands(pesos)}.$centavos';
    return '${negative ? '-' : ''}$text${withCurrency ? ' MXN' : ''}';
  }

  /// 10000 -> "$100" (para los botones de monto sugerido).
  static String formatShort(int cents) => '\$${_thousands(cents ~/ 100)}';

  /// Convierte lo que escribe la persona en centavos.
  /// Acepta "100", "100.5", "1,000.00". Devuelve null si no es un monto.
  static int? parseCents(String raw) {
    final cleaned = raw.replaceAll(',', '').replaceAll(' ', '').trim();
    final match = RegExp(r'^(\d{1,7})(?:\.(\d{0,2}))?$').firstMatch(cleaned);
    if (match == null) return null;
    final pesos = int.parse(match.group(1)!);
    final decimals = (match.group(2) ?? '').padRight(2, '0');
    return pesos * 100 + int.parse(decimals);
  }

  static String _thousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }
}
