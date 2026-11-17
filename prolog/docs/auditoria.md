# Auditoría de estado global, assert y retract — Etapa 3

Fecha: 17 de noviembre de 2026
Alcance: `prolog/src/` completo y `scripts/validar_resultados.py`.

## Resumen

Búsqueda de texto sobre todo el código de la etapa:

| Patrón | Ocurrencias |
| --- | --- |
| `assert`, `asserta`, `assertz` | 0 (solo un comentario en `cargar.pl` que documenta la decisión) |
| `retract`, `retractall` | 0 |
| `nb_setval`, `nb_linkval`, `b_setval` | 0 |
| `flag/2`, `flag/3`, `abolish`, `nb_getval` | 0 |
| Variables globales (`:- dynamic`, `:- mutable`) | 0 |

Comando usado:

```bash
grep -rn -E "asserta|assertz|assert\b|retract|nb_setval|b_setval|nb_linkval|\bflag\b|abolish|dynamic|mutable" prolog/src
```

`prolog/src/constantes.pl:1-18` confirma que los hechos de política viajan por
argumentos: `modulo_politica(politica)` es un argumento del predicado
`cargar_politica/2`, no un hecho global mutable. La política se carga en un
módulo dedicado (`politica`) y las reglas reciben ese módulo como primer
argumento, de modo que dos políticas conviven en las pruebas sin pisarse.

## Negar por falla y corte: revisión de cada uno

| Ubicación | Construcción | Justificación en código | Veredicto |
| --- | --- | --- | --- |
| `prolog/src/cargar.pl:57` | `-> !, fail` (fin de archivo) | El `repeat` de `combinacion_leida/2` reintentaría leer para siempre; el corte elimina ese punto de elección. Comentario en líneas 49-51 y 63-68. | Correcto |
| `prolog/src/razon.pl:66` | `!` en `primera_del_orden/5` | Es la primera regla del orden (D5) que falla; explorar las siguientes sería trabajo inútil y podría reportar una razón distinta a la del orden. Comentario líneas 42-48. | Correcto |
| `prolog/src/main.pl:79` | `!` en `parse_args/4` | Argumentos en orden posicional, el primer match gana; sin el corte los `parse_args` posteriores volverían a ligar. Comentario arriba del predicado. | Correcto |
| `prolog/src/prototipo.pl:33` | `-> !, fail` | Prototipo original de Fase 0, conservado como referencia histórica; no se usa en el flujo principal ni en las pruebas. | Aceptable |
| `prolog/src/razon.pl:42-44`, `30-34` | `-> ;` (negación por falla) | Pregunta existencial: "¿existe al menos una regla violada?". Si ninguna falla, `cumple`. El comentario en líneas 26-32 lo explica. | Correcto |
| `prolog/src/cargar.pl:86,115`, `202` | `\==`, `\+` | Comparaciones de desigualdad y negación en validaciones (no son negación por falla de una solución, sino filtros de hechos). | Correcto |

## Resultado

No se encontró ningún uso de assert, retract ni variables globales para
resultados intermedios. Todo el estado viaja por argumentos y unificación; la
política se carga desde `data/politica.pl` como hechos y los resultados se
escriben al evaluarse cada combinación (`exportar:escribir_resultado/3`), sin
acumular en memoria. Los cortes y las negaciones por falla están justificados
en comentario.

La auditoría está limpia.
