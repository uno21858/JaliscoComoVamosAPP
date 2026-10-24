import 'data_filters.dart';
import 'data_source.dart';

/// Lo que eligió la persona en 2.6 para armar el informe.
class ReportRequest {
  const ReportRequest({
    required this.topicIds,
    required this.source,
    required this.filters,
    required this.plainSummaries,
  });

  final List<String> topicIds;
  final DataSource source;
  final DataFilters filters;
  final bool plainSummaries;
}
