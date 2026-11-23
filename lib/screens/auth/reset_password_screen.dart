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

/// Recuperar contraseña: correo -> código + contraseña nueva -> entra solo.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final _email = TextEditingController(text: widget.initialEmail);
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (!looksLikeEmail(email)) return setState(() => _error = 'Escribe un correo válido.');
    if (_codeSent && _code.text.trim().length != 6) return setState(() => _error = 'El código tiene 6 dígitos.');
    if (_codeSent && _password.text.length < 8) {
      return setState(() => _error = 'La contraseña necesita al menos 8 caracteres.');
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthService?>()!;
    Result<void> result;
    if (!_codeSent) {
      result = await auth.forgotPassword(email);
    } else {
      result = await auth.resetPassword(email, _code.text, _password.text);
      if (result.isOk) {
        result = switch (await auth.signIn(email, _password.text)) {
          Ok() => const Ok(null),
          Err(:final failure) => Err(failure),
        };
      }
    }
    if (!mounted) return;
    switch (result) {
      case Ok() when _codeSent:
        context.go(AppRoutes.surveys);
      case Ok():
        setState(() {
          _busy = false;
          _codeSent = true;
        });
      case Err(:final failure):
        setState(() {
          _busy = false;
          _error = failure.message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthForm(
      title: 'Recuperar contraseña',
      intro: _codeSent
          ? 'Si hay una cuenta con ${_email.text.trim()}, te llegó un código. Escríbelo con tu contraseña nueva.'
          : 'Te mandamos un código a tu correo para cambiar la contraseña.',
      busy: _busy,
      error: _error,
      submitLabel: _codeSent ? 'Cambiar contraseña' : 'Mandar código',
      onSubmit: _submit,
      fields: [
        AuthField(
          label: 'Correo',
          field: JcvTextField(
            controller: _email,
            semanticLabel: 'Correo',
            enabled: !_codeSent,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
        ),
        if (_codeSent) ...[
          AuthField(
            label: 'Código',
            field: JcvTextField(
              controller: _code,
              semanticLabel: 'Código',
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofillHints: const [AutofillHints.oneTimeCode],
            ),
          ),
          AuthField(
            label: 'Contraseña nueva',
            field: JcvTextField(
              controller: _password,
              semanticLabel: 'Contraseña nueva',
              hintText: 'Mínimo 8, con mayúscula y número',
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              onSubmitted: (_) => unawaited(_submit()),
            ),
          ),
        ],
      ],
    );
  }
}
