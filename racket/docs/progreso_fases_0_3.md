# Registro de progreso: Fases 0–3

## 1. Identificación de la ejecución

| Dato | Valor |
| --- | --- |
| Fecha de inicio | 2026-10-26 |
| Fecha de finalización | 2026-10-26 |
| Rama | `feature/etapa2-fases-0-3` |
| Commit inicial | `32cec486f4f9e21b9fc19bb67866d6cb9ecbc8ea` |
| Commit final | El commit de cierre de esta ejecución; se consulta con `git log -1 --format=%H` después de registrar estos documentos. |
| Racket | 9.3 [cs], instalación local |
| Sistema operativo | Linux `artix-degeo` 6.12.68, x86_64 |
| gcc | 16.1.1 |
| Shell | bash |

La instalación de Racket fue local; no se instaló en el sistema. Se configuraron `PLTCONFIGDIR` y `PATH` para usar esa instalación en todos los comandos de Racket.

## 2. Comandos de prueba ejecutados

```bash
# C
make clean
make
make test

# Regresión contra la Etapa 1
bash tests/regression_etapa1.sh main
bash tests/regression_etapa1.sh origin/main

# Racket
raco test -j 4 racket/tests
raco test racket/tests/test-catalogo.rkt
raco test racket/tests/test-preferencias.rkt
raco test racket/tests/test-universo.rkt
raco test racket/tests/test-choques.rkt
raco test racket/tests/test-generador.rkt
raco test racket/tests/test-filtros.rkt
raco test racket/tests/test-streams.rkt

# Auditoría
grep -RIn --fixed-strings -- 'set!' racket/src
grep -RIn --fixed-strings -- 'hash-set!' racket/src
grep -RIn --fixed-strings -- 'vector-set!' racket/src
grep -RIn --fixed-strings -- 'set-box!' racket/src
grep -RIn --fixed-strings -- '#:mutable' racket/src
grep -RIn --fixed-strings -- 'list->stream' racket/src
grep -RIn --fixed-strings -- 'Any' racket/src
grep -RIn --fixed-strings -- 'cast' racket/src
```

## 3. Registro por fase

### 3.1 Fase 0 — Arranque, decisiones y contrato

**Objetivo:** cerrar D1–D7, documentar la entrada del catálogo y las preferencias, el prototipo de streams y la comparación de formatos.

**Estado inicial:** no existía `racket/docs/`. Los módulos de tipos, catálogo, preferencias, universo y choques ya existían, pero no había documentación de decisiones ni evidencia de streams.

**Archivos revisados:**

- `plan_Fase0-3.md`
- `README.md`
- `racket/src/types.rkt`
- `racket/src/catalogo.rkt`
- `racket/src/preferencias.rkt`
- `racket/src/universo.rkt`
- `racket/src/choques.rkt`
- `data/salida_computadores.json`, `data/salida_fisica.json`

**Archivos creados:**

- `racket/docs/decisiones.md`
- `racket/docs/entrada_catalogo.md`
- `racket/docs/preferencias.md`
- `racket/docs/estructuras.md`
- `racket/docs/formatos_salida.md`
- `racket/docs/prototipo_streams.md`
- `racket/docs/progreso_fase_1.md`
- `racket/docs/progreso_fase_2.md`
- `racket/docs/plan_pruebas_generador.md`
- `racket/docs/progreso_fases_0_3.md`
- `racket/docs/auditoria_fases_0_3.md`
- `racket/docs/guia_defensa.md`
- `racket/tests/test-streams.rkt`

**Pruebas ejecutadas:** `raco test racket/tests/test-streams.rkt` (3 tests passed) y las pruebas de generador que dependen del prototipo.

**Resultado:** D1–D7 documentadas; formatos de catálogo y preferencias documentados; prototipo de streams con evidencia ejecutable; comparación JSON/JSONL/CSV/Prolog completada.

**Problemas encontrados:** ninguno de contenido; la documentación se escribió después de estabilizar el código para que los resultados observados fueran reales.

**Decisiones tomadas:** D1–D7 según `decisiones.md`; D3 queda preliminar.

**Riesgos pendientes:** la decisión de formato de salida depende de la Fase 4 y de la preferencia del profesor.

**Estado final:** cerrada.

### 3.2 Fase 1 — Datos y ampliación de C

**Objetivo:** verificar los seis semestres, el campo `career`, la lógica de C y la regresión contra la Etapa 1.

**Estado inicial:** los datos de los semestres 5–6 ya estaban en la rama; el campo `career` estaba en C y en las salidas. Faltaba verificarlos de forma sistemática y documentar el resultado.

**Archivos revisados:** `include/constants.h`, `include/structs.h`, `include/catalog.h`, `src/catalog.c`, `src/export.c`, `src/main.c`, `data/fuente/plan_computadores.csv`, `data/fuente/plan_fisica.csv`, catálogos, historiales, salidas, `tests/regression_etapa1.sh` y `README.md`.

**Archivos modificados:**

- `README.md`: se actualizó de cuatro a seis semestres, de 6 a 8 cursos matriculables en Computadores y los conteos de grupos con choque (220/221 y 308/308).
- `tests/regression_etapa1.sh`: se agregó un respaldo a `origin/main` cuando la base no tiene `Makefile`.

**Pruebas ejecutadas:** `make test`, regeneración de salidas y `diff`, regresión contra `origin/main`.

**Resultado:**

- C: 48/48, 35/35 y 73/73 pruebas.
- 39 cursos por carrera; 17/14 aprobados; 8/8 matriculables; 221/308 grupos.
- Salidas regeneradas idénticas.
- Regresión: solo `career` difiere.

**Problemas encontrados:**

- La rama local `main` de este entorno apunta a `d47540d` (commit inicial sin código), no a la Etapa 1.
- El README tenía conteos de cuatro semestres.

**Correcciones:** respaldo a `origin/main` en el script y actualización del README.

**Riesgos pendientes:** la verificación de los horarios de los cursos nuevos depende de las fuentes recopiladas por el equipo; no se consultó la Guía externa.

**Estado final:** cerrada.

### 3.3 Fase 2 — Tipos y lectura de entradas

**Objetivo:** estabilizar structs y contratos, validar catálogo y preferencias, y construir el universo.

**Estado inicial:** los módulos existían y las pruebas iniciales pasaban. El lector de catálogo no validaba números de grupo repetidos, auto-requisitos ni la coherencia de `has_conflict` del curso; las pruebas de errores eran limitadas.

**Archivos revisados:** `types.rkt`, `lectura.rkt`, `catalogo.rkt`, `preferencias.rkt`, `universo.rkt` y sus pruebas.

**Archivos modificados:**

- `racket/src/types.rkt`: comentario de inmutabilidad sin la palabra `#:mutable`.
- `racket/src/catalogo.rkt`: validación de grupos repetidos, auto-requisitos, coherencia de `has_conflict` del curso y campo obligatorio.
- `racket/tests/test-catalogo.rkt`: casos de carrera inválida, conteo, código repetido, mismo código en dos carreras, grupo repetido, campo faltante, auto-requisito, choque incoherente, versión, JSON malformado y raíz no objeto.
- `racket/tests/test-preferencias.rkt`: casos de objeto, créditos negativos, carrera, código, grupos vacíos/no positivos/repetidos, `courses` no lista, falta de máximo, JSON malformado y archivo vacío.
- `racket/tests/test-universo.rkt`: universo vacío, orden, no modificación del catálogo y curso sin grupos.

**Archivos creados:** los fixtures `catalogo_*.json` y `preferencias_*.json` nuevos en `racket/tests/data/`.

**Pruebas ejecutadas:** 6 tests de catálogo, 4 de preferencias y 6 de universo; todas pasan.

**Resultado:** los tipos y contratos están documentados; el catálogo y las preferencias se cargan con errores controlados; el universo preserva el orden y no modifica el catálogo.

**Problemas encontrados:** ninguno bloqueante; se agregaron validaciones que C ya aplicaba pero Racket no.

**Decisiones tomadas:** permitir cursos repetidos en preferencias y reportarlos en el universo; usar la primera aparición; conservar grupos en orden del catálogo; no recalcular choques en el lector.

**Riesgos pendientes:** la restricción de correquisitos dentro de las combinaciones no se implementa en esta fase.

**Estado final:** cerrada.

### 3.4 Fase 3 — Choques, streams y polimorfismo

**Objetivo:** implementar choques, generador perezoso y filtro genérico, con pruebas aisladas y combinadas.

**Estado inicial:** `choques.rkt` y sus pruebas existían. No existían `generador.rkt`, `filtros.rkt`, pruebas de generador, pruebas de filtros ni evidencia de pereza.

**Archivos revisados:** `choques.rkt`, `types.rkt`, `universo.rkt`, `catalogo.rkt`, `preferencias.rkt`, los oráculos y las pruebas existentes.

**Archivos creados:**

- `racket/src/generador.rkt`
- `racket/src/filtros.rkt`
- `racket/tests/test-generador.rkt`
- `racket/tests/test-filtros.rkt`
- `racket/tests/test-streams.rkt`

**Archivos modificados:** `racket/tests/test-choques.rkt` se mantuvo; se verificó la consistencia con C. `racket/src/generador.rkt` se corrigió para diferir la construcción de las ramas con `stream-lazy`.

**Pruebas ejecutadas:** 5 de choques, 14 de generador, 7 de filtros y 3 de streams; 45 tests en total con el resto de la suite.

**Resultado:**

- Choques: regla de borde, simetría, grupos vacíos y consistencia con C.
- Generador: 41 combinaciones del oráculo total y 26 del rango 6–10, en orden, con créditos correctos y sin combinación vacía.
- Pereza: 60 cursos, 2^60 − 1 combinaciones posibles, primer resultado `C59-1 | 1`.
- Filtro: enteros, cadenas y combinaciones con la misma función, límites inclusivos y rango sin resultados.
- Auditoría: sin mutación en `racket/src/`.

**Problemas encontrados:** la primera versión del generador construía las dos ramas de cada curso antes de llamar a `stream-append`; con 24 cursos el proceso no terminaba. Se corrigió con `stream-lazy` en las ramas y en el resto de grupos. La prueba de 60 cursos verifica la corrección.

**Decisiones tomadas:** D1 con omisión; orden de omisión primero; grupos en orden de catálogo; combinación vacía excluida; filtro con `any/c` y extractor.

**Riesgos pendientes:** el generador no aplica todavía el filtro de créditos integrado al flujo principal (Fase 4) ni restricciones de correquisitos; la exportación final no existe.

**Estado final:** cerrada.

## 4. Registro por persona

### 4.1 Persona A — Tipos y choques

| Aspecto | Detalle |
| --- | --- |
| Tareas asignadas | Structs y contratos; detección de choques entre bloques, grupos y selección. |
| Evidencia encontrada | `types.rkt` con structs inmutables y `contract-out`; `choques.rkt` con la regla de borde; pruebas iniciales de choques. |
| Trabajo completado | Revisión de contratos; pruebas de borde, simetría, grupos vacíos y consistencia con C; documentación en `estructuras.md` y `guia_defensa.md`. |
| Trabajo que ya existía | Structs, contratos y funciones de choques. |
| Trabajo pendiente | Ninguno para Fases 0–3. |
| Archivos relacionados | `racket/src/types.rkt`, `racket/src/choques.rkt`, `racket/tests/test-choques.rkt`. |
| Pruebas asociadas | 5 tests de choques; consistencia con las dos salidas reales. |

### 4.2 Persona B — Catálogo y generador

| Aspecto | Detalle |
| --- | --- |
| Tareas asignadas | Lector de catálogo y generador de combinaciones. |
| Evidencia encontrada | `catalogo.rkt` y pruebas iniciales; no existía `generador.rkt`. |
| Trabajo completado | Validaciones adicionales del catálogo; creación del generador perezoso; oráculos; prueba de 60 cursos; documentación. |
| Trabajo que ya existía | Lector de catálogo y pruebas básicas. |
| Trabajo pendiente | Exportación final (Fase 4) y posible restricción de correquisitos. |
| Archivos relacionados | `racket/src/catalogo.rkt`, `racket/src/generador.rkt`, `racket/tests/test-catalogo.rkt`, `racket/tests/test-generador.rkt`, `racket/tests/data/*`. |
| Pruebas asociadas | 6 tests de catálogo; 14 tests de generador; 3 tests de streams. |

### 4.3 Persona C — Preferencias, universo y filtro

| Aspecto | Detalle |
| --- | --- |
| Tareas asignadas | Lector de preferencias, construcción del universo y filtro polimórfico. |
| Evidencia encontrada | `preferencias.rkt` y `universo.rkt` con pruebas iniciales; no existía `filtros.rkt`. |
| Trabajo completado | Pruebas de errores de preferencias; pruebas de orden y no mutación del universo; creación del filtro genérico y sus pruebas con tres tipos. |
| Trabajo que ya existía | Lectores y universo. |
| Trabajo pendiente | Filtro integrado al flujo principal y exportación (Fase 4). |
| Archivos relacionados | `racket/src/preferencias.rkt`, `racket/src/universo.rkt`, `racket/src/filtros.rkt`, `racket/tests/test-preferencias.rkt`, `racket/tests/test-universo.rkt`, `racket/tests/test-filtros.rkt`. |
| Pruebas asociadas | 4 tests de preferencias; 6 de universo; 7 de filtros. |

## 5. Decisiones modificadas o correcciones registradas

No había un documento previo de decisiones que se pudiera cambiar; D1–D7 se documentaron por primera vez. Sí se registran estas correcciones de implementación:

| Situación original | Nueva situación | Razón | Impacto |
| --- | --- | --- | --- |
| El generador construía las ramas con `stream-append` sin diferirlas. | Las ramas se envuelven en `stream-lazy`. | Con 24 cursos el árbol de llamadas era exponencial antes de devolver el primer elemento. | `generador.rkt`, pruebas de generador y documento de streams. |
| El catálogo no validaba grupos repetidos, auto-requisitos ni coherencia de `has_conflict`. | Se agregaron esas validaciones. | C ya las aplica y el contrato de entrada debe ser coherente. | `catalogo.rkt`, fixtures y pruebas. |
| El script de regresión usaba `main` sin verificar que contuviera código. | Si la base no tiene `Makefile`, usa `origin/main`. | En este entorno `main` local es un commit inicial. | `tests/regression_etapa1.sh`. |
| El README describía cuatro semestres y conteos viejos. | Se actualizó a seis semestres y conteos actuales. | Los datos de la rama ya tenían los semestres 5–6. | `README.md`. |

## 6. Limitaciones

- **No se implementaron las Fases 4–7:** no hay exportador final, programa principal, interfaz, sugerencias ni Prolog.
- **No hay revisión del equipo registrada:** las pruebas se ejecutaron y los oráculos se contrastaron; el equipo debe revisar la tabla y la guía de defensa.
- **La restricción de correquisitos dentro de las combinaciones no está implementada:** el plan de Fases 0–3 solo exige choques y el filtro de créditos; la información de correquisitos queda en el struct para fases posteriores.
- **La verificación de los horarios nuevos depende de las fuentes del equipo:** no se consultó la Guía externa ni se validó cada profesor contra el sitio del TEC.
- **Racket se instaló localmente:** los comandos de este documento suponen esa instalación; en otro entorno debe usarse el Racket del sistema.
- **La rama local `main` está en un commit inicial:** la regresión usa `origin/main` como respaldo. En un clon normal, `main` debería apuntar a la Etapa 1.
- **El formato de salida es preliminar:** JSON Lines se propone para la Fase 4, pero no se implementó ni se probó con un exportador real.
- **El lector de catálogo valida `has_conflict` del curso contra sus grupos:** asume la semántica de C (curso = cualquier grupo). Un archivo de otra herramienta con otra semántica sería rechazado.
- **No se probó con catálogos reales de más de 39 cursos ni con streams de millones de elementos:** la prueba de 60 cursos es una demostración de pereza, no una prueba de rendimiento a gran escala.

## 7. Estado final

| Criterio | Estado |
| --- | --- |
| D1–D7 documentadas | Sí |
| Entrada de catálogo documentada | Sí |
| Preferencias documentadas | Sí |
| Prototipo de streams documentado y probado | Sí |
| Comparación de formatos | Sí |
| Campo `career` verificado | Sí |
| Regresión contra Etapa 1 | Sí, solo `career` |
| Tipos y contratos documentados | Sí |
| Catálogo, preferencias y universo | Sí |
| Choques con casos límite | Sí |
| Generador con streams reales | Sí |
| Sin materialización eager | Sí |
| Combinación vacía excluida | Sí |
| Filtro polimórfico con tres tipos | Sí |
| Todas las pruebas de Fases 0–3 | Sí, 45 de Racket; 48/35/73 de C |
| Auditoría sin mutación indebida | Sí |
| Registro de progreso | Este documento |
| Guía de defensa | `guia_defensa.md` |
| Limitaciones y decisiones provisionales | Sección 6 y `decisiones.md` |

La Etapa 2 queda preparada para la Fase 4, que deberá consumir el stream de combinaciones, aplicar el filtro de créditos en el flujo principal, definir la exportación JSONL y conectar la salida con Prolog.
