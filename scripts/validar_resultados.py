#!/usr/bin/env python3
import json
import sys


def load(path):
    with open(path, "r", encoding="utf-8") as f:
        for n, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            yield n, json.loads(line)


def main():
    if len(sys.argv) != 3:
        print("uso: validar_resultados.py ENTRADA.jsonl SALIDA.jsonl", file=sys.stderr)
        return 2
    entrada, salida = sys.argv[1], sys.argv[2]
    combinaciones = [obj for _, obj in load(entrada)]
    resultados = [obj for _, obj in load(salida)]
    errores = []

    if len(combinaciones) != len(resultados):
        errores.append(f"cantidad distinta: entrada {len(combinaciones)}, salida {len(resultados)}")
    if len({r['id'] for r in resultados}) != len(resultados):
        errores.append("ids repetidos en la salida")

    por_id = {r['id']: r for r in resultados}
    EXPECTED_KEYS = {"id", "cumple", "razon", "razon_descripcion", "creditos_totales", "detalle", "cursos_areas"}
    for combo in combinaciones:
        r = por_id.get(combo['id'])
        if r is None:
            errores.append(f"falta el resultado para id={combo['id']}")
            continue
        if set(r) != EXPECTED_KEYS:
            errores.append(f"id={combo['id']} claves inesperadas: {sorted(set(r) ^ EXPECTED_KEYS)}")
        if r['cumple']:
            if r['razon'] != "ninguna":
                errores.append(f"id={r['id']} cumple=true con razon={r['razon']}")
            if r['razon_descripcion'] != "":
                errores.append(f"id={r['id']} cumple=true con razon_descripcion no vacia")
            if r['detalle'] != {} or r['cursos_areas'] != []:
                errores.append(f"id={r['id']} cumple=true con detalle o cursos_areas no vacios")
        else:
            if r['razon'] == "ninguna":
                errores.append(f"id={r['id']} cumple=false con razon=ninguna")
            if not isinstance(r['detalle'], dict) or not r['detalle']:
                errores.append(f"id={r['id']} cumple=false con detalle vacio o no dict")
        total = sum(c['credits'] for c in combo['courses'])
        if r['creditos_totales'] != total:
            errores.append(f"id={r['id']} creditos_totales {r['creditos_totales']} != {total} calculado de la entrada")
        cursos_entrada = {(c['career'], c['code']) for c in combo['courses']}
        if len(cursos_entrada) != len(combo['courses']):
            errores.append(f"id={r['id']} la entrada repite un curso")

    print(f"entrada={len(combinaciones)} salida={len(resultados)} errores={len(errores)}")
    for e in errores[:20]:
        print("error:", e)
    if errores:
        return 1
    counts = {}
    for r in resultados:
        key = "cumple" if r['cumple'] else r['razon']
        counts[key] = counts.get(key, 0) + 1
    print("distribucion:", json.dumps(counts, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
