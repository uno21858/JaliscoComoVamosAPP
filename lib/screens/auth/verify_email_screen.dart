import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/core.dart';
import '../../core/router/app_routes.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/auth_form.dart';

typedef PendingSignUp = ({String email, String password});

/// 3.3 Verifica tu correo: el código de 6 dígitos que manda Cognito.
/// Al confirmar entra solo (la contraseña viene en memoria desde 3.1).
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.pending});

  final PendingSignUp pending;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_code.text.trim().length != 6) return setState(() => _error = 'El código tiene 6 dígitos.');
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthService?>()!;
    final (:email, :password) = widget.pending;
    var result = await auth.confirm(email, _code.text);
    if (result.isOk) {
      result = switch (await auth.signIn(email, password)) {
        Ok() => const Ok(null),
        Err(:final failure) => Err(failure),
      };
    }
    if (!mounted) return;
    switch (result) {
      case Ok():
        context.go(AppRoutes.surveys);
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.message;
        });
    }
  }

  Future<void> _resend() async {
    final result = await context.read<AuthService?>()!.resendCode(widget.pending.email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(switch (result) { Ok() => 'Te mandamos otro código.', Err(:final failure) => failure.message }),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AuthForm(
      title: 'Verifica tu correo',
      intro: 'Te mandamos un código de 6 dígitos a ${widget.pending.email}. '
          'Si no lo ves, revisa tu carpeta de spam.',
      busy: _busy,
      error: _error,
      submitLabel: 'Confirmar',
      onSubmit: _confirm,
      fields: [
        AuthField(
          label: 'Código',
          field: JcvTextField(
            controller: _code,
            semanticLabel: 'Código de verificación',
            hintText: '123456',
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            autofillHints: const [AutofillHints.oneTimeCode],
            onSubmitted: (_) => unawaited(_confirm()),
          ),
        ),
      ],
      footer: [
        Center(child: JcvTextButton(label: 'Reenviar código', onPressed: () => unawaited(_resend()))),
      ],
    );
  }
}
