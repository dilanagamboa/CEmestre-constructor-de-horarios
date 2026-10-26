# Estructuras de datos de Racket

Los tipos de la Etapa 2 están en `racket/src/types.rkt`. Todos son structs de Racket sin campos mutables y con `#:transparent`, lo que permite compararlos con `equal?` e imprimirlos en las pruebas. Las funciones públicas se exportan con `contract-out`.

El objetivo de esta representación es conservar la información del JSON de C, mantener la identidad `(carrera, código)` y permitir que el generador acumule una selección sin modificar los datos originales.

## 1. Mapa de estructuras

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

## 2. `bloque`

```racket
(struct bloque ([dia dia/c] [inicio minuto/c] [fin minuto/c]))
```

| Campo | Contrato | Propósito |
| --- | --- | --- |
| `dia` | `'MON`, `'TUE`, `'WED`, `'THU`, `'FRI` o `'SAT` | Día de la clase. |
| `inicio` | entero entre 0 y 1439 | Minutos desde las 00:00. |
| `fin` | entero entre 0 y 1439 | Minutos desde las 00:00. |

Invariantes:

- El día debe ser uno de los seis códigos del JSON.
- Las horas deben estar dentro del día.
- El lector de catálogo exige `fin > inicio`; el constructor directo no lo impone, así que las pruebas y el código deben respetarlo.
- Un bloque no tiene identidad propia: pertenece a un grupo.

El bloque se usa en `choques.rkt` para comparar horarios y en el futuro exportador para describir el horario de una combinación.

## 3. `grupo`

```racket
(struct grupo ([numero exact-positive-integer?]
               [profesor string?]
               [bloques (listof bloque?)]
               [choque boolean?]))
```

| Campo | Contrato | Propósito |
| --- | --- | --- |
| `numero` | entero positivo | Número de grupo dentro del curso. |
| `profesor` | texto | Profesor del grupo. |
| `bloques` | lista de bloques | Horario del grupo; puede ser vacía. |
| `choque` | booleano | Bandera `has_conflict` de C para ese grupo. |

Invariantes:

- `numero` no se repite dentro del mismo curso; lo valida `catalogo.rkt`.
- `bloques` puede ser `[]`; en ese caso `grupos-chocan?` siempre devuelve `#f`.
- `choque` es una referencia de C, no la fuente de verdad del generador.

Los grupos de un mismo curso son alternativas: el generador elige como máximo uno. Por eso `choques.rkt` nunca compara dos grupos del mismo curso entre sí.

## 4. `curso`

```racket
(struct curso ([carrera carrera/c]
               [codigo non-empty-string?]
               [nombre non-empty-string?]
               [creditos exact-nonnegative-integer?]
               [prerrequisitos (listof non-empty-string?)]
               [correquisitos (listof non-empty-string?)]
               [grupos (listof grupo?)]
               [aprobado boolean?]
               [matriculable boolean?]))
```

| Campo | Contrato | Propósito |
| --- | --- | --- |
| `carrera` | `'computadores` o `'fisica` | Carrera que aporta el curso. |
| `codigo` | texto no vacío | Código del curso. |
| `nombre` | texto no vacío | Nombre del curso. |
| `creditos` | entero no negativo | Créditos. Puede ser 0. |
| `prerrequisitos` | lista de códigos | Códigos de prerrequisitos, sin repetir la validación de existencia aquí. |
| `correquisitos` | lista de códigos | Códigos de correquisitos. |
| `grupos` | lista de grupos | Ofertas del curso; puede ser vacía. |
| `aprobado` | booleano | El estudiante ya lo aprobó. |
| `matriculable` | booleano | C puede matricularlo según requisitos. |

Invariantes:

- La pareja `(carrera, codigo)` identifica el curso; `leer-catalogo` no permite repetirla.
- `creditos` no es negativo.
- `grupos` puede ser vacío; el universo y el generador lo manejan.
- `aprobado` y `matriculable` son banderas independientes: un curso aprobado puede tener `matriculable = false`.
- El curso no se modifica durante el universo: `struct-copy` crea una copia con menos grupos.

El curso completo viaja dentro de cada `par-curso-grupo`, de modo que una combinación no necesita un catálogo global para conocer créditos, carrera o nombre.

## 5. `catalogo`

```racket
(struct catalogo ([cursos (listof curso?)]))
```

Propósito: agrupar los cursos de una o varias carreras ya leídos. `leer-catalogo` acepta una lista no vacía de rutas y une los archivos. La estructura no impone por sí sola la unicidad de `(carrera, codigo)`; esa regla la aplica el lector antes de construir el catálogo.

Invariantes:

- Todos los elementos son `curso?`.
- La lista puede estar vacía solo si se construye directamente; el lector exige al menos un archivo.
- No se modifica después de construirse.

## 6. `interes`

```racket
(struct interes ([carrera carrera/c]
                 [codigo non-empty-string?]
                 [grupos (non-empty-listof exact-positive-integer?)]))
```

Representa un curso que el estudiante quiere llevar y los grupos que acepta. Los grupos son números, no structs `grupo`, porque en el archivo de preferencias el estudiante todavía no conoce los profesores ni los horarios.

Invariantes:

- La lista de grupos no está vacía.
- Los números son positivos.
- El lector de preferencias exige que no se repitan; el contrato del struct no lo impone, pero `leer-preferencias` lo valida.
- La carrera y el código identifican el curso junto con el catálogo.

## 7. `preferencias`

```racket
(struct preferencias ([intereses (listof interes?)]
                      [creditos-min exact-nonnegative-integer?]
                      [creditos-max exact-nonnegative-integer?]))
```

Invariantes:

- `creditos-min` y `creditos-max` no son negativos.
- `leer-preferencias` exige `creditos-min <= creditos-max`.
- `intereses` puede estar vacío; en ese caso el universo no tiene cursos.
- El lector permite cursos repetidos; el universo decide quedarse con la primera aparición.

## 8. `par-curso-grupo`

```racket
(struct par-curso-grupo ([curso curso?] [grupo grupo?]))
```

Propósito: unir un curso con el grupo elegido. Es la unidad de una combinación y la unidad que `choques.rkt` recorre para comprobar compatibilidad.

Invariantes:

- El grupo debe pertenecer al curso; el generador lo garantiza porque recorre `(curso-grupos curso)`.
- El par guarda los structs completos, no índices, para que el exportador tenga toda la información.

## 9. `combinacion`

```racket
(struct combinacion ([pares (non-empty-listof par-curso-grupo?)]
                     [creditos exact-nonnegative-integer?]))
```

Propósito: representar una matrícula válida candidata.

Invariantes:

- `pares` nunca está vacío: la combinación vacía se excluye en el generador.
- `creditos` es la suma de los créditos de los cursos de `pares`; el generador la acumula y las pruebas la verifican.
- Los pares conservan el orden del universo, no el orden inverso en que se acumularon.
- No hay dos pares del mismo curso; el generador procesa cada curso una sola vez.
- Los grupos de los pares son compatibles entre sí; el generador solo agrega un grupo si `grupo-compatible?` devuelve `#t`.

## 10. `universo`

`universo` está definido en `racket/src/universo.rkt`, no en `types.rkt`, porque es el resultado del cruce entre catálogo y preferencias:

```racket
(struct universo ([cursos (listof curso?)] [avisos (listof string?)]))
```

Invariantes:

- `cursos` solo contiene cursos no aprobados, matriculables y con al menos un grupo solicitado que existe.
- Cada curso de `cursos` es una copia con `grupos` recortado; el catálogo original no cambia.
- `avisos` contiene textos legibles para el usuario, en el orden en que se detectaron.
- El orden de `cursos` es el orden de las preferencias.
- El orden de `grupos` dentro de cada curso es el orden del catálogo.

## 11. Por qué son inmutables

- El generador necesita compartir cursos y grupos entre muchas combinaciones; la inmutabilidad evita que una rama altere los datos de otra.
- Las pruebas pueden comparar structs con `equal?` y reutilizar el mismo catálogo sin miedo a efectos laterales.
- El filtro y el futuro exportador pueden recorrer un stream varias veces sin que cambie el contenido.
- La ausencia de `set!`, campos mutables y variables reasignadas es un requisito explícito del plan y se audita en `racket/docs/auditoria_fases_0_3.md`.
- La recursión acumula selección y créditos como parámetros; no necesita estado global.

## 12. Relación con la generación

1. `catalogo.rkt` construye `catalogo` con `curso`s completos.
2. `preferencias.rkt` construye `preferencias` con `interes`es.
3. `universo.rkt` produce `universo` con copias recortadas de los cursos.
4. `generador.rkt` recorre los cursos del universo y acumula:
   - `seleccion`: lista inversa de `par-curso-grupo`;
   - `creditos`: suma acumulada.
5. Al terminar, invierte la selección, construye `combinacion` y la emite en un stream.
6. `filtros.rkt` extrae `combinacion-creditos` y devuelve otro stream.

Ningún paso modifica un struct ya construido: se crean nuevos valores con los constructores o con `struct-copy`.
