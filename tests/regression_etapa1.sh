#!/usr/bin/env bash
# prueba de regresion del campo carrera: compila la Etapa 1 entregada (main)
# y la version actual, corre ambas con los mismos datos y compara las salidas
# la unica diferencia permitida es la linea "career" de cada curso
# uso: bash tests/regression_etapa1.sh [rama_o_commit_base]

set -e
BASE="${1:-main}"

# en algunos clones el main local puede estar en un commit inicial sin codigo;
# en ese caso se usa la rama remota, que contiene la Etapa 1 entregada
if ! git cat-file -e "$BASE:Makefile" > /dev/null 2>&1; then
    echo "AVISO - $BASE no contiene Makefile; se usa origin/main"
    BASE="origin/main"
fi

TMP="$(mktemp -d)"

# copia limpia de la version base en una carpeta temporal
git worktree add --detach "$TMP/base" "$BASE" > /dev/null 2>&1
make -C "$TMP/base" > /dev/null
make clean > /dev/null
make > /dev/null

status=0
for carrera in computadores fisica; do
    catalogo="data/catalogo_$carrera.csv"
    historial="data/historial_$carrera.csv"

    # las dos versiones leen los mismos datos de la rama actual
    "$TMP/base/cemestre" "$catalogo" "$historial" "$TMP/antes.json" > /dev/null
    ./cemestre "$catalogo" "$historial" "$TMP/despues.json" "$carrera" > /dev/null

    # sin la linea career, la salida nueva debe ser identica a la anterior
    grep -v '"career": ' "$TMP/despues.json" > "$TMP/sin_carrera.json"
    if diff -q "$TMP/antes.json" "$TMP/sin_carrera.json" > /dev/null; then
        echo "OK   - $carrera: misma salida que $BASE salvo career"
    else
        echo "FAIL - $carrera: la salida cambio respecto a $BASE"
        status=1
    fi

    # cada curso debe traer su carrera
    cursos=$(grep -c '"code": ' "$TMP/despues.json")
    con_carrera=$(grep -c "\"career\": \"$carrera\"" "$TMP/despues.json")
    if [ "$cursos" -eq "$con_carrera" ]; then
        echo "OK   - $carrera: $cursos cursos con career"
    else
        echo "FAIL - $carrera: $con_carrera de $cursos cursos con career"
        status=1
    fi
done

git worktree remove --force "$TMP/base"
rm -rf "$TMP"
exit $status