/// De dónde salen los datos que se muestran.
enum DataSource {
  amg('AMG', 'Fuente: AMG 2026', 'AMG 2026'),
  tec('Tec', 'Fuente: Tec', 'Estudiantes Tec'),
  comparison('Comparativa', 'Comparativa AMG vs Tec', 'Comparativa AMG vs Tec');

  const DataSource(this.label, this.chipLabel, this.longLabel);

  /// Texto del control segmentado de filtros.
  final String label;

  /// Texto del chip azul arriba de las gráficas.
  final String chipLabel;

  /// Texto completo para resúmenes ("Estudiantes Tec").
  final String longLabel;
}
