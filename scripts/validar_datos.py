#!/usr/bin/env python3
"""Compara lo que regresan las RPC de Supabase contra las tablas oficiales de JCV.

Uso:
  python3 scripts/validar_datos.py ["carpeta de datos de JCV"]

La carpeta por default es ~/Downloads/DatosEncuestaBienestar de Jovenes - Jul-Ago 2026
y tiene que traer el diccionario JSON, el CSV de la base y el Excel "Cruces de
Variables". Esos archivos nunca van al repo.

Qué hace: por cada pregunta de la hoja RESUMEN del Excel, pide a jcv.graficas
(con la anon key del .env, igual que la app) el total y cada grupo con filtro
(hombre/mujer, 3 edades, 3 estratos) y revisa que cada porcentaje coincida.
Las preguntas que JCV no puso en el RESUMEN se comparan contra los microdatos.
La RPC redondea a 1 decimal, así que se permite una diferencia de 0.06 puntos.
Sale con 1 si encuentra diferencias o si la RPC regresa conteos (n).
Solo imprime porcentajes, nunca conteos.

Necesita openpyxl (pip install openpyxl).
"""
import csv
import json
import pathlib
import sys
import urllib.request

try:
    import openpyxl
except ImportError:
    sys.exit("Falta openpyxl: pip install openpyxl")

RAIZ = pathlib.Path(__file__).resolve().parent.parent
CARPETA = pathlib.Path.home() / "Downloads/DatosEncuestaBienestar de Jovenes - Jul-Ago 2026"
DICCIONARIO = "Bienestar_de_Jovenes_Jul-Ago_2026_diccionario.json"
BASE_CSV = "Base de Datos_Bienestar de Jovenes - Jul-Ago 2026.csv"
CRUCES = "Cruces de Variables - Bienestar de Jovenes - Jul-Ago 2026 (2).xlsx"

# Columna de la hoja RESUMEN -> filtros de la RPC. "Otro" (col 6) no es filtro en la app.
COLUMNAS = {
    2: ("Total", {}),
    4: ("Hombres", {"p_sexo": "M"}),
    5: ("Mujeres", {"p_sexo": "F"}),
    8: ("15 a 19", {"p_edad": "15-19"}),
    9: ("20 a 24", {"p_edad": "20-24"}),
    10: ("25 a 29", {"p_edad": "25-29"}),
    12: ("Estrato alto", {"p_estrato": "ALTO"}),
    13: ("Estrato medio", {"p_estrato": "MEDIO"}),
    14: ("Estrato bajo", {"p_estrato": "BAJO"}),
}
# 0.05 por el redondeo a 1 decimal de la RPC, más un poco porque el factor del CSV
# trae menos decimales que el que usó JCV (Q_47 estrato alto: 2.049 vs 2.051).
TOLERANCIA = 0.06


def norm(texto) -> str:
    return " ".join(str(texto).replace("[NO LEER]", "").split()).lower()


def leer_env() -> dict:
    env = {}
    for linea in (RAIZ / ".env").read_text(encoding="utf-8").splitlines():
        if "=" in linea and not linea.lstrip().startswith("#"):
            clave, valor = linea.split("=", 1)
            env[clave.strip()] = valor.strip().strip("'\"")
    return env


def rpc(env: dict, funcion: str, params: dict):
    llave = env["SUPABASE_ANON_KEY"]
    req = urllib.request.Request(
        f"{env['SUPABASE_URL']}/rest/v1/rpc/{funcion}",
        data=json.dumps(params).encode(),
        headers={
            "apikey": llave,
            "Authorization": f"Bearer {llave}",
            "Content-Type": "application/json",
            "Content-Profile": "jcv",
        },
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        return json.load(resp)


def main() -> int:
    carpeta = pathlib.Path(sys.argv[1]).expanduser() if len(sys.argv) > 1 else CARPETA
    env = leer_env()
    variables = [v for v in json.loads((carpeta / DICCIONARIO).read_text(encoding="utf-8")) if v.startswith(("Q_", "T_Q_"))]

    # {columna: {variable: grafica}}; graficas acepta hasta 40 variables por llamada.
    rpc_por_col = {}
    for col, (_, filtros) in COLUMNAS.items():
        rpc_por_col[col] = {}
        for i in range(0, len(variables), 40):
            for g in rpc(env, "graficas", {"p_variables": variables[i : i + 40], **filtros}):
                rpc_por_col[col][g["variable"]] = g
    total = rpc_por_col[2]
    # JCV pidió no mostrar cuántas respuestas hay: desde v1.08 la RPC no trae n.
    if con_n := sorted({v for col in rpc_por_col.values() for v, g in col.items() if "n" in g}):
        sys.exit(f"La RPC volvió a regresar n (conteos) en: {', '.join(con_n[:5])}")
    # Un texto puede ser de varias variables (Q_70 en minutos y Q_70recode por
    # rangos): se elige la que tenga la primera opción del bloque.
    por_texto = {}
    for v, g in total.items():
        por_texto.setdefault(norm(g["texto"]), []).append(v)

    def opciones_de(v):
        return {norm(o["etiqueta"]) for o in total[v]["opciones"]}

    hoja = openpyxl.load_workbook(carpeta / CRUCES, read_only=True, data_only=True)["RESUMEN"]
    var, candidatas, titulo = None, [], ""
    sin_pareja, vistas, iguales, saltados, difs = [], set(), 0, 0, []
    suma_excel = {}  # (variable, columna) -> suma de la columna en el Excel
    for fila in hoja.iter_rows(min_row=3, values_only=True):
        if fila[0] and norm(fila[0]) != "total":
            titulo, var = str(fila[0]), None
            candidatas = por_texto.get(norm(titulo), [])
            if not candidatas:
                sin_pareja.append(titulo)
        etiqueta = fila[1]
        if not etiqueta or norm(etiqueta) == "media aritmética":
            continue
        if var is None and candidatas:
            var = next((c for c in candidatas if norm(etiqueta) in opciones_de(c)), None)
            candidatas = []
            (vistas.add(var) if var else sin_pareja.append(titulo))
        if not var:
            continue
        for col, (grupo, _) in COLUMNAS.items():
            g = rpc_por_col[col].get(var)
            if g is None or g["insuficiente"]:
                saltados += 1
                continue
            opciones = {norm(o["etiqueta"]): o["porcentaje"] for o in g["opciones"]}
            esperado = (fila[col] or 0) * 100  # celda vacía = nadie eligió esa opción
            suma_excel[var, col] = suma_excel.get((var, col), 0) + esperado
            obtenido = opciones.get(norm(etiqueta))
            if obtenido is None or abs(float(obtenido) - esperado) > TOLERANCIA:
                difs.append((var, col, grupo, etiqueta, round(esperado, 2), obtenido))
            else:
                iguales += 1

    # Si la columna del Excel no suma 100, el error es del Excel, no de la RPC.
    # Ej. T_Q_11_5 de 15 a 19 años suma 146 %; los microdatos dan lo mismo que la RPC.
    excel_mal = [d for d in difs if abs(suma_excel[d[0], d[1]] - 100) > 0.5]
    reales = [d for d in difs if d not in excel_mal]

    # Las que JCV no puso en el RESUMEN: total contra los microdatos, ponderado
    # con FACTOR. Vacío o -1 es "no le tocó la pregunta", igual que al importar.
    sin_resumen = sorted(v for v in total if v not in vistas)
    with open(carpeta / BASE_CSV, encoding="latin-1") as f:
        filas = list(csv.DictReader(f))
    for v in sin_resumen:
        pesos = {}
        for f in filas:
            valor = f[v].strip()
            if valor not in ("", "-1"):
                pesos[int(float(valor))] = pesos.get(int(float(valor)), 0) + float(f["FACTOR"])
        for o in total[v]["opciones"]:
            esperado = 100 * pesos.get(o["codigo"], 0) / sum(pesos.values())
            if abs(float(o["porcentaje"]) - esperado) > TOLERANCIA:
                reales.append((v, 2, "Total, microdatos", o["etiqueta"], round(esperado, 2), o["porcentaje"]))
            else:
                iguales += 1

    print(f"Preguntas comparadas: {len(vistas)} contra el RESUMEN de JCV y "
          f"{len(sin_resumen)} contra los microdatos ({', '.join(sin_resumen)})")
    print(f"Porcentajes iguales: {iguales} · distintos: {len(reales)} · grupos ocultos por privacidad: {saltados}")
    for var_, _, grupo, etiqueta, esperado, obtenido in reales[:30]:
        print(f"  DIF {var_} [{grupo}] {etiqueta}: esperado {esperado} · RPC {obtenido}")
    for var_, col, grupo in sorted({(d[0], d[1], d[2]) for d in excel_mal}):
        print(f"  Error en el Excel de JCV: {var_} [{grupo}] suma {suma_excel[var_, col]:.0f} % en vez de 100 %")
    if sin_pareja:
        print("Bloques del RESUMEN que no están en la base (respuestas abiertas o variables que la app no usa):")
        for t in sin_pareja:
            print(f"  …{t[-85:]}")
    return 1 if reales else 0


if __name__ == "__main__":
    sys.exit(main())
