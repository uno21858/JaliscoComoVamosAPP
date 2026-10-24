import 'package:flutter/cupertino.dart';

/// Íconos de temática de la hoja de componentes (CupertinoIcons).
IconData topicIcon(String topicId) {
  switch (topicId) {
    case 'bienestar':
      return CupertinoIcons.smiley;
    case 'educacion-trabajo':
      return CupertinoIcons.book;
    case 'tiempo-libre':
      return CupertinoIcons.gamecontroller;
    case 'hogar-familia':
      return CupertinoIcons.house_alt;
    case 'salud':
      return CupertinoIcons.waveform_path_ecg;
    case 'seguridad':
      return CupertinoIcons.shield;
    case 'comunidad':
      return CupertinoIcons.person_3;
    case 'transporte':
      return CupertinoIcons.bus;
    default:
      return CupertinoIcons.chart_bar;
  }
}
