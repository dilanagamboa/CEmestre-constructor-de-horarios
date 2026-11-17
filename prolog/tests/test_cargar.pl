% pruebas de la carga de combinaciones
% uso desde la raiz del repositorio:
%   swipl -g run_tests -t halt prolog/tests/test_cargar.pl

:- module(test_cargar, []).

:- use_module(library(plunit)).
:- use_module('../src/cargar').

% ruta de un archivo de prueba, relativa a esta carpeta, para que las
% pruebas corran desde cualquier directorio
fixture(Nombre, Ruta) :-
    module_property(test_cargar, file(Archivo)),
    file_directory_name(Archivo, Carpeta),
    atomic_list_concat([Carpeta, '/fixtures/', Nombre], Ruta).

datos(Nombre, Ruta) :-
    module_property(test_cargar, file(Archivo)),
    file_directory_name(Archivo, Carpeta),
    atomic_list_concat([Carpeta, '/../../data/', Nombre], Ruta).

% numero de linea de un error de carga
linea_error(Objetivo, Linea) :-
    catch(Objetivo, cemestre_error(_, [Linea | _]), true).

:- begin_tests(cargar_combinaciones).

test(cantidad) :-
    fixture('combinaciones_prueba.jsonl', Ruta),
    leer_combinaciones(Ruta, Combinaciones),
    length(Combinaciones, 13).

test(primer_termino) :-
    fixture('combinaciones_prueba.jsonl', Ruta),
    leer_combinaciones(Ruta, [Primera | _]),
    Primera == combinacion(1, [curso('CE2103', 1, 4, computadores, programacion),
                               curso('MA1103', 1, 4, fisica, matematica),
                               curso('CS3404', 1, 2, fisica, humanidades)]).

% recorrido por backtracking: cada solucion es una combinacion distinta y
% los ids salen en el orden del archivo
test(backtracking, Ids == [1,2,3,4,5,6,7,8,9,10,11,12,13]) :-
    fixture('combinaciones_prueba.jsonl', Ruta),
    abrir_combinaciones(Ruta, Entrada),
    call_cleanup(findall(Id, combinacion_leida(Entrada, combinacion(Id, _)), Ids),
                 close(Entrada)).

test(archivo_vacio, Combinaciones == []) :-
    fixture('combinaciones_vacio.jsonl', Ruta),
    leer_combinaciones(Ruta, Combinaciones).

% las lineas en blanco y los finales de linea de Windows no afectan
test(lineas_vacias_y_crlf, Ids == [1, 7]) :-
    fixture('combinaciones_lineas_vacias.jsonl', Ruta),
    leer_combinaciones(Ruta, Combinaciones),
    findall(Id, member(combinacion(Id, _), Combinaciones), Ids).

test(archivo_inexistente, throws(cemestre_error(_, _))) :-
    leer_combinaciones('no_existe.jsonl', _).

test(linea_corrupta, Linea == 2) :-
    fixture('combinaciones_corrupta.jsonl', Ruta),
    linea_error(leer_combinaciones(Ruta, _), Linea).

test(campo_faltante, Args == [1, area]) :-
    fixture('combinaciones_sin_area.jsonl', Ruta),
    catch(leer_combinaciones(Ruta, _), cemestre_error(_, Args), true).

% el archivo real de racket se carga completo y cada curso trae su area
test(datos_reales) :-
    datos('combinaciones.jsonl', Ruta),
    leer_combinaciones(Ruta, Combinaciones),
    length(Combinaciones, N),
    N > 0,
    forall(member(combinacion(_, Cursos), Combinaciones),
           forall(member(curso(_, _, _, _, Area), Cursos), atom(Area))).

:- end_tests(cargar_combinaciones).