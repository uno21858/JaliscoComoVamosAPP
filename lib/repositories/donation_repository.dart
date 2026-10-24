import 'package:flutter/widgets.dart';

import '../core/result.dart';
import '../models/models.dart';

/// Donativos. El monto viaja en centavos y el servidor lo vuelve a validar.
abstract interface class DonationRepository {
  /// Crea el intento de pago en el servidor (Stripe).
  Future<Result<DonationIntent>> createIntent({
    required int amountCents,
    required String email,
  });

  /// Consulta el estado. Manda el servidor (webhook), no la app.
  Future<Result<DonationReceipt>> fetchReceipt(String intentId);
}

/// Muestra la interfaz de pago. Hoy es una hoja simulada; con Stripe será
/// PaymentSheet o Checkout en el navegador (decisión pendiente, RF-DON-01).
abstract interface class PaymentPresenter {
  Future<PaymentSheetOutcome> present(BuildContext context, DonationIntent intent);
}
