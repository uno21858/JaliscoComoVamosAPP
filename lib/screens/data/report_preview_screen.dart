import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../core/core.dart';
import '../../models/models.dart';
import '../../repositories/repositories.dart';
import '../../services/local/report_pdf.dart';
import '../../widgets/widgets.dart';

/// 2.7 Vista previa del informe. La miniatura es ilustrativa; el PDF (RF-DAT-10)
/// se arma en el teléfono con los mismos agregados del dashboard.
class ReportPreviewScreen extends StatefulWidget {
  const ReportPreviewScreen({super.key, required this.request});

  final ReportRequest request;

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  final _pageController = PageController(viewportFraction: 0.72);
  int _page = 0;
  Uint8List? _pdf;
  bool _busy = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Con una temática lleva su nombre; con varias, solo "informe-jcv".
  String get _fileName {
    final ids = widget.request.topicIds;
    return ids.length == 1 ? 'informe-jcv-${ids.single}.pdf' : 'informe-jcv.pdf';
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Pide las gráficas de cada temática y arma el PDF una sola vez.
  Future<Uint8List?> _buildPdf() async {
    if (_pdf case final pdf?) return pdf;
    final request = widget.request;
    final repo = context.read<DataRepository>();
    final results = await Future.wait([
      for (final topicId in request.topicIds)
        repo.getTopicCharts(topicId: topicId, source: request.source, filters: request.filters),
    ]);
    final sections = <ReportSection>[];
    for (final (i, result) in results.indexed) {
      switch (result) {
        case Ok(value: Enough(:final data)):
          sections.add((topicId: request.topicIds[i], data: data));
        case Ok(value: TooFew()):
          sections.add((topicId: request.topicIds[i], data: null));
        case Err(:final failure):
          _snack(failure.message);
          return null;
      }
    }
    return _pdf = await buildReportPdf(request, sections);
  }

  Future<void> _withPdf(Future<void> Function(Uint8List pdf) action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final pdf = await _buildPdf();
      if (pdf != null && mounted) await action(pdf);
    } on Object {
      _snack('No se pudo armar el informe. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Hoja del sistema para guardar en Archivos o imprimir.
  void _export() => unawaited(_withPdf(
        (pdf) => Printing.layoutPdf(onLayout: (_) async => pdf, name: _fileName),
      ));

  void _share() => unawaited(_withPdf(
        (pdf) => Printing.sharePdf(bytes: pdf, filename: _fileName),
      ));

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final pages = request.topicIds.length;
    final subtitle = [
      request.source.longLabel,
      request.filters.ageLabel,
    ].join(' · ');

    return Scaffold(
      body: Column(
        children: [
          const ScreenHeader(title: 'Vista previa'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(top: 18, bottom: 24 + MediaQuery.paddingOf(context).bottom),
              children: [
                SizedBox(
                  height: 370,
                  child: PageView.builder(
                    itemCount: pages,
                    controller: _pageController,
                    onPageChanged: (page) => setState(() => _page = page),
                    itemBuilder: (context, index) => Center(
                      child: _PagePreview(
                        title: Topics.nameOf(request.topicIds[index]),
                        subtitle: subtitle,
                        pageNumber: index + 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Temática ${_page + 1} de $pages',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const IconCircle(
                        icon: CupertinoIcons.doc_chart,
                        size: 44,
                        iconSize: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 18 / 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                            Text(
                              'PDF · $pages ${pages == 1 ? 'temática' : 'temáticas'}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      JcvButton(
                        label: _busy ? 'Armando el PDF…' : 'Exportar PDF',
                        leadingIcon: CupertinoIcons.arrow_down_doc,
                        onPressed: _busy ? null : _export,
                      ),
                      const SizedBox(height: 12),
                      JcvButton(
                        label: 'Compartir',
                        variant: JcvButtonVariant.outline,
                        leadingIcon: CupertinoIcons.square_arrow_up,
                        onPressed: _busy ? null : _share,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hoja tamaño carta en miniatura, con la estructura del informe.
class _PagePreview extends StatelessWidget {
  const _PagePreview({required this.title, required this.subtitle, required this.pageNumber});

  final String title;
  final String subtitle;
  final int pageNumber;

  @override
  Widget build(BuildContext context) {
    Widget line(double widthFactor) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: widthFactor,
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );

    return Semantics(
      label: 'Vista previa de la temática $pageNumber del informe: $title',
      excludeSemantics: true,
      child: Container(
        width: 250,
        height: 354,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(color: Color(0x290E3B70), blurRadius: 24, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                JcvRing(size: 22),
                SizedBox(width: 6),
                Text(
                  'Informe · Jalisco Cómo Vamos',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const JcvColorBar(height: 3),
            const SizedBox(height: 8),
            Text(
              title,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.navy),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 2,
              style: const TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            const RingGrid(
              ringSize: 38,
              columns: 4,
              slices: [ChartSlice('', 71), ChartSlice('', 54), ChartSlice('', 33), ChartSlice('', 22)],
            ),
            line(1),
            const SizedBox(height: 8),
            line(0.92),
            const SizedBox(height: 8),
            line(0.96),
            const SizedBox(height: 8),
            line(0.6),
            const SizedBox(height: 12),
            Row(
              children: [
                const DonutChart(
                  size: 56,
                  semanticLabel: '',
                  slices: [
                    ChartSlice('a', 52),
                    ChartSlice('b', 21),
                    ChartSlice('c', 15),
                    ChartSlice('d', 12),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    children: [
                      line(1),
                      const SizedBox(height: 6),
                      line(0.8),
                      const SizedBox(height: 6),
                      line(0.66)
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Temática $pageNumber',
                style: const TextStyle(
                  fontSize: 6,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
