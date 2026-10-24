import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../flavors/flavor_config.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import '../../services/mock/mock_donation_service.dart';
import '../../widgets/widgets.dart';

/// 4.4 Hoja de pago SIMULADA. No captura datos de tarjeta: los campos están
/// deshabilitados a propósito. En producción esta parte la dibuja Stripe
/// (PaymentSheet o Checkout), y la app nunca ve la tarjeta (RF-DON-01).
class MockPaymentPresenter implements PaymentPresenter {
  MockPaymentPresenter(this._service);

  final MockDonationService _service;

  @override
  Future<PaymentSheetOutcome> present(BuildContext context, DonationIntent intent) async {
    final outcome = await showModalBottomSheet<PaymentSheetOutcome>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.white,
      barrierColor: AppColors.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MockPaymentSheet(intent: intent),
    );
    final result = outcome ?? PaymentSheetOutcome.cancelled;
    if (result != PaymentSheetOutcome.cancelled) {
      _service.settle(intent.id, paid: result == PaymentSheetOutcome.completed);
    }
    return result;
  }
}

class _MockPaymentSheet extends StatelessWidget {
  const _MockPaymentSheet({required this.intent});

  final DonationIntent intent;

  @override
  Widget build(BuildContext context) {
    final isIos = defaultTargetPlatform == TargetPlatform.iOS;
    final amount = Money.format(intent.amountCents);
    void close(PaymentSheetOutcome outcome) => Navigator.of(context).pop(outcome);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetGrabber(),
            Row(
              children: [
                const Icon(CupertinoIcons.lock_fill, size: 14, color: AppColors.navy),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Pago seguro',
                    style: TextStyle(
                      fontSize: 15,
                      height: 20 / 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => close(PaymentSheetOutcome.cancelled),
                  icon: const Icon(CupertinoIcons.xmark, size: 16, color: AppColors.textSecondary),
                ),
              ],
            ),
            const Text(
              'Donativo a Jalisco Cómo Vamos',
              style: TextStyle(
                fontSize: 13,
                height: 18 / 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 28,
                height: 34 / 28,
                fontWeight: FontWeight.w900,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 14),
            JcvButton(
              label: isIos ? 'Pagar con Apple Pay' : 'Pagar con Google Pay',
              variant: JcvButtonVariant.black,
              onPressed: () => close(PaymentSheetOutcome.completed),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(child: Divider(color: AppColors.grayBlue)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text('o con tarjeta', style: AppTextStyles.caption),
                ),
                Expanded(child: Divider(color: AppColors.grayBlue)),
              ],
            ),
            const SizedBox(height: 10),
            const _DisabledField(icon: CupertinoIcons.creditcard, hint: 'Número de tarjeta'),
            const SizedBox(height: 8),
            const Row(
              children: [
                Expanded(child: _DisabledField(hint: 'MM/AA')),
                SizedBox(width: 12),
                Expanded(child: _DisabledField(hint: 'CVC')),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Simulación: en la app real estos campos los muestra Stripe.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 12),
            JcvButton(
              label: 'Pagar $amount',
              onPressed: () => close(PaymentSheetOutcome.completed),
            ),
            if (FlavorConfig.instance.isDev)
              Center(
                child: JcvTextButton(
                  label: 'Simular pago rechazado',
                  onPressed: () => close(PaymentSheetOutcome.declined),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DisabledField extends StatelessWidget {
  const _DisabledField({required this.hint, this.icon});

  final String hint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final iconData = icon;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayBlue, width: 1.5),
      ),
      child: Row(
        children: [
          if (iconData != null) ...[
            Icon(iconData, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 10),
          ],
          Text(
            hint,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
