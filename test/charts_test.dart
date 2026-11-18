import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jcv_app/models/chart.dart';
import 'package:jcv_app/widgets/jcv_charts.dart';

const feliz = [
  ChartSlice('Muy feliz', 51.5),
  ChartSlice('Algo feliz', 36.8),
  ChartSlice('Poco feliz', 8.1),
  ChartSlice('Nada feliz', 2.6),
  ChartSlice('No sabe', 0.8),
  ChartSlice('No contesta', 0.2),
];

/// 15 incisos, como la gráfica de confianza (la de grupo más larga).
final confianza = [
  for (var i = 0; i < 15; i++) ChartSlice('Institución con nombre largo número ${i + 1}', 5.0 * i + 3),
];

/// 12 opciones, como la de más opciones (Q_69).
final muchas = [for (var i = 0; i < 12; i++) ChartSlice('Opción con texto largo ${i + 1}', 12.0 - i)];

Future<void> pumpAt(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(390 * 3, 3000 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(padding: const EdgeInsets.all(36), child: child),
    ),
  ));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('dona: leyenda con todas las opciones', (tester) async {
    await pumpAt(
      tester,
      Column(children: [
        DonutChart(slices: feliz, size: 180, centerValue: '52%', semanticLabel: describeSlices('F', feliz)),
        const ChartLegend(slices: feliz, columns: 2),
      ]),
    );
    expect(find.text('No contesta'), findsOneWidget);
    expect(find.text('52%'), findsNWidgets(2)); // centro + leyenda
  });

  testWidgets('anillos: 15 incisos sin desbordarse, % y nombre de cada uno', (tester) async {
    await pumpAt(tester, RingGrid(slices: confianza));
    expect(find.text('73%'), findsOneWidget);
    expect(find.textContaining('número 15'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'número 1: 3%')), findsOneWidget);
  });

  testWidgets('barras: 12 opciones con su %', (tester) async {
    await pumpAt(tester, BarRows(slices: muchas));
    expect(find.text('Opción con texto largo 12'), findsOneWidget);
    expect(find.text('1%'), findsOneWidget);
  });

  testWidgets('comparativa: AMG y Tec con el mismo riel', (tester) async {
    await pumpAt(tester, const ComparisonBars(rows: [ComparisonRow('Muy feliz', 51.5, 63.2)]));
    expect(find.text('52%'), findsOneWidget);
    expect(find.text('63%'), findsOneWidget);
  });
}
