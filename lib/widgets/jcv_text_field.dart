import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';

/// Campo relleno del wireflow (gris azulado, radio 14, 52 de alto).
/// Con [errorText] cambia a fondo blanco y borde rojo, como en 4.3.
class JcvTextField extends StatelessWidget {
  const JcvTextField({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.semanticLabel,
    this.prefixIcon,
    this.prefixText,
    this.suffixText,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
    this.outlined = false,
    this.enabled = true,
    this.maxLength,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? semanticLabel;
  final IconData? prefixIcon;
  final String? prefixText;
  final String? suffixText;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  /// Variante blanca con borde (como el "otro correo" de 4.2).
  final bool outlined;
  final bool enabled;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    final icon = prefixIcon;
    final prefix = prefixText;
    final suffix = suffixText;

    final Color background;
    final Border? border;
    if (hasError) {
      background = AppColors.white;
      border = Border.all(color: AppColors.raspberry, width: 2);
    } else if (outlined) {
      background = AppColors.white;
      border = Border.all(color: AppColors.grayBlue, width: 1.5);
    } else {
      background = AppColors.grayBlue;
      border = null;
    }

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: border,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 10),
          ],
          if (prefix != null) ...[
            Text(
              prefix,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              inputFormatters: inputFormatters,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              autofillHints: autofillHints,
              maxLength: maxLength,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                counterText: '',
                semanticCounterText: '',
                // Si no hay placeholder, el lector de pantalla lee la etiqueta.
                hintText: hintText ?? semanticLabel,
                hintStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          if (suffix != null) ...[
            const SizedBox(width: 8),
            Text(
              suffix,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Etiqueta arriba de un campo, con marca opcional de "Obligatorio".
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false});

  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 16 / 13,
                fontWeight: FontWeight.w800,
                color: AppColors.navyDark,
              ),
            ),
          ),
          if (required)
            const Text(
              'Obligatorio',
              style: TextStyle(
                fontSize: 11,
                height: 16 / 11,
                fontWeight: FontWeight.w800,
                color: AppColors.wine,
              ),
            ),
        ],
      ),
    );
  }
}
