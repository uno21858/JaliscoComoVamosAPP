import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/core.dart';
import '../../core/router/app_routes.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/widgets.dart';
import 'widgets/auth_form.dart';

/// 3.1 Acceso: entrar o crear cuenta con correo y contraseña.
class AccessScreen extends StatefulWidget {
  const AccessScreen({super.key, this.register = false});

  final bool register;

  @override
  State<AccessScreen> createState() => _AccessScreenState();
}

class _AccessScreenState extends State<AccessScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  late bool _register = widget.register;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (!looksLikeEmail(email)) return setState(() => _error = 'Escribe un correo válido.');
    if (_register && !isTecEmail(email)) return setState(() => _error = tecOnlyMessage);
    if (password.length < 8) return setState(() => _error = 'La contraseña necesita al menos 8 caracteres.');

    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = context.read<AuthService?>()!;
    final String? error;
    if (_register) {
      final result = await auth.signUp(email, password);
      error = switch (result) { Ok() => null, Err(:final failure) => failure.message };
      if (error == null && mounted) {
        unawaited(context.push(AppRoutes.verifyEmail, extra: (email: email, password: password)));
      }
    } else {
      final result = await auth.signIn(email, password);
      switch (result) {
        case Ok(value: SignInOutcome.signedIn):
          error = null;
          if (mounted) context.go(AppRoutes.surveys);
        case Ok(value: SignInOutcome.needsConfirmation):
          // Se registró y no confirmó: se le manda otro código.
          await auth.resendCode(email);
          error = null;
          if (mounted) {
            unawaited(context.push(AppRoutes.verifyEmail, extra: (email: email, password: password)));
          }
        case Err(:final failure):
          error = failure.message;
      }
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await context.read<AuthService?>()!.signInWithGoogle();
    if (!mounted) return;
    if (result case Ok(value: true)) return context.go(AppRoutes.surveys);
    setState(() {
      _busy = false;
      _error = switch (result) { Err(:final failure) => failure.message, _ => null };
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasGoogle = context.read<AuthService?>()?.hasGoogle ?? false;
    return AuthForm(
      title: _register ? 'Crear cuenta' : 'Iniciar sesión',
      intro: _register
          ? 'Usa tu correo @tec.mx. Con tu cuenta cada encuesta se cuenta una sola vez. '
              'Tus respuestas no quedan ligadas a tu correo.'
          : 'Entra con tu correo @tec.mx para responder las encuestas.',
      busy: _busy,
      error: _error,
      submitLabel: _register ? 'Crear cuenta' : 'Entrar',
      onSubmit: _submit,
      fields: [
        AuthField(
          label: 'Correo',
          field: JcvTextField(
            controller: _email,
            semanticLabel: 'Correo',
            hintText: 'A01234567@tec.mx',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
          ),
        ),
        AuthField(
          label: 'Contraseña',
          field: JcvTextField(
            controller: _password,
            semanticLabel: 'Contraseña',
            hintText: _register ? 'Mínimo 8, con mayúscula y número' : null,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => unawaited(_submit()),
            autofillHints: [_register ? AutofillHints.newPassword : AutofillHints.password],
          ),
        ),
      ],
      footer: [
        if (hasGoogle) ...[
          JcvButton(
            label: 'Continuar con Google',
            variant: JcvButtonVariant.secondary,
            onPressed: _busy ? null : () => unawaited(_google()),
          ),
          const SizedBox(height: 12),
        ],
        if (!_register)
          Center(
            child: JcvTextButton(
              label: '¿Olvidaste tu contraseña?',
              onPressed: () => unawaited(context.push(AppRoutes.resetPassword, extra: _email.text.trim())),
            ),
          ),
        Center(
          child: JcvTextButton(
            label: _register ? 'Ya tengo cuenta' : 'Crear una cuenta',
            underline: true,
            onPressed: () => setState(() {
              _register = !_register;
              _error = null;
            }),
          ),
        ),
      ],
    );
  }
}
