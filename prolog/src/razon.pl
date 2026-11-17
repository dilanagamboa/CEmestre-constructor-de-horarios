% Módulo razon: determina si una combinación cumple o viola una regla
% Define el orden de las reglas (Id, Regla)
% Decide la razón y el veredicto para la Etapa 3.

:- module(razon, [evaluar_combinacion/3]).

:- use_module(reglas, [regla_violada/4]).

% Orden de las reglas definido aquí para la defensa
orden_reglas([
    balance_carreras,
    limite_por_area,
    incompatibilidad
]).

% Evalúa una combinación contra la política y devuelve:
% cumple o viola(Regla, Detalle)
evaluar_combinacion(Politica, Combinacion, Veredicto) :-
    orden_reglas(Reglas),
    (   buscar_violacion(Reglas, Politica, Combinacion, Regla, Detalle)
    ->  Veredicto = viola(Regla, Detalle)
    ;   Veredicto = cumple
    ).

% Recorre las reglas en orden hasta encontrar la primera violada
buscar_violacion([Regla | Resto], Politica, Combinacion, Regla, Detalle) :-
    % Usamos negación por falla justificada:
    % Si regla_violada tiene éxito, es porque se encontró una violación.
    % El corte (!) asegura que si encontramos una violación, no buscamos otras reglas.
    regla_violada(Regla, Politica, Combinacion, Detalle),
    !.
buscar_violacion([_ | Resto], Politica, Combinacion, Regla, Detalle) :-
    buscar_violacion(Resto, Politica, Combinacion, Regla, Detalle).
