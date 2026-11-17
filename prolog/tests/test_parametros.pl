% pruebas de parametros de la politica: cambiar porcentajes, N y pares
% incompatibles solo tocando el archivo de la politica, sin tocar el
% codigo; es la misma maniobra que se hace en la defensa
% uso desde la raiz del repositorio:
%   swipl -g run_tests -t halt prolog/tests/test_parametros.pl

:- module(test_parametros, []).

:- use_module(library(plunit)).
:- use_module('../src/cargar').
:- use_module('../src/razon').

% hechos cargados al abrir el modulo: las combinaciones de prueba y la
% ruta de la politica real; asi ningun predicado depende de variables
% capturadas en un directivo
:- dynamic combinacion_fixture/1.
:- dynamic ruta_real_fixture/1.

:- prolog_load_context(directory, Carpeta),
   atomic_list_concat([Carpeta, '/fixtures/combinaciones_prueba.jsonl'], RutaCombinaciones),
   leer_combinaciones(RutaCombinaciones, CombinacionesPrueba),
   maplist([C]>>assertz(combinacion_fixture(C)), CombinacionesPrueba),
   atomic_list_concat([Carpeta, '/../../data/combinaciones.jsonl'], RutaReal),
   assertz(ruta_real_fixture(RutaReal)),
   % test_cargar ya cargo data/politica.pl en prueba_politica_real; SWI no
   % permite cargar el mismo archivo en otro modulo, asi que se reutiliza
   % el mismo modulo (la re-consulta en el mismo modulo es valida)
   atomic_list_concat([Carpeta, '/../../data/politica.pl'], RutaPoliticaReal),
   maplist([Fixture, Modulo]>>
           (atomic_list_concat([Carpeta, '/fixtures/', Fixture], Ruta),
            cargar_politica(Ruta, Modulo)),
           ['politica_prueba.pl',
            'politica_59.pl',
            'politica_sin_maximo.pl',
            'politica_n3.pl',
            'politica_n1.pl',
            'politica_sin_pares.pl'],
           [prueba, prueba_59, sin_maximo, prueba_n3, prueba_n1, prueba_sin_pares]),
   cargar_politica(RutaPoliticaReal, prueba_politica_real).

% combinaciones de referencia en combinaciones_prueba.jsonl:
%  3: tres cursos de area fisica          -> limite_por_area si N < 3
%  6: solo fisica, 6 creditos             -> balance solo si fisica tiene maximo
%  7: solo computadores, 6 creditos       -> balance si computadores < 100 %
%  8: 6/10 de computadores = 60 % exacto
% 10: un solo curso de fisica, 2 creditos -> balance si fisica < 100 %
% 11: viola balance, limite e incompatibilidad
% 12: computadores EL2113 + fisica MT2001 -> incompatibilidad si el par esta declarado
combinacion_prueba(Id, combinacion(Id, Cursos)) :-
    once(combinacion_fixture(combinacion(Id, Cursos))).

:- begin_tests(parametros).

% el porcentaje exacto no se rechaza (comparacion entera, 60 % de 10)
test(porcentaje_exacto_no_viola) :-
    combinacion_prueba(8, Combinacion),
    once(evaluar_con_orden(prueba, [balance_carreras], Combinacion, Veredicto)),
    assertion(Veredicto == cumple).

% un punto por debajo del porcentaje exacto ya viola
test(porcentaje_un_punto_por_debajo_viola) :-
    combinacion_prueba(8, Combinacion),
    once(evaluar_con_orden(prueba_59, [balance_carreras], Combinacion, Veredicto)),
    assertion(Veredicto = viola(balance_carreras, _)).

% una sola carrera y por encima de su maximo
test(una_sola_carrera_computadores_viola) :-
    combinacion_prueba(7, Combinacion),
    once(evaluar_con_orden(prueba, [balance_carreras], Combinacion, Veredicto)),
    assertion(Veredicto = viola(balance_carreras, carrera(computadores, 6, 6, 60))).

% una sola carrera sin porcentaje declarado no viola (D6)
test(una_sola_carrera_fisica_sin_limite_cumple) :-
    combinacion_prueba(6, Combinacion),
    once(evaluar_con_orden(sin_maximo, [balance_carreras], Combinacion, Veredicto)),
    assertion(Veredicto == cumple).

% un solo curso y su carrera por encima del maximo
test(un_solo_curso_viola_por_su_carrera) :-
    combinacion_prueba(10, Combinacion),
    once(evaluar_con_orden(prueba, [balance_carreras], Combinacion, Veredicto)),
    assertion(Veredicto = viola(balance_carreras, carrera(fisica, 2, 2, 80))).

% subir N desactiva el limite por area para esa combinacion
test(subir_n_levanta_el_limite) :-
    combinacion_prueba(3, Combinacion),
    once(evaluar_con_orden(prueba_n3, [limite_por_area], Combinacion, Veredicto)),
    assertion(Veredicto == cumple).

% bajar N lo activa de nuevo
test(bajar_n_activa_el_limite) :-
    combinacion_prueba(3, Combinacion),
    once(evaluar_con_orden(prueba_n1, [limite_por_area], Combinacion, Veredicto)),
    assertion(Veredicto = viola(limite_por_area, area(fisica, 3, 1))).

% cambiar N no afecta a las otras reglas
test(cambiar_n_no_afecta_balance) :-
    combinacion_prueba(11, Combinacion),
    once(evaluar_con_orden(prueba_n3, [balance_carreras], Combinacion, Veredicto)),
    assertion(Veredicto = viola(balance_carreras, _)).

% agregar un par incompatible sin tocar el codigo: la combinacion 12 solo
% viola si el par esta declarado en la politica
test(par_declarado_viola) :-
    combinacion_prueba(12, Combinacion),
    once(evaluar_con_orden(prueba, [incompatibilidad], Combinacion, Veredicto)),
    assertion(Veredicto = viola(incompatibilidad, par(fisica-'MT2001', computadores-'EL2113'))).

test(par_no_declarado_no_viola) :-
    combinacion_prueba(12, Combinacion),
    once(evaluar_con_orden(prueba_sin_pares, [incompatibilidad], Combinacion, Veredicto)),
    assertion(Veredicto == cumple).

% cambiar el orden de las reglas cambia la razon reportada, no la validez
test(cambio_de_orden_cambia_la_razon) :-
    combinacion_prueba(11, Combinacion),
    once(evaluar_con_orden(prueba, [limite_por_area, balance_carreras], Combinacion, Veredicto1)),
    assertion(Veredicto1 = viola(limite_por_area, _)),
    once(evaluar_con_orden(prueba, [incompatibilidad, balance_carreras, limite_por_area], Combinacion, Veredicto2)),
    assertion(Veredicto2 = viola(incompatibilidad, _)).

% la politica real carga y toda la salida se puede evaluar; el tiempo se
% imprime en la traza, no se aserta, para que la prueba no dependa de la
% maquina
test(politica_real_evalua_las_2255_combinaciones) :-
    ruta_real_fixture(RutaReal),
    abrir_combinaciones(RutaReal, Entrada),
    statistics(runtime, [Antes|_]),
    forall(combinacion_leida(Entrada, Combinacion),
           evaluar_combinacion(prueba_politica_real, Combinacion, _)),
    close(Entrada),
    statistics(runtime, [Despues|_]),
    Tiempo is (Despues - Antes) / 1000,
    format("2255 combinaciones evaluadas con la politica real en ~3f s~n", [Tiempo]).

:- end_tests(parametros).
