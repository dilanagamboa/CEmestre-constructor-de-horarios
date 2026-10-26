# Decisiones de diseño de las Fases 0–3

Este documento registra las decisiones D1–D7 que afectan la Etapa 2 en Racket. Se redactó el 2026-10-26 sobre la rama `feature/etapa2-fases-0-3`, tomando como base el commit `32cec486f4f9e21b9fc19bb67866d6cb9ecbc8ea` y el contrato de salida de la Etapa 1 en C.

La regla general es que el código de `racket/src/` sea funcional: structs inmutables, contratos explícitos, recursión y streams. Las decisiones que siguen no cambian el formato JSON que produce C ni la identificación de un curso como pareja `(carrera, código)`.

## Resumen

| ID | Decisión |
| --- | --- |
| D1 | Una combinación es un subconjunto no vacío de los cursos habilitados del universo; se permite omitir cursos y se excluye la combinación vacía. |
| D2 | Se usan structs inmutables y contratos de Racket (`contract-out`), no Typed Racket. |
| D3 | Para la Fase 4 se propone JSON Lines (un objeto JSON por combinación); todavía no se implementa la exportación. |
| D4 | Una combinación guarda pares curso-grupo y el total de créditos; la carrera y el horario se obtienen del curso y del grupo de cada par. |
| D5 | En el borde, un bloque que termina exactamente cuando empieza otro no choca. La comparación usa `<` estricto. |
| D6 | Racket recalcula los choques a partir de los bloques. La bandera `has_conflict` de C se usa solo como referencia de consistencia. |
| D7 | El código C queda en la raíz, Racket en `racket/`, los datos compartidos en `data/`, las pruebas en `racket/tests/` y la documentación en `racket/docs/`. |

---

## D1 — Definición de combinación

### Alternativas consideradas

1. **Todos los cursos de interés:** cada combinación debe incluir exactamente un grupo de cada curso del universo. Es la lectura más restrictiva y no permite que el filtro de créditos descarte cursos.
2. **Subconjunto no vacío:** cada combinación elige un subconjunto no vacío de los cursos habilitados y, para cada curso elegido, un grupo compatible. Los cursos que no se eligen simplemente se omiten.
3. **Subconjunto que puede ser vacío:** igual que la anterior, pero permitiendo la combinación sin cursos.

### Decisión final

Se adoptó la alternativa 2: una combinación es un **subconjunto no vacío** de los cursos habilitados del universo. La combinación vacía se excluye explícitamente. La omisión de cursos se controla con la constante `OMITIR-CURSOS?` de `racket/src/generador.rkt`; hoy vale `#t`.

### Justificación

El plan de la Etapa 2 exige que el filtro por créditos pueda quedarse con algunas combinaciones y descartar otras. Si todos los cursos fueran obligatorios, un estudiante no podría comparar escenarios con menos cursos, y el rango de créditos perdería sentido. La omisión también refleja la matrícula real: el estudiante decide qué cursos llevar y no está obligado a llevar todo su plan en un solo semestre. Excluir la combinación vacía evita emitir una “solución” sin cursos ni créditos, que no representa una matrícula útil.

### Consecuencias sobre el diseño

- El generador tiene dos ramas por curso: omitirlo o elegir uno de sus grupos.
- La rama de omisión se emite primero, antes de la rama de selección, para que el orden sea determinista.
- La condición de terminación emite una combinación solo si la selección acumulada no está vacía.
- El filtro por créditos puede aplicarse después, sin que el generador conozca todavía los límites.
- Si el profesor confirma que deben incluirse todos los cursos, el cambio se hace en un solo módulo: `OMITIR-CURSOS?` pasa a `#f` y la rama de omisión devuelve `empty-stream`. No hay que tocar `types.rkt`, `universo.rkt`, `filtros.rkt` ni las pruebas de lectura.

### Archivos afectados

- `racket/src/generador.rkt`: constante `OMITIR-CURSOS?`, rama de omisión y exclusión de la combinación vacía.
- `racket/src/types.rkt`: contrato `combinacion` con `non-empty-listof`.
- `racket/tests/test-generador.rkt`: casos de omisión, combinación vacía y universo vacío.
- `racket/docs/plan_pruebas_generador.md`: casos 1, 2, 8 y 9.

### Cómo se verifica

- El oráculo `racket/tests/data/esperado_rango_total.txt` contiene 41 combinaciones no vacías; la prueba compara el stream completo con ese archivo.
- El oráculo `esperado_varios_grupos.txt` contiene las 26 combinaciones con créditos entre 6 y 10.
- `racket/tests/test-generador.rkt` comprueba que todas las combinaciones tienen al menos un par y que el universo vacío produce un stream vacío.
- La prueba de pereza pide solo el primer resultado de 60 cursos y obtiene `C59-1 | 1` sin materializar las 2^60 − 1 combinaciones posibles.

---

## D2 — Tipos o contratos

### Alternativas consideradas

1. **Typed Racket:** tipado estático en todos los módulos, con `Any`, `cast` y anotaciones en las fronteras.
2. **Racket con contratos:** structs inmutables y `contract-out` en las funciones públicas, con validación en tiempo de ejecución.
3. **Sin contratos ni tipos:** confiar en la disciplina del programador.

### Decisión final

Se usa **Racket con contratos** en todos los módulos. Los structs son inmutables y transparentes; las funciones exportadas tienen contratos explícitos. No se usa `Any` ni `cast` de Typed Racket.

### Justificación

El proyecto ya tenía `types.rkt` con structs y `contract-out`, y el resto de los módulos sigue esa misma estrategia. Los contratos documentan la interfaz y atrapan datos mal formados en las fronteras (lectura de JSON, universo, generador y filtro) sin obligar a anotar cada función recursiva. Además, el filtro polimórfico necesita aceptar cualquier tipo de elemento; el contrato `(stream/c any/c)` expresa esa genericidad sin introducir `Any` de Typed Racket. Mantener una sola estrategia evita mezclar dos sistemas de tipos y conserva la compatibilidad con el código existente.

### Consecuencias sobre el diseño

- `types.rkt` define los predicados y contratos de los structs.
- `catalogo.rkt`, `preferencias.rkt`, `universo.rkt`, `choques.rkt`, `generador.rkt` y `filtros.rkt` usan `contract-out`.
- Las funciones internas no llevan contratos para no duplicar validaciones, pero reciben datos ya validados por las fronteras.
- El filtro usa `any/c` solo en el parámetro de tipo; no hay casts ni tipos dinámicos explícitos.
- Las pruebas verifican los errores de contrato con `check-exn`.

### Archivos afectados

- `racket/src/types.rkt`
- `racket/src/lectura.rkt`
- `racket/src/catalogo.rkt`
- `racket/src/preferencias.rkt`
- `racket/src/universo.rkt`
- `racket/src/choques.rkt`
- `racket/src/generador.rkt`
- `racket/src/filtros.rkt`

### Cómo se verifica

- `raco test racket/tests` compila y ejecuta los módulos con sus contratos.
- La auditoría de `racket/docs/auditoria_fases_0_3.md` confirma que no aparecen `Any`, `cast`, `set!`, `#:mutable` ni `list->stream` en `racket/src/`.
- Las pruebas de lectura comprueban que los datos inválidos producen `exn:fail:user` y no errores inesperados.

---

## D3 — Formato de salida

### Alternativas consideradas

1. **JSON array:** un solo arreglo con todas las combinaciones, como el JSON que ya produce C.
2. **JSON Lines (JSONL):** un objeto JSON independiente por línea, escrito a medida que se consumen las combinaciones.
3. **CSV:** una fila por combinación, con columnas planas.
4. **Hechos de Prolog:** términos como `combinacion([...], Creditos).`

### Decisión final

Para la Fase 4 se propone **JSON Lines**, con un objeto JSON por combinación y una línea por objeto. La decisión es preliminar: la exportación final no se implementa en las Fases 0–3. El contrato de entrada de C sigue siendo JSON normal y no se modifica.

### Justificación

- **Escritura incremental:** cada combinación se puede escribir apenas se produce, sin esperar a cerrar un arreglo.
- **Compatibilidad con streams:** el exportador puede consumir el stream y escribir línea por línea; no necesita materializar la lista completa.
- **Consumo desde Prolog:** cada línea es un objeto autocontenido y puede convertirse a hechos de Prolog sin conservar comas ni corchetes globales.
- **Legibilidad y depuración:** una línea se puede inspeccionar o filtrar con herramientas de texto; un archivo enorme en una sola línea es más difícil de revisar.
- **Estructuras anidadas:** JSONL conserva los objetos y arreglos internos (pares, bloques), algo que CSV pierde o requiere separadores inventados.

La comparación completa está en `racket/docs/formatos_salida.md`.

### Consecuencias sobre el diseño

- No se implementa todavía un módulo exportador ni se agregan campos al JSON de C.
- La futura Fase 4 deberá definir el esquema exacto de cada línea (pares, créditos, carrera, código, grupo, bloques).
- El formato de entrada de C permanece JSON con `format_version` y `course_count`.
- La decisión puede revisarse cuando el profesor indique el formato preferido para la entrega.

### Archivos afectados

- `racket/docs/formatos_salida.md`
- Futuro módulo de exportación de la Fase 4 (no creado en esta etapa).

### Cómo se verifica

- La comparación documental cubre escritura incremental, consumo desde Prolog, legibilidad, tamaño y compatibilidad con streams.
- No hay pruebas de exportación porque la Fase 4 está fuera del alcance de esta entrega.
- La decisión queda marcada como provisional en este documento y en `progreso_fases_0_3.md`.

---

## D4 — Campos de combinación

### Alternativas consideradas

1. Guardar solo los identificadores `(carrera, código, grupo)` y volver a buscar en el catálogo al exportar.
2. Guardar los structs completos de curso y grupo en cada par, más el total de créditos.
3. Guardar una copia plana de todos los campos (carrera, código, nombre, créditos, bloques) en cada combinación.

### Decisión final

Una combinación contiene:

- `pares`: lista no vacía de `par-curso-grupo`, donde cada par guarda el `curso` y el `grupo` elegidos;
- `creditos`: suma de los créditos de los cursos elegidos.

La carrera se obtiene de `(curso-carrera curso)`, el código de `(curso-codigo curso)`, el número de grupo de `(grupo-numero grupo)` y los bloques de `(grupo-bloques grupo)`. No se duplican esos datos dentro de la combinación. El identificador o la cantidad de cursos se pueden calcular al exportar; no se almacenan por ahora.

### Justificación

Guardar los structs completos evita búsquedas repetidas y permite que el futuro exportador tenga toda la información sin depender de un catálogo global. No se guarda una copia plana porque duplicaría datos y podría quedar desincronizada. Los créditos sí se acumulan durante la recursión porque son parte del estado del generador y el filtro los necesita sin recorrer todos los pares.

### Consecuencias sobre el diseño

- `par-curso-grupo` es la unidad de una selección.
- `combinacion` tiene un contrato `non-empty-listof par-curso-grupo?` y créditos no negativos.
- El generador acumula créditos como parámetro y los guarda al emitir; no los recalcula al final.
- Un futuro exportador puede derivar la carrera por curso y la cantidad de cursos con `length`.
- La información de horarios está disponible en `grupo-bloques` si Prolog la necesita.

### Archivos afectados

- `racket/src/types.rkt`
- `racket/src/generador.rkt`
- `racket/tests/test-generador.rkt`
- `racket/docs/estructuras.md`

### Cómo se verifica

- Las pruebas comprueban que `combinacion-creditos` coincide con la suma de `curso-creditos` de los pares.
- Las pruebas del oráculo comparan el texto de cada par `codigo-numero` y el total de créditos.
- La prueba de la combinación vacía confirma que `pares` nunca es vacío.

---

## D5 — Choques en el borde

### Alternativas consideradas

1. Considerar choque cuando un bloque termina exactamente cuando otro empieza (`<=`).
2. Considerar que no hay choque en ese borde (`<` estricto).
3. Redondear o ampliar los intervalos con un margen arbitrario.

### Decisión final

Se adopta la alternativa 2, la misma de la Etapa 1: dos bloques del mismo día chocan si cada uno empieza **antes** de que termine el otro. Si un bloque termina a las 10:00 y otro empieza a las 10:00, no chocan. La comparación es `<` estricto en ambos sentidos. Días distintos nunca chocan. Un grupo sin bloques nunca choca.

### Justificación

Es la regla ya implementada en `src/conflicts.c` y documentada en el README de la Etapa 1. Cambiarla rompería la compatibilidad y produciría falsos positivos en horarios consecutivos. El margen arbitrario no está justificado por los datos.

### Consecuencias sobre el diseño

- `bloques-chocan?` usa `(and (eq? dia dia) (< inicio-a fin-b) (< inicio-b fin-a))`.
- `grupos-chocan?` usa `ormap` sobre los bloques de ambos grupos.
- `grupo-compatible?` recorre la selección acumulada y se detiene al primer choque.
- Los grupos alternativos del mismo curso no se comparan entre sí porque el generador elige como máximo un grupo por curso.

### Archivos afectados

- `racket/src/choques.rkt`
- `racket/src/generador.rkt`
- `racket/tests/test-choques.rkt`
- `racket/tests/test-generador.rkt`

### Cómo se verifica

- `test-choques.rkt` cubre horarios idénticos, traslape parcial, bloque contenido, borde en ambos órdenes, días distintos, grupos con varios bloques y grupos vacíos.
- `test-generador.rkt` comprueba que dos cursos en borde sí producen la combinación conjunta, mientras que dos cursos con traslape no.
- La prueba de consistencia con C compara la bandera por grupo de las dos carreras reales con el cálculo de Racket.

---

## D6 — Fuente de los choques

### Alternativas consideradas

1. Confiar únicamente en la bandera `has_conflict` que escribe C.
2. Recalcular los choques en Racket a partir de los bloques y usar la bandera de C solo como referencia.
3. Ignorar los choques y delegar la decisión a la Etapa 3 (Prolog).

### Decisión final

Se adopta la alternativa 2. `choques.rkt` calcula los choques entre bloques y grupos; la bandera `has_conflict` de C se conserva en `grupo-choque` y se usa en una prueba de consistencia, no como fuente de verdad. El lector de catálogo valida que la bandera del curso sea coherente con las banderas de sus grupos, pero no intenta recalcular los choques de todo el catálogo al leer.

### Justificación

Racket necesita comparar un grupo candidato contra una selección parcial, incluyendo grupos de cursos que pueden no haber sido marcados como conflictivos en el catálogo completo. Recalcular desde los bloques permite esa comparación y hace que el generador sea independiente de la implementación de C. La prueba de consistencia detecta si C y Racket interpretan distinto el borde o los días. No se recalcula al leer porque el catálogo sintético de pruebas usa banderas deliberadamente conservadoras y porque el lector no debe hacer el trabajo del generador.

### Consecuencias sobre el diseño

- `grupo` conserva el campo `choque` para la referencia de C.
- `bloques-chocan?` y `grupos-chocan?` son la fuente de verdad para el generador.
- `catalogo.rkt` valida `has_conflict` del curso contra `ormap grupo-choque` de sus grupos.
- La prueba de consistencia se ejecuta solo si existen las salidas reales; si faltan, falla con un mensaje que indica generarlas con `./cemestre`.
- Las diferencias entre C y Racket deben documentarse; hoy no hay diferencias en los datos reales.

### Archivos afectados

- `racket/src/choques.rkt`
- `racket/src/catalogo.rkt`
- `racket/src/generador.rkt`
- `racket/tests/test-choques.rkt`

### Cómo se verifica

- `test-choques.rkt` compara, grupo por grupo, `choca-en-catalogo?` (cálculo de Racket) con `grupo-choque` (bandera de C) para Computadores y Física.
- El lector rechaza un catálogo de prueba donde la bandera del curso no coincide con sus grupos.
- `make test` de C sigue pasando y la regresión confirma que la lógica de choques de C no cambió.

---

## D7 — Organización del repositorio

### Alternativas consideradas

1. Mezclar C y Racket en un solo directorio.
2. Separar por lenguaje y por tipo de archivo, compartiendo solo los datos.
3. Duplicar los datos dentro de cada etapa.

### Decisión final

Se mantiene la organización existente:

| Ubicación | Contenido |
| --- | --- |
| Raíz (`src/`, `include/`, `tests/`) | Etapa 1 en C: carga, choques, validación y exportación JSON. |
| `data/` | Datos compartidos: catálogos CSV, historiales, fuentes y salidas JSON de C. |
| `racket/src/` | Módulos funcionales de la Etapa 2: tipos, lectura, catálogo, preferencias, universo, choques, generador y filtros. |
| `racket/tests/` | Suites de Racket y datos sintéticos/oráculos. |
| `racket/docs/` | Decisiones, contratos, progreso, pruebas, auditoría y guía de defensa. |
| `plan_Fase0-3.md` | Guía de trabajo de esta entrega (no forma parte del código). |

La rama de trabajo es `feature/etapa2-fases-0-3`. Los commits siguen el estilo del historial: prefijos `feat:`, `data:`, `test:` y `docs:` en inglés o español, con un mensaje corto y específico. La revisión se apoya en tres evidencias: pruebas automatizadas, oráculos manuales y comparación con C.

### Justificación

La separación permite que C siga siendo un programa independiente y que Racket consuma sus salidas sin acoplarse a los archivos internos de C. Los datos compartidos evitan duplicar catálogos e historiales. La documentación separada por fase facilita la defensa y la revisión cruzada.

### Consecuencias sobre el diseño

- Racket lee `data/salida_computadores.json` y `data/salida_fisica.json`, no los CSV directamente.
- Las pruebas sintéticas viven en `racket/tests/data/` para no depender de los datos reales.
- La Etapa 2 no implementa las Fases 4–7: no hay exportador final, programa principal, interfaz ni Prolog.
- El README de la raíz sigue describiendo la Etapa 1 y se actualizó para reflejar los seis semestres y los conteos actuales.

### Cómo se verifica

- `git status` y `git log` muestran la rama y los archivos de cada fase.
- `raco test racket/tests` ejecuta las suites de Racket.
- `make test` y `bash tests/regression_etapa1.sh main` verifican C y la compatibilidad con la Etapa 1.
- La auditoría de `racket/src/` confirma que no se introdujo mutación ni materialización eager.

---

## Decisiones provisionales y pendientes

- **D3** es preliminar: JSON Lines se propone para la Fase 4, pero no se implementa en esta entrega.
- **D1** queda preparada para cambiar en un solo módulo si el profesor exige que todos los cursos estén presentes.
- El formato exacto de cada línea JSONL y la conversión a hechos de Prolog se definirán en la Fase 4.
- La revisión final de los datos de Física y de los horarios de los semestres 5–6 sigue siendo responsabilidad del equipo; este documento registra lo que se pudo verificar con las pruebas y los archivos disponibles.
