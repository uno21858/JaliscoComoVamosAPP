"""Convierte la base de JCV (Bienestar de Jóvenes AMG) en 3 CSV para jcv.*.

Uso:
    python3 -I scripts/importar_amg.py "<carpeta de datos de JCV>" [<carpeta de salida>]

La salida por defecto es <carpeta de datos>/../jcv_import, fuera del repo:
los microdatos de la encuesta nunca entran a git. Después se cargan con
scripts/cargar_amg.sql.

Solo stdlib. Se queda fuera todo lo que puede identificar a alguien:
número de cuestionario, fecha, duración, colonia y respuestas abiertas.
"""

import csv
import json
import re
import sys
from pathlib import Path

BASE_CSV = "Base de Datos_Bienestar de Jovenes - Jul-Ago 2026.csv"
DICCIONARIO = "Bienestar_de_Jovenes_Jul-Ago_2026_diccionario.json"

# Demográficas: van a jcv.personas con los códigos de FilterCatalog de la app.
# Se valida contra el diccionario para que un cambio de codificación truene aquí.
DEMOGRAFICAS = {
    "Q_2": ("municipio", {"1": ("El Salto", "ELS"), "2": ("Guadalajara", "GDL"),
                          "3": ("San Pedro Tlaquepaque", "TLQ"), "4": ("Tlajomulco de Zúñiga", "TLJ"),
                          "5": ("Tonalá", "TON"), "6": ("Zapopan", "ZAP")}),
    "Q_72recode": ("edad", {"1": ("15 a 19 años", "15-19"), "2": ("20 a 24 años", "20-24"),
                            "3": ("25 a 29 años", "25-29")}),
    "Q_71": ("sexo", {"1": ("Hombre", "M"), "2": ("Mujer", "F"), "3": ("Otra, ¿cuál?", "O"),
                      "4": ("No sabe/No contestó [NO LEER]", None)}),
    "Estrato": ("estrato", {"1": ("Alto", "ALTO"), "2": ("Medio", "MEDIO"), "3": ("Bajo", "BAJO")}),
}
NO_SON_PREGUNTAS = {"SbjNum", "Date", "Duration", "FACTOR", "Q_3", "Q_72", *DEMOGRAFICAS}

# Temática de la app por número de pregunta del cuestionario (bloques de JCV).
TEMAS = [
    (6, 12, "bienestar"),
    (13, 19, "educacion-trabajo"),
    (20, 29, "tiempo-libre"),
    (30, 35, "hogar-familia"),
    (36, 42, "salud"),
    (43, 53, "seguridad"),
    (54, 68, "comunidad"),  # desigualdad, barrio, participación, confianza, política
    (69, 70, "transporte"),
    (74, 75, "educacion-trabajo"),
    (76, 81, "hogar-familia"),
]


def limpiar(texto: str) -> str:
    return " ".join(texto.replace("[NO LEER]", "").split())


def tema_de(variable: str) -> str | None:
    numero = int(re.search(r"Q_(\d+)", variable).group(1))
    return next((tema for desde, hasta, tema in TEMAS if desde <= numero <= hasta), None)


def codigo(valor: str) -> int | None:
    """'5' o '5.0' -> 5; vacío o -1 -> None. Cualquier otra cosa truena.

    -1 es "no aplica" (pase de pregunta): Q_47 lo tiene en los 1,075 que no
    fueron víctimas y Q_70recode en los 12 que no se desplazan.
    """
    valor = valor.strip()
    if valor in ("", "-1"):
        return None
    if not re.fullmatch(r"\d+(\.0+)?", valor):
        raise ValueError(valor)
    return int(float(valor))


def main(datos: Path, salida: Path) -> None:
    dic = json.loads((datos / DICCIONARIO).read_text(encoding="utf-8"))
    # Solo se leen códigos numéricos y FACTOR; latin-1 nunca falla al decodificar.
    with open(datos / BASE_CSV, encoding="latin-1", newline="") as f:
        filas = list(csv.DictReader(f))

    for var, (_, mapa) in DEMOGRAFICAS.items():
        esperado = {k: etiqueta for k, (etiqueta, _) in mapa.items()}
        if dic[var]["valores"] != esperado:
            sys.exit(f"Cambió la codificación de {var}: {dic[var]['valores']}")

    preguntas, excluidas = [], []
    for var, meta in dic.items():
        valores = meta.get("valores") or {}
        if var in NO_SON_PREGUNTAS or f"{var}recode" in dic:
            continue  # demográfica, identificable, o tiene versión recodificada
        if len(valores) < 2 or tema_de(var) is None:
            excluidas.append((var, "abierta o numérica"))
            continue
        try:
            usados = {codigo(fila[var]) for fila in filas} - {None}
        except ValueError as e:
            excluidas.append((var, f"valor no numérico {e}"))
            continue
        fuera = usados - {int(k) for k in valores}
        if fuera:
            excluidas.append((var, f"códigos fuera del diccionario {sorted(fuera)}"))
            continue
        preguntas.append(var)

    salida.mkdir(parents=True, exist_ok=True)

    with open(salida / "preguntas.csv", "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["variable", "orden", "tema", "texto", "opciones"])
        for orden, var in enumerate(preguntas, start=1):
            opciones = [{"codigo": int(k), "etiqueta": limpiar(v)}
                        for k, v in sorted(dic[var]["valores"].items(), key=lambda kv: int(kv[0]))]
            w.writerow([var, orden, tema_de(var), limpiar(dic[var]["etiqueta"]),
                        json.dumps(opciones, ensure_ascii=False)])

    total_respuestas = 0
    with open(salida / "personas.csv", "w", encoding="utf-8", newline="") as fp, \
         open(salida / "respuestas.csv", "w", encoding="utf-8", newline="") as fr:
        wp, wr = csv.writer(fp), csv.writer(fr)
        wp.writerow(["id", "fuente", "municipio", "edad", "sexo", "estrato", "factor"])
        wr.writerow(["variable", "persona_id", "valor"])
        for persona_id, fila in enumerate(filas, start=1):
            demo = [DEMOGRAFICAS[v][1].get(fila[v].strip(), (None, None))[1] for v in DEMOGRAFICAS]
            wp.writerow([persona_id, "AMG", *demo, fila["FACTOR"].strip()])
            for var in preguntas:
                valor = codigo(fila[var])
                if valor is not None:  # vacío = no le tocó (pase de pregunta)
                    wr.writerow([var, persona_id, valor])
                    total_respuestas += 1

    print(f"personas: {len(filas)}  preguntas: {len(preguntas)}  respuestas: {total_respuestas}")
    for var, motivo in excluidas:
        print(f"  fuera {var}: {motivo}")
    print(f"CSV en {salida}")


if __name__ == "__main__":
    if len(sys.argv) not in (2, 3):
        sys.exit(__doc__)
    carpeta = Path(sys.argv[1]).expanduser()
    main(carpeta, Path(sys.argv[2]).expanduser() if len(sys.argv) == 3 else carpeta.parent / "jcv_import")
