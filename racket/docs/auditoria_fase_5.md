# Auditoría de la Fase 5

| Verificación | Comando | Resultado |
|---|---|---|
| Mutación en `racket/src` | `grep -rnE "set!\|hash-set!\|vector-set!\|set-box!\|#:mutable" racket/src` | Sin coincidencias |
| Listas convertidas a stream | `grep -rn "list->stream" racket/src` | Sin coincidencias |
| Ciclos con `for` en `racket/src` | `grep -rn "(for " racket/src` | Sin coincidencias; todo se resuelve con recursión, `map`, `filter` y streams |
| Compilación de Racket | `raco make racket/src/*.rkt` | Compila sin errores |
| Pruebas de Racket | `raco test racket/tests` | 65 pruebas pasan |
| Módulo de C tras el campo carrera | `make clean && make && make test` | Compila y pasa sus pruebas |

## Contratos

Todos los módulos de `racket/src` exportan sus funciones con `contract-out`. `en-rango` usa `parametric->/c`. `filtrar-por-rango` usa `stream/c any/c`, porque en Racket 8.10 `parametric->/c` no se puede combinar con `stream/c`.

## Efectos permitidos

Las únicas operaciones con efectos son la lectura de archivos (`lectura.rkt`) y la escritura de la salida (`exportador.rkt`, `main.rkt`). Ninguna reasigna variables ni modifica estructuras.