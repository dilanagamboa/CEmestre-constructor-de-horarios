# Guía de defensa del código de la Etapa 2

Esta guía permite explicar el código de las Fases 0–3 y sirve como material de estudio para la defensa. Para cada módulo se indica responsabilidad, entradas, salidas, invariantes, dependencias, funciones principales, errores, pruebas y cambios que se pueden hacer en vivo durante la defensa.

## 1. Preguntas sobre el diseño

### ¿Qué es una combinación?

Una `combinacion` es una lista no vacía de `par-curso-grupo` más el total de créditos. Cada par une un `curso` del universo con uno de sus `grupo`s. La combinación representa una matrícula candidata: los cursos elegidos y el grupo de cada uno, sin choques entre ellos.

### ¿Por qué la combinación no puede ser vacía?

Porque una matrícula sin cursos no es una solución útil. Además, el plan pide explícitamente un subconjunto **no vacío** de los cursos habilitados. El generador emite la combinación solo si la selección acumulada tiene al menos un par; si el universo está vacío, devuelve `empty-stream`.

### ¿Por qué se eligieron contratos y no Typed Racket?

Porque el proyecto ya usaba structs inmutables y `contract-out`, y los contratos permiten validar los datos en las fronteras (JSON, preferencias, universo) sin anotar cada función recursiva. También permiten que el filtro sea genérico con `(stream/c any/c)` sin introducir `Any` ni `cast`. Mantener una sola estrategia evita mezclar dos sistemas de tipos.

### ¿Por qué los structs son inmutables?

Porque el generador comparte cursos y grupos entre muchas ramas. Si una rama pudiera modificar un curso, las otras verían datos inconsistentes. La inmutabilidad también permite comparar con `equal?`, reutilizar el catálogo en las pruebas y recorrer un stream varias veces sin efectos laterales. No se usa `#:mutable`, `set!`, `set-box!`, `hash-set!` ni `vector-set!` en `racket/src/`.

### ¿Cómo se identifica un curso?

Por la pareja `(carrera, código)`, no solo por el código. Un mismo código puede existir en Computadores y en Física con requisitos distintos. `buscar-curso` recibe carrera y código; `leer-catalogo` solo considera duplicado un par repetido; `interes` también guarda carrera y código.

### ¿Por qué se conserva la carrera dentro del curso?

Porque el curso viaja dentro de cada combinación y el futuro exportador necesita saber a qué carrera pertenece sin volver a buscar en el catálogo. También porque la carrera es parte de la identidad y de la interpretación de los requisitos.

## 2. Preguntas sobre la lectura

### ¿Qué ocurre si el JSON está corrupto?

`leer-json` intenta leerlo con `read-json`; si falla, lanza `exn:fail:user` con “no es un JSON valido”. Las pruebas usan `catalogo_json_malformado.json` y `preferencias_json_malformado.json`.

### ¿Qué ocurre si falta un campo?

`campo` busca la clave y, si no existe, lanza `exn:fail:user` con “falta el campo …”. No se usan accesos directos que produzcan errores internos.

### ¿Qué ocurre si un curso no existe?

`catalogo.rkt` no puede saberlo hasta que se leen las preferencias; `universo.rkt` busca la pareja y, si no existe, descarta el interés y agrega “no esta en el catalogo”. El programa no se cae.

### ¿Qué ocurre si un grupo solicitado no existe?

`universo.rkt` conserva solo los grupos que existen, avisa “no tiene el grupo N” y, si no queda ninguno, descarta el curso con “no le queda ningun grupo de interes”.

### ¿Qué ocurre si el curso ya fue aprobado?

`universo.rkt` lo excluye y avisa “ya esta aprobado”. El curso sigue en el catálogo; solo no se ofrece para matrícula.

### ¿Cómo se detectan cursos duplicados?

En el catálogo, `leer-catalogo` busca una pareja `(carrera, código)` repetida y lanza un error. En preferencias, el lector permite repetidos y el universo conserva la primera aparición, avisa “esta repetido, se usa la primera aparicion”. La diferencia es deliberada: el catálogo es un contrato de datos y las preferencias son una entrada de usuario que puede tener errores corregibles.

## 3. Preguntas sobre choques

### ¿Cómo se determina que dos bloques chocan?

Dos bloques chocan si son del mismo día y cada uno empieza antes de que termine el otro:

```racket
(and (eq? (bloque-dia a) (bloque-dia b))
     (< (bloque-inicio a) (bloque-fin b))
     (< (bloque-inicio b) (bloque-fin a)))
```

### ¿Qué ocurre en el borde de dos bloques?

Si un bloque termina a las 10:00 y otro empieza a las 10:00, no chocan. La comparación es `<` estricta. Es la misma regla de `src/conflicts.c` de la Etapa 1.

### ¿Por qué los grupos alternativos del mismo curso no se comparan?

Porque son alternativas: el estudiante elige uno, no todos. El generador procesa cada curso una sola vez y elige como máximo un grupo. Comparar dos grupos del mismo curso produciría falsos choques.

### ¿Cómo se compara Racket con la bandera de C?

`test-choques.rkt` lee las salidas reales, recalcula para cada grupo si choca con algún grupo de otro curso y compara con `has_conflict` de C. En los datos actuales no hay diferencias: 221 grupos en Computadores y 308 en Física. La bandera de C es una referencia; la fuente de verdad para generar es el cálculo de Racket.

### ¿Qué sucede con un grupo sin horario?

`grupo-bloques` es `[]`, `grupos-chocan?` usa `ormap` y devuelve `#f`, así que el grupo nunca choca. El generador puede elegirlo si está en el universo.

## 4. Preguntas sobre streams

### ¿Por qué el generador devuelve un stream?

Porque el número de combinaciones puede ser enorme y no se quiere materializar todo antes de devolver el primer resultado. Un stream permite pedir uno, dos o los primeros N, y calcular el resto solo cuando se necesite. El filtro por créditos también puede consumir el stream de forma incremental.

### ¿Qué significa que sea perezoso?

Significa que la cola de un stream no se evalúa hasta que se pide. `stream-cons` crea una cabeza y una promesa; `stream-first` fuerza la cabeza; `stream-rest` devuelve la cola, que puede seguir diferida. En el generador, las ramas se envuelven en `stream-lazy` para que construir el stream no dispare toda la recursión.

### ¿Cómo se evita generar todas las combinaciones?

Cada curso tiene dos ramas diferidas. Al pedir el primer resultado, Racket solo recorre el camino hasta la primera combinación; no evalúa las ramas que no hacen falta. La prueba de 60 cursos (2^60 − 1 combinaciones) obtiene `C59-1 | 1` sin agotar la memoria.

### ¿Qué se evalúa al solicitar solo el primer resultado?

Se evalúa la cadena de omisiones hasta el último curso, se elige el primer grupo compatible de ese curso y se emite la combinación. No se evalúan las ramas de selección de los cursos anteriores ni las alternativas de grupo posteriores.

### ¿Por qué `list->stream` no sería suficiente?

Porque `list->stream` recibe una lista ya construida. Para construirla habría que generar todas las combinaciones antes de devolver el stream, que es exactamente lo que el plan prohíbe. El generador usa `stream-cons` y `stream-lazy`, no `list->stream`. La auditoría lo confirma.

### ¿Qué dificultad apareció con `stream-append`?

`stream-append` es perezoso, pero sus argumentos se evalúan antes de la llamada. La primera versión construía las dos ramas de cada curso antes de concatenarlas; con 24 cursos el proceso no terminaba. La solución fue envolver cada rama en `stream-lazy`, no solo la concatenación. Esta es una buena anécdota para la defensa: la pereza hay que preservarla en la construcción, no solo en la operación final.

## 5. Preguntas sobre polimorfismo

### ¿Qué tipo de elementos acepta el filtro?

Cualquier elemento: su contrato es `(stream/c any/c)`. No está atado a `combinacion`.

### ¿Cómo se extrae el valor que se compara?

El segundo argumento es una función extractora `(-> any/c real?)`. Por ejemplo:

- `identity` para enteros;
- `string-length` para cadenas;
- `combinacion-creditos` para combinaciones;
- `(lambda (c) (length (combinacion-pares c)))` para contar cursos.

### ¿Por qué el filtro funciona con enteros, cadenas y combinaciones?

Porque no conoce el tipo concreto: solo aplica la extractora y compara el número resultante con los límites. La misma implementación sirve para los tres tipos. Las pruebas lo demuestran con `(2 3 4)`, `("bb" "ccc")` y 26 combinaciones.

### ¿Qué parte del filtro no depende de un tipo específico?

Todo el cuerpo de `filtrar-por-rango`: la validación `min <= max` y `stream-filter` con `(<= minimo valor)` y `(<= valor maximo)`. La única parte específica es la extractora que pasa el usuario.

## 6. Preguntas sobre el paradigma funcional

### ¿Dónde se evidencia la inmutabilidad?

En `types.rkt`: todos los structs se declaran sin `#:mutable`. En `universo.rkt`, el catálogo se copia con `struct-copy`; no se modifica. En el generador, la selección y los créditos se acumulan como parámetros. La auditoría no encuentra `set!`, `hash-set!`, `vector-set!` ni `set-box!` en `racket/src/`.

### ¿Dónde se utiliza recursión?

- `primer-repetido` y `sin-repetidos?` en los lectores;
- `recorrer` en el universo;
- `grupo-compatible?` en choques;
- `generar` y `recorrer` en el generador;
- `stream-filter` internamente para el filtro.

### ¿Qué reemplaza a los ciclos con estado?

La recursión estructural y las funciones de orden superior. Por ejemplo, `recorrer` recibe `vistos`, `cursos` y `avisos` como parámetros y devuelve un nuevo `universo`; no hay variables que cambien de valor. `elegir-grupos` recorre la lista de grupos con recursión y `stream-append`.

### ¿Qué reemplaza a las variables reasignables?

Los parámetros de la recursión. En el generador:

- `pendientes` es la lista de cursos que faltan;
- `seleccion` es la lista inversa de pares elegidos;
- `creditos` es la suma acumulada.

Cada llamada recibe una versión nueva; no se modifica la anterior.

### ¿Cómo se acumulan selección y créditos?

La selección se acumula con `(cons (par-curso-grupo curso grupo) seleccion)` y se invierte al emitir para conservar el orden del universo. Los créditos se acumulan con `(+ creditos (curso-creditos curso))` en la misma llamada recursiva. Ambos son parámetros, no variables globales.

## 7. Explicación por módulo

### 7.1 `types.rkt`

- **Responsabilidad:** definir los structs inmutables y sus contratos.
- **Entradas:** ninguna; es un módulo de definiciones.
- **Salidas:** constructores, predicados, accesores y contratos.
- **Invariantes:** día válido, minutos 0–1439, créditos no negativos, combinación no vacía, listas tipadas.
- **Dependencias:** `racket/contract` (incluido en `#lang racket`).
- **Funciones principales:** `bloque`, `grupo`, `curso`, `catalogo`, `interes`, `preferencias`, `par-curso-grupo`, `combinacion`.
- **Errores:** los contratos lanzan `exn:fail:contract` si se construye un valor inválido.
- **Pruebas:** indirectamente todas; `test-choques.rkt` construye structs, `test-generador.rkt` verifica combinaciones.
- **Cambio en vivo:** cambiar el contrato de `combinacion` a `listof` permitiría la combinación vacía, pero rompería D1 y las pruebas. No se recomienda.

### 7.2 `lectura.rkt`

- **Responsabilidad:** utilidades comunes de lectura JSON y errores.
- **Entradas:** rutas, hashes y claves.
- **Salidas:** datos JSON, campos validados o `exn:fail:user`.
- **Invariantes:** los errores incluyen el lugar; las listas se validan con `lista-de`.
- **Dependencias:** `json`.
- **Funciones principales:** `leer-json`, `campo`, `lista-de`, `error-lectura`.
- **Errores:** archivo inexistente, vacío, JSON inválido, campo faltante o tipo incorrecto.
- **Pruebas:** `test-catalogo.rkt`, `test-preferencias.rkt`.
- **Cambio en vivo:** agregar un campo nuevo al catálogo requiere usar `campo` y un contrato; no hay que tocar `leer-json`.

### 7.3 `catalogo.rkt`

- **Responsabilidad:** convertir el JSON de C en structs y unir carreras.
- **Entradas:** lista no vacía de rutas.
- **Salidas:** `catalogo`.
- **Invariantes:** `format_version = 1`; `course_count` correcto; carreras válidas; horas válidas; grupos no repetidos; pareja `(carrera, código)` única.
- **Dependencias:** `types.rkt`, `lectura.rkt`.
- **Funciones principales:** `hora->minutos`, `json->bloque`, `json->grupo`, `json->curso`, `leer-cursos`, `leer-catalogo`, `cursos-habilitados`, `buscar-curso`.
- **Errores:** todos los de la tabla de `entrada_catalogo.md`.
- **Pruebas:** 6 tests de `test-catalogo.rkt`.
- **Cambio en vivo:** mostrar `hora->minutos` con `"07:30"` → 450 y `"25:00"` → `#f`; agregar un grupo repetido y ver el error.

### 7.4 `preferencias.rkt`

- **Responsabilidad:** leer y validar el archivo de preferencias.
- **Entradas:** ruta.
- **Salidas:** `preferencias`.
- **Invariantes:** mín/máx no negativos, mín ≤ máx, carreras válidas, códigos no vacíos, grupos positivos no repetidos.
- **Dependencias:** `types.rkt`, `lectura.rkt`.
- **Funciones principales:** `json->interes`, `leer-preferencias`, `sin-repetidos?`.
- **Errores:** objeto, campos, créditos, rango, carrera, código y grupos.
- **Pruebas:** 4 tests de `test-preferencias.rkt`.
- **Cambio en vivo:** cambiar `min_credits` a 10 y `max_credits` a 6 para ver el error; agregar un grupo 0.

### 7.5 `universo.rkt`

- **Responsabilidad:** cruzar catálogo y preferencias y producir cursos recortados con avisos.
- **Entradas:** `catalogo`, `preferencias`.
- **Salidas:** `universo`.
- **Invariantes:** solo cursos habilitados/no aprobados, solo grupos existentes, orden de preferencias, catálogo intacto.
- **Dependencias:** `types.rkt`, `catalogo.rkt`.
- **Funciones principales:** `aviso`, `evaluar-interes`, `recorrer`, `construir-universo`.
- **Errores:** no lanza errores de usuario; reporta avisos.
- **Pruebas:** 6 tests de `test-universo.rkt`.
- **Cambio en vivo:** pedir un grupo inexistente y mostrar el aviso; pedir un curso aprobado y mostrar el aviso.

### 7.6 `choques.rkt`

- **Responsabilidad:** decidir si bloques, grupos o un grupo contra una selección chocan.
- **Entradas:** bloques, grupos, lista de pares.
- **Salidas:** booleanos.
- **Invariantes:** mismo día, `<` estricto, grupos sin bloques no chocan, simetría.
- **Dependencias:** `types.rkt`.
- **Funciones principales:** `bloques-chocan?`, `grupos-chocan?`, `grupo-compatible?`.
- **Errores:** los contratos rechazan valores que no sean bloques, grupos o listas de pares.
- **Pruebas:** 5 tests de `test-choques.rkt`, incluida la consistencia con C.
- **Cambio en vivo:** cambiar `<` por `<=` y mostrar que el borde 10:00–10:00 empieza a chocar; luego revertir.

### 7.7 `generador.rkt`

- **Responsabilidad:** generar el stream de combinaciones no vacías.
- **Entradas:** `universo` o lista de cursos.
- **Salidas:** `(stream/c combinacion?)`.
- **Invariantes:** cada curso se procesa una vez; cada par es compatible; no hay combinación vacía; orden determinista; créditos sumados.
- **Dependencias:** `types.rkt`, `universo.rkt`, `choques.rkt`, `racket/stream`.
- **Funciones principales:** `elegir-grupos`, `generar`, `generar-combinaciones-de-cursos`, `generar-combinaciones`.
- **Errores:** los contratos rechazan universos o listas mal tipadas.
- **Pruebas:** 14 tests de `test-generador.rkt`; 3 de streams.
- **Cambio en vivo:** cambiar `OMITIR-CURSOS?` a `#f` y mostrar que solo aparecen combinaciones con todos los cursos; revertir. También mostrar `stream-first` de 60 cursos.

### 7.8 `filtros.rkt`

- **Responsabilidad:** filtrar cualquier stream por un rango inclusivo.
- **Entradas:** stream, extractora, mínimo, máximo.
- **Salidas:** stream filtrado.
- **Invariantes:** `min <= max`; límites inclusivos; no conoce `combinacion`.
- **Dependencias:** `racket/stream`.
- **Funciones principales:** `filtrar-por-rango`.
- **Errores:** `raise-arguments-error` si `min > max`.
- **Pruebas:** 7 tests de `test-filtros.rkt`.
- **Cambio en vivo:** filtrar los créditos de las combinaciones con 6–10 y mostrar 26; filtrar enteros con 2–4; filtrar cadenas por longitud.

## 8. Cambios posibles en vivo

| Cambio | Efecto esperado | Cómo revertir |
| --- | --- | --- |
| `OMITIR-CURSOS?` a `#f` | Solo combinaciones con todos los cursos del universo. | Volver a `#t`. |
| Filtro 6–10 sobre combinaciones | 26 resultados. | Cambiar límites. |
| Filtro 100–200 | Stream vacío. | Cambiar límites. |
| `<=` en `bloques-chocan?` | El borde 10:00–10:00 choca. | Volver a `<`. |
| Agregar un grupo repetido al catálogo | Error “el grupo … aparece mas de una vez”. | Quitar el grupo. |
| Pedir un grupo inexistente en preferencias | Aviso y exclusión del curso si no queda ninguno. | Corregir el número. |

## 9. Limitaciones que se deben declarar

- No se implementaron Fases 4–7: no hay exportador final, programa principal, interfaz ni Prolog.
- No se aplica todavía una restricción específica de correquisitos dentro de las combinaciones; el plan de Fases 0–3 solo exige choques y créditos.
- La revisión final de los datos y de esta guía queda pendiente por parte del equipo.
- El formato JSONL es una propuesta preliminar para la Fase 4.
- La instalación de Racket fue local; los comandos de la guía usan esa ruta.
