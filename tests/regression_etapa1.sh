#!/usr/bin/env bash
# prueba de regresion del campo carrera: compila la Etapa 1 entregada (main)
# y la version actual, corre ambas con los mismos datos y compara las salidas
# la unica diferencia permitida es la linea "career" de cada curso
# uso: bash tests/regression_etapa1.sh [rama_o_commit_base]

set -e
BASE="${1:-origin/main}"

# la Etapa 1 entregada se comparan contra origin/main (la rama principal
# remota, que contiene el código de la Etapa 1 sin los campos area ni
# format_version de las etapas posteriores). Usar main local puede fallar
# porque main puede contener código de etapas superiores.
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

    # sin career, area ni format_version, la salida nueva debe ser identica a la anterior
    # (area y format_version son cambios de la Etapa 3, los revisa regression_etapa2.sh;
    # career es el cambio propio de la Etapa 2, lo verifica abajo con con_carrera)
    grep -v -e '"career": ' -e '"area": ' -e '"format_version": ' "$TMP/despues.json" > "$TMP/sin_carrera.json"
    grep -v -e '"career": ' -e '"area": ' -e '"format_version": ' "$TMP/antes.json" > "$TMP/antes_sin_version.json"
    if diff -q "$TMP/antes_sin_version.json" "$TMP/sin_carrera.json" > /dev/null; then
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