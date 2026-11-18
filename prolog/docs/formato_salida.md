# Contrato de salida para la Etapa 4 (Java)

Este documento define el formato exacto de salida que la Etapa 3 (Prolog) genera para que la Etapa 4 (Java) la consuma.

El formato está descrito con el comportamiento **real y verificado** de `prolog/src/exportar.pl` (ver tests y la corrida de `main.pl` sobre `data/combinaciones.jsonl`).

## Especificación del formato JSON Lines

- **Formato**: Un archivo de texto con una línea por combinación.
- **Estructura**: Cada línea es un objeto JSON independiente, sin encabezado ni arreglo global.
- **Escritura**: Cada registro se escribe al evaluar la combinación (no se acumula nada en memoria). Una combinación = una línea.
- **Orden de claves**: las claves se escriben en el orden `id`, `cursos`, `cumple`, `razon`, `razon_descripcion`, `creditos_totales`, `detalle`, `cursos_areas`.

## Campos obligatorios

- `id`: número identificador de la combinación (entero positivo).
- `cumple`: booleano que indica si la combinación cumple todas las reglas de política.
- `razon`:
  - Si `cumple` es `true`, el valor es `"ninguna"`.
  - Si `cumple` es `false`, el valor es el nombre de la primera regla violada en el orden de evaluación (`balance_carreras`, `limite_por_area`, o `incompatibilidad`).
- `razon_descripcion`:
  - `""` cuando `cumple` es `true`.
  - Descripción legible en español de la regla violada (de `constantes:regla/2`) cuando `cumple` es `false`.
- `creditos_totales`: entero con la suma total de créditos de todos los cursos de la combinación.
- `detalle`: objeto cuyo contenido depende de `razon` (ver abajo). `{}` cuando `cumple` es `true`.
- `cursos_areas`: lista de códigos de curso (strings) en exceso para la regla `limite_por_area`. `[]` en los demás casos.

## Campo `cursos`

Cada registro incluye, además de los campos anteriores, un campo `cursos` que es una lista de objetos JSON con los pares **curso-grupo** elegidos para esa combinación. Este campo está presente en **todos** los registros, tanto en los que cumplen como en los que violan, y es la **salida mínima** que exige el enunciado (D4 / Fase 5): la salida debe traer los pares curso-grupo y no tocar la lógica de generación ni de filtrado. Se genera por `lista_json_cursos/2`, que convierte cada entrada del catálogo `curso(Codigo, Grupo, Creditos, Carrera, Area)` en `{"carrera":"~w","codigo":"~w","grupo":~w}`.

Ejemplo: para la combinación 1 (Fisica general II + Matemática + Electrónica CS3404):

```json
{"id":1,"cursos":[{"carrera":"fisica","codigo":"MA1103","grupo":1},{"carrera":"fisica","codigo":"MI2106","grupo":2},{"carrera":"fisica","codigo":"FI2103","grupo":1},{"carrera":"fisica","codigo":"CS3404","grupo":1}],"cumple":false,"razon":"balance_carreras",...}
```

## `detalle` según `razon`

### `balance_carreras`
```json
{"carrera":"fisica","creditos_carrera":12,"creditos_totales":12,"maximo_porcentaje":70}
```
- `carrera`: nombre de la carrera cuyo porcentaje de créditos excede el máximo permitido (`"computadores"` o `"fisica"`).
- `creditos_carrera`: créditos aportados por esa carrera.
- `creditos_totales`: créditos totales de la combinación (duplicado del campo de primer nivel).
- `maximo_porcentaje`: máximo porcentaje permitido para esa carrera según la política (p. ej. `70`).

### `limite_por_area`
```json
{"area":"fisica","cantidad":4,"maximo":3,"cursos":["FI1202","MI2106","FI2103","FI1102"]}
```
- `area`: nombre del área que excede el límite.
- `cantidad`: número de cursos de esa área en la combinación.
- `maximo`: máximo de cursos por área permitido por la política (`max_cursos_por_area`).
- `cursos`: lista de códigos de los cursos de esa área.
- En este caso `cursos_areas` (primer nivel) contiene la misma lista de códigos.

### `incompatibilidad`
```json
{"par":["computadores-FI1102","fisica-FI1102"]}
```
- `par`: los dos cursos incompatibles, en el formato `carrera-codigo` (p. ej. `"computadores-FI1102"`). Ambos provienen de hechos `par_incompatible/2` de la política; el par se detecta de forma simétrica.

## Ejemplos completos

### Combinación válida
```json
{"id":21,"cursos":[{"carrera":"computadores","codigo":"MA2104","grupo":1},{"carrera":"fisica","codigo":"FI2103","grupo":1},{"carrera":"fisica","codigo":"FI1102","grupo":4},{"carrera":"fisica","codigo":"CS3404","grupo":1}],"cumple":true,"razon":"ninguna","razon_desinxion":"","creditos_totales":12,"detalle":{},"cursos_areas":[]}
```

### Combinación que viola `balance_carreras`
```json
{"id":1,"cursos":[{"carrera":"fisica","codigo":"MA1103","grupo":1},{"carrera":"fisica","codigo":"MI2106","grupo":2},{"carrera":"fisica","codigo":"FI2103","grupo":1},{"carrera":"fisica","codigo":"CS3404","grupo":1}],"cumple":false,"razon":"balance_carreras","razon_descripcion":"Balance entre carreras","creditos_totales":12,"detalle":{"carrera":"fisica","creditos_carrera":12,"creditos_totales":12,"maximo_porcentaje":70},"cursos_areas":[]}
```

### Combinación que viola `limite_por_area`
```json
{"id":130,"cursos":[{"carrera":"computadores","codigo":"FI1202","grupo":2},{"carrera":"computadores","codigo":"MA2104","grupo":1},{"carrera":"fisica","codigo":"MI2106","grupo":2},{"carrera":"fisica","codigo":"FI2103","grupo":1},{"carrera":"fisica","codigo":"FI1102","grupo":4}],"cumple":false,"razon":"limite_por_area","razon_descripcion":"Limite de cursos por area","creditos_totales":14,"detalle":{"area":"fisica","cantidad":4,"maximo":3,"cursos":["FI1202","MI2106","FI2103","FI1102"]},"cursos_areas":["FI1202","MI2106","FI2103","FI1102"]}
```

### Combinación que viola `incompatibilidad`
```json
{"id":215,"cursos":[{"carrera":"computadores","codigo":"FI1102","grupo":1},{"carrera":"computadores","codigo":"MA2104","grupo":1},{"carrera":"fisica","codigo":"FI1102","grupo":4},{"carrera":"fisica","codigo":"CS3404","grupo":1}],"cumple":false,"razon":"incompatibilidad","razon_descripcion":"Cursos incompatibles","creditos_totales":12,"detalle":{"par":["computadores-FI1102","fisica-FI1102"]},"cursos_areas":[]}
```

## Notas técnicas

- El archivo debe ser procesado línea por línea; no se debe cargar todo en memoria.
- El formato es compatible con las bibliotecas JSON habituales en Java (Jackson, Gson).
- Las cadenas JSON van siempre entre comillas; `razon_descripcion` vacío se escribe como `""`.
- Si no hay cursos en el área correspondiente, `cursos_areas` es `[]`.
- `detalle` siempre está presente (aunque sea `{}`).
- La lista `cursos_areas` aparece duplicada para la regla `limite_por_area`: una vez en la raíz del registro y otra dentro de `detalle.cursos`. La razón es de contratos: la raíz es la lista de códigos en exceso, que consume la Etapa 4 como un solo campo, mientras que `detalle.cursos` es el contenido específico del objeto `detalle` y puede tener otro significado en otras reglas (para `balance_carreras` y `incompatibilidad`, `detalle` no lleva `cursos`). Mantener ambas posiciones evita que un consumidor que lea solo `detalle` o solo la raíz se quede sin la información, y no rompe el formato JSON Lines: cada consumers puede usar la que prefiera. Si se prefiera eliminar la duplicación, bastaría cambiar `escribir_razon_area/9` en `prolog/src/exportar.pl` para que `cursos_areas` sea `[]` y dejar `detalle.cursos` como la única fuente.
- Uno de los consumidores previstos es la Etapa 4 (Java); este formato es el contrato entre Prolog y Java.
