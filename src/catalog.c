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
 * - credits  : entero >= 0.
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
 * ------------------------------------------------------------------------- */

/* ============================ helpers ============================ */

static int parse_int(const char *s, int *out) {
    if (s == NULL || s[0] == '\0') return 0;
    char *end;
    long v = strtol(s, &end, 10);
    if (end == s || *end != '\0') return 0;
    if (v < 0 || v > 1000000) return 0;
    *out = (int)v;
    return 1;
}

static int parse_weekday(const char *s, Weekday *out) {
    if (strcmp(s, "MON") == 0) { *out = MONDAY;    return 1; }
    if (strcmp(s, "TUE") == 0) { *out = TUESDAY;   return 1; }
    if (strcmp(s, "WED") == 0) { *out = WEDNESDAY; return 1; }
    if (strcmp(s, "THU") == 0) { *out = THURSDAY;  return 1; }
    if (strcmp(s, "FRI") == 0) { *out = FRIDAY;    return 1; }
    if (strcmp(s, "SAT") == 0) { *out = SATURDAY;  return 1; }
    return 0;
}

static int parse_time(const char *s, int *hour, int *minute) {
    char buf[16];
    if (!safe_strcpy(buf, sizeof(buf), s)) return 0;

    char *parts[2];
    int n = split_fields(buf, ':', parts, 2);
    if (n != 2) return 0;

    int h, m;
    if (!parse_int(parts[0], &h)) return 0;
    if (!parse_int(parts[1], &m)) return 0;
    if (h > 23 || m > 59) return 0;

    *hour = h;
    *minute = m;
    return 1;
}

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

static int parse_group(char *s, Group *group) {
    char *parts[3];
    int n = split_fields(s, '@', parts, 3);
    if (n != 3) return 0;

    int number;
    if (!parse_int(parts[0], &number) || number <= 0) return 0;
    group->group_number = number;

    if (parts[1][0] == '\0') return 0;
    if (strlen(parts[1]) >= MAX_PROFESSOR_LENGTH) return 0;
    safe_strcpy(group->professor, MAX_PROFESSOR_LENGTH, parts[1]);

    group->block_count = 0;
    group->has_conflict = 0;

    if (parts[2][0] == '\0') {
        return 1; /* grupo sin bloques: valido pero sin horario */
    }

    char *blocks[MAX_BLOCKS_PER_GROUP];
    int bn = split_fields(parts[2], '+', blocks, MAX_BLOCKS_PER_GROUP);
    if (bn < 0 || bn == 0) return 0;

    for (int i = 0; i < bn; i++) {
        if (!parse_block(blocks[i], &group->blocks[i])) return 0;
    }
    group->block_count = bn;
    return 1;
}

static int parse_groups(char *field, Course *course) {
    course->group_count = 0;
    if (field[0] == '\0') return 1;

    char *parts[MAX_GROUPS_PER_COURSE];
    int n = split_fields(field, '|', parts, MAX_GROUPS_PER_COURSE);
    if (n < 0) return 0;

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

static int parse_codes_field(char *field,
                             char codes[][MAX_CODE_LENGTH],
                             int max_count,
                             int *out_count) {
    *out_count = 0;
    if (field[0] == '\0') return 1;

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

static int parse_course_line(char *line, Course *course) {
    memset(course, 0, sizeof(*course));

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

    course->can_enroll = 0;
    return 1;
}

/* ============================ public ============================ */

ErrorCode catalog_init(Catalog *catalog) {
    if (catalog == NULL) return ERROR_MEMORY_ALLOCATION;
    catalog->courses = NULL;
    catalog->course_count = 0;
    catalog->capacity = 0;
    return SUCCESS;
}

ErrorCode catalog_add_course(Catalog *catalog, const Course *course) {
    if (catalog == NULL || course == NULL) return ERROR_MEMORY_ALLOCATION;
    if (catalog->course_count >= MAX_COURSES) return ERROR_LIMIT_EXCEEDED;

    if (catalog->course_count >= catalog->capacity) {
        int new_capacity = (catalog->capacity == 0)
            ? CATALOG_INITIAL_CAPACITY
            : catalog->capacity * 2;
        if (new_capacity > MAX_COURSES) new_capacity = MAX_COURSES;

        Course *new_courses = realloc(catalog->courses,
                                      sizeof(Course) * (size_t)new_capacity);
        if (new_courses == NULL) {
            return ERROR_MEMORY_ALLOCATION;
        }
        catalog->courses = new_courses;
        catalog->capacity = new_capacity;
    }

    catalog->courses[catalog->course_count] = *course;
    catalog->course_count++;
    return SUCCESS;
}

int catalog_find_course_index(const Catalog *catalog, const char *code) {
    if (catalog == NULL || code == NULL) return -1;
    for (int i = 0; i < catalog->course_count; i++) {
        if (strcmp(catalog->courses[i].code, code) == 0) {
            return i;
        }
    }
    return -1;
}

/* 1 si todo prerrequisito y correquisito apunta a un curso del catalogo.
 * Se revisa al final de la carga porque un requisito puede definirse en una linea posterior. */
static int requisites_exist(const Catalog *catalog) {
    for (int i = 0; i < catalog->course_count; i++) {
        const Course *c = &catalog->courses[i];
        for (int p = 0; p < c->prerequisite_count; p++) {
            if (catalog_find_course_index(catalog, c->prerequisites[p]) == -1) return 0;
        }
        for (int q = 0; q < c->corequisite_count; q++) {
            if (catalog_find_course_index(catalog, c->corequisites[q]) == -1) return 0;
        }
    }
    return 1;
}

ErrorCode catalog_load(const char *path, Catalog *catalog) {
    if (catalog == NULL) return ERROR_INVALID_FORMAT;

    ErrorCode init_result = catalog_init(catalog);
    if (init_result != SUCCESS) return init_result;

    if (path == NULL) return ERROR_INVALID_FORMAT;


    FILE *file = fopen(path, "r");
    if (file == NULL) {
        return ERROR_FILE_NOT_FOUND;
    }

    char line[MAX_LINE_LENGTH];
    while (fgets(line, sizeof(line), file) != NULL) {
        trim_whitespace(line);

        if (line[0] == '\0') continue;
        if (line[0] == '#')  continue;
        
        Course course;
        if (!parse_course_line(line, &course)) {
            fclose(file);
            catalog_free(catalog);
            return ERROR_INVALID_FORMAT;
        }

        if (catalog_find_course_index(catalog, course.code) != -1) {
            fclose(file);
            catalog_free(catalog);
            return ERROR_INVALID_FORMAT;
        }

        ErrorCode add_result = catalog_add_course(catalog, &course);
        if (add_result != SUCCESS) {
            fclose(file);
            catalog_free(catalog);
            return add_result;
        }
    }

    fclose(file);

    if (!requisites_exist(catalog)) {
        catalog_free(catalog);
        return ERROR_INCOMPLETE_DATA;
    }
    return SUCCESS;
}

void catalog_free(Catalog *catalog) {
    if (catalog == NULL) return;
    free(catalog->courses);
    catalog->courses = NULL;
    catalog->course_count = 0;
    catalog->capacity = 0;
}