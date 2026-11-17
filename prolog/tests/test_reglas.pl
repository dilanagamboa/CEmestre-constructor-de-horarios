% pruebas de las tres reglas de politica, cada una por separado
% uso desde la raiz del repositorio:
%   swipl -g run_tests -t halt prolog/tests/test_reglas.pl

:- module(test_reglas, []).

:- use_module(library(plunit)).
:- use_module(library(lists)).
:- use_module('../src/cargar').
:- use_module('../src/reglas').

% las dos politicas de prueba se cargan en modulos distintos, de modo que
% las mismas combinaciones se evaluan con valores diferentes sin estado
% global
:- prolog_load_context(directory, Carpeta),
   atomic_list_concat([Carpeta, '/fixtures/politica_prueba.pl'], Prueba),
   atomic_list_concat([Carpeta, '/fixtures/politica_sin_maximo.pl'], SinMaximo),
   cargar_politica(Prueba, prueba),
   cargar_politica(SinMaximo, sin_maximo).

combinacion_prueba(Id, Combinacion) :-
    module_property(test_reglas, file(Archivo)),
    file_directory_name(Archivo, Carpeta),
    atomic_list_concat([Carpeta, '/fixtures/combinaciones_prueba.jsonl'], Ruta),
    leer_combinaciones(Ruta, Combinaciones),
    memberchk(combinacion(Id, Cursos), Combinaciones),
    Combinacion = combinacion(Id, Cursos).

% reglas que viola una combinacion, sin repetir y en orden alfabetico
reglas_violadas(Politica, Id, Reglas) :-
    combinacion_prueba(Id, Combinacion),
    findall(R, regla_violada(R, Politica, Combinacion, _), Lista),
    sort(Lista, Reglas).

% todas las reglas que viola cada combinacion, calculadas a mano
% (esperados.pl solo tiene la primera en el orden de diseno)
% politica_prueba.pl: computadores 60 %, fisica 80 %, N = 2
viola(prueba,  1, []).
viola(prueba,  2, [balance_carreras]).                                     % computadores 8 de 10
viola(prueba,  3, [limite_por_area]).                                      % tres de fisica
viola(prueba,  4, [incompatibilidad]).                                     % FI1102 en las dos carreras
viola(prueba,  5, [balance_carreras, limite_por_area]).                    % 8 de 12 y tres de matematica
viola(prueba,  6, [balance_carreras]).                                     % solo fisica
viola(prueba,  7, [balance_carreras]).                                     % solo computadores
viola(prueba,  8, []).                                                     % 60 % exacto
viola(prueba,  9, [incompatibilidad, limite_por_area]).
viola(prueba, 10, [balance_carreras]).                                     % un solo curso
viola(prueba, 11, [balance_carreras, incompatibilidad, limite_por_area]).
viola(prueba, 12, [incompatibilidad]).                                     % par declarado al reves
viola(prueba, 13, [balance_carreras]).                                     % fisica 10 de 12
% politica_sin_maximo.pl: igual, pero fisica no tiene porcentaje
viola(sin_maximo,  1, []).
viola(sin_maximo,  2, [balance_carreras]).
viola(sin_maximo,  3, [limite_por_area]).
viola(sin_maximo,  4, [incompatibilidad]).
viola(sin_maximo,  5, [balance_carreras, limite_por_area]).
viola(sin_maximo,  6, []).
viola(sin_maximo,  7, [balance_carreras]).
viola(sin_maximo,  8, []).
viola(sin_maximo,  9, [incompatibilidad, limite_por_area]).
viola(sin_maximo, 10, []).
viola(sin_maximo, 11, [balance_carreras, incompatibilidad, limite_por_area]).
viola(sin_maximo, 12, [incompatibilidad]).
viola(sin_maximo, 13, []).

:- begin_tests(reglas).

% una prueba por combinacion y politica, generada desde la tabla viola/3
test(tabla, [forall(viola(Politica, Id, Esperadas)), Reglas == Esperadas]) :-
    reglas_violadas(Politica, Id, Reglas).

test(detalle_balance, Detalles == [carrera(computadores, 8, 10, 60)]) :-
    combinacion_prueba(2, C),
    findall(D, regla_violada(balance_carreras, prueba, C, D), Detalles).

% el limite exacto (60 de 100) no se considera superado
test(balance_limite_exacto, fail) :-
    combinacion_prueba(8, C),
    regla_violada(balance_carreras, prueba, C, _).

test(detalle_area, Detalles == [area(matematica, 3, 2)]) :-
    combinacion_prueba(5, C),
    findall(D, regla_violada(limite_por_area, prueba, C, D), Detalles).

% la combinacion tiene MT2001 antes que EL2113 y la politica declara el par
% al reves; aun asi se detecta una sola vez
test(detalle_incompatibilidad, Detalles == [par(fisica-'MT2001', computadores-'EL2113')]) :-
    combinacion_prueba(12, C),
    findall(D, regla_violada(incompatibilidad, prueba, C, D), Detalles).

:- end_tests(reglas).

:- begin_tests(auxiliares).

test(creditos_totales, Total == 12) :-
    combinacion_prueba(13, combinacion(_, Cursos)),
    creditos_totales(Cursos, Total).

% modo enumerar: Carrera libre
test(creditos_por_carrera_enumerar, Pares == [computadores-4, fisica-6]) :-
    combinacion_prueba(1, combinacion(_, Cursos)),
    findall(K-Cr, creditos_de_carrera(Cursos, K, Cr), Pares).

% modo verificar: Carrera y Creditos dados
test(creditos_por_carrera_verificar, [nondet]) :-
    combinacion_prueba(1, combinacion(_, Cursos)),
    creditos_de_carrera(Cursos, fisica, 6).

test(creditos_carrera_ausente, fail) :-
    combinacion_prueba(7, combinacion(_, Cursos)),
    creditos_de_carrera(Cursos, fisica, _).

test(cursos_de_area, [nondet, Codigos == ['FI1102', 'MI2106', 'FI2103']]) :-
    combinacion_prueba(3, combinacion(_, Cursos)),
    cursos_de_area(Cursos, fisica, Codigos).

% incompatibles/3 en sus dos modos y en los dos ordenes del par
test(incompatibles_verificar, [nondet]) :-
    incompatibles(prueba, computadores-'EL2113', fisica-'MT2001'),
    incompatibles(prueba, fisica-'MT2001', computadores-'EL2113').

test(incompatibles_buscar, Otros == [fisica-'MT2001']) :-
    findall(X, incompatibles(prueba, computadores-'EL2113', X), Otros).

test(incompatibles_no_declarado, fail) :-
    incompatibles(prueba, computadores-'CE2103', _).

:- end_tests(auxiliares).