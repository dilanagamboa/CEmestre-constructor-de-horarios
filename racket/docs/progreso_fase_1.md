# Progreso de la Fase 1: datos y ampliación de C

> Documento histórico del cierre de la Fase 1. El estado final de la Etapa 2 está en `revision_final.md` y en el README.

Fecha de revisión: 2026-10-26.
Rama: `feature/etapa2-fases-0-3`.
Commit revisado: `32cec486f4f9e21b9fc19bb67866d6cb9ecbc8ea`.

## 1. Objetivo

Verificar que la Etapa 1 en C conserva su lógica, que los catálogos cubren los seis primeros semestres de Computadores y Física, que el campo `career` se asigna y exporta correctamente, y que la regresión contra la Etapa 1 entregada solo difiere en ese campo.

## 2. Archivos revisados

| Archivo | Qué se revisó |
| --- | --- |
| `include/constants.h` | Carreras válidas (`computadores`, `fisica`), versión del formato, límites. |
| `include/structs.h` | Campo `career` en `Course`; estructuras de grupos y bloques. |
| `include/catalog.h` | Declaración de `catalog_is_valid_career` y `catalog_set_career`. |
| `src/catalog.c` | Asignación de carrera a todos los cursos y validación de carreras. |
| `src/export.c` | Escritura del campo `"career"` en cada curso. |
| `src/main.c` | Lectura del cuarto argumento y llamada a `catalog_set_career` antes de exportar. |
| `src/conflicts.c` / `tests/*` | Lógica de choques y pruebas existentes. |
| `data/fuente/plan_computadores.csv` | Plan de Computadores hasta sexto semestre. |
| `data/fuente/plan_fisica.csv` | Plan de Física hasta sexto semestre. |
| `data/catalogo_computadores.csv` | 39 cursos, 221 grupos. |
| `data/catalogo_fisica.csv` | 39 cursos, 308 grupos. |
| `data/historial_computadores.csv` | 17 cursos aprobados. |
| `data/historial_fisica.csv` | 14 cursos aprobados. |
| `data/salida_computadores.json` | Salida real con `career`. |
| `data/salida_fisica.json` | Salida real con `career`. |
| `tests/regression_etapa1.sh` | Regresión contra la Etapa 1. |
| `README.md` | Descripción de datos, conteos y reglas. |

## 3. Verificación del campo `career` en C

El flujo es:

1. `main.c` recibe la carrera como cuarto argumento opcional; por defecto usa `computadores`.
2. Después de cargar el catálogo, llama a `catalog_set_career(&catalog, career)`.
3. `catalog_set_career` valida con `catalog_is_valid_career` y copia la carrera a `Course.career` de todos los cursos.
4. `export.c` escribe `"career": "<carrera>"` en cada objeto de curso.
5. Si la carrera no es válida, C termina con `ERROR_INVALID_FORMAT` y no exporta.

Comprobaciones realizadas:

- `data/salida_computadores.json`: 39 cursos, los 39 con `"career": "computadores"`.
- `data/salida_fisica.json`: 39 cursos, los 39 con `"career": "fisica"`.
- Todos los cursos de `data/salida_computadores.json` tienen `"career": "computadores"` y todos los de `data/salida_fisica.json` tienen `"career": "fisica"`; un mismo código puede existir en ambas carreras.
- El campo se mantiene estable para todos los cursos de una misma ejecución.
- La identidad de un curso sigue siendo la pareja `(carrera, código)`; un mismo código puede existir en ambas carreras.

## 4. Datos de los seis semestres

### 4.1 Conteos

| Carrera | Cursos | Grupos | Grupos con choque | Aprobados | Matriculables | Sin grupos |
| --- | ---: | ---: | ---: | ---: | ---: | --- |
| Computadores | 39 | 221 | 220 | 17 | 8 | `SE1100`, `SE1200`, `SE1400` |
| Física | 39 | 308 | 308 | 14 | 8 | `CI0200`, `FI2104`, `IF3501` |

Los conteos se obtuvieron de las salidas JSON y coinciden con los mensajes de `./cemestre`:

```
Carrera:    computadores
Catalogo:   data/catalogo_computadores.csv (39 cursos, 221 grupos)
Historial:  data/historial_computadores.csv (17 cursos aprobados)
Choques:    220 grupos con choque de horario
Matricula:  8 cursos matriculables

Carrera:    fisica
Catalogo:   data/catalogo_fisica.csv (39 cursos, 308 grupos)
Historial:  data/historial_fisica.csv (14 cursos aprobados)
Choques:    308 grupos con choque de horario
Matricula:  8 cursos matriculables
```

### 4.2 Cursos agregados en los semestres 5 y 6

El commit `96b5d3f` agregó diez cursos a Computadores:

`CE1107`, `CE3101`, `CE3201`, `MA2105`, `PI5516`, `CE1108`, `CE1109`, `CE1110`, `CE4301`, `CI3203`.

Agregó doce cursos a Física:

`FI2104`, `IF3501`, `IF3503`, `MA2104`, `MA3106`, `PI3612`, `IF3601`, `IF3602`, `IF3603`, `IF3604`, `MI3108`, `PI5302`.

Los planes de `data/fuente/` se actualizaron a seis semestres y los catálogos generados tienen 39 cursos en cada carrera. Los historiales siguen representando a estudiantes que aprobaron los dos primeros semestres, por lo que el número de aprobados no cambia con los cursos nuevos.

### 4.3 Cursos sin grupos

- Computadores: `SE1100`, `SE1200` y `SE1400` son actividades de 0 créditos que la Guía ofrece con otros códigos; quedan en el plan sin grupos.
- Física: `CI0200` es un examen diagnóstico aprobado; `FI2104` e `IF3501` quedan sin grupos en la fuente disponible.

El lector de Racket acepta `"groups": []`; el universo los excluye si se piden y el generador no los elige.

### 4.4 Correquisitos especiales

- `QU1102` y `QU1106` se exigen mutuamente como correquisito. La validación de C permite matricularlos juntos en el mismo periodo.
- `FI1202` tiene como correquisito `FI1102`; `FI1102` tiene como correquisito `MA1102` en Computadores.
- En Física, `IF3603` e `IF3604` se exigen mutuamente; `IF3502` tiene dos correquisitos (`MT2001`, `MT2002`).
- En Computadores, `CE1108` tiene como correquisito `CE4301`; `CE3201` tiene como correquisito `CE1107`.

Racket conserva `corequisites` en el struct `curso`, pero la selección de combinaciones no implementa todavía una restricción específica de correquisitos: el plan de las Fases 0–3 solo exige choques y el filtro de créditos. La información queda disponible para fases posteriores.

## 5. Pruebas de C

Comando:

```bash
make clean
make
make test
```

Resultado observado:

```
tests/run_tests:    48/48 pruebas pasaron
tests/run_phase4:   35/35 pruebas pasaron
tests/run_export:   73/73 pruebas pasaron
```

Las tres suites pasan. La suite de exportación incluye los datos reales de las dos carreras y confirma:

- 39 cursos y 17 aprobados en Computadores;
- 39 cursos y 14 aprobados en Física;
- los cursos sin grupos esperados;
- 8 cursos matriculables en cada carrera;
- los casos de correquisitos mutuos.

## 6. Regeneración de las salidas

Se ejecutó C con las rutas actuales y se compararon las salidas con los archivos versionados:

```bash
./cemestre data/catalogo_computadores.csv data/historial_computadores.csv /tmp/salida_computadores.json computadores
./cemestre data/catalogo_fisica.csv data/historial_fisica.csv /tmp/salida_fisica.json fisica
diff -q data/salida_computadores.json /tmp/salida_computadores.json
diff -q data/salida_fisica.json /tmp/salida_fisica.json
```

`diff` no reportó diferencias: las salidas versionadas son reproducibles y contienen `career`.

## 7. Regresión contra la Etapa 1

Comando (el script acepta un commit o rama base):

```bash
bash tests/regression_etapa1.sh main
```

Salida observada:

```
AVISO - main no contiene Makefile; se usa origin/main
OK   - computadores: misma salida que origin/main salvo career
OK   - computadores: 39 cursos con career
OK   - fisica: misma salida que origin/main salvo career
OK   - fisica: 39 cursos con career
```

La rama local `main` de este entorno apunta a un commit inicial (`d47540d`) que solo contiene un README, no a la Etapa 1. La rama remota `origin/main` (`afba181`, merge de la Etapa 1) sí contiene el código. Por eso el script ahora detecta que la base no tiene `Makefile` y usa `origin/main` automáticamente. Ejecutado explícitamente:

```bash
bash tests/regression_etapa1.sh origin/main
```

produce los mismos cuatro `OK` sin el aviso.

La regresión elimina las líneas `"career": ...` de la salida nueva y compara el resto con la salida de la Etapa 1. La única diferencia funcional es el campo `career`; la lógica de choques, requisitos y matriculabilidad no cambió.

## 8. Problemas encontrados y correcciones

| Problema | Corrección |
| --- | --- |
| La rama local `main` no contiene el código de la Etapa 1. | El script de regresión usa `origin/main` como respaldo cuando la base no tiene `Makefile`. |
| El README decía que los catálogos cubrían cuatro semestres. | Se actualizó a seis semestres y se aclaró que los historiales representan dos semestres aprobados. |
| El README listaba 6 cursos matriculables en Computadores. | Se actualizó a los 8 actuales, incluyendo `MA2105` y `CI3203`. |
| El README daba 196/197 y 285/285 grupos con choque. | Se actualizó a 220/221 y 308/308. |
| Los cursos nuevos sin grupos podían confundirse con errores. | Se documentaron `FI2104` e `IF3501` como casos sin grupos de la fuente. |

## 9. Evidencia y estado final

- `make test`: 48/48, 35/35 y 73/73.
- Salidas regeneradas idénticas a las versionadas.
- Regresión: solo `career` difiere.
- Carreras correctas en los 78 cursos (39 + 39).
- Documentación de datos y decisiones actualizada.

Estado: **Fase 1 cerrada** para el alcance de las Fases 0–3. La validación de correquisitos dentro de las combinaciones y la exportación final quedan para fases posteriores.
