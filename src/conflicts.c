#include "../include/conflicts.h"

/* Convierte (hora, minuto) a minutos totales del dia para comparar
 * intervalos con una sola resta. */
static int minutes_of(int hour, int minute) {
    return hour * 60 + minute;
}

int conflicts_blocks_overlap(const TimeBlock *a, const TimeBlock *b) {
    if (a == NULL || b == NULL) return 0;
    if (a->day != b->day) return 0;

    int a_start = minutes_of(a->start_hour, a->start_minute);
    int a_end   = minutes_of(a->end_hour,   a->end_minute);
    int b_start = minutes_of(b->start_hour, b->start_minute);
    int b_end   = minutes_of(b->end_hour,   b->end_minute);

    /* Solapan si cada uno empieza antes de que el otro termine. */
    return a_start < b_end && b_start < a_end;
}

int conflicts_groups_overlap(const Group *a, const Group *b) {
    if (a == NULL || b == NULL) return 0;

    for (int i = 0; i < a->block_count; i++) {
        for (int j = 0; j < b->block_count; j++) {
            if (conflicts_blocks_overlap(&a->blocks[i], &b->blocks[j])) {
                return 1;
            }
        }
    }
    return 0;
}

int conflicts_detect_catalog(Catalog *catalog) {
    if (catalog == NULL) return -1;

    /* reset: la funcion es idempotente, se puede llamar varias veces */
    for (int c = 0; c < catalog->course_count; c++) {
        for (int g = 0; g < catalog->courses[c].group_count; g++) {
            catalog->courses[c].groups[g].has_conflict = 0;
        }
    }

    int marked = 0;

    for (int c1 = 0; c1 < catalog->course_count; c1++) {
        for (int c2 = c1 + 1; c2 < catalog->course_count; c2++) {
            for (int g1 = 0; g1 < catalog->courses[c1].group_count; g1++) {
                Group *ga = &catalog->courses[c1].groups[g1];

                for (int g2 = 0; g2 < catalog->courses[c2].group_count; g2++) {
                    Group *gb = &catalog->courses[c2].groups[g2];

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