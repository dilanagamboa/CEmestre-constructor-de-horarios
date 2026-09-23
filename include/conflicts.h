#ifndef CONFLICTS_H
#define CONFLICTS_H

#include "structs.h"
#include "constants.h"
#include <stddef.h>

/* Dos bloques chocan si son del mismo dia y sus intervalos se solapan. */
int conflicts_blocks_overlap(const TimeBlock *a, const TimeBlock *b);

/* Dos grupos chocan si algun bloque del primero se solapa con algun
 * bloque del segundo. */
int conflicts_groups_overlap(const Group *a, const Group *b);

/* Recorre todo el catalogo y marca has_conflict = 1 en cada grupo que
 * comparte al menos un bloque solapado con un grupo de OTRO curso.
 *
 * Los grupos de un mismo curso son alternativas, por lo que no se
 * marcan entre si.
 *
 * Reinicia todos los has_conflict antes de calcular.
 * Devuelve la cantidad de grupos marcados, o -1 si catalog es NULL. */
int conflicts_detect_catalog(Catalog *catalog);

#endif