% pruebas del modulo razon: veredicto y orden de las reglas
% uso desde la raiz del repositorio:
%   swipl -g run_tests -t halt prolog/tests/test_razon.pl

:- module(test_razon, []).

:- use_module(library(plunit)).
:- use_module('../src/cargar').
:- use_module('../src/razon').

% las dos politicas de prueba se cargan en modulos distintos, igual que en
% test_reglas.pl
:- prolog_load_context(directory, Carpeta),
   atomic_list_concat([Carpeta, '/fixtures/politica_prueba.pl'], Prueba),
   atomic_list_concat([Carpeta, '/fixtures/politica_sin_maximo.pl'], SinMaximo),
   cargar_politica(Prueba, prueba),
   cargar_politica(SinMaximo, sin_maximo),
   atomic_list_concat([Carpeta, '/fixtures/esperados.pl'], Esperados),
   consult(Esperados).

combinacion_prueba(Id, combinacion(Id, Cursos)) :-
    module_property(test_razon, file(Archivo)),
    file_directory_name(Archivo, Carpeta),
    atomic_list_concat([Carpeta, '/fixtures/combinaciones_prueba.jsonl'], Ruta),
    leer_combinaciones(Ruta, Combinaciones),
    member(combinacion(Id, Cursos), Combinaciones).

veredicto_coincide(Politica, Id, Cumple, Regla) :-
    combinacion_prueba(Id, Combinacion),
    evaluar_combinacion(Politica, Combinacion, Veredicto),
    (   Cumple == true
    ->  (   Veredicto == cumple,
            Regla == ninguna
        )
    ;   Veredicto = viola(Reportada, _),
        Reportada == Regla,
        Regla \== ninguna
    ).

% cambiar el orden de las reglas cambia la regla reportada (razon/0 en la
% primera violacion); la combinacion viola siempre las mismas reglas, pero
% la primera del orden es la que se reporta
veredicto_con_orden(Orden, Politica, Id, Regla) :-
    combinacion_prueba(Id, Combinacion),
    evaluar_con_orden(Politica, Orden, Combinacion, Veredicto),
    Veredicto = viola(Reportada, _),
    Reportada == Regla.

:- begin_tests(razon).

% tabla de resultados esperados, calculada a mano (ver fixtures/esperados.pl)
test(esperados_por_defecto, true) :-
    forall(esperado(Politica, Id, Cumple, Regla),
           veredicto_coincide(Politica, Id, Cumple, Regla)).

% probar solo limitar por area no basta: con sin_maximo, el 100 % de fisica
% no viola balance (no tiene maximo definido), asi que los mismos ids
% cumplen
test(sin_limite_por_complementario, true) :-
    forall(esperado(sin_maximo, Id, Cumple, Regla),
           veredicto_coincide(sin_maximo, Id, Cumple, Regla)).

% casos en que cambiar el orden de las reglas cambia la razon reportada
test(cambio_de_orden_cambia_razon, true) :-
    forall(esperado_orden(Orden, Politica, Id, Regla),
           veredicto_con_orden(Orden, Politica, Id, Regla)).

% la evaluacion con el orden explicito siempre cae en violar la union de
% las reglas que de hecho se violan, en cualquier orden: el conjunto de
% reglas violadas no depende del orden, solo la primera
test(el_orden_cambia_la_primera_mas_no_la_regla, true) :-
    once(combinacion_prueba(11, Combinacion)),
    forall(member(Orden, [[balance_carreras, limite_por_area, incompatibilidad],
                          [incompatibilidad, balance_carreras, limite_por_area],
                          [limite_por_area, incompatibilidad, balance_carreras]]),
           (   evaluar_con_orden(prueba, Orden, Combinacion, viola(Regla, _))
           ->  memberchk(Regla, [balance_carreras, limite_por_area, incompatibilidad])
           )).

:- end_tests(razon).
