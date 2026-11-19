#!/usr/bin/env python3
"""Revisa que la app no dibuje gráficas de barras (JCV las quiso fuera).

Uso:  python3 scripts/check_sin_barras.py
Sale con 0 si no hay, con 1 y la lista de archivos si encuentra alguna.

No cuenta como gráfica la barra de progreso de las encuestas (ProgressTrack).
Revisa todo lib/, el PDF incluido. ChartKind se revisa aparte: si vuelve a
tener un tipo de barras, falla aunque nadie lo use todavía.
"""
import pathlib
import re
import sys

RAIZ = pathlib.Path(__file__).resolve().parent.parent

# Widgets de barras propios o de paquetes (fl_chart, syncfusion, charts_flutter).
BARRAS = re.compile(r"\b(BarRows|ComparisonBars|ChartKind\.bars|barWidth|BarChart\w*|BarSeries|ColumnSeries|StackedBar\w*)\b")
TIPOS = re.compile(r"enum ChartKind\s*\{([^}]*)\}")


def main() -> int:
    hallazgos = []
    for archivo in sorted((RAIZ / "lib").rglob("*.dart")):
        texto = archivo.read_text(encoding="utf-8")
        for n, linea in enumerate(texto.splitlines(), 1):
            if BARRAS.search(linea) and not linea.lstrip().startswith("//"):
                hallazgos.append(f"{archivo.relative_to(RAIZ)}:{n}: {linea.strip()}")
        if tipos := TIPOS.search(texto):
            if "bar" in tipos.group(1).lower():
                hallazgos.append(f"{archivo.relative_to(RAIZ)}: ChartKind todavía tiene un tipo de barras")

    if hallazgos:
        print("Encontré gráficas de barras:")
        print("\n".join(f"  {h}" for h in hallazgos))
        return 1
    print("Sin gráficas de barras en la app.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
