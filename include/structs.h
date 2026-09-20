#ifndef STRUCTS_H
#define STRUCTS_H

#include "constants.h"

// se usa un enum en vez de strings para comparar horarios de forma más rápida y sin errores de typing
typedef enum {
    MONDAY,
    TUESDAY,
    WEDNESDAY,
    THURSDAY,
    FRIDAY,
    SATURDAY
} Weekday;

// las horas se guardan en formato 24 horas, separando hora y minuto
typedef struct {
    Weekday day;
    int start_hour;
    int start_minute;
    int end_hour;
    int end_minute;
} TimeBlock;

// un curso puede tener varios grupos, y cada grupo puede tener varios días a la semana (bloques)
typedef struct {
    int group_number;
    char professor[MAX_PROFESSOR_LENGTH];
    TimeBlock blocks[MAX_BLOCKS_PER_GROUP];
    int block_count;
    int has_conflict; // validación en la fase de detección de choques, 1 si choca con otro grupo
} Group;

// representa un curso completo del plan de estudios
// requisitos y correquisitos se guardan como arreglos de códigos, no como punteros
typedef struct {
    char code[MAX_CODE_LENGTH];
    char name[MAX_NAME_LENGTH];
    int credits;

    char prerequisites[MAX_PREREQUISITES][MAX_CODE_LENGTH];
    int prerequisite_count;

    char corequisites[MAX_COREQUISITES][MAX_CODE_LENGTH];
    int corequisite_count;

    Group groups[MAX_GROUPS_PER_COURSE];
    int group_count;

    int can_enroll; // se llena en la fase de validación de requisitos, 1 si el estudiante lo puede matricular
} Course;

// catálogo completo de una carrera, con memoria dinámica porque no se sabe cuántos cursos van a cargarse
// crece con realloc en catalog_add_course() y se libera con catalog_free()
typedef struct {
    Course *courses;
    int course_count;
    int capacity;
} Catalog;

// historial de cursos ya aprobados por el estudiante
typedef struct {
    char approved_courses[MAX_APPROVED_COURSES][MAX_CODE_LENGTH];
    int approved_count;
} StudentHistory;

// detalle de un error de carga del catalogo, para que main pueda decir donde esta el problema
typedef struct {
    int line;                       // numero de linea del archivo (desde 1), 0 si no aplica
    char course[MAX_CODE_LENGTH];   // codigo del curso involucrado, vacio si no se conoce
    char related[MAX_CODE_LENGTH];  // codigo relacionado (por ejemplo el requisito inexistente)
} LoadErrorInfo;

#endif