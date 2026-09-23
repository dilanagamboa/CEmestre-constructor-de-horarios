#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "../include/catalog.h"
#include "../include/utils.h"

/* -------------------------------------------------------------------------
 * Formato esperado de catalogo.csv
 * -------------------------------------------------------------------------
 * Una linea por curso, campos separados por ';':
 *
 *   code ; name ; credits ; prereqs ; coreqs ; groups
 *
 * - code     : hasta MAX_CODE_LENGTH-1 caracteres, no vacio, unico.
 * - name     : hasta MAX_NAME_LENGTH-1 caracteres, no vacio.
 * - credits  : entero >= 0 (hay cursos de 0 creditos, como los SE y el examen diagnostico).
 * - prereqs  : codigos separados por '/', vacio si no hay.
 * - coreqs   : codigos separados por '/', vacio si no hay.
 * - groups   : grupos separados por '|', vacio si no hay.
 *     - cada grupo:  number @ professor @ blocks
 *     - blocks:      bloques separados por '+'
 *     - cada bloque: DIA , HH:MM , HH:MM
 *     - DIA in {MON, TUE, WED, THU, FRI, SAT}
 *
 * Ejemplo:
 *   CE1106;Paradigmas;4;CE1103;;1@Juan Perez@MON,08:00,10:00
 *   CE2103;Estructuras;4;CE1106;CE2105;1@Maria@WED,13:00,15:00|2@Pedro@THU,15:00,17:00
 *
 * Lineas vacias o que empiezan con '#' se ignoran.
 *
 * El parseo va de afuera hacia adentro: primero se parte la linea por ';',
 * luego el campo de grupos por '|', cada grupo por '@', sus bloques por '+'
 * y cada bloque por ','. Cada nivel tiene su propia funcion helper.
 * ------------------------------------------------------------------------- */

/* ============================ helpers ============================ */

/* Convierte un texto a entero no negativo. A diferencia de atoi, strtol nos
 * deja saber donde termino de leer: si 'end' no llego al final del string,
 * habia basura despues del numero (por ejemplo "4a") y se rechaza.
 * Devuelve 1 si el numero es valido, 0 si no. */
static int parse_int(const char *s, int *out) {
    if (s == NULL || s[0] == '\0') return 0;
    char *end;
    long v = strtol(s, &end, 10);
    if (end == s || *end != '\0') return 0;
    if (v < 0 || v > 1000000) return 0;   /* tope para no desbordar el int */
    *out = (int)v;
    return 1;
}

/* Traduce el codigo de dia del CSV (MON, TUE...) al enum Weekday.
 * Cualquier otro texto se considera un dia mal escrito. */
static int parse_weekday(const char *s, Weekday *out) {
    if (strcmp(s, "MON") == 0) { *out = MONDAY;    return 1; }
    if (strcmp(s, "TUE") == 0) { *out = TUESDAY;   return 1; }
    if (strcmp(s, "WED") == 0) { *out = WEDNESDAY; return 1; }
    if (strcmp(s, "THU") == 0) { *out = THURSDAY;  return 1; }
    if (strcmp(s, "FRI") == 0) { *out = FRIDAY;    return 1; }
    if (strcmp(s, "SAT") == 0) { *out = SATURDAY;  return 1; }
    return 0;
}

/* Lee una hora "HH:MM" y la separa en hora y minuto.
 * Se copia a un buffer local porque split_fields modifica el string que
 * recibe (pone '\0' en los separadores) y 's' es const. */
static int parse_time(const char *s, int *hour, int *minute) {
    char buf[16];
    if (!safe_strcpy(buf, sizeof(buf), s)) return 0;

    char *parts[2];
    int n = split_fields(buf, ':', parts, 2);
    if (n != 2) return 0;

    int h, m;
    if (!parse_int(parts[0], &h)) return 0;
    if (!parse_int(parts[1], &m)) return 0;
    if (h > 23 || m > 59) return 0;   /* hora imposible, ej. 25:00 o 10:75 */

    *hour = h;
    *minute = m;
    return 1;
}

/* Lee un bloque "DIA,HH:MM,HH:MM" y llena el TimeBlock. */
static int parse_block(char *s, TimeBlock *block) {
    char *parts[3];
    int n = split_fields(s, ',', parts, 3);
    if (n != 3) return 0;

    if (!parse_weekday(parts[0], &block->day)) return 0;
    if (!parse_time(parts[1], &block->start_hour, &block->start_minute)) return 0;
    if (!parse_time(parts[2], &block->end_hour,   &block->end_minute))   return 0;

    /* un bloque que empieza despues de terminar es dato mal transcrito */
    int start = block->start_hour * 60 + block->start_minute;
    int end   = block->end_hour   * 60 + block->end_minute;
    if (start >= end) return 0;

    return 1;
}

/* Lee un grupo "numero@profesor@bloques" y llena el Group.
 * El campo de bloques puede venir vacio (grupo sin horario asignado). */
static int parse_group(char *s, Group *group) {
    char *parts[3];
    int n = split_fields(s, '@', parts, 3);
    if (n != 3) return 0;

    /* el numero de grupo tiene que ser positivo */
    int number;
    if (!parse_int(parts[0], &number) || number <= 0) return 0;
    group->group_number = number;

    /* profesor obligatorio; si no cabe se rechaza en vez de cortarlo */
    if (parts[1][0] == '\0') return 0;
    if (strlen(parts[1]) >= MAX_PROFESSOR_LENGTH) return 0;
    safe_strcpy(group->professor, MAX_PROFESSOR_LENGTH, parts[1]);

    group->block_count = 0;
    group->has_conflict = 0;   /* se calcula despues en conflicts.c */

    if (parts[2][0] == '\0') {
        return 1; /* grupo sin bloques: valido pero sin horario */
    }

    /* split_fields devuelve -1 si hay mas de MAX_BLOCKS_PER_GROUP bloques */
    char *blocks[MAX_BLOCKS_PER_GROUP];
    int bn = split_fields(parts[2], '+', blocks, MAX_BLOCKS_PER_GROUP);
    if (bn < 0 || bn == 0) return 0;

    for (int i = 0; i < bn; i++) {
        if (!parse_block(blocks[i], &group->blocks[i])) return 0;
    }
    group->block_count = bn;
    return 1;
}

/* Lee todos los grupos de un curso (separados por '|').
 * Un curso sin grupos es valido: puede estar en el plan pero no abrirse. */
static int parse_groups(char *field, Course *course) {
    course->group_count = 0;
    if (field[0] == '\0') return 1;

    char *parts[MAX_GROUPS_PER_COURSE];
    int n = split_fields(field, '|', parts, MAX_GROUPS_PER_COURSE);
    if (n < 0) return 0;   /* mas grupos de los que caben en el struct */

    for (int i = 0; i < n; i++) {
        if (!parse_group(parts[i], &course->groups[i])) return 0;
    }

    /* dos grupos del mismo curso no pueden tener el mismo numero */
    for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++) {
            if (course->groups[i].group_number == course->groups[j].group_number) return 0;
        }
    }
    course->group_count = n;
    return 1;
}

/* Lee una lista de codigos separados por '/' (se usa igual para
 * prerrequisitos y correquisitos) y los copia en el arreglo 'codes'.
 * 'max_count' es el limite del arreglo destino; si vienen mas, se rechaza.
 * Tambien se rechazan codigos vacios, como en "CE1101//CE1102". */
static int parse_codes_field(char *field,
                             char codes[][MAX_CODE_LENGTH],
                             int max_count,
                             int *out_count) {
    *out_count = 0;
    if (field[0] == '\0') return 1;   /* sin requisitos */

    char *parts[16];
    int n = split_fields(field, '/', parts, 16);
    if (n < 0 || n > max_count) return 0;

    for (int i = 0; i < n; i++) {
        if (parts[i][0] == '\0') return 0;
        if (strlen(parts[i]) >= MAX_CODE_LENGTH) return 0;
        safe_strcpy(codes[i], MAX_CODE_LENGTH, parts[i]);
    }
    *out_count = n;
    return 1;
}

/* Convierte una linea completa del CSV en un Course.
 * Devuelve 1 si la linea es valida, 0 si tiene cualquier error. */
static int parse_course_line(char *line, Course *course) {
    /* se limpia el struct para no arrastrar basura de la pila */
    memset(course, 0, sizeof(*course));

    /* tienen que venir exactamente los 6 campos */
    char *fields[6];
    int n = split_fields(line, ';', fields, 6);
    if (n != 6) {
        return 0;
    }

    /* codigo y nombre son obligatorios; si no caben es un dato mal transcrito
     * (se rechaza en vez de truncarlo en silencio) */
    if (fields[0][0] == '\0' || strlen(fields[0]) >= MAX_CODE_LENGTH) return 0;
    if (fields[1][0] == '\0' || strlen(fields[1]) >= MAX_NAME_LENGTH) return 0;

    safe_strcpy(course->code, MAX_CODE_LENGTH, fields[0]);
    safe_strcpy(course->name, MAX_NAME_LENGTH, fields[1]);

    int credits;
    if (!parse_int(fields[2], &credits)) {
        return 0;
    }
    course->credits = credits;

    if (!parse_codes_field(fields[3], course->prerequisites,
                           MAX_PREREQUISITES, &course->prerequisite_count)) {
        return 0;
    }

    if (!parse_codes_field(fields[4], course->corequisites,
                           MAX_COREQUISITES, &course->corequisite_count)) {
        return 0;
    }

    if (!parse_groups(fields[5], course)) {
        return 0;
    }

    /* un curso no puede ser requisito ni correquisito de si mismo */
    for (int i = 0; i < course->prerequisite_count; i++) {
        if (strcmp(course->prerequisites[i], course->code) == 0) return 0;
    }
    for (int i = 0; i < course->corequisite_count; i++) {
        if (strcmp(course->corequisites[i], course->code) == 0) return 0;
    }

    course->can_enroll = 0;   /* se calcula despues en validation.c */
    return 1;
}

/* ============================ public ============================ */

/* Deja el catalogo vacio. Todavia no se reserva memoria: el arreglo se
 * crea con el primer catalog_add_course (realloc con NULL funciona como malloc). */
ErrorCode catalog_init(Catalog *catalog) {
    if (catalog == NULL) return ERROR_MEMORY_ALLOCATION;
    catalog->courses = NULL;
    catalog->course_count = 0;
    catalog->capacity = 0;
    return SUCCESS;
}

/* Agrega un curso al final del arreglo dinamico.
 * Si ya no hay espacio, la capacidad se duplica (16, 32, 64...) hasta el
 * tope MAX_COURSES. Duplicar evita hacer un realloc por cada curso. */
ErrorCode catalog_add_course(Catalog *catalog, const Course *course) {
    if (catalog == NULL || course == NULL) return ERROR_MEMORY_ALLOCATION;
    if (catalog->course_count >= MAX_COURSES) return ERROR_LIMIT_EXCEEDED;

    if (catalog->course_count >= catalog->capacity) {
        int new_capacity = (catalog->capacity == 0)
            ? CATALOG_INITIAL_CAPACITY
            : catalog->capacity * 2;
        if (new_capacity > MAX_COURSES) new_capacity = MAX_COURSES;

        /* se usa un puntero temporal: si realloc falla devuelve NULL, pero el
         * bloque viejo sigue siendo valido y no se pierde (no hay fuga) */
        Course *new_courses = realloc(catalog->courses,
                                      sizeof(Course) * (size_t)new_capacity);
        if (new_courses == NULL) {
            return ERROR_MEMORY_ALLOCATION;
        }
        catalog->courses = new_courses;
        catalog->capacity = new_capacity;
    }

    /* copia del struct completo (los arreglos internos se copian por valor) */
    catalog->courses[catalog->course_count] = *course;
    catalog->course_count++;
    return SUCCESS;
}

/* Busqueda lineal por codigo. Con los cursos de 4 semestres el catalogo es
 * pequeno, asi que no hace falta algo mas elaborado. */
int catalog_find_course_index(const Catalog *catalog, const char *code) {
    if (catalog == NULL || code == NULL) return -1;
    for (int i = 0; i < catalog->course_count; i++) {
        if (strcmp(catalog->courses[i].code, code) == 0) {
            return i;
        }
    }
    return -1;
}

/* anota en info (si no es NULL) donde fallo la carga */
static void set_error_info(LoadErrorInfo *info, int line, const char *course, const char *related) {
    if (info == NULL) return;
    info->line = line;
    safe_strcpy(info->course, MAX_CODE_LENGTH, course != NULL ? course : "");
    safe_strcpy(info->related, MAX_CODE_LENGTH, related != NULL ? related : "");
}

/* 1 si todo prerrequisito y correquisito apunta a un curso del catalogo.
 * Se revisa al final de la carga porque un requisito puede definirse en una linea posterior.
 * Si falla, info dice que curso pide que requisito inexistente. */
static int requisites_exist(const Catalog *catalog, LoadErrorInfo *info) {
    for (int i = 0; i < catalog->course_count; i++) {
        const Course *c = &catalog->courses[i];
        for (int p = 0; p < c->prerequisite_count; p++) {
            if (catalog_find_course_index(catalog, c->prerequisites[p]) == -1) {
                set_error_info(info, 0, c->code, c->prerequisites[p]);
                return 0;
            }
        }
        for (int q = 0; q < c->corequisite_count; q++) {
            if (catalog_find_course_index(catalog, c->corequisites[q]) == -1) {
                set_error_info(info, 0, c->code, c->corequisites[q]);
                return 0;
            }
        }
    }
    return 1;
}

/* Version simple de la carga, para quien no necesita el detalle del error. */
ErrorCode catalog_load(const char *path, Catalog *catalog) {
    return catalog_load_ex(path, catalog, NULL);
}

/* Carga todo el catalogo desde el archivo.
 * La politica es "todo o nada": ante el primer error se cierra el archivo,
 * se libera lo que ya se habia cargado y se devuelve el codigo de error.
 * Asi nunca queda un catalogo a medias ni memoria sin liberar. */
ErrorCode catalog_load_ex(const char *path, Catalog *catalog, LoadErrorInfo *info) {
    set_error_info(info, 0, NULL, NULL);

    if (catalog == NULL) return ERROR_INVALID_FORMAT;

    ErrorCode init_result = catalog_init(catalog);
    if (init_result != SUCCESS) return init_result;

    if (path == NULL) return ERROR_INVALID_FORMAT;


    FILE *file = fopen(path, "r");
    if (file == NULL) {
        return ERROR_FILE_NOT_FOUND;
    }

    char line[MAX_LINE_LENGTH];
    int line_number = 0;   /* para decirle al usuario en que linea esta el error */
    while (fgets(line, sizeof(line), file) != NULL) {
        line_number++;

        /* si el buffer se lleno sin llegar al salto de linea, la linea no cabe en MAX_LINE_LENGTH:
         * se rechaza en vez de leerla partida en pedazos */
        size_t raw_len = strlen(line);
        if (raw_len == sizeof(line) - 1 && line[raw_len - 1] != '\n' && !feof(file)) {
            set_error_info(info, line_number, NULL, NULL);
            fclose(file);
            catalog_free(catalog);
            return ERROR_LIMIT_EXCEEDED;
        }

        /* quita espacios y el '\n' (o "\r\n" si el archivo viene de Windows) */
        trim_whitespace(line);

        if (line[0] == '\0') continue;   /* linea vacia */
        if (line[0] == '#')  continue;   /* comentario */
        
        Course course;
        if (!parse_course_line(line, &course)) {
            /* parse_course_line deja el primer campo (el codigo) como inicio de 'line' */
            set_error_info(info, line_number, line, NULL);
            fclose(file);
            catalog_free(catalog);
            return ERROR_INVALID_FORMAT;
        }

        /* codigo repetido: el mismo curso aparece dos veces en el archivo */
        if (catalog_find_course_index(catalog, course.code) != -1) {
            set_error_info(info, line_number, course.code, NULL);
            fclose(file);
            catalog_free(catalog);
            return ERROR_INVALID_FORMAT;
        }

        ErrorCode add_result = catalog_add_course(catalog, &course);
        if (add_result != SUCCESS) {
            set_error_info(info, line_number, course.code, NULL);
            fclose(file);
            catalog_free(catalog);
            return add_result;
        }
    }

    fclose(file);

    /* ya con todos los cursos cargados se puede verificar que los requisitos existan */
    if (!requisites_exist(catalog, info)) {
        catalog_free(catalog);
        return ERROR_INCOMPLETE_DATA;
    }
    return SUCCESS;
}

/* Libera el arreglo de cursos. Como los structs guardan todo por valor
 * (sin punteros internos), un solo free alcanza. Se deja el catalogo en
 * NULL/0 para que llamarla dos veces no cause un doble free. */
void catalog_free(Catalog *catalog) {
    if (catalog == NULL) return;
    free(catalog->courses);
    catalog->courses = NULL;
    catalog->course_count = 0;
    catalog->capacity = 0;
}