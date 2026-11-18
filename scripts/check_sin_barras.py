#!/usr/bin/env python3
"""Revisa que la app no dibuje gráficas de barras (JCV las quiso fuera).

Uso:  python3 scripts/check_sin_barras.py
Sale con 0 si no hay, con 1 y la lista de archivos si encuentra alguna.

No cuenta como gráfica la barra de progreso de las encuestas (ProgressTrack).
El PDF (services/local/report_pdf.dart) dibuja barras a propósito porque en
papel se leen mejor; se revisa aparte con --pdf.
"""
import pathlib
import re
import sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent
PDF = RAIZ / "lib/services/local/report_pdf.dart"

# Widgets de barras propios o de paquetes (fl_chart, syncfusion, charts_flutter).
BARRAS = re.compile(r"\b(BarRows|ComparisonBars|ChartKind\.bars|BarChart\w*|BarSeries|ColumnSeries|StackedBar\w*)\b")
TIPOS = re.compile(r"enum ChartKind\s*\{([^}]*)\}")


def main() -> int:
    revisar_pdf = "--pdf" in sys.argv
    hallazgos = []
    for archivo in sorted((RAIZ / "lib").rglob("*.dart")):
        if archivo == PDF and not revisar_pdf:
            continue
        texto = archivo.read_text(encoding="utf-8")
        for n, linea in enumerate(texto.splitlines(), 1):
            if BARRAS.search(linea) and not linea.lstrip().startswith("//"):
                hallazgos.append(f"{archivo.relative_to(RAIZ)}:{n}: {linea.strip()}")
        if tipos := TIPOS.search(texto):
            if "bar" in tipos.group(1).lower():
                hallazgos.append(f"{archivo.relative_to(RAIZ)}: ChartKind todavía tiene un tipo de barras")
    if revisar_pdf and "barWidth" in PDF.read_text(encoding="utf-8"):
        hallazgos.append(f"{PDF.relative_to(RAIZ)}: el PDF dibuja barras (barWidth)")

    if hallazgos:
        print("Encontré gráficas de barras:")
        print("\n".join(f"  {h}" for h in hallazgos))
        return 1
    print("Sin gráficas de barras en la app.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
