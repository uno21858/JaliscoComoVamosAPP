/// Estados del anexo B.2 del spec. `paid` solo lo pone el webhook firmado.
enum DonationStatus { pending, paid, failed, expired }

/// Intento de donativo creado en el servidor. El monto ya viene revalidado.
class DonationIntent {
  const DonationIntent({
    required this.id,
    required this.amountCents,
    required this.email,
  });

  final String id;
  final int amountCents;
  final String email;
}

/// Lo que devuelve la hoja de pago al cerrarse.
enum PaymentSheetOutcome { completed, declined, cancelled }

/// Comprobante que se muestra en 4.5.
class DonationReceipt {
  const DonationReceipt({
    required this.intentId,
    required this.amountCents,
    required this.email,
    required this.status,
    required this.date,
    required this.folio,
  });

  final String intentId;
  final int amountCents;
  final String email;
  final DonationStatus status;
  final DateTime date;
  final String folio;
}
