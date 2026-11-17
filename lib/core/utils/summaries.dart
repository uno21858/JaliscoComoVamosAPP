import '../../models/chart.dart';
import 'formatters.dart';

/// Resúmenes de gráficas con plantilla, nunca texto libre. Los usan el mock y
/// el servicio real, así una demo con mocks se lee igual que con datos reales.
abstract final class Summaries {
  /// La categoría más común y la que le sigue.
  static String chart(List<ChartSlice> slices, {required bool multipleChoice}) {
    final sorted = [...slices]..sort((a, b) => b.percent.compareTo(a.percent));
    final first = sorted.first;
    if (multipleChoice) {
      return '“${first.label}” es lo más mencionado: '
          '${Formatters.percent(first.percent)} lo eligió.';
    }
    if (sorted.length < 2) {
      return '“${first.label}” reúne el ${Formatters.percent(first.percent)}.';
    }
    final second = sorted[1];
    return 'La respuesta más común es “${first.label}” '
        '(${Formatters.percent(first.percent)}), seguida de “${second.label}” '
        '(${Formatters.percent(second.percent)}).';
  }

  /// La categoría con la diferencia más grande entre AMG y Tec.
  static String comparison(List<ComparisonRow> rows) {
    final row = rows.reduce(
      (a, b) => (a.tec - a.amg).abs() >= (b.tec - b.amg).abs() ? a : b,
    );
    final tec = Formatters.percent(row.tec);
    final amg = Formatters.percent(row.amg);
    final diff = row.tec - row.amg;
    if (diff.abs() < 3) {
      return 'En “${row.label}”, el Tec y el AMG están muy parejos '
          '($tec contra $amg).';
    }
    final more = diff > 0 ? 'más' : 'menos';
    return 'En el Tec, $more jóvenes responden “${row.label}” que en el AMG '
        '($tec contra $amg).';
  }
}
