# CEmestre: constructor de horarios

Instituto Tecnológico de Costa Rica, Escuela de Ingeniería en Computadores
Paradigmas de Programación (CE1106). Proyecto, Etapa 1 (paradigma imperativo, lenguaje C)

| Integrante                      | Carné      |
| ------------------------------- | ---------- |
| Paulo Andrés Centeno Flores     | 2025119739 |
| Máyerlin Dilana Gamboa González | 2025096295 |
| David Jafeth Obando Blanco      | 2024157494 |

CEmestre es una herramienta de apoyo a la matrícula universitaria, pues a partir del plan de estudios de una carrera y de los cursos que un estudiante ya aprobó determina qué cursos puede matricular y cuáles presentan choques de horario, como base para construir un horario de matrícula válido. El sistema completo se desarrolla en cuatro etapas, una por paradigma (C, Racket, Prolog y Java), y cada etapa corresponde a un programa independiente que lee y escribe archivos.

Esta primera etapa, escrita en C bajo el paradigma imperativo, carga el catálogo de cursos y el historial del estudiante, detecta los choques de horario, valida los requisitos y exporta el resultado en un archivo JSON, que sirve de insumo a la Etapa 2 (Racket). El módulo no genera combinaciones de horario ni ofrece interfaz, pues esas tareas corresponden a etapas posteriores. Se trabajó con Ingeniería en Computadores y con Física, cada una con su propio catálogo e historial; los catálogos cubren los seis primeros semestres de su plan y los historiales representan a estudiantes que aprobaron los dos primeros.

## 1. Uso

El proyecto se compila y se prueba en Linux (en Windows, con WSL y Ubuntu) y requiere `gcc`, `make` y `valgrind`. Se compila con `-Wall -Wextra -Wpedantic -std=c99`.

| Comando         | Qué hace                                                                           |
| --------------- | ---------------------------------------------------------------------------------- |
| `make`          | Compila el ejecutable `./cemestre`                                                 |
| `make run`      | Ejecuta el programa con las rutas por defecto (el catálogo de ejemplo de 5 cursos) |
| `make test`     | Compila y corre las tres suites de pruebas                                         |
| `make valgrind` | Corre el programa y las pruebas bajo Valgrind                                      |
| `make clean`    | Borra lo generado                                                                  |

El ejecutable recibe tres rutas opcionales, a saber, el catálogo, el historial y la salida, tal que para las dos carreras se ejecuta de la siguiente manera.

```bash
./cemestre data/catalogo_computadores.csv data/historial_computadores.csv data/salida_computadores.json
./cemestre data/catalogo_fisica.csv       data/historial_fisica.csv       data/salida_fisica.json
```

Si algo falla, el programa explica el error por `stderr`, indica la línea y el curso cuando puede, y termina con un código de salida que corresponde al `ErrorCode` de `include/constants.h`.

| Código | Significado                                                                   |
| ------ | ----------------------------------------------------------------------------- |
| 0      | Todo bien                                                                     |
| 1      | No se pudo abrir el archivo                                                   |
| 2      | Formato inválido o dato inconsistente                                         |
| 3      | Datos incompletos (un requisito apunta a un curso que no está en el catálogo) |
| 4      | Falta de memoria                                                              |
| 5      | El historial menciona un curso que no está en el catálogo                     |
| 6      | Se superó un límite de tamaño                                                 |
| 7      | No se pudo escribir el archivo de salida                                      |

## 2. Documentación de diseño

### 2.1 Arquitectura del proyecto

El programa ejecuta cinco pasos en un orden fijo, que son cargar el catálogo, cargar el historial, detectar los choques de horario, validar la matrícula y exportar el resultado.

```
     catalogo.csv                    historial.csv
          │                               │
          ▼                               ▼
    catalog_load  ───────────────►  history_load
                                          │
                                          ▼
                              conflicts_detect_catalog
                                          │
                                          ▼
                              validation_mark_enrollable
                                          │
                                          ▼
                                export_catalog_json
                                          │
                                          ▼
                                     salida.json
```

El historial se valida contra el catálogo ya cargado, por lo que `catalog_load` precede a `history_load`. Cada paso vive en su propio módulo y los módulos se comunican únicamente mediante las estructuras de `structs.h`, tal que el cargador llena el `Catalog`, el módulo de choques escribe `has_conflict` en cada `Group`, el de validación escribe `can_enroll` en cada `Course` y el exportador solo lee. De este modo, cada módulo se puede modificar y probar por separado sin afectar a los demás.

| Archivo               | Responsabilidad                                                                                                        |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `include/constants.h` | Todas las constantes, como los límites, las rutas por defecto, los códigos de error y de día, y la versión del formato |
| `include/structs.h`   | Las estructuras `TimeBlock`, `Group`, `Course`, `Catalog`, `StudentHistory` y `LoadErrorInfo`                          |
| `src/utils.c`         | Utilidades de texto, como `trim_whitespace`, `safe_strcpy` y `split_fields`                                            |
| `src/catalog.c`       | Lee y valida el catálogo, que crece con `realloc` y se libera con `catalog_free`                                       |
| `src/history.c`       | Lee el historial y lo valida contra el catálogo                                                                        |
| `src/conflicts.c`     | Detecta choques de horario y marca `has_conflict` en cada grupo                                                        |
| `src/validation.c`    | Calcula `can_enroll` según prerrequisitos, correquisitos e historial                                                   |
| `src/export.c`        | Escribe el JSON de salida, escapando los caracteres especiales                                                         |
| `src/main.c`          | Une el flujo, lee los argumentos y traduce los errores a mensajes y códigos de salida                                  |

### 2.2 Decisiones de diseño

#### 2.2.1 Decisiones propias del dataset

Los datos se tomaron de la [Guía de Horarios del TEC](https://tec-appsext.itcr.ac.cr/guiahorarios/escuela.aspx), así como de las fichas del plan de estudios de cada carrera.

Cada carrera tiene su propio catálogo, pues el mismo código puede tener requisitos distintos en cada plan. `CS2101` (Ambiente Humano) no tiene requisitos en Computadores, pero en Física exige `CI1106` e `IF1101`. Asimismo, `FI1101` exige `MA1102` como prerrequisito en Computadores y como correquisito en Física, y también cabe destacar que `FI1102` pide `MA1102` como correquisito en Computadores y como prerrequisito en Física. Como el cargador exige códigos únicos, mezclar ambas carreras habría obligado a elegir una versión y a equivocarse en la otra.

Los créditos y los requisitos se tomaron del plan de estudios de cada carrera, y de la tabla de horarios recolectada únicamente los grupos. Los archivos originales quedan en `data/fuente/` como evidencia de la recolección.

El alcance de cada catálogo se definió de la siguiente manera.

| Curso                                        | Tratamiento                                                                                                                                                                                      |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `MA0101` (Computadores)                      | Se incluye, pues es requisito de `MA1102`.                                                                                                                                                       |
| `CI0200` y `CI0202` (Física)                 | Se incluyen, pues son requisitos de `CI1230`. `CI0200`, un examen diagnóstico, queda sin grupos y aparece como aprobado en el historial.                                                         |
| `SE1100`, `SE1200` y `SE1400` (Computadores) | Se incluyen según el plan, con 0 créditos y sin requisitos. Quedan sin grupos, pues la Guía ofrece estas actividades con otros códigos (`SE1102` Acción social, `SE1204` Natación, entre otros). |
| `CI0205`                                     | Se excluye, pues tiene 0 créditos, no tiene grupos en la Guía y ningún curso lo requiere.                                                                                                        |
| `FH1000`                                     | Se excluye, pues es bimestral y no encaja con el modelo semestral.                                                                                                                               |

`IF1101` no se ofreció este semestre, por lo que sus horarios se tomaron de otro periodo de la Guía y sus cuatro grupos se numeraron del 1 al 4 en el orden en que aparecen.

Los datos reales obligaron a ajustar los límites iniciales. `CI0200` demostró que un curso puede valer 0 créditos, por lo que la regla pasó a ser créditos mayores o iguales a 0, y `CI1107` (Comunicación Oral) tiene 32 grupos en Física, de manera que `MAX_GROUPS_PER_COURSE` subió de 20 a 40 y `MAX_LINE_LENGTH` de 2048 a 4096 bytes. Además, una línea que no cabe en el buffer ahora se rechaza con `ERROR_LIMIT_EXCEEDED` en lugar de leerse partida.

La Guía escribe los días en español (`LUN`, `MAR`, `MIE`...), pero el formato usa `MON`, `TUE`, `WED`, `THU`, `FRI` y `SAT`, los mismos del JSON, para que la Etapa 2 no dependa del idioma de la fuente. Los nombres de curso se escribieron sin tildes, así como los profesores se conservaron tal como los da la Guía, en mayúsculas.

Cada historial representa a un estudiante que aprobó los dos primeros semestres de su plan, así como los cursos previos que estos requieren (`MA0101` en Computadores, y `CI0200`, `CI0202` y `MA1102` en Física), lo que da 17 cursos en Computadores y 14 en Física. Con ellos quedan 8 cursos matriculables en Computadores (`CE2103`, `CS2101`, `EL2113`, `FI1102`, `FI1202`, `MA2104`, `MA2105` y `CI3203`) y 8 en Física.

#### 2.2.2 Un caso límite real, los correquisitos mutuos

El caso límite más importante apareció al correr el programa con los datos reales. `QU1102` (Laboratorio de Química Básica I) y `QU1106` (Química Básica I) se exigen mutuamente como correquisito, y lo natural es que se matriculen en el mismo semestre. La política inicial consideraba cumplido un correquisito solo si el curso ya estaba aprobado, de manera que dos cursos que se exigen entre sí nunca podían matricularse, pues cada uno esperaba al otro. Con el historial vacío, esa política dejaba 6 cursos matriculables en Física, mientras que la corrección deja 8. Las cadenas, como `FI1202`, que exige `FI1102`, el cual a su vez exige `MA1102` en Computadores, sufrían el mismo problema.

La solución fue cambiar la política, tal que un correquisito se considera cumplido si el curso ya está aprobado o si el estudiante podría matricularlo en el mismo periodo, es decir, si cumple sus propios prerrequisitos y, recursivamente, sus propios correquisitos. Para que la recursión termine con correquisitos mutuos, se marcan los cursos de la cadena actual y, al volver a uno ya visitado, se asume que se matriculan juntos (`validation_corequisites_ok`, en `src/validation.c`).

Esto tiene una consecuencia para la Etapa 2, pues `can_enroll = true` no garantiza que los correquisitos estén aprobados, sino que pueden llevarse juntos, de modo que al armar combinaciones se debe exigir que se elijan en el mismo horario, para lo cual el JSON incluye la lista `corequisites`. La Etapa 2 conserva esa lista y la incluye en su salida para que la Etapa 3 (Prolog) aplique la restricción; el generador no la impone porque el enunciado prohíbe restricciones distintas a los créditos. El caso real y su resolución se explican en 2.2.2 y en la decisión D8. El caso está cubierto en `tests/test_phase4.c` con cursos sintéticos, así como en `tests/test_export.c` con los datos reales, donde con historial vacío `QU1102` y `QU1106` son matriculables juntos, pero `FI1101` no, pues su correquisito `MA1102` necesita `MA0101`.

#### 2.2.3 Formato de salida

La salida es un archivo JSON. Un curso tiene varios grupos y cada grupo varios bloques horarios, una estructura anidada que en un CSV plano habría exigido inventar separadores dentro de las celdas y convertir el orden de las columnas en parte del contrato. En JSON cada dato se identifica por su nombre, Racket lo lee con la biblioteca `json` de su distribución estándar y C solo necesita escribirlo, lo cual resuelve un exportador propio que escapa comillas, barras y caracteres de control.

Un curso queda de la siguiente manera (ejemplo real de `CE2201`).

```json
{
  "code": "CE2201",
  "name": "Laboratorio de circuitos electricos",
  "credits": 1,
  "prerequisites": ["FI1202"],
  "corequisites": [],
  "groups": [
    {
      "number": 1,
      "professor": "ARAYA MARTINEZ LEONARDO",
      "blocks": [{ "day": "MON", "start": "09:30", "end": "11:20" }],
      "has_conflict": true
    }
  ],
  "has_conflict": true,
  "approved": false,
  "can_enroll": false
}
```

El archivo completo incluye además `format_version` y `course_count`. Los ocho campos que exige el enunciado son `code`, `name`, `credits`, `groups`, `prerequisites`, `corequisites`, `has_conflict` y `can_enroll`, y los demás detalles responden a decisiones del diseño.

| Campo                  | Justificación                                                                                                                                                                                                                       |
| ---------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `has_conflict` (grupo) | Los grupos de un mismo curso son alternativas y no se comparan entre sí. Un bloque que termina a las 10:00 no choca con otro que empieza a las 10:00.                                                                               |
| `has_conflict` (curso) | Es verdadero si algún grupo choca, como pide el enunciado. En los datos actuales lo tienen los 36 cursos con grupos (los otros 3 no tienen grupos); a nivel de grupo chocan 220 de 221 en Computadores y 308 de 308 en Física, por lo que la Etapa 2 usa el indicador por grupo y los bloques para recalcular los pares. |
| `approved`             | Distingue un curso ya aprobado de uno con requisitos faltantes, pues ambos dejan `can_enroll` en falso.                                                                                                                             |
| `can_enroll`           | Mide la elegibilidad curricular, independiente de los choques (los correquisitos se explican en 2.2.2).                                                                                                                             |
| `format_version`       | Protege el contrato con la Etapa 2, pues se sube `OUTPUT_FORMAT_VERSION` si el formato cambia de forma incompatible.                                                                                                                |

### 2.3 Estructuras de datos desarrolladas

Las estructuras se definen en `include/structs.h` y las constantes que fijan sus tamaños en `include/constants.h`.

| Estructura                           | Contenido                                                                                                                                           | Tamaño     |
| ------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| `Weekday` (enum)                     | `MONDAY` ... `SATURDAY`, en lugar de strings, para comparar horarios más rápido y sin errores de escritura                                          |            |
| `TimeBlock`                          | `day`, `start_hour`, `start_minute`, `end_hour`, `end_minute` (formato de 24 horas)                                                                 | 20 bytes   |
| `Group`                              | `group_number`, `professor`, hasta 3 `TimeBlock`, `block_count` y `has_conflict`                                                                    | 132 bytes  |
| `Course`                             | `code`, `name`, `credits`, arreglos de códigos de prerrequisitos y correquisitos con sus contadores, hasta 40 `Group`, `group_count` y `can_enroll` | 5492 bytes |
| `Catalog`                            | `courses` (arreglo dinámico de `Course`), `course_count` y `capacity`                                                                               | 16 bytes   |
| `StudentHistory`                     | Arreglo de hasta 60 códigos de cursos aprobados y `approved_count`                                                                                  | 604 bytes  |
| `LoadErrorInfo`                      | `line`, `course` y `related`, para indicar dónde falló la carga                                                                                     |            |
| `ErrorCode` (enum, en `constants.h`) | Valores de retorno de las funciones de carga y exportación                                                                                          |            |

Tres decisiones sustentan estas estructuras. Los requisitos y correquisitos se guardan como arreglos de códigos y no como punteros, de modo que un `Course` se copia por valor y el catálogo puede crecer con `realloc` sin invalidar referencias. Los textos y las listas pequeñas tienen tamaño fijo dentro de la estructura (por ejemplo, `char code[MAX_CODE_LENGTH]`), lo que evita reservar memoria por cada campo. Y el catálogo es el único dato en memoria dinámica, pues no se sabe de antemano cuántos cursos se cargarán, así que parte de una capacidad de 16, se duplica con `realloc` cuando se llena y tiene como tope 200 cursos, unos 1.1 MB en el peor caso.

Los demás límites (3 bloques por grupo, 6 prerrequisitos, 4 correquisitos, 60 cursos aprobados, códigos de hasta 9 caracteres y nombres de hasta 79 bytes) también están en `constants.h` y se suben si los datos reales los superan.

La detección de choques compara cada par de cursos distintos y, dentro de cada par, cada bloque con cada bloque. Dos bloques chocan si son del mismo día y cada uno empieza antes de que termine el otro, con las horas convertidas a minutos. Con unos 300 grupos son decenas de miles de comparaciones, es decir, instantáneo, y como la función reinicia `has_conflict` antes de calcular, es idempotente.

## 3. Formato de entrada

El catálogo tiene una línea por curso, con seis campos separados por punto y coma, en el orden siguiente.

```
codigo;nombre;creditos;prerrequisitos;correquisitos;grupos
```

Los prerrequisitos y correquisitos son códigos separados por `/`, o vacío si no hay. Los grupos se separan por `|` y cada uno tiene la forma `numero@profesor@bloques`, con los bloques separados por `+` y escritos como `DIA,HH:MM,HH:MM`. Un ejemplo real es la línea siguiente.

```
CE2201;Laboratorio de circuitos electricos;1;FI1202;;1@ARAYA MARTINEZ LEONARDO@MON,09:30,11:20
```

Las líneas vacías y las que empiezan con `#` se ignoran, y el archivo debe estar en UTF-8 sin BOM. Un grupo puede no tener horario (`1@Ana@`) y en ese caso nunca choca con nada. El cargador rechaza todo el catálogo, indicando línea y curso, en los siguientes casos.

- Una línea no tiene exactamente seis campos.
- Los créditos no son un entero mayor o igual a 0.
- El código o el nombre están vacíos o no caben en su límite.
- Un código de curso está repetido.
- Un curso es requisito o correquisito de sí mismo.
- Un número de grupo se repite dentro de un curso.
- Un bloque termina antes de empezar o tiene horas fuera de 00:00 a 23:59.
- El profesor está vacío o no cabe en su límite.
- Se supera un límite de cantidad o una línea no cabe en el buffer.
- Un requisito apunta a un curso que no está en el catálogo (se revisa al final de la carga, ya que puede definirse en una línea posterior).

El historial tiene un código de curso por línea. Cada código debe existir en el catálogo y no puede repetirse, con un máximo de 60, y un archivo vacío es válido y significa que el estudiante no ha aprobado nada.

## 4. Pruebas, errores y memoria

`make test` compila y ejecuta tres suites, y todas pasan.

| Suite                   | Pruebas | Qué cubre                                                                                                                    |
| ----------------------- | ------- | ---------------------------------------------------------------------------------------------------------------------------- |
| `tests/test_phase123.c` | 48      | Utilidades, carga del catálogo y del historial, validaciones del cargador, errores con línea y curso, y detección de choques |
| `tests/test_phase4.c`   | 35      | Prerrequisitos, correquisitos con matrícula simultánea, correquisitos mutuos y cadenas, idempotencia y cursos aprobados      |
| `tests/test_export.c`   | 73      | El exportador (escapes, formas límite, errores) y el flujo completo con los datos reales de las dos carreras                 |

Los archivos incorrectos a propósito están en `tests/data_invalid/` y los casos válidos límite en `tests/data_valid/`, de modo que cada regla del cargador tiene su archivo y su prueba. En cuanto a la memoria, todo `malloc` o `realloc` tiene su `free` en todos los caminos, incluidos los de error, y `make valgrind` no reporta fugas ni errores.

## 5. Referencias

Anthropic. (2026). *Claude* (versión Claude Opus 5.5) [Modelo de lenguaje de gran escala]. https://claude.ai

DeepSeek. (2026). *DeepSeek* (versión V4.1 Flash) [Modelo de lenguaje de gran escala]. https://www.deepseek.com

Kernighan, B. W., & Ritchie, D. M. (1988). *The C Programming Language* (2.ª ed.). Prentice Hall.

# Etapa 2: generación de combinaciones de horario en Racket

Instituto Tecnológico de Costa Rica, Escuela de Ingeniería en Computadores
Paradigmas de Programación (CE1106). Proyecto, Etapa 2 (paradigma funcional, lenguaje Racket)

Esta etapa implementa el módulo que recibe el catálogo procesado por la Etapa 1 en C y las preferencias del estudiante, genera las combinaciones de cursos y grupos sin choques de horario, las filtra por el rango de créditos y las exporta en JSON Lines para la Etapa 3 (Prolog). El módulo no arma el horario final, no optimiza, no sugiere combinaciones, no tiene interfaz y no aplica restricciones distintas a los créditos.

> Las secciones 2.1, 2.2.1, 2.2.2, 2.2.3 y 2.3 de este título documentan la Etapa 2. Las secciones 1 a 5 anteriores describen la Etapa 1 y se conservan como contrato de entrada.

## 2.1 Arquitectura del proyecto

El programa ejecuta un flujo de seis pasos, siempre en el mismo orden: leer el catálogo de C, leer las preferencias, cruzar ambas entradas para construir el universo, generar las combinaciones con streams, filtrar por créditos y escribir la salida. La figura siguiente muestra los archivos y los módulos que intervienen.

```
 data/salida_computadores.json ─┐
 data/salida_fisica.json ───────┴──► catalogo.rkt ──────► catalogo
                                                             │
 data/preferencias.json ───────────► preferencias.rkt ──► preferencias
                                                             │
                                                             ▼
                                                      universo.rkt
                                                             │
                                                             ▼
                                             universo (cursos + avisos)
                                                             │
                                                             ▼
                                                      generador.rkt
                                                             │
                                                             ▼
                                             stream de combinaciones
                                                             │
                                                             ▼
                                                      filtros.rkt
                                                             │
                                                             ▼
                                        stream filtrado por créditos
                                                             │
                                                             ▼
                                                     exportador.rkt
                                                             │
                                                             ▼
                                             data/combinaciones.jsonl
```

El catálogo y las preferencias se leen una sola vez. `universo.rkt` descarta los cursos aprobados, los que C no marcó como matriculables y los grupos que el estudiante no pidió; los problemas se acumulan como avisos y no detienen el programa. El generador recibe únicamente ese universo ya recortado, de modo que no vuelve a consultar el catálogo ni las preferencias. El filtro de créditos es una instancia del filtro polimórfico y el exportador consume el stream de a un elemento.

| Archivo | Responsabilidad |
| --- | --- |
| `racket/src/types.rkt` | Structs inmutables de la etapa: `bloque`, `grupo`, `curso`, `catalogo`, `interes`, `preferencias`, `par-curso-grupo` y `combinacion`, con sus contratos. |
| `racket/src/lectura.rkt` | Utilidades de lectura de JSON y construcción de errores controlados con el archivo y el campo donde falló. |
| `racket/src/catalogo.rkt` | Lee y valida las salidas JSON de C, convierte horas y bloques, une varias carreras y ofrece `cursos-habilitados` y `buscar-curso`. |
| `racket/src/preferencias.rkt` | Lee y valida `min_credits`, `max_credits` y la lista de cursos de interés con sus grupos. |
| `racket/src/universo.rkt` | Cruza catálogo y preferencias, recorta los grupos de interés y produce el struct `universo` con sus avisos. |
| `racket/src/choques.rkt` | Decide si dos bloques, dos grupos o un grupo contra una selección acumulada chocan. |
| `racket/src/generador.rkt` | Genera de forma recursiva y perezosa el stream de combinaciones no vacías, sin choques y con los créditos acumulados. |
| `racket/src/filtros.rkt` | Implementa el filtro polimórfico por rango inclusivo y su instancia para los créditos de una combinación. |
| `racket/src/exportador.rkt` | Serializa cada combinación como una línea JSON y la escribe mientras consume el stream. |
| `racket/src/constantes.rkt` | Centraliza las rutas por defecto de catálogos, preferencias y salida, resueltas desde la ubicación del código. |
| `racket/src/main.rkt` | Une el flujo, procesa los argumentos de la línea de comandos, muestra los avisos y traduce los errores a un código de salida distinto de cero. |

El flujo no usa estado global ni variables reasignadas. La selección de cursos, los créditos y los avisos viajan como parámetros de la recursión o como campos de structs nuevos. Las únicas operaciones con efectos son la lectura de archivos en `lectura.rkt` y la escritura de la salida en `exportador.rkt`; el resto de los módulos son funciones puras.

## 2.2 Decisiones de diseño

### 2.2.1 Decisiones propias y específicas

#### D1: qué es una combinación

Una combinación es un subconjunto **no vacío** de los cursos habilitados del universo. Para cada curso elegido se toma exactamente un grupo de interés que exista en el catálogo y que no choque con los grupos ya elegidos. Los cursos que no se eligen simplemente se omiten; la combinación vacía se excluye.

La decisión se apoya en el enunciado, que pide “un grupo por cada curso habilitado” y, al mismo tiempo, filtrar por créditos. Si todos los cursos fueran obligatorios, el total de créditos sería fijo y el filtro no tendría sentido. También refleja la matrícula real: el estudiante decide qué cursos llevar y puede comparar escenarios con menos cursos. El comportamiento se controla con la constante `OMITIR-CURSOS?` de `generador.rkt`, hoy en `#t`; si el profesor confirma la otra interpretación, basta cambiarla a `#f` y la rama de omisión devuelve `empty-stream`, sin tocar los demás módulos.

Con los datos reales, `data/preferencias.json` pide ocho cursos de Computadores y Física en un rango de 12 a 18 créditos. El programa produce 762 combinaciones, con 3, 4, 5 o 6 cursos y créditos entre 12 y 18; ninguna incluye los ocho cursos y ninguna está vacía. Esa variedad es precisamente la que permite que el filtro de créditos tenga efecto.

#### D2: contratos en lugar de Typed Racket

Se usan structs inmutables y contratos de Racket (`contract-out`) en las fronteras de cada módulo, no Typed Racket. Los contratos documentan la interfaz y atrapan datos mal formados en la lectura del JSON, en el universo, en el generador y en el filtro, sin obligar a anotar cada función recursiva. También permiten que el filtro acepte cualquier tipo de elemento con `(stream/c any/c)` y que el criterio `en-rango` sea paramétrico con `parametric->/c`, sin introducir `Any` ni `cast` de Typed Racket. La decisión es uniforme en todos los módulos y se verifica con `raco make` y con la auditoría de `racket/src/`.

#### D5: choque en el borde

Dos bloques del mismo día chocan si cada uno empieza **antes** de que termine el otro. La comparación es `<` estricta en ambos sentidos. Si un bloque termina a las 10:00 y otro empieza a las 10:00, no chocan; los días distintos nunca chocan y un grupo sin bloques tampoco. Es exactamente la regla de `src/conflicts.c` de la Etapa 1, de modo que ambas etapas interpretan igual los horarios.

Un caso real de choque es `MA0101` grupo 1, miércoles de 15:00 a 17:50, contra `MA1102` grupo 12, miércoles de 15:00 a 17:50: los bloques son idénticos y el generador no los combina. El borde se prueba con el caso sintético `S1-1` contra `S2-2`, que se tocan a las 10:00 y sí producen una combinación conjunta; la prueba está en `test-choques.rkt` y `test-generador.rkt`. En los catálogos reales no se encontró un par de grupos distintos que termine exactamente cuando empieza otro, por eso el borde se cubre con datos construidos a mano y no con una coincidencia accidental de los datos.

#### D6: fuente de los choques

Racket recalcula los choques a partir de los bloques con `choques.rkt`; la bandera `has_conflict` que escribe C se conserva en el campo `choque` del grupo y se usa solo como referencia de consistencia. Racket necesita comparar un grupo candidato contra una selección parcial, incluso cuando el catálogo completo ya no está disponible en esa rama, y recalcular desde los bloques hace que el generador sea independiente de la implementación de C.

La prueba `test-choques.rkt` lee las salidas reales de las dos carreras y compara, grupo por grupo, el cálculo de Racket con la bandera de C: 221 grupos en Computadores y 308 en Física, sin diferencias. El lector de catálogo también rechaza un archivo en el que `has_conflict` del curso no coincida con la bandera de alguno de sus grupos.

#### Streams y generación recursiva

El generador no construye la lista completa de combinaciones. Para cada curso abre dos ramas: omitirlo o elegir uno de sus grupos compatibles. La rama de omisión se emite primero y cada rama se envuelve en `stream-lazy`, porque `stream-append` evalúa sus argumentos antes de construir el stream; sin esa precaución, el árbol de llamadas se expandía completo antes de devolver el primer resultado. La selección se guarda al revés y se invierte al emitir para conservar el orden del universo; los créditos se acumulan con `(+ creditos (curso-creditos curso))` en la misma llamada recursiva. No hay `set!`, `hash-set!`, `vector-set!`, `set-box!`, `#:mutable` ni `list->stream` en `racket/src/`.

La pereza se demuestra con 60 cursos de un grupo cada uno: hay 2^60 − 1 combinaciones no vacías y pedir solo la primera devuelve `C59-1 | 1` de inmediato. En el universo real de las dos carreras, con todos los cursos habilitados y todos sus grupos, el número de combinaciones posibles es del orden de 3.5 × 10^14; `test-casos-limite.rkt` pide las primeras 100 y termina sin materializar el resto. El flujo principal aprovecha la misma propiedad: el filtro y el exportador consumen el stream de a un elemento.

#### Correquisitos y alcance de la etapa

C marca un curso como matriculable si su correquisito está aprobado o si también se podría matricular en el mismo periodo. Por eso `can_enroll = true` no garantiza que los correquisitos estén aprobados. La Etapa 2 conserva la lista `corequisites` en el struct del curso y la incluye en la salida, pero no la usa como restricción del generador: el enunciado prohíbe aplicar restricciones distintas a los créditos y esa regla corresponde a Prolog. El caso real y su justificación se explican en 2.2.2 y en la decisión D8 de `racket/docs/decisiones.md`.

### 2.2.2 Un caso límite real y cómo se resolvió

#### Correquisitos que no se imponen en esta etapa

El caso más delicado apareció con los correquisitos reales de Computadores. `FI1202` (Laboratorio de Física General II) tiene como correquisito `FI1102` (Física General II), y `FI1102` tiene a su vez como correquisito `MA1102`. C marca `FI1202` como matriculable porque `FI1102` se puede llevar en el mismo periodo, no porque ya esté aprobado. La Etapa 2, por diseño, no impone esa relación: el enunciado pide generar combinaciones sin choques y filtrar por créditos, y prohíbe aplicar restricciones distintas a los créditos. Por eso el generador puede producir una combinación con `FI1202` sin `FI1102`.

El caso se observa en la salida real. La combinación con `id = 13` contiene `FI1202` grupo 2, `MA2104` grupo 1, `MA1103` grupo 1 y `FI2103` grupo 1, pero no contiene `FI1102`; la línea incluye `"corequisites":["FI1102"]` dentro del curso. La combinación con `id = 52` sí contiene `FI1102` grupo 1 y `FI1202` grupo 2, además de otros tres cursos. Ambas son válidas para esta etapa porque no tienen choques y suman créditos dentro del rango; la diferencia es que la primera no cumple la regla de correquisitos que le corresponde a Prolog.

La solución no fue agregar una restricción al generador, sino dejar el dato disponible y documentar la frontera entre etapas (decisión D8). El exportador incluye `corequisites` en cada curso, de modo que la Etapa 3 puede exigir que los correquisitos se elijan juntos sin volver a abrir el catálogo de C. El mismo criterio cubre el caso de `QU1102` y `QU1106` en Física, que se exigen mutuamente como correquisito, y el de `FI1102` en Computadores, que exige `MA1102` como correquisito. Si el profesor pidiera que la restricción se aplicara ya en esta etapa, el cambio quedaría localizado en el generador y en el universo, no en el formato de salida.

#### El mismo código en dos carreras

Otro caso real es la identidad de un curso. Doce códigos aparecen en las dos carreras, pero no siempre significan lo mismo: `FI1102` exige `FI1101` en Computadores y `FI1101` más `MA1102` en Física; `CS2101` no tiene requisitos en Computadores y exige `CI1106` e `IF1101` en Física. Por eso un curso se identifica con la pareja `(carrera, código)` y no solo con el código. `leer-catalogo` acepta el mismo código en carreras distintas, pero rechaza la pareja repetida; `buscar-curso` recibe carrera y código; y el archivo de preferencias también incluye `career`. Sin esta decisión, mezclar las dos carreras habría obligado a elegir una versión de los requisitos y a equivocarse en la otra.

### 2.2.3 Formato de salida

La salida es `data/combinaciones.jsonl`, en formato JSON Lines: un objeto JSON independiente por línea y una línea por combinación. No hay encabezado, pie ni arreglo global; si ninguna combinación cumple el rango de créditos, el archivo queda vacío. El contrato completo, con el tipo de cada campo, está en `racket/docs/formato_salida.md`.

Un ejemplo real es la combinación `id = 13`, que también sirve para ilustrar el caso de los correquisitos.

```json
{"course_count":4,"courses":[{"blocks":[{"day":"TUE","end":"14:50","start":"13:00"}],"career":"computadores","code":"FI1202","corequisites":["FI1102"],"credits":1,"group":2,"name":"Laboratorio fisica general II"},{"blocks":[{"day":"TUE","end":"19:50","start":"18:00"},{"day":"THU","end":"19:50","start":"18:00"}],"career":"computadores","code":"MA2104","corequisites":[],"credits":4,"group":1,"name":"Calculo superior"},{"blocks":[{"day":"WED","end":"09:20","start":"07:30"},{"day":"FRI","end":"09:20","start":"07:30"}],"career":"fisica","code":"MA1103","corequisites":[],"credits":4,"group":1,"name":"Calculo y algebra lineal"},{"blocks":[{"day":"TUE","end":"16:50","start":"15:00"},{"day":"THU","end":"16:50","start":"15:00"}],"career":"fisica","code":"FI2103","corequisites":[],"credits":3,"group":1,"name":"Fisica general III"}],"id":13,"total_credits":12}
```

| Campo | Tipo | Obligatorio | Justificación |
| --- | --- | --- | --- |
| `id` | entero positivo | extra | Permite que Prolog y la Etapa 4 se refieran a una combinación concreta sin depender de su posición en el archivo. |
| `total_credits` | entero no negativo | sí | Es la suma de los créditos de los cursos elegidos; el filtro de la Etapa 2 ya la usó para aceptar la combinación. |
| `course_count` | entero positivo | extra | Permite aplicar restricciones por cantidad de cursos sin recorrer la lista. |
| `courses` | lista no vacía | sí | Contiene los pares curso-grupo seleccionados. |
| `career` | `"computadores"` o `"fisica"` | sí | Identifica la carrera de origen del curso y evita confundir códigos repetidos entre carreras. |
| `code` | texto | sí | Código del curso. |
| `group` | entero positivo | sí | Número del grupo elegido. |
| `name` | texto | extra | La Etapa 4 lo muestra al usuario sin volver al catálogo. |
| `credits` | entero no negativo | extra | Prolog puede recalcular o comparar créditos por curso. |
| `corequisites` | lista de códigos | extra | Es la información que Prolog necesita para aplicar la regla de correquisitos (D8). |
| `blocks` | lista de bloques | extra | Prolog revisa compatibilidades de horario sin abrir el catálogo; cada bloque trae `day`, `start` y `end` en `HH:MM`. |

La elección de JSON Lines responde a una decisión de diseño concreta, no solo estética. El exportador consume el stream de combinaciones de a un elemento y escribe cada línea en el momento en que la recibe; no necesita saber cuál es la última combinación, no acumula comas y no tiene que materializar la lista completa para cerrar un arreglo. Si el proceso se interrumpe, las líneas anteriores siguen siendo objetos JSON válidos. Cada línea es autocontenida, de modo que Prolog puede leerla y convertirla en un hecho sin conservar el estado de un documento mayor. Las estructuras anidadas (varios cursos, varios bloques por grupo y listas de correquisitos) se conservan; un CSV plano habría exigido inventar separadores dentro de las celdas y convertir el orden de las columnas en parte del contrato.

La salida garantiza que ninguna combinación tiene choques entre sus grupos, que `total_credits` está en el rango inclusivo de las preferencias, que un curso `(career, code)` aparece una sola vez por combinación y que todos los cursos estaban marcados como matriculables por C. El archivo de la Etapa 1 sigue siendo un JSON normal con `format_version` y `course_count`; la salida de la Etapa 2 no modifica ese contrato de entrada.

## 2.3 Estructuras de datos desarrolladas

Los tipos están en `racket/src/types.rkt` y el struct `universo` en `racket/src/universo.rkt`. Todos son structs de Racket sin campos mutables, con `#:transparent` para poder compararlos con `equal?` e imprimirlos en las pruebas. Las funciones públicas se exportan con `contract-out`.

```
catalogo
  └── cursos: (listof curso)
        ├── carrera, codigo, nombre, creditos
        ├── prerrequisitos, correquisitos
        ├── aprobado, matriculable
        └── grupos: (listof grupo)
              ├── numero, profesor, choque
              └── bloques: (listof bloque)
                    ├── dia
                    ├── inicio
                    └── fin

preferencias
  ├── creditos-min, creditos-max
  └── intereses: (listof interes)
        ├── carrera, codigo
        └── grupos: (non-empty-listof exact-positive-integer)

universo
  ├── cursos: (listof curso)   ; copias recortadas del catálogo
  └── avisos: (listof string)

combinacion
  ├── pares: (non-empty-listof par-curso-grupo)
  │     ├── curso
  │     └── grupo
  └── creditos
```

| Estructura | Campos principales | Propósito e invariantes |
| --- | --- | --- |
| `bloque` | `dia`, `inicio`, `fin` | Día de la clase y minutos desde las 00:00. El día es `MON` a `SAT`; las horas están entre 0 y 1439 y el lector exige `fin > inicio`. |
| `grupo` | `numero`, `profesor`, `bloques`, `choque` | Oferta de un curso. `numero` es positivo y no se repite dentro del curso; `bloques` puede ser vacío y entonces el grupo nunca choca; `choque` es la bandera de C y se usa solo para la prueba de consistencia. |
| `curso` | `carrera`, `codigo`, `nombre`, `creditos`, `prerrequisitos`, `correquisitos`, `grupos`, `aprobado`, `matriculable` | Curso del catálogo. La pareja `(carrera, codigo)` es su identidad; `creditos` puede ser 0; `grupos` puede ser vacío; `aprobado` y `matriculable` son banderas independientes. |
| `catalogo` | `cursos` | Agrupa los cursos de una o varias carreras ya leídos. El lector exige al menos un archivo y no permite repetir la pareja `(carrera, codigo)`. |
| `interes` | `carrera`, `codigo`, `grupos` | Curso que el estudiante quiere llevar y los números de grupo que acepta. La lista de grupos no está vacía y sus elementos son positivos; el lector exige que no se repitan. |
| `preferencias` | `intereses`, `creditos-min`, `creditos-max` | Entrada del estudiante. Los créditos no son negativos y el lector exige `creditos-min <= creditos-max`; `intereses` puede estar vacío. |
| `par-curso-grupo` | `curso`, `grupo` | Un curso con el grupo elegido. Es la unidad de una combinación y guarda los structs completos para que el exportador no dependa de un catálogo global. |
| `combinacion` | `pares`, `creditos` | Matrícula candidata. `pares` nunca está vacío, los grupos son compatibles entre sí y `creditos` es la suma de los créditos de los cursos elegidos. |
| `universo` | `cursos`, `avisos` | Resultado del cruce entre catálogo y preferencias. Solo contiene cursos no aprobados, matriculables y con al menos un grupo solicitado que existe; los avisos son textos legibles para el usuario. |

Tres invariantes sostienen el resto del diseño. Primero, la identidad `(carrera, código)` permite que el mismo código exista en dos carreras con requisitos distintos sin mezclarse. Segundo, el universo se construye con `struct-copy` sobre el curso original, así que recortar los grupos no modifica el catálogo y una misma combinación puede compartir cursos y grupos sin efectos laterales. Tercero, la combinación guarda los pares completos y no índices, de modo que el exportador conoce carrera, nombre, créditos, correquisitos y bloques sin volver a buscar en el catálogo.

La generación acumula estado como parámetros de la recursión: `pendientes` es la lista de cursos que faltan, `seleccion` es la lista inversa de pares ya elegidos y `creditos` es la suma acumulada. Al llegar al final se invierte la selección, se construye la combinación y se emite en el stream. Ningún paso modifica un struct ya construido: se crean valores nuevos con los constructores o con `struct-copy`.

## 2.4 Uso, pruebas y estructura del repositorio

El proyecto completo se compila y se prueba en Linux. La Etapa 2 requiere Racket 9.3 o una versión compatible con `racket/stream`, `json` y `rackunit`; no necesita paquetes externos. La Etapa 1 requiere `gcc`, `make` y, para la revisión de memoria, `valgrind`.

### 2.4.1 Ejecución

Desde la raíz del repositorio, el programa usa por defecto `data/preferencias.json`, `data/salida_computadores.json`, `data/salida_fisica.json` y escribe `data/combinaciones.jsonl`:

```bash
racket racket/src/main.rkt
```

También se pueden indicar las rutas en el orden preferencias, salida y uno o más catálogos:

```bash
racket racket/src/main.rkt data/preferencias.json data/combinaciones.jsonl \
    data/salida_computadores.json data/salida_fisica.json
```

Las rutas por defecto se resuelven desde la ubicación de `constantes.rkt`, así que el programa funciona aunque se ejecute desde otra carpeta. Si faltan argumentos o el número no es válido, muestra el uso y termina con código 1. Los errores de lectura y de escritura se informan por `stderr` con un mensaje que incluye el archivo o el campo problemático, y el programa termina con código 1; un error de datos nunca se convierte en una traza interna sin explicación.

La salida del ejemplo real tiene 762 líneas. Para inspeccionarla:

```bash
wc -l data/combinaciones.jsonl
head -1 data/combinaciones.jsonl
```

### 2.4.2 Pruebas de Racket

```bash
raco test racket/tests
raco make racket/src/*.rkt
```

La suite completa tiene 65 pruebas y todas pasan. Las suites se reparten así.

| Suite | Pruebas | Qué cubre |
| --- | ---: | --- |
| `test-catalogo.rkt` | 6 | Catálogo válido, archivo vacío e inexistente, carrera inválida, conteo, código repetido, mismo código en dos carreras, grupo repetido, campo faltante, auto-requisito, choque incoherente, versión y JSON malformado. |
| `test-preferencias.rkt` | 4 | Preferencias válidas, archivo vacío e inexistente, JSON malformado, créditos negativos, rango imposible, carrera inválida, código vacío, grupos vacíos, no positivos y repetidos, `courses` que no es lista y campo faltante. |
| `test-universo.rkt` | 6 | Universo vacío, orden de preferencias, avisos de cursos no habilitados, aprobados, inexistentes, repetidos y grupos inexistentes; no modificación del catálogo. |
| `test-choques.rkt` | 5 | Horario idéntico, traslape parcial, bloque contenido, borde, días distintos, grupos con varios bloques, grupos vacíos y consistencia con las banderas de C. |
| `test-generador.rkt` | 14 | Oráculos manuales, combinación vacía, omisión de cursos, un curso con uno o varios grupos, choques, borde, créditos acumulados y pereza con 60 cursos. |
| `test-filtros.rkt` | 9 | Límites inclusivos con enteros, cadenas y combinaciones, segundo extractor, rango sin resultados, mínimo mayor que máximo, pereza y el criterio paramétrico. |
| `test-streams.rkt` | 3 | `stream-cons` y `stream-append` difieren la cola, y el generador no usa `list->stream` ni `stream->list`. |
| `test-exportador.rkt` | 6 | Formato `HH:MM`, campos obligatorios, ida y vuelta, coherencia de créditos y cantidad, primera línea y archivo vacío. |
| `test-main.rkt` | 4 | Flujo completo con el catálogo sintético, avisos, rango sin resultados y archivo de entrada inexistente. |
| `test-casos-limite.rkt` | 3 | Mínimo igual a máximo, un solo curso y universo grande con las primeras 100 combinaciones. |
| `test-validar-salida.rkt` | 5 | Validación de la salida real contra el catálogo de C: campos, créditos, rango, choques, cursos matriculables y unicidad. |

### 2.4.3 Pruebas de la Etapa 1 y regresión

```bash
make clean
make
make test
bash tests/regression_etapa1.sh origin/main
```

Las tres suites de C pasan con 48/48, 35/35 y 73/73 pruebas. La regresión confirma que la salida de C es idéntica a la de `origin/main` salvo por el campo `career`, que es el cambio propio de la Etapa 2. El detalle de la validación final está en `racket/docs/revision_final.md` y la auditoría de mutación y tipos en `racket/docs/auditoria_fase_5.md`.

### 2.4.4 Estructura del repositorio

```
.
├── data/                     datos compartidos, fuentes, salidas de C y combinaciones.jsonl
├── include/                  cabeceras de la Etapa 1 en C
├── src/                      código de la Etapa 1 en C
├── tests/                    pruebas y datos de la Etapa 1
├── racket/
│   ├── src/                  módulos funcionales de la Etapa 2
│   ├── tests/                suites de Racket, fixtures y oráculos manuales
│   └── docs/                 decisiones, contratos, auditorías, guía de defensa y revisión final
├── Makefile                  compilación y pruebas de C
├── README.md                 documentación de las dos etapas
└── planDocTest.md            plan de trabajo de la Etapa 2
```

El archivo `data/preferencias.json` mezcla cursos de Computadores y Física para ejercitar los dos catálogos. El programa no impone una carrera de estudiante porque el enunciado no la pide; la carrera se conserva por curso para que la salida siga siendo inequívoca.

## Referencias de la Etapa 2

Racket. (2026). *The Racket Reference* (versión 9.3). https://docs.racket-lang.org/reference/

Racket. (2026). *Streams*. https://docs.racket-lang.org/reference/streams.html

Racket. (2026). *Contracts*. https://docs.racket-lang.org/reference/contracts.html

Racket. (2026). *JSON*. https://docs.racket-lang.org/reference/json.html

Racket. (2026). *RackUnit*. https://docs.racket-lang.org/rackunit/
