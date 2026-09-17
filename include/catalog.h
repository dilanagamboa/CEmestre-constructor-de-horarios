#ifndef CATALOG_H
#define CATALOG_H

#include "structs.h"
#include "constants.h"

// capacidad inicial del arreglo dinámico de cursos que se duplica con realloc cuando se llena
#define CATALOG_INITIAL_CAPACITY 16

// inicializa un catálogo vacío
ErrorCode catalog_init(Catalog *catalog);

// agrega una copia de Course al catálogo, creciendo el arreglo con realloc si hace falta
ErrorCode catalog_add_course(Catalog *catalog, const Course *course);

// carga el catalogo completo desde 'path', si hay errores lo rechaza
ErrorCode catalog_load(const char *path, Catalog *catalog);

// busca un curso por código, devuelve su índice en catalog->courses o -1 si no existe
int catalog_find_course_index(const Catalog *catalog, const char *code);

// libera la memoria del catálogo y lo deja en un estado seguro para reusar o descartar
void catalog_free(Catalog *catalog);

#endif