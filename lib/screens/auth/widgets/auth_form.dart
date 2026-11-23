import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../../widgets/widgets.dart';

/// Esqueleto común de 3.1, 3.3 y recuperar contraseña: cabecera, intro,
/// campos y el error en rojo arriba del botón.
class AuthForm extends StatelessWidget {
  const AuthForm({
    super.key,
    required this.title,
    required this.intro,
    required this.fields,
    required this.submitLabel,
    required this.onSubmit,
    this.busy = false,
    this.error,
    this.footer = const [],
  });

  final String title;
  final String intro;
  final List<Widget> fields;
  final String submitLabel;
  final VoidCallback? onSubmit;
  final bool busy;
  final String? error;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    final message = error;
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          ScreenHeader(title: title),
          Expanded(
            child: AutofillGroup(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  Text(intro, style: AppTextStyles.body),
                  const SizedBox(height: 22),
                  ...fields,
                  if (message != null) ...[
                    const SizedBox(height: 4),
                    Semantics(liveRegion: true, child: Text(message, style: AppTextStyles.error)),
                  ],
                  const SizedBox(height: 20),
                  JcvButton(label: submitLabel, busy: busy, onPressed: onSubmit),
                  const SizedBox(height: 12),
                  ...footer,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etiqueta + campo con el espacio de abajo.
class AuthField extends StatelessWidget {
  const AuthField({super.key, required this.label, required this.field});

  final String label;
  final Widget field;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [FieldLabel(label), field],
      ),
    );
  }
}

bool looksLikeEmail(String value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
