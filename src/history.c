#include <stdio.h>
#include <string.h>
#include "../include/history.h"
#include "../include/utils.h"

void history_init(StudentHistory *history) {
    history->approved_count = 0;
}

int history_has_course(const StudentHistory *history, const char *code) {
    for (int i = 0; i < history->approved_count; i++) {
        if (strcmp(history->approved_courses[i], code) == 0) {
            return 1;
        }
    }
    return 0;
}

ErrorCode history_load(const char *path, const Catalog *catalog, StudentHistory *history) {
    FILE *file = fopen(path, "r");
    if (file == NULL) {
        return ERROR_FILE_NOT_FOUND;
    }

    history_init(history);

    char line[MAX_LINE_LENGTH];
    while (fgets(line, sizeof(line), file) != NULL) {
        trim_whitespace(line);

        // líneas vacías se ignoran
        if (line[0] == '\0') {
            continue;
        }

        // un código que no cabe en MAX_CODE_LENGTH ya es un dato mal transcrito
        if (strlen(line) >= MAX_CODE_LENGTH) {
            fclose(file);
            return ERROR_INVALID_FORMAT;
        }

        // el código debe existir en el catálogo ya cargado
        if (catalog_find_course_index(catalog, line) == -1) {
            fclose(file);
            return ERROR_COURSE_NOT_FOUND;
        }

        // un curso repetido en el historial no es posible
        if (history_has_course(history, line)) {
            fclose(file);
            return ERROR_INVALID_FORMAT;
        }

        if (history->approved_count >= MAX_APPROVED_COURSES) {
            fclose(file);
            return ERROR_LIMIT_EXCEEDED;
        }

        safe_strcpy(history->approved_courses[history->approved_count], MAX_CODE_LENGTH, line);
        history->approved_count++;
    }

    fclose(file);

    // historial vacío no es problema
    return SUCCESS;
}