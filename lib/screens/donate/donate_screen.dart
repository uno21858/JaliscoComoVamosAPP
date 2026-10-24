import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/core.dart';
import '../../core/router/app_routes.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../repositories/repositories.dart';
import '../../widgets/widgets.dart';

/// 4.1 Donativo y 4.3 error de monto. Se puede donar sin cuenta.
class DonateScreen extends StatelessWidget {
  const DonateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DonateController>(
      create: (context) => DonateController(context.read<DonationRepository>()),
      child: const _DonateView(),
    );
  }
}

class _DonateView extends StatefulWidget {
  const _DonateView();

  @override
  State<_DonateView> createState() => _DonateViewState();
}

class _DonateViewState extends State<_DonateView> {
  final _amountController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();
  bool _emailTouched = false;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus && _emailController.text.isNotEmpty) {
        setState(() => _emailTouched = true);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  void _selectPreset(DonateController controller, int cents) {
    _amountController.clear();
    controller.selectPreset(cents);
    FocusScope.of(context).unfocus();
  }

  Future<void> _donate(DonateController controller) async {
    FocusScope.of(context).unfocus();
    final intent = await controller.createIntent();
    if (!mounted || intent == null) return;

    final outcome = await context.read<PaymentPresenter>().present(context, intent);
    if (!mounted) return;
    if (outcome == PaymentSheetOutcome.cancelled) {
      controller.stopBusy();
      return;
    }

    final receipt = await controller.fetchReceipt(intent.id);
    if (!mounted || receipt == null) return;
    context.go(
      receipt.status == DonationStatus.paid ? AppRoutes.donationSuccess : AppRoutes.donationFailed,
      extra: receipt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DonateController>();
    final amountError = controller.amountError;
    final showEmailError = _emailTouched && !controller.emailValid && controller.email.isNotEmpty;
    final serverError = controller.error;

    return Scaffold(
      body: Column(
        children: [
          const RootHeader(
            title: 'Donar',
            subtitle: 'Tu apoyo sostiene al observatorio ciudadano',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                const Text(
                  'Tu donativo ayuda a Jalisco Cómo Vamos a seguir midiendo cómo vamos.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.navyDark,
                  ),
                ),
                const SizedBox(height: 20),
                const FieldLabel('Elige un monto'),
                const SizedBox(height: 2),
                EvenGrid(
                  columns: 3,
                  spacing: 10,
                  children: [
                    for (final cents in DonateController.presets)
                      _AmountButton(
                        cents: cents,
                        selected: !controller.usingCustom && controller.selectedPreset == cents,
                        onTap: () => _selectPreset(controller, cents),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const FieldLabel('Otro monto'),
                JcvTextField(
                  controller: _amountController,
                  semanticLabel: 'Otro monto en pesos',
                  hintText: 'Mínimo \$20.00',
                  prefixText: '\$',
                  suffixText: 'MXN',
                  errorText: amountError,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    LengthLimitingTextInputFormatter(12),
                  ],
                  onChanged: controller.setCustomText,
                ),
                if (amountError != null) ...[
                  const SizedBox(height: 6),
                  _InlineError(amountError),
                ],
                const SizedBox(height: 16),
                const FieldLabel('Correo para tu recibo', required: true),
                JcvTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  hintText: 'tucorreo@ejemplo.com',
                  prefixIcon: CupertinoIcons.mail,
                  errorText: showEmailError ? 'Escribe un correo válido' : null,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  onChanged: controller.setEmail,
                ),
                const SizedBox(height: 6),
                if (showEmailError)
                  const _InlineError('Escribe un correo válido, por ejemplo tucorreo@ejemplo.com')
                else
                  const Text('Ahí te llega tu comprobante.', style: AppTextStyles.caption),
                const SizedBox(height: 16),
                const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(CupertinoIcons.lock_fill, size: 14, color: AppColors.navyDark),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pagas en el siguiente paso con Apple Pay, Google Pay o tarjeta.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 18 / 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navyDark,
                        ),
                      ),
                    ),
                  ],
                ),
                if (serverError != null) ...[
                  const SizedBox(height: 14),
                  _InlineError(serverError),
                ],
                const SizedBox(height: 24),
                JcvButton(
                  label: controller.buttonLabel,
                  busy: controller.busy,
                  onPressed: controller.canDonate ? () => unawaited(_donate(controller)) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountButton extends StatelessWidget {
  const _AmountButton({required this.cents, required this.selected, required this.onTap});

  final int cents;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: '${Money.formatShort(cents)} pesos',
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.navy : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.navy : AppColors.grayBlue,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  Money.formatShort(cents),
                  style: TextStyle(
                    fontSize: 20,
                    height: 24 / 20,
                    fontWeight: FontWeight.w900,
                    color: selected ? AppColors.white : AppColors.navy,
                  ),
                ),
                Text(
                  'MXN',
                  style: TextStyle(
                    fontSize: 11,
                    height: 14 / 11,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.white.withValues(alpha: 0.86)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(CupertinoIcons.exclamationmark_circle_fill, size: 14, color: AppColors.wine),
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: AppTextStyles.error)),
        ],
      ),
    );
  }
}
