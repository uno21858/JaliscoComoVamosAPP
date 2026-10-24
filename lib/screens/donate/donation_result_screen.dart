import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/core.dart';
import '../../core/router/app_routes.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

/// 4.5 Pago exitoso y 4.6 Pago rechazado. Solo `paid` muestra el éxito.
class DonationResultScreen extends StatelessWidget {
  const DonationResultScreen({super.key, required this.receipt});

  final DonationReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final paid = receipt.status == DonationStatus.paid;
    return Scaffold(
      body: Column(
        children: [
          RootHeader(
            title: 'Donar',
            subtitle: paid ? 'Pago completado' : 'Pago no completado',
          ),
          Expanded(child: paid ? _Success(receipt: receipt) : const _Failure()),
        ],
      ),
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.receipt});

  final DonationReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final amount = Money.format(receipt.amountCents);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 24),
      children: [
        const Center(
          child: IconCircle(
            icon: CupertinoIcons.checkmark_seal_fill,
            size: 88,
            iconSize: 44,
            background: AppColors.lime,
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          header: true,
          child: Text(
            '¡Gracias! Tu donativo de $amount fue recibido',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              height: 28 / 22,
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Enviamos tu comprobante a '),
              TextSpan(
                text: receipt.email,
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
              ),
              const TextSpan(text: '.'),
            ],
          ),
          textAlign: TextAlign.center,
          style: AppTextStyles.body,
        ),
        const SizedBox(height: 22),
        JcvCard(
          child: Column(
            children: [
              _ReceiptRow(label: 'Monto', value: amount),
              const SizedBox(height: 12),
              _ReceiptRow(label: 'Fecha', value: Formatters.date(receipt.date)),
              const SizedBox(height: 12),
              _ReceiptRow(label: 'Folio', value: receipt.folio),
            ],
          ),
        ),
        const SizedBox(height: 20),
        JcvButton(label: 'Volver al inicio', onPressed: () => context.go(AppRoutes.home)),
        const SizedBox(height: 4),
        Center(
          child: JcvTextButton(
            label: 'Hacer otro donativo',
            onPressed: () => context.go(AppRoutes.donate),
          ),
        ),
      ],
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure();

  @override
  Widget build(BuildContext context) {
    return CenteredStateView(
      icon: CupertinoIcons.xmark_circle_fill,
      circleColor: AppColors.errorCircle,
      iconColor: AppColors.raspberry,
      circleSize: 88,
      title: 'Tu pago no se completó',
      message: 'No se realizó ningún cargo. Revisa los datos o intenta con otro método.',
      actions: [
        JcvButton(
          label: 'Intentar de nuevo',
          leadingIcon: CupertinoIcons.arrow_clockwise,
          onPressed: () => context.go(AppRoutes.donate),
        ),
        JcvTextButton(label: 'Volver al inicio', onPressed: () => context.go(AppRoutes.home)),
      ],
    );
  }
}
