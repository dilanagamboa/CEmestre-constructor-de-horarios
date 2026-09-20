#ifndef EXPORT_H
#define EXPORT_H

#include <stdio.h>

#include "structs.h"
#include "constants.h"

/* Escribe el JSON en un stream ya abierto (un archivo, stdout...).
 * Devuelve SUCCESS, ERROR_INVALID_FORMAT si algun puntero es NULL, o
 * ERROR_FILE_WRITE si el stream reporta un error de escritura. */
ErrorCode export_catalog_json_stream(FILE *out,
                                     const Catalog *catalog,
                                     const StudentHistory *history);

/* Crea (o sobreescribe) el archivo en 'path' y escribe el JSON.
 * Devuelve SUCCESS, ERROR_INVALID_FORMAT si algun puntero es NULL, o
 * ERROR_FILE_WRITE si no se pudo abrir o escribir el archivo. */
ErrorCode export_catalog_json(const char *path,
                              const Catalog *catalog,
                              const StudentHistory *history);

#endif