import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

class _TabSpec {
  const _TabSpec(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Barra inferior: Inicio · Datos · + · Encuestas · Donar.
/// Ícono relleno = pestaña activa. El + abre el asistente desde cualquier lado.
class JcvTabBar extends StatelessWidget {
  const JcvTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAssistant,
  });

  /// 0 Inicio, 1 Datos, 2 Encuestas, 3 Donar.
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAssistant;

  static const _tabs = <_TabSpec>[
    _TabSpec('Inicio', CupertinoIcons.house, CupertinoIcons.house_fill),
    _TabSpec('Datos', CupertinoIcons.chart_bar, CupertinoIcons.chart_bar_fill),
    _TabSpec('Encuestas', CupertinoIcons.doc_text, CupertinoIcons.doc_text_fill),
    _TabSpec('Donar', CupertinoIcons.heart, CupertinoIcons.heart_fill),
  ];

  static const _overhang = 22.0;
  static const _itemsHeight = 49.0;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final barHeight = _itemsHeight + (bottomInset > 8 ? bottomInset : 8);

    Widget tab(int index) {
      final spec = _tabs[index];
      final active = index == currentIndex;
      final color = active ? AppColors.navy : AppColors.textDisabled;
      return Expanded(
        child: Semantics(
          selected: active,
          button: true,
          label: spec.label,
          excludeSemantics: true,
          child: InkResponse(
            onTap: () => onTap(index),
            radius: 32,
            child: SizedBox(
              height: _itemsHeight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    Icon(active ? spec.activeIcon : spec.icon, size: 24, color: color),
                    const SizedBox(height: 4),
                    Text(
                      spec.label,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 11,
                        height: 13 / 11,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                        color: color,
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

    return SizedBox(
      height: _overhang + barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: barHeight,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A0E3B70),
                    blurRadius: 20,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: barHeight - _itemsHeight),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    tab(0),
                    tab(1),
                    const Expanded(child: SizedBox.shrink()),
                    tab(2),
                    tab(3),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(child: AssistantFab(onPressed: onAssistant)),
          ),
        ],
      ),
    );
  }
}

/// Botón central rojo que abre el asistente de IA.
class AssistantFab extends StatelessWidget {
  const AssistantFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Asistente IA',
      excludeSemantics: true,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 4),
          boxShadow: const [
            BoxShadow(color: Color(0x59DD1A4A), blurRadius: 18, offset: Offset(0, 8)),
          ],
        ),
        child: Material(
          color: AppColors.raspberry,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: const Center(
              child: Icon(CupertinoIcons.plus, size: 26, color: AppColors.white),
            ),
          ),
        ),
      ),
    );
  }
}
