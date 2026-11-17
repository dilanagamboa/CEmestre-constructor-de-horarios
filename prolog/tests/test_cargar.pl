% pruebas de la carga de combinaciones y de la politica
% uso desde la raiz del repositorio:
%   swipl -g run_tests -t halt prolog/tests/test_cargar.pl

:- module(test_cargar, []).

:- use_module(library(plunit)).
:- use_module('../src/cargar').

% ruta de un archivo de prueba, relativa a esta carpeta, para que las
% pruebas corran desde cualquier directorio; si el fixture no existe la
% prueba falla, asi una prueba de error no pasa solo porque falta el archivo
fixture(Nombre, Ruta) :-
    module_property(test_cargar, file(Archivo)),
    file_directory_name(Archivo, Carpeta),
    atomic_list_concat([Carpeta, '/fixtures/', Nombre], Ruta),
    exists_file(Ruta).

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

:- begin_tests(cargar_politica).

test(politica_real) :-
    datos('politica.pl', Ruta),
    cargar_politica(Ruta, prueba_politica_real),
    hecho_politica(prueba_politica_real, max_cursos_por_area(N)),
    integer(N).

% sin porcentajes ni pares la politica es valida y esos hechos no tienen
% soluciones, en lugar de dar un error de predicado inexistente
test(politica_minima) :-
    fixture('politica_solo_area.pl', Ruta),
    cargar_politica(Ruta, prueba_politica_minima),
    \+ hecho_politica(prueba_politica_minima, max_porcentaje_carrera(_, _)),
    \+ hecho_politica(prueba_politica_minima, par_incompatible(_, _)).

test(politica_inexistente, throws(cemestre_error(_, _))) :-
    cargar_politica('no_existe.pl', prueba_politica_inexistente).

test(porcentaje_invalido, throws(cemestre_error(_, _))) :-
    fixture('politica_porcentaje_invalido.pl', Ruta),
    cargar_politica(Ruta, prueba_porcentaje_invalido).

test(sin_maximo_por_area, throws(cemestre_error(_, _))) :-
    fixture('politica_sin_max_area.pl', Ruta),
    cargar_politica(Ruta, prueba_sin_max_area).

test(maximo_por_area_cero, throws(cemestre_error(_, _))) :-
    fixture('politica_max_area_cero.pl', Ruta),
    cargar_politica(Ruta, prueba_max_area_cero).

test(carrera_desconocida, throws(cemestre_error(_, _))) :-
    fixture('politica_carrera_desconocida.pl', Ruta),
    cargar_politica(Ruta, prueba_carrera_desconocida).

test(par_repetido, throws(cemestre_error(_, _))) :-
    fixture('politica_par_repetido.pl', Ruta),
    cargar_politica(Ruta, prueba_par_repetido).

test(par_mismo_curso, throws(cemestre_error(_, _))) :-
    fixture('politica_par_mismo_curso.pl', Ruta),
    cargar_politica(Ruta, prueba_par_mismo_curso).

:- end_tests(cargar_politica).