import 'dart:math';

import '../../core/app_error.dart';
import '../../core/error_sanitizer.dart';
import '../../core/result.dart';
import '../../core/utils/money.dart';
import '../../models/donation.dart';
import '../../repositories/donation_repository.dart';
import 'mock_network.dart';

/// Implementación de [DonationRepository] sin Stripe. Guarda los intentos en
/// memoria. La hoja de pago simulada llama a [settle] con el resultado, que
/// es lo que en producción haría el webhook firmado de Stripe.
class MockDonationService implements DonationRepository {
  final _random = Random();
  final _intents = <String, DonationIntent>{};
  final _statuses = <String, DonationStatus>{};
  final _folios = <String, String>{};

  @override
  Future<Result<DonationIntent>> createIntent({
    required int amountCents,
    required String email,
  }) =>
      guardResult(() async {
        await simulateNetwork();
        // El servidor vuelve a validar el monto (RF-DON-06).
        if (amountCents < Money.minDonationCents) {
          throw ValidationError(
            'El donativo mínimo es de ${Money.format(Money.minDonationCents)}',
          );
        }
        if (amountCents > Money.maxDonationCents) {
          throw ValidationError(
            'El donativo máximo es de ${Money.format(Money.maxDonationCents)}',
          );
        }
        final id = 'mock_${DateTime.now().microsecondsSinceEpoch}';
        final intent = DonationIntent(id: id, amountCents: amountCents, email: email.trim());
        _intents[id] = intent;
        _statuses[id] = DonationStatus.pending;
        return intent;
      });

  /// Solo para el mock: registra cómo terminó la hoja de pago simulada.
  void settle(String intentId, {required bool paid}) {
    if (!_intents.containsKey(intentId)) return;
    _statuses[intentId] = paid ? DonationStatus.paid : DonationStatus.failed;
    if (paid) _folios[intentId] = (1000000 + _random.nextInt(8999999)).toString();
  }

  @override
  Future<Result<DonationReceipt>> fetchReceipt(String intentId) => guardResult(() async {
        await simulateNetwork();
        final intent = _intents[intentId];
        if (intent == null) throw const ValidationError('No encontramos ese donativo.');
        return DonationReceipt(
          intentId: intentId,
          amountCents: intent.amountCents,
          email: intent.email,
          status: _statuses[intentId] ?? DonationStatus.pending,
          date: DateTime.now(),
          folio: _folios[intentId] ?? '',
        );
      });
}
