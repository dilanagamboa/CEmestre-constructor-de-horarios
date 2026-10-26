# Comparación de formatos de salida

La Etapa 1 exporta un JSON con el catálogo procesado. La Etapa 2 todavía **no** implementa la exportación final de combinaciones: esa tarea corresponde a la Fase 4. Este documento compara las alternativas para dejar registrada la decisión preliminar D3.

Los criterios que se evaluaron son:

1. **Escritura incremental:** se puede escribir cada resultado sin esperar a tener toda la solución.
2. **Compatibilidad con streams:** el exportador puede consumir un stream y escribir a medida que llegan los elementos.
3. **Lectura desde Prolog:** la Etapa 3 debe poder consumir el resultado.
4. **Preservación de estructuras anidadas:** pares, cursos, grupos y bloques.
5. **Legibilidad y depuración:** facilidad para revisar una línea o un registro.
6. **Tamaño y repetitividad:** cuánto se repite la misma información.

## 1. JSON array

Un solo objeto o arreglo con todas las combinaciones:

```json
{
  "format_version": 1,
  "combinations": [
    {"pairs": [{"career": "computadores", "code": "S1", "group": 1}], "credits": 4},
    {"pairs": [{"career": "computadores", "code": "S1", "group": 1}, {"career": "computadores", "code": "S4", "group": 1}], "credits": 6}
  ]
}
```

Ventajas:

- Es el formato más familiar y el mismo estilo del JSON de C.
- Un consumidor puede leer todo el archivo con una biblioteca JSON estándar.
- Preserva estructuras anidadas.

Desventajas:

- Para escribir un arreglo hay que abrir corchete, escribir elementos separados por comas y cerrar al final; no es natural para un stream.
- Si se quiere evitar la coma final, hay que saber cuál es el último elemento o materializar la lista.
- Un archivo grande se vuelve una sola estructura difícil de inspeccionar por partes.
- Si el proceso falla a mitad, el archivo queda inválido.

## 2. JSON Lines (JSONL)

Un objeto JSON independiente por línea:

```json
{"pairs":[{"career":"computadores","code":"S1","group":1}],"credits":4}
{"pairs":[{"career":"computadores","code":"S1","group":1},{"career":"computadores","code":"S4","group":1}],"credits":6}
```

Ventajas:

- **Escritura incremental:** cada combinación se escribe apenas se produce; no hay que saber cuál es la última.
- **Streams:** el exportador puede consumir el stream y escribir línea por línea sin materializar la lista.
- **Tolerancia a fallos:** si el proceso se interrumpe, las líneas anteriores siguen siendo registros válidos.
- **Depuración:** se puede usar `head`, `tail`, `grep` o un editor de texto por líneas; cada línea es autocontenida.
- **Prolog:** cada línea se puede convertir a un hecho `combinacion(...)` con un programa pequeño; o Prolog puede leer JSONL si se le da un parser.
- **Estructuras anidadas:** conserva los objetos y arreglos internos.

Desventajas:

- No es un único documento JSON; algunas herramientas esperan un arreglo.
- Hay que definir el esquema de cada línea y documentarlo.
- La conversión a hechos de Prolog requiere un paso adicional.

## 3. CSV

Una fila por combinación:

```csv
credits,courses
4,computadores:S1:1
6,computadores:S1:1|computadores:S4:1
```

Ventajas:

- Muy compacto y fácil de abrir en una hoja de cálculo.
- Se puede escribir de forma incremental.
- Fácil de procesar con herramientas de texto.

Desventajas:

- Las estructuras anidadas (varios cursos, varios grupos, varios bloques) se tienen que aplanar con separadores inventados.
- El orden y los separadores pasan a formar parte del contrato.
- Los textos con comas, comillas o saltos de línea requieren escapes.
- Prolog tendría que reconstruir la estructura desde el texto.
- No expresa naturalmente los tipos ni los campos opcionales.

## 4. Hechos de Prolog

```prolog
combinacion(4, [par(computadores, 'S1', 1)]).
combinacion(6, [par(computadores, 'S1', 1), par(computadores, 'S4', 1)]).
```

Ventajas:

- Es el formato natural para la Etapa 3.
- Prolog puede consultarlo directamente sin un parser externo.
- Permite representar listas y términos anidados.

Desventajas:

- Es un formato específico de Prolog; otros consumidores necesitan un parser o una conversión.
- Hay que escapar átomos, comillas y caracteres especiales.
- No es tan legible para una persona que no conoce Prolog.
- Escribir hechos a medida que se generan es posible, pero el esquema queda atado a la Etapa 3.
- La Etapa 2 todavía no tiene la biblioteca ni el formato de la Etapa 3 acordados.

## 5. Comparación

| Criterio | JSON array | JSON Lines | CSV | Hechos Prolog |
| --- | --- | --- | --- | --- |
| Escritura incremental | Difícil por las comas/cierre | Sí | Sí | Sí |
| Compatibilidad con streams | Baja | Alta | Alta | Alta |
| Lectura desde Prolog | Requiere parser JSON | Requiere parser JSON o conversión | Requiere reconstruir | Directa |
| Estructuras anidadas | Sí | Sí | No | Sí |
| Legibilidad por partes | Baja | Alta | Alta | Media |
| Tamaño | Medio | Medio | Bajo | Medio |
| Depuración con texto | Media | Alta | Alta | Media |
| Riesgo de formato inválido a mitad | Alto | Bajo | Bajo | Bajo |

## 6. Decisión preliminar

Se propone **JSON Lines** para la Fase 4:

- un objeto por línea;
- cada objeto con `pairs` (lista de pares) y `credits`;
- cada par con la carrera, el código y el número de grupo; opcionalmente, los bloques para Prolog;
- una línea final de metadatos si hace falta, por ejemplo `{"format_version":1,"combination_count":N}`, o un encabezado comentado que no se confunda con un objeto.

La decisión es **provisional**. No se implementa en las Fases 0–3 porque el plan prohíbe adelantar la exportación final. Antes de la Fase 4 hay que confirmar:

- el nombre exacto de los campos;
- si se incluyen los bloques en cada par o solo la referencia al grupo;
- si se agrega un encabezado o un pie con la cantidad de combinaciones;
- cómo se convierte cada línea a hechos de Prolog;
- si el profesor prefiere JSON array, CSV o hechos directamente.

## 7. Relación con el JSON de C

El JSON de C sigue siendo la **entrada** de Racket y no se modifica. La decisión D3 es solo para la **salida de combinaciones** de la Etapa 2. El campo `format_version` del JSON de C protege el contrato de entrada; para JSONL se propone un campo equivalente en el encabezado o en la primera línea.

## 8. Verificación

- La comparación cubre los cinco criterios del plan (consumo incremental, compatibilidad con streams, lectura desde Prolog, preservación de estructuras y facilidad de depuración) y agrega el tamaño como criterio de desempate.
- No hay pruebas de exportación porque la Fase 4 está fuera del alcance.
- La decisión queda registrada en `racket/docs/decisiones.md` (D3) y en `racket/docs/progreso_fases_0_3.md`.
