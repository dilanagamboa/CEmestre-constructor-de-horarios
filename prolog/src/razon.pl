% razon de rechazo: primer regla violada y veredicto de una combinacion
% el veredicto se decide evaluando las reglas en el orden de diseno (D5) y
% quedandose con la primera que la combinacion incumple
%
% el orden vive en constantes:orden_reglas/1 y en ningun otro lugar, para
% poder cambiarlo en la defensa sin tocar este modulo ni las reglas
%
% uso:
%   evaluar_combinacion(Modulo, Combinacion, Veredicto)
%   Veredicto = cumple
%   Veredicto = viola(Regla, Detalle)
%
%   evaluar_con_orden(Modulo, Orden, Combinacion, Veredicto)
%   igual a /3 pero recibe el orden explicito, para probar que cambiar el
%   orden de evaluacion cambia la regla reportada, sin tocar constantes

:- module(razon, [
    evaluar_combinacion/3,
    evaluar_con_orden/4,
    primera_violacion/4,
    primera_con_orden/5
]).

:- use_module(constantes, [orden_reglas/1]).
:- use_module(reglas, [regla_violada/4]).

% ------------------------------------------------------------------------
% veredicto
% ------------------------------------------------------------------------

% evalua con el orden de diseno (D5), que vive en constantes:orden_reglas/1
evaluar_combinacion(Politica, Combinacion, Veredicto) :-
    orden_reglas(Reglas),
    evaluar_con_orden(Politica, Reglas, Combinacion, Veredicto).

% negacion por falla justificada: si ninguna regla del orden se viola, el
% veredicto es cumple; el -> es correcto porque no hay otra solucion que
% buscar (la pregunta es si existe al menos una violacion)
evaluar_con_orden(Politica, Orden, Combinacion, Veredicto) :-
    (   primera_con_orden(Politica, Orden, Combinacion, Regla, Detalle)
    ->  Veredicto = viola(Regla, Detalle)
    ;   Veredicto = cumple
    ).

% ------------------------------------------------------------------------
% primer regla violada, en el orden de diseno
% ------------------------------------------------------------------------

% recorre el orden de las reglas y se detiene en la primera que falla
% el corte es justificado: es la primera regla violada, asi que no hay que
% explorar las siguientes ni buscar mas detalles de la misma regla; el corte
% conmuta el "si" de arriba y evita ambos costos
primera_violacion(Politica, Combinacion, Regla, Detalle) :-
    orden_reglas(Reglas),
    primera_con_orden(Politica, Reglas, Combinacion, Regla, Detalle).

% recorre el orden dado y se detiene en la primera regla que falla
% el corte es justificado: es la primera regla violada, asi que no hay que
% explorar las siguientes ni buscar mas detalles de la misma regla; el corte
% conmuta el "si" de arriba y evita ambos costos
primera_con_orden(Politica, Orden, Combinacion, Regla, Detalle) :-
    primera_del_orden(Orden, Politica, Combinacion, Regla, Detalle).

primera_del_orden([Regla | _], Politica, Combinacion, Regla, Detalle) :-
    regla_violada(Regla, Politica, Combinacion, Detalle),
    !.
primera_del_orden([_ | Resto], Politica, Combinacion, Regla, Detalle) :-
    primera_del_orden(Resto, Politica, Combinacion, Regla, Detalle).

