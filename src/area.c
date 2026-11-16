#include <stdio.h>
#include <string.h>

#include "../include/area.h"
#include "../include/catalog.h"
#include "../include/utils.h"

/* -------------------------------------------------------------------------
 * Asignacion del area de cada curso (Etapa 3)
 * -------------------------------------------------------------------------
 * El area vive en un archivo aparte, una linea por curso:
 *
 *   code ; area
 *
 * Ejemplo:
 *   CE1101;programacion
 *   MA1102;matematica
 *
 * Se usa un archivo de mapeo en vez de una columna nueva en catalogo.csv
 * para no cambiar el formato que ya leen las Etapas 1 y 2 ni sus pruebas.
 * El archivo se valida contra el catalogo ya cargado, igual que el historial.
 * ------------------------------------------------------------------------- */

/* lista unica de areas validas, definida en constants.h */
static const char *const VALID_AREAS[] = { AREA_LIST };
static const int VALID_AREA_COUNT = (int)(sizeof(VALID_AREAS) / sizeof(VALID_AREAS[0]));

int area_is_valid(const char *area) {
    if (area == NULL) return 0;
    for (int i = 0; i < VALID_AREA_COUNT; i++) {
        if (strcmp(area, VALID_AREAS[i]) == 0) return 1;
    }
    return 0;
}

void area_set_unassigned(Catalog *catalog) {
    if (catalog == NULL) return;
    for (int i = 0; i < catalog->course_count; i++) {
        safe_strcpy(catalog->courses[i].area, MAX_AREA_LENGTH, AREA_UNASSIGNED);
    }
}

/* anota en info (si no es NULL) donde fallo la carga */
static void set_error_info(LoadErrorInfo *info, int line, const char *course) {
    if (info == NULL) return;
    info->line = line;
    safe_strcpy(info->course, MAX_CODE_LENGTH, course != NULL ? course : "");
    info->related[0] = '\0';
}

/* Procesa una linea ya limpia. Devuelve SUCCESS o el error de esa linea.
 * Un curso cuya area ya no esta vacia aparecio antes en el archivo. */
static ErrorCode parse_area_line(char *line, Catalog *catalog) {
    char *fields[2];
    if (split_fields(line, ';', fields, 2) != 2) return ERROR_INVALID_FORMAT;

    trim_whitespace(fields[0]);
    trim_whitespace(fields[1]);
    if (fields[0][0] == '\0' || strlen(fields[0]) >= MAX_CODE_LENGTH) return ERROR_INVALID_FORMAT;
    if (!area_is_valid(fields[1])) return ERROR_INVALID_FORMAT;

    int idx = catalog_find_course_index(catalog, fields[0]);
    if (idx == -1) return ERROR_COURSE_NOT_FOUND;

    Course *course = &catalog->courses[idx];
    if (course->area[0] != '\0') return ERROR_INVALID_FORMAT;   /* codigo repetido */

    safe_strcpy(course->area, MAX_AREA_LENGTH, fields[1]);
    return SUCCESS;
}

ErrorCode area_load(const char *path, Catalog *catalog, LoadErrorInfo *info) {
    set_error_info(info, 0, NULL);
    if (path == NULL || catalog == NULL) return ERROR_INVALID_FORMAT;

    FILE *file = fopen(path, "r");
    if (file == NULL) return ERROR_FILE_NOT_FOUND;

    /* se parte de areas vacias para detectar cursos repetidos o sin area */
    for (int i = 0; i < catalog->course_count; i++) {
        catalog->courses[i].area[0] = '\0';
    }

    char line[MAX_LINE_LENGTH];
    int line_number = 0;
    while (fgets(line, sizeof(line), file) != NULL) {
        line_number++;

        /* una linea que no cabe en el buffer se rechaza en vez de leerse partida */
        size_t raw_len = strlen(line);
        if (raw_len == sizeof(line) - 1 && line[raw_len - 1] != '\n' && !feof(file)) {
            set_error_info(info, line_number, NULL);
            fclose(file);
            return ERROR_LIMIT_EXCEEDED;
        }

        trim_whitespace(line);
        if (line[0] == '\0' || line[0] == '#') continue;

        /* split_fields corta 'line' en el ';', asi que line queda con el codigo */
        ErrorCode result = parse_area_line(line, catalog);
        if (result != SUCCESS) {
            set_error_info(info, line_number, line);
            fclose(file);
            return result;
        }
    }
    fclose(file);

    /* la regla de limite por area necesita el area de todos los cursos */
    for (int i = 0; i < catalog->course_count; i++) {
        if (catalog->courses[i].area[0] == '\0') {
            set_error_info(info, 0, catalog->courses[i].code);
            return ERROR_INCOMPLETE_DATA;
        }
    }
    return SUCCESS;
}
