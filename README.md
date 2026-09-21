# CEmestre: constructor de horarios

Instituto Tecnológico de Costa Rica, Escuela de Ingeniería en Computadores
Paradigmas de Programación (CE1106). Proyecto, Etapa 1 (paradigma imperativo, lenguaje C)

| Integrante                      | Carné      |
| ------------------------------- | ---------- |
| Paulo Andrés Centeno Flores     | 2025119739 |
| Máyerlin Dilana Gamboa González | 2025096295 |
| David Jafeth Obando Blanco      | 2024157494 |

CEmestre es una herramienta de apoyo a la matrícula universitaria, pues a partir del plan de estudios de una carrera y de los cursos que un estudiante ya aprobó determina qué cursos puede matricular y cuáles presentan choques de horario, como base para construir un horario de matrícula válido. El sistema completo se desarrolla en cuatro etapas, una por paradigma (C, Racket, Prolog y Java), y cada etapa corresponde a un programa independiente que lee y escribe archivos.

Esta primera etapa, escrita en C bajo el paradigma imperativo, carga el catálogo de cursos y el historial del estudiante, detecta los choques de horario, valida los requisitos y exporta el resultado en un archivo JSON, que sirve de insumo a la Etapa 2 (Racket). El módulo no genera combinaciones de horario ni ofrece interfaz, pues esas tareas corresponden a etapas posteriores. Se trabajó con Ingeniería en Computadores y con Física, cada una con su propio catálogo e historial y limitadas a los cuatro primeros semestres de su plan.

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

Cada historial representa a un estudiante que aprobó los dos primeros semestres de su plan, así como los cursos previos que estos requieren (`MA0101` en Computadores, y `CI0200`, `CI0202` y `MA1102` en Física), lo que da 17 cursos en Computadores y 14 en Física. Con ellos quedan 6 cursos matriculables en Computadores (`CE2103`, `CS2101`, `EL2113`, `FI1102`, `FI1202` y `MA2104`) y 8 en Física.

#### 2.2.2 Un caso límite real, los correquisitos mutuos

El caso límite más importante apareció al correr el programa con los datos reales. `QU1102` (Laboratorio de Química Básica I) y `QU1106` (Química Básica I) se exigen mutuamente como correquisito, y lo natural es que se matriculen en el mismo semestre. La política inicial consideraba cumplido un correquisito solo si el curso ya estaba aprobado, de manera que dos cursos que se exigen entre sí nunca podían matricularse, pues cada uno esperaba al otro. Con el historial vacío, esa política dejaba 6 cursos matriculables en Física, mientras que la corrección deja 8. Las cadenas, como `FI1202`, que exige `FI1102`, el cual a su vez exige `MA1102` en Computadores, sufrían el mismo problema.

La solución fue cambiar la política, tal que un correquisito se considera cumplido si el curso ya está aprobado o si el estudiante podría matricularlo en el mismo periodo, es decir, si cumple sus propios prerrequisitos y, recursivamente, sus propios correquisitos. Para que la recursión termine con correquisitos mutuos, se marcan los cursos de la cadena actual y, al volver a uno ya visitado, se asume que se matriculan juntos (`validation_corequisites_ok`, en `src/validation.c`).

Esto tiene una consecuencia para la Etapa 2, pues `can_enroll = true` no garantiza que los correquisitos estén aprobados, sino que pueden llevarse juntos, de modo que al armar combinaciones se debe exigir que se elijan en el mismo horario, para lo cual el JSON incluye la lista `corequisites`. El caso está cubierto en `tests/test_phase4.c` con cursos sintéticos, así como en `tests/test_export.c` con los datos reales, donde con historial vacío `QU1102` y `QU1106` son matriculables juntos, pero `FI1101` no, pues su correquisito `MA1102` necesita `MA0101`.

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
| `has_conflict` (curso) | Es verdadero si algún grupo choca, como pide el enunciado. Casi siempre lo es (196 de 197 grupos en Computadores y 285 de 285 en Física), por lo que la Etapa 2 usa el indicador por grupo y los bloques para recalcular los pares. |
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
