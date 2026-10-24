import 'package:flutter/foundation.dart';

import '../core/result.dart';
import '../core/utils/formatters.dart';
import '../core/utils/money.dart';
import '../models/donation.dart';
import '../repositories/donation_repository.dart';

/// Formulario de donativo (4.1 y 4.3). Todo en centavos.
class DonateController extends ChangeNotifier {
  DonateController(this._repository);

  final DonationRepository _repository;

  static const presets = <int>[5000, 10000, 20000];

  int? _preset = 10000;
  String _customText = '';
  String _email = '';
  bool _busy = false;
  String? _error;

  int? get selectedPreset => _preset;
  String get customText => _customText;
  String get email => _email;
  bool get busy => _busy;
  String? get error => _error;

  bool get usingCustom => _customText.trim().isNotEmpty;

  int? get amountCents => usingCustom ? Money.parseCents(_customText) : _preset;

  /// Error del campo "Otro monto". Solo aparece si la persona escribió algo.
  String? get amountError {
    if (!usingCustom) return null;
    final cents = Money.parseCents(_customText);
    if (cents == null) return 'Escribe un monto válido, por ejemplo 150.00';
    if (cents < Money.minDonationCents) {
      return 'El donativo mínimo es de ${Money.format(Money.minDonationCents)}';
    }
    if (cents > Money.maxDonationCents) {
      return 'El donativo máximo es de ${Money.format(Money.maxDonationCents)}';
    }
    return null;
  }

  bool get emailValid => EmailValidator.isValid(_email);

  bool get canDonate {
    final cents = amountCents;
    return !_busy &&
        cents != null &&
        amountError == null &&
        cents >= Money.minDonationCents &&
        cents <= Money.maxDonationCents &&
        emailValid;
  }

  /// Texto del botón: "Donar $100.00 MXN", o solo "Donar" si no hay monto válido.
  String get buttonLabel {
    final cents = amountCents;
    if (cents == null || amountError != null) return 'Donar';
    return 'Donar ${Money.format(cents)}';
  }

  void selectPreset(int cents) {
    _preset = cents;
    _customText = '';
    _error = null;
    notifyListeners();
  }

  void setCustomText(String text) {
    _customText = text;
    if (text.trim().isNotEmpty) _preset = null;
    _error = null;
    notifyListeners();
  }

  void setEmail(String email) {
    _email = email;
    _error = null;
    notifyListeners();
  }

  /// Crea el intento en el servidor. Devuelve null y deja [error] si falla.
  Future<DonationIntent?> createIntent() async {
    final cents = amountCents;
    if (!canDonate || cents == null) return null;
    _busy = true;
    _error = null;
    notifyListeners();
    final result = await _repository.createIntent(amountCents: cents, email: _email.trim());
    _busy = false;
    switch (result) {
      case Ok(:final value):
        notifyListeners();
        return value;
      case Err(:final failure):
        _error = failure.message;
        notifyListeners();
        return null;
    }
  }

  /// Pregunta al servidor cómo quedó el pago.
  Future<DonationReceipt?> fetchReceipt(String intentId) async {
    _busy = true;
    notifyListeners();
    final result = await _repository.fetchReceipt(intentId);
    _busy = false;
    switch (result) {
      case Ok(:final value):
        notifyListeners();
        return value;
      case Err(:final failure):
        _error = failure.message;
        notifyListeners();
        return null;
    }
  }

  void stopBusy() {
    _busy = false;
    notifyListeners();
  }
}
