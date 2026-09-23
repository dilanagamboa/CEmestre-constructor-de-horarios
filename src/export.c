#include <stdio.h>

#include "../include/export.h"
#include "../include/history.h"

/* -------------------------------------------------------------------------
 * Exporta el catalogo ya procesado a JSON, que es el contrato con la
 * Etapa 2 (Racket). El JSON se escribe a mano con fprintf/fputs, sin
 * librerias externas, cuidando comas, comillas y escapes para que el
 * archivo siempre sea valido.
 * ------------------------------------------------------------------------- */

/* ============================ helpers ============================ */

/* Pasa el enum Weekday al codigo de texto (MON, TUE...), el mismo que se
 * usa en catalogo.csv, para que entrada y salida sean consistentes. */
static const char *weekday_code(Weekday day) {
    switch (day) {
        case MONDAY:    return DAY_CODE_MONDAY;
        case TUESDAY:   return DAY_CODE_TUESDAY;
        case WEDNESDAY: return DAY_CODE_WEDNESDAY;
        case THURSDAY:  return DAY_CODE_THURSDAY;
        case FRIDAY:    return DAY_CODE_FRIDAY;
        case SATURDAY:  return DAY_CODE_SATURDAY;
        default:        return DAY_CODE_UNKNOWN;
    }
}

/* En C los booleanos son 0/1, pero en JSON tienen que ser true/false. */
static const char *json_bool(int value) {
    return value ? "true" : "false";
}

/* Escribe un string entre comillas, escapando los caracteres que romperian
 * el JSON (comillas, barra invertida, saltos de linea, etc.).
 * Se recorre como unsigned char para que las tildes y la n con tilde (UTF-8,
 * bytes >= 0x80) no se lean como negativos y se copien tal cual. */
static void write_json_string(FILE *out, const char *s) {
    fputc('"', out);
    for (const unsigned char *p = (const unsigned char *)s; *p != '\0'; p++) {
        switch (*p) {
            case '"':  fputs("\\\"", out); break;
            case '\\': fputs("\\\\", out); break;
            case '\n': fputs("\\n", out);  break;
            case '\r': fputs("\\r", out);  break;
            case '\t': fputs("\\t", out);  break;
            default:
                /* cualquier otro caracter de control se escribe como \uXXXX */
                if (*p < 0x20) {
                    fprintf(out, "\\u%04x", (unsigned int)*p);
                } else {
                    fputc((int)*p, out);
                }
        }
    }
    fputc('"', out);
}

/* Escribe ["A", "B"] o [] si no hay codigos. */
static void write_code_array(FILE *out,
                             const char codes[][MAX_CODE_LENGTH],
                             int count) {
    fputc('[', out);
    for (int i = 0; i < count; i++) {
        if (i > 0) fputs(", ", out);   /* coma solo entre elementos */
        write_json_string(out, codes[i]);
    }
    fputc(']', out);
}

/* Escribe un bloque como {"day": "MON", "start": "08:00", "end": "10:00"}.
 * %02d rellena con cero a la izquierda para que la hora siempre sea HH:MM. */
static void write_block(FILE *out, const TimeBlock *b) {
    fprintf(out, "{\"day\": \"%s\", \"start\": \"%02d:%02d\", \"end\": \"%02d:%02d\"}",
            weekday_code(b->day),
            b->start_hour, b->start_minute,
            b->end_hour, b->end_minute);
}

/* Escribe un grupo con su numero, profesor, bloques y si choca.
 * 'is_last' indica si es el ultimo del arreglo, porque JSON no acepta
 * una coma despues del ultimo elemento. */
static void write_group(FILE *out, const Group *g, int is_last) {
    fputs("        {\n", out);
    fprintf(out, "          \"number\": %d,\n", g->group_number);
    fputs("          \"professor\": ", out);
    write_json_string(out, g->professor);
    fputs(",\n", out);

    fputs("          \"blocks\": [", out);
    for (int i = 0; i < g->block_count; i++) {
        if (i > 0) fputs(", ", out);
        write_block(out, &g->blocks[i]);
    }
    fputs("],\n", out);

    fprintf(out, "          \"has_conflict\": %s\n", json_bool(g->has_conflict));
    fprintf(out, "        }%s\n", is_last ? "" : ",");
}

/* Un curso choca si al menos uno de sus grupos choca con otro curso. */
static int course_has_conflict(const Course *course) {
    for (int g = 0; g < course->group_count; g++) {
        if (course->groups[g].has_conflict) return 1;
    }
    return 0;
}

/* Escribe un curso completo con todos los campos que pide el enunciado:
 * codigo, nombre, creditos, grupos/horarios, requisitos, correquisitos,
 * si choca y si se puede matricular. Ademas se agrega "approved" para
 * que la Etapa 2 sepa que cursos ya aprobo el estudiante sin tener que
 * leer el historial por aparte. */
static void write_course(FILE *out,
                         const Course *c,
                         const StudentHistory *history,
                         int is_last) {
    fputs("    {\n", out);

    fputs("      \"code\": ", out);
    write_json_string(out, c->code);
    fputs(",\n", out);

    fputs("      \"name\": ", out);
    write_json_string(out, c->name);
    fputs(",\n", out);

    fprintf(out, "      \"credits\": %d,\n", c->credits);

    fputs("      \"prerequisites\": ", out);
    write_code_array(out, c->prerequisites, c->prerequisite_count);
    fputs(",\n", out);

    fputs("      \"corequisites\": ", out);
    write_code_array(out, c->corequisites, c->corequisite_count);
    fputs(",\n", out);

    /* un curso sin grupos se escribe como [] en una sola linea */
    if (c->group_count == 0) {
        fputs("      \"groups\": [],\n", out);
    } else {
        fputs("      \"groups\": [\n", out);
        for (int g = 0; g < c->group_count; g++) {
            write_group(out, &c->groups[g], g == c->group_count - 1);
        }
        fputs("      ],\n", out);
    }

    /* has_conflict del curso resume el de sus grupos; el detalle por grupo
     * queda dentro de "groups" para que la Etapa 2 elija grupos sin choque */
    fprintf(out, "      \"has_conflict\": %s,\n", json_bool(course_has_conflict(c)));
    fprintf(out, "      \"approved\": %s,\n",
            json_bool(history_has_course(history, c->code)));
    fprintf(out, "      \"can_enroll\": %s\n", json_bool(c->can_enroll));

    fprintf(out, "    }%s\n", is_last ? "" : ",");
}

/* ============================ public ============================ */

/* Escribe el JSON completo en un stream ya abierto. Recibir un FILE* en
 * vez de una ruta permite escribir tambien a stdout, lo cual sirve para
 * probar sin crear archivos. */
ErrorCode export_catalog_json_stream(FILE *out,
                                     const Catalog *catalog,
                                     const StudentHistory *history) {
    if (out == NULL || catalog == NULL || history == NULL) {
        return ERROR_INVALID_FORMAT;
    }

    /* encabezado: format_version permite que la Etapa 2 detecte si el
     * formato cambia en el futuro; course_count sirve de verificacion */
    fputs("{\n", out);
    fprintf(out, "  \"format_version\": %d,\n", OUTPUT_FORMAT_VERSION);
    fprintf(out, "  \"course_count\": %d,\n", catalog->course_count);

    if (catalog->course_count == 0) {
        fputs("  \"courses\": []\n", out);
    } else {
        fputs("  \"courses\": [\n", out);
        for (int i = 0; i < catalog->course_count; i++) {
            write_course(out, &catalog->courses[i], history,
                         i == catalog->course_count - 1);
        }
        fputs("  ]\n", out);
    }

    fputs("}\n", out);

    /* en vez de revisar cada fputs, se revisa una vez al final: ferror
     * queda activo si cualquier escritura anterior fallo */
    if (ferror(out)) {
        return ERROR_FILE_WRITE;
    }
    return SUCCESS;
}

/* Abre (o crea) el archivo de salida, escribe el JSON y lo cierra. */
ErrorCode export_catalog_json(const char *path,
                              const Catalog *catalog,
                              const StudentHistory *history) {
    if (path == NULL || catalog == NULL || history == NULL) {
        return ERROR_INVALID_FORMAT;
    }

    /* "w" crea el archivo o lo sobreescribe si ya existia */
    FILE *out = fopen(path, "w");
    if (out == NULL) {
        return ERROR_FILE_WRITE;   /* ej. la carpeta no existe o no hay permisos */
    }

    ErrorCode result = export_catalog_json_stream(out, catalog, history);

    /* fclose puede fallar al vaciar el buffer (disco lleno, por ejemplo) */
    if (fclose(out) != 0 && result == SUCCESS) {
        result = ERROR_FILE_WRITE;
    }
    return result;
}