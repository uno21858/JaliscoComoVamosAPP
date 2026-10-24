import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../../models/models.dart';
import '../../../widgets/widgets.dart';

/// Elige el control según el tipo de pregunta.
class QuestionInput extends StatelessWidget {
  const QuestionInput({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
    required this.onToggle,
  });

  final Question question;
  final Object? value;
  final ValueChanged<Object> onChanged;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case QuestionType.age:
        return AgeWheel(
          key: ValueKey('age-${question.id}'),
          question: question,
          value: value is int ? value as int : null,
          onChanged: onChanged,
        );
      case QuestionType.single:
        return Column(
          children: [
            for (final option in question.options) ...[
              OptionTile(
                label: option.label,
                selected: value == option.code,
                multiple: false,
                onTap: () => onChanged(option.code),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      case QuestionType.multiple:
        final selected = value is List<String> ? value as List<String> : const <String>[];
        final limit = question.maxSelections;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final option in question.options) ...[
              OptionTile(
                label: option.label,
                selected: selected.contains(option.code),
                multiple: true,
                onTap: () => onToggle(option.code),
              ),
              const SizedBox(height: 10),
            ],
            if (limit != null)
              Text(
                'Elegiste ${selected.length} de $limit.',
                style: AppTextStyles.caption,
              ),
          ],
        );
      case QuestionType.scale:
        return ScaleGrid(
          question: question,
          value: value is int ? value as int : null,
          onChanged: onChanged,
        );
    }
  }
}

/// Opción de respuesta: 60 de alto, radio o casilla a la izquierda.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.multiple,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool multiple;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      checked: multiple ? selected : null,
      inMutuallyExclusiveGroup: !multiple,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppColors.limePale : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.navy : AppColors.grayBlue,
            width: selected ? 2 : 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  if (multiple) _SquareMark(checked: selected) else _RadioMark(selected: selected),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 20 / 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(
          color: selected ? AppColors.navy : AppColors.textSecondary,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.navy),
            )
          : null,
    );
  }
}

class _SquareMark extends StatelessWidget {
  const _SquareMark({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? AppColors.navy : AppColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: checked ? AppColors.navy : AppColors.textSecondary,
          width: 2,
        ),
      ),
      child: checked
          ? const Icon(CupertinoIcons.checkmark_alt, size: 15, color: AppColors.white)
          : null,
    );
  }
}

/// 3.7 Rueda de edad dentro de una tarjeta, con "años" a la derecha.
class AgeWheel extends StatefulWidget {
  const AgeWheel({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final Question question;
  final int? value;
  final ValueChanged<Object> onChanged;

  @override
  State<AgeWheel> createState() => _AgeWheelState();
}

class _AgeWheelState extends State<AgeWheel> {
  late final FixedExtentScrollController _controller;

  int get _min => widget.question.min;
  int get _max => widget.question.max;

  @override
  void initState() {
    super.initState();
    final start = widget.value ?? widget.question.initialValue ?? _min;
    _controller = FixedExtentScrollController(initialItem: start.clamp(_min, _max).toInt() - _min);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return JcvCard(
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 216,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            CupertinoPicker(
              scrollController: _controller,
              itemExtent: 36,
              selectionOverlay: const SizedBox.shrink(),
              onSelectedItemChanged: (index) => widget.onChanged(_min + index),
              children: [
                for (var age = _min; age <= _max; age++)
                  Center(
                    child: Text(
                      '$age',
                      style: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
              ],
            ),
            const IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(left: 110),
                child: Text(
                  'años',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3.10 Escala numérica (por ejemplo 0 a 10) en rejilla de 6 columnas.
class ScaleGrid extends StatelessWidget {
  const ScaleGrid({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final Question question;
  final int? value;
  final ValueChanged<Object> onChanged;

  @override
  Widget build(BuildContext context) {
    final minLabel = question.minLabel;
    final maxLabel = question.maxLabel;
    return Column(
      children: [
        EvenGrid(
          columns: 6,
          children: [
            for (var n = question.min; n <= question.max; n++)
              _ScaleButton(number: n, selected: value == n, onTap: () => onChanged(n)),
          ],
        ),
        if (minLabel != null && maxLabel != null) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text('${question.min} · $minLabel', style: AppTextStyles.caption),
              ),
              Expanded(
                child: Text(
                  '${question.max} · $maxLabel',
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ScaleButton extends StatelessWidget {
  const _ScaleButton({required this.number, required this.selected, required this.onTap});

  final int number;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: selected ? AppColors.navy : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? AppColors.navy : AppColors.grayBlue,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.white : AppColors.navy,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 3.9 Aviso rosa cuando falta responder una pregunta obligatoria.
class RequiredAnswerBanner extends StatelessWidget {
  const RequiredAnswerBanner({super.key, this.message = 'Por favor responde la pregunta para continuar'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: NoticeBox(
        icon: CupertinoIcons.exclamationmark_circle_fill,
        iconColor: AppColors.wine,
        background: AppColors.errorBackground,
        text: message,
        textStyle: const TextStyle(
          fontSize: 13,
          height: 18 / 13,
          fontWeight: FontWeight.w800,
          color: AppColors.wine,
        ),
      ),
    );
  }
}
