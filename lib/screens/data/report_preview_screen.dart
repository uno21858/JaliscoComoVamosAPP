import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../models/models.dart';
import '../../widgets/widgets.dart';

/// 2.7 Vista previa del informe. Es ilustrativa: el PDF real (RF-DAT-10) se
/// genera cuando exista el backend, con los mismos agregados del dashboard.
class ReportPreviewScreen extends StatefulWidget {
  const ReportPreviewScreen({super.key, required this.request});

  final ReportRequest request;

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  final _pageController = PageController(viewportFraction: 0.72);
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String get _fileName {
    final first = widget.request.topicIds.first;
    return 'informe-jcv-$first.pdf';
  }

  void _notAvailableYet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('La exportación del informe todavía no está disponible en esta versión.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final pages = request.topicIds.length;
    final subtitle = [
      request.source.longLabel,
      request.filters.municipalityLabel,
      request.filters.ageLabel,
    ].join(' · ');

    return Scaffold(
      body: Column(
        children: [
          const ScreenHeader(title: 'Vista previa'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 18, bottom: 24),
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
                  'Página ${_page + 1} de $pages',
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
                        label: 'Exportar PDF',
                        leadingIcon: CupertinoIcons.arrow_down_doc,
                        onPressed: _notAvailableYet,
                      ),
                      const SizedBox(height: 12),
                      JcvButton(
                        label: 'Compartir',
                        variant: JcvButtonVariant.outline,
                        leadingIcon: CupertinoIcons.square_arrow_up,
                        onPressed: _notAvailableYet,
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

    Widget bar(double width, Color color) => Container(
          width: width,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(2)),
          ),
        );

    return Semantics(
      label: 'Vista previa de la página $pageNumber del informe: $title',
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.navy),
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
            for (final (amg, tec) in const [(120.0, 156.0), (48.0, 55.0), (34.0, 11.0), (28.0, 7.0)]) ...[
              bar(amg, AppColors.navy),
              const SizedBox(height: 2),
              bar(tec, AppColors.gold),
              const SizedBox(height: 5),
            ],
            const SizedBox(height: 6),
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
                    children: [line(1), const SizedBox(height: 6), line(0.8), const SizedBox(height: 6), line(0.66)],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Página $pageNumber',
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
