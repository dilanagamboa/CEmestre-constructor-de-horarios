#include <stdio.h>
#include "../include/catalog.h"
#include "../include/history.h"
#include "../include/conflicts.h"
#include "../include/validation.h"
#include "../include/export.h"

int main(void) {
    Catalog catalog;
    StudentHistory history;

    if (catalog_load("data/catalogo.csv", &catalog) != SUCCESS) {
        return 1;
    }
    if (history_load("data/historial.csv", &catalog, &history) != SUCCESS) {
        catalog_free(&catalog);
        return 1;
    }

    conflicts_detect_catalog(&catalog);
    validation_mark_enrollable(&catalog, &history);

    ErrorCode err = export_catalog_json_stream(stdout, &catalog, &history);

    catalog_free(&catalog);
    return (int)err;
}