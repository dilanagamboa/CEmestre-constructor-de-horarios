# CEmestre — Constructor de horarios

Diseñar e implementar, de forma incremental y utilizando distintos paradigmas
de programación, un sistema que apoye a un estudiante en la construcción de un
horario de matrícula válido, aplicando en cada etapa un paradigma para resolver
el subproblema correspondiente.

**Etapa 1 — Paradigma imperativo (C).** Estado actual: Fases 1 a 4 del plan de
trabajo completadas y probadas.

---

## 1. Estado del proyecto

| Fase | Descripción | Estado |
|------|-------------|--------|
| 1 | Diseño y arquitectura (`structs.h`, `constants.h`) | Completada |
| 2 | Carga de catálogo e historial | Completada |
| 3 | Detección de choques de horario | Completada |
| 4 | Validación de requisitos y correquisitos | Completada |
| 5 | Exportación e integración (`main.c`) | Pendiente |
| 6 | Pruebas integrales y limpieza de datos | Pendiente |
| 7 | Documentación final | En progreso |

---

## 2. Documentación

### 2.1 Arquitectura del proyecto

El programa sigue un flujo lineal en cinco etapas, cada una implementada en un
módulo independiente:

```
cargar catálogo → cargar historial → detectar choques → validar matrícula → exportar
```

Módulos actuales:

- **`utils`** — utilidades de strings y parsing (`trim_whitespace`, `safe_strcpy`, `split_fields`).
- **`catalog`** — carga, indexación y liberación del catálogo de cursos.
- **`history`** — carga y consulta del historial de cursos aprobados.
- **`conflicts`** — detección de solapamientos de bloques horarios.
- **`validation`** — validación de prerrequisitos y correquisitos.

Cada módulo expone una interfaz en `include/` y una implementación en `src/`.
Ninguna función usa `malloc` innecesario ni recursión; el estilo es imperativo
puro: recorridos con índices, retornos por valor y códigos de error explícitos.

Estructura de archivos:

```
proyecto/
├── include/
│   ├── catalog.h
│   ├── conflicts.h
│   ├── constants.h
│   ├── history.h
│   ├── structs.h
│   ├── utils.h
│   └── validation.h
├── src/
│   ├── catalog.c
│   ├── conflicts.c
│   ├── history.c
│   ├── utils.c
│   └── validation.c
├── data/
│   ├── catalogo.csv
│   └── historial.csv
└── tests/
    ├── test_phase123.c
    ├── test_phase4.c
    └── data_invalid/
```

### 2.2 Decisiones de diseño

#### 2.2.1 Separador `@` en el campo de grupos

El formato de `catalogo.csv` usa `;` como separador de campos y, dentro del
campo `groups`, `@` como separador entre número de grupo, profesor y bloques.
Originalmente se usaba `:` para ese rol, pero se cambió a `@` porque `:`
también aparece dentro del formato de hora (`HH:MM`), lo que producía
ambigüedad al parsear. Ejemplo:

```
CE1106;Paradigmas;4;CE1103;;1@Juan Perez@MON,08:00,10:00
```

Con `@` el parser puede hacer `split` sin necesidad de lógica de contexto.

#### 2.2.2 Caso límite real: correquisitos mutuos

Durante la Fase 4 se identificó un caso recurrente en el plan de estudios de
Ingeniería en Computadores del TEC: la asignatura **CE2103 — Estructuras de
Datos** y su laboratorio **CE2104 — Laboratorio de Estructuras de Datos**
aparecen declarados como correquisitos mutuos en la Guía de Horarios. Es decir,
CE2103 lista a CE2104 como correquisito y CE2104 lista a CE2103 como
correquisito.

**Situación concreta.** Un estudiante tiene aprobado el prerrequisito común
(CE1106 — Paradigmas de Programación) pero **no** tiene en su historial ni
CE2103 ni CE2104.

**Política aplicada.** Un correquisito se considera cumplido únicamente si el
curso correspondiente aparece en el historial de cursos aprobados. No se simula
matrícula simultánea en el mismo semestre.

**Consecuencia.** Bajo esta política, tanto CE2103 como CE2104 quedan marcados
con `can_enroll = 0`: cada uno exige al otro como correquisito aprobado y
ninguno lo está. El comportamiento es simétrico: si el historial del estudiante
ya contiene uno de los dos (por ejemplo por convalidación), el otro pasa a ser
matriculable.

**Por qué se acepta esta limitación.** La Etapa 1 no arma horarios ni simula
procesos de matrícula; su alcance es determinar elegibilidad curricular a partir
de un historial cerrado de cursos ya aprobados. Simular matrícula simultánea
requeriría un modelo temporal de inscripción (semestre en curso, cupos,
prioridades) que excede el enunciado. La limitación se documenta explícitamente
para que la Etapa 2 (Racket) no interprete erróneamente `can_enroll = 0` como
"curso imposible de llevar en la realidad", sino como "curso no elegible según
el historial cargado".

**Cómo se probó.** En `tests/test_phase4.c`, bloque 5, se construyen dos cursos
mutuamente correquisitados (`H` ↔ `I`) con un prerrequisito común `R`, y se
verifica:

1. Con `R` aprobado pero sin `H` ni `I`, ambos quedan `can_enroll = 0`.
2. Con `R` y `H` aprobados, `I` pasa a `can_enroll = 1` (simetría).

**Decisión asociada: `can_enroll` no considera `has_conflict`.** Un curso sin
prerrequisitos ni correquisitos pendientes es marcado `can_enroll = 1` aunque
todos sus grupos tengan `has_conflict = 1`. La razón es que `can_enroll`
representa **elegibilidad curricular** y `has_conflict` representa
**factibilidad de horario**. Mezclar ambas responsabilidades haría que un
cambio en el catálogo de horarios alterara la elegibilidad del estudiante, lo
que rompe la separación de módulos del proyecto.

**Política de correquisitos (resumen).** Para la validación de correquisitos se
adoptó la política de que un correquisito se considera cumplido si el curso
correspondiente ya aparece en el historial de cursos aprobados del estudiante.
No se simula la matrícula simultánea en el mismo semestre porque el historial
solo contiene cursos aprobados y porque el alcance de la Etapa 1 no incluye
construir horarios ni simular matrícula. Esta decisión mantiene la validación
simple, determinista y coherente con el paradigma imperativo puro. Si el
estudiante no ha aprobado algún correquisito, el curso se marca con
`can_enroll = 0`.

### 2.3 Estructuras de datos desarrolladas

Todas las estructuras viven en `include/structs.h` y los límites y constantes
en `include/constants.h`, separados por exigencia del enunciado.

- **`TimeBlock`** — un bloque horario: día (`Weekday`), hora y minuto de inicio
  y de fin. Se guardan horas y minutos por separado para evitar parsear strings
  en cada comparación.
- **`Group`** — un grupo de un curso: número, profesor, arreglo de hasta
  `MAX_BLOCKS_PER_GROUP` bloques, contador y bandera `has_conflict`.
- **`Course`** — un curso: código, nombre, créditos, arreglos de códigos de
  prerrequisitos y correquisitos con sus contadores, grupos, y bandera
  `can_enroll`.
- **`Catalog`** — arreglo dinámico de cursos con `course_count` y `capacity`.
  Crece con `realloc` en `catalog_add_course` y se libera con `catalog_free`.
- **`StudentHistory`** — arreglo estático de códigos aprobados y contador.

Los strings se copian con `safe_strcpy`, que garantiza `'\0'` final y trunca de
forma segura si el origen no cabe. No hay `malloc` fuera del catálogo.

---

## 3. Pruebas y resultados

### 3.1 Cómo compilar y correr

Fases 1–3:

```bash
gcc -Wall -Wextra -Wpedantic -std=c99 -g \
    src/utils.c src/catalog.c src/history.c src/conflicts.c \
    tests/test_phase123.c -o tests/run_tests

./tests/run_tests
```

Fase 4:

```bash
gcc -Wall -Wextra -Wpedantic -std=c99 -g \
    src/utils.c src/catalog.c src/history.c src/validation.c \
    tests/test_phase4.c -o tests/run_phase4

./tests/run_phase4
```

El ejecutable retorna `0` si todas las pruebas pasan y `1` si alguna falla, para
que el resultado sea verificable desde un script.

### 3.2 Cobertura de la Fase 4

El archivo `tests/test_phase4.c` agrupa las pruebas en seis bloques:

| Bloque | Qué verifica |
|--------|--------------|
| 1 | Historial vacío: sólo los cursos sin prerrequisitos ni correquisitos son matriculables |
| 2 | Historial con `A` aprobado: se cumple un prerrequisito y un correquisito, pero no los que dependen de `D` |
| 3 | Historial con `A` y `D` aprobados: se cumplen prerrequisitos compuestos y múltiples correquisitos |
| 4 | Idempotencia: dos llamadas consecutivas a `validation_mark_enrollable` producen el mismo estado de `can_enroll` |
| 5 | Caso real: correquisitos mutuos (`H` ↔ `I`) con prerrequisito común `R` |
| 6 | Validaciones directas y robustez ante punteros `NULL` |

### 3.3 Resultados

Ejecución local en Artix Linux, `gcc 13.2`, con `-Wall -Wextra -Wpedantic` sin
advertencias:

```
OK   - historial vacio: A sin requisitos es matriculable
OK   - historial vacio: D sin requisitos es matriculable
OK   - historial vacio: B con prerrequisito A no es matriculable
...
OK   - robustez: course NULL devuelve 0
OK   - robustez: history NULL devuelve 0

28/28 pruebas pasaron
```

Las pruebas de Fases 1–3 (`tests/test_phase123.c`) reportan `33/33`.

### 3.4 Criterios de aceptación de la Fase 4

- [x] Todos los cursos con prerrequisitos incumplidos quedan con `can_enroll = 0`.
- [x] Todos los cursos con correquisitos incumplidos quedan con `can_enroll = 0`.
- [x] Los cursos sin requisitos son matriculables cuando el historial no aporta nada en contra.
- [x] `validation_mark_enrollable` es idempotente.
- [x] El caso límite de correquisitos mutuos está documentado (2.2.2) y probado (bloque 5).
- [x] El módulo compila sin advertencias con `-Wall -Wextra -Wpedantic`.

---

## 4. Compilación del proyecto completo

```bash
gcc -Wall -Wextra -Wpedantic -std=c99 -g \
    src/utils.c src/catalog.c src/history.c src/conflicts.c src/validation.c \
    tests/test_phase4.c -o tests/run_phase4
```

`main.c` y el módulo exportador se agregarán en la Fase 5.

