#ifndef AREA_H
#define AREA_H

#include "structs.h"
#include "constants.h"

// formato de areas_<carrera>.csv: una linea "codigo;area" por curso del catalogo
// las lineas vacias o que empiezan con '#' se ignoran

// 1 si area es una de las areas validas de AREA_LIST, 0 si no
int area_is_valid(const char *area);

// asigna AREA_UNASSIGNED a todos los cursos, para correr sin archivo de areas
void area_set_unassigned(Catalog *catalog);

// lee el archivo de areas y asigna una a cada curso del catalogo ya cargado
// todo curso debe quedar con exactamente un area; si info != NULL dice donde fallo
ErrorCode area_load(const char *path, Catalog *catalog, LoadErrorInfo *info);

#endif
