#!/usr/bin/env bash
# prueba de regresion del campo area: compila la Etapa 2 entregada (etiqueta
# etapa2-entregada) y la version actual, corre ambas con los mismos datos y
# compara las salidas de C
# las unicas diferencias permitidas son la linea "area" de cada curso y
# format_version, que sube de 1 a 2 por el campo nuevo
# uso: bash tests/regression_etapa2.sh [rama_etiqueta_o_commit_base]

set -e
BASE="${1:-etapa2-entregada}"

if ! git cat-file -e "$BASE:Makefile" > /dev/null 2>&1; then
    echo "FAIL - $BASE no existe o no contiene Makefile (git fetch --tags)"
    exit 1
fi

TMP="$(mktemp -d)"
trap 'git worktree remove --force "$TMP/base" > /dev/null 2>&1 || true; rm -rf "$TMP"' EXIT

# copia limpia de la version base en una carpeta temporal
git worktree add --detach "$TMP/base" "$BASE" > /dev/null 2>&1
make -C "$TMP/base" > /dev/null
make clean > /dev/null
make > /dev/null

status=0
for carrera in computadores fisica; do
    catalogo="data/catalogo_$carrera.csv"
    historial="data/historial_$carrera.csv"
    areas="data/areas_$carrera.csv"

    # las dos versiones leen los mismos datos de la rama actual
    "$TMP/base/cemestre" "$catalogo" "$historial" "$TMP/antes.json" "$carrera" > /dev/null
    ./cemestre "$catalogo" "$historial" "$TMP/despues.json" "$carrera" "$areas" > /dev/null

    # sin el area ni la version, la salida nueva debe ser identica a la anterior
    grep -v -e '"area": ' -e '"format_version": ' "$TMP/despues.json" > "$TMP/nueva.json"
    grep -v -e '"format_version": ' "$TMP/antes.json" > "$TMP/vieja.json"
    if diff -q "$TMP/vieja.json" "$TMP/nueva.json" > /dev/null; then
        echo "OK   - $carrera: misma salida que $BASE salvo area y format_version"
    else
        echo "FAIL - $carrera: la salida cambio respecto a $BASE"
        status=1
    fi

    # cada curso debe traer un area asignada
    cursos=$(grep -c '"code": ' "$TMP/despues.json")
    con_area=$(grep '"area": ' "$TMP/despues.json" | grep -vc '"sin_area"' || true)
    if [ "$cursos" -eq "$con_area" ]; then
        echo "OK   - $carrera: $cursos cursos con area"
    else
        echo "FAIL - $carrera: $con_area de $cursos cursos con area"
        status=1
    fi

    # sin archivo de areas, el programa sigue corriendo como en la Etapa 2
    if ./cemestre "$catalogo" "$historial" "$TMP/sin_areas.json" "$carrera" > /dev/null \
        && [ "$(grep -c '"area": "sin_area"' "$TMP/sin_areas.json")" -eq "$cursos" ]; then
        echo "OK   - $carrera: sin archivo de areas corre y marca sin_area"
    else
        echo "FAIL - $carrera: sin archivo de areas no corre como antes"
        status=1
    fi
done

exit $status
