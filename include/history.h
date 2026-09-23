#ifndef HISTORY_H
#define HISTORY_H

#include "structs.h"
#include "catalog.h"
#include "constants.h"

// formato de historial.csv: una línea de texto por curso aprobado (solo código)

// deja el historial vacío
void history_init(StudentHistory *history);

// carga el historial desde path y lo valida con catalog
ErrorCode history_load(const char *path, const Catalog *catalog, StudentHistory *history);

// 1 si code está en el historial, 0 si no
int history_has_course(const StudentHistory *history, const char *code);

#endif