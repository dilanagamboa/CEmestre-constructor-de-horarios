#include "../include/conflicts.h"

/* Convierte (hora, minuto) a minutos totales del dia para comparar
 * intervalos con una sola resta. */
static int minutes_of(int hour, int minute) {
    return hour * 60 + minute;
}

/* Revisa si dos bloques de horario (dia + inicio + fin) se traslapan. */
int conflicts_blocks_overlap(const TimeBlock *a, const TimeBlock *b) {
    if (a == NULL || b == NULL) return 0;
    if (a->day != b->day) return 0;   /* dias distintos nunca chocan */

    int a_start = minutes_of(a->start_hour, a->start_minute);
    int a_end   = minutes_of(a->end_hour,   a->end_minute);
    int b_start = minutes_of(b->start_hour, b->start_minute);
    int b_end   = minutes_of(b->end_hour,   b->end_minute);

    /* Solapan si cada uno empieza antes de que el otro termine.
     * Se usa '<' estricto, asi que bloques pegados (uno termina 10:00 y el
     * otro empieza 10:00) NO cuentan como choque. Esta condicion cubre
     * todos los casos: traslape parcial, un bloque dentro del otro y
     * horarios identicos. */
    return a_start < b_end && b_start < a_end;
}

/* Dos grupos chocan si al menos un bloque de uno se traslapa con al menos
 * un bloque del otro. Se comparan todos contra todos (maximo 3x3 bloques)
 * y se sale apenas se encuentra el primer choque. */
int conflicts_groups_overlap(const Group *a, const Group *b) {
    if (a == NULL || b == NULL) return 0;

    for (int i = 0; i < a->block_count; i++) {
        for (int j = 0; j < b->block_count; j++) {
            if (conflicts_blocks_overlap(&a->blocks[i], &b->blocks[j])) {
                return 1;
            }
        }
    }
    return 0;   /* un grupo sin bloques nunca entra a los for, entonces no choca */
}

/* Marca has_conflict en cada grupo que choca con algun grupo de otro curso.
 * Devuelve cuantos grupos quedaron marcados. */
int conflicts_detect_catalog(Catalog *catalog) {
    if (catalog == NULL) return -1;

    /* reset: la funcion es idempotente, se puede llamar varias veces */
    for (int c = 0; c < catalog->course_count; c++) {
        for (int g = 0; g < catalog->courses[c].group_count; g++) {
            catalog->courses[c].groups[g].has_conflict = 0;
        }
    }

    int marked = 0;

    /* c2 arranca en c1 + 1 por dos razones: cada par de cursos se revisa
     * una sola vez (A-B y no tambien B-A), y un curso nunca se compara
     * consigo mismo, porque sus grupos son alternativas entre si
     * (el estudiante solo matricula uno). */
    for (int c1 = 0; c1 < catalog->course_count; c1++) {
        for (int c2 = c1 + 1; c2 < catalog->course_count; c2++) {
            for (int g1 = 0; g1 < catalog->courses[c1].group_count; g1++) {
                /* puntero al grupo para modificarlo directo en el catalogo */
                Group *ga = &catalog->courses[c1].groups[g1];

                for (int g2 = 0; g2 < catalog->courses[c2].group_count; g2++) {
                    Group *gb = &catalog->courses[c2].groups[g2];

                    /* el choque es simetrico: se marcan los dos grupos.
                     * El if evita contar dos veces un grupo que ya estaba
                     * marcado por otro choque. */
                    if (conflicts_groups_overlap(ga, gb)) {
                        if (!ga->has_conflict) { ga->has_conflict = 1; marked++; }
                        if (!gb->has_conflict) { gb->has_conflict = 1; marked++; }
                    }
                }
            }
        }
    }

    return marked;
}