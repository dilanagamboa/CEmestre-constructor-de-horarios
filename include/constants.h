#ifndef CONSTANTS_H
#define CONSTANTS_H

// todas las constantes del proyecto viven acá, separadas de structs.h

// límites de tamaño para strings, para evitar usar malloc en todo lado
#define MAX_CODE_LENGTH        10
#define MAX_NAME_LENGTH        80
#define MAX_PROFESSOR_LENGTH   60

// límites de cantidad
#define MAX_COURSES            200
#define MAX_GROUPS_PER_COURSE  40
#define MAX_BLOCKS_PER_GROUP   3    // un grupo puede tener hasta 3 días de clases a la semana
#define MAX_PREREQUISITES      6
#define MAX_COREQUISITES       4
#define MAX_APPROVED_COURSES   60

// tamaño máximo de una línea leída de catalogo.csv o historial.csv
#define MAX_LINE_LENGTH         4096

// rutas por defecto de los archivos de entrada y salida
// se pueden sobreescribir si el programa recibe argumentos por consola
#define DEFAULT_CATALOG_PATH   "data/catalogo.csv"
#define DEFAULT_HISTORY_PATH   "data/historial.csv"
#define DEFAULT_OUTPUT_PATH    "data/salida.json"

// códigos de error que se usan como valor de retorno en las funciones de carga
typedef enum {
    SUCCESS = 0,
    ERROR_FILE_NOT_FOUND = 1,
    ERROR_INVALID_FORMAT = 2,
    ERROR_INCOMPLETE_DATA = 3,
    ERROR_MEMORY_ALLOCATION = 4,
    ERROR_COURSE_NOT_FOUND = 5,
    ERROR_LIMIT_EXCEEDED = 6,
    ERROR_FILE_WRITE = 7
} ErrorCode;

#define OUTPUT_FORMAT_VERSION  1

// codigos de dia que se escriben en el archivo de salida (mismos que usa catalogo.csv)
#define DAY_CODE_MONDAY        "MON"
#define DAY_CODE_TUESDAY       "TUE"
#define DAY_CODE_WEDNESDAY     "WED"
#define DAY_CODE_THURSDAY      "THU"
#define DAY_CODE_FRIDAY        "FRI"
#define DAY_CODE_SATURDAY      "SAT"
#define DAY_CODE_UNKNOWN       "UNK"

#endif