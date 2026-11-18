% main.pl
% Programa principal de la etapa 3.
% Lee combinaciones de un archivo JSONL, las evalúa contra la política,
% y escribe los resultados en otro archivo JSONL, uno por línea.
% Codificación: todos los archivos se tratan como UTF-8, asi que el archivo
% se declara con encoding(utf8) para evitar warnings de secuencias multibyte
% ilegales (los datos reales traen tildes y caracteres especiales).

:- encoding(utf8).

:- use_module(library(lists)).
:- use_module(cargar, [
    abrir_combinaciones/2,
    combinacion_leida/2,
    cargar_politica/2
]).
:- use_module(razon, [evaluar_combinacion/3]).
:- use_module(exportar, [escribir_resultado/3]).
:- use_module(constantes).

% ------------------------------------------------------------------------
% flujo principal: evalua combinaciones y escribe resultados
% ------------------------------------------------------------------------
% Código de salida 0 con éxito; distinto de cero ante cualquier error,
% capturado aquí para que swipl -g main -t halt informe el fallo.
main :-
    (   catch(flujo_principal, Error, imprimir_error(Error))
    ->  true
    ;   halt(1)
    ).

% flujo_principal/0
% Flujo completo: parsea argumentos, carga la política, recorre las
% combinaciones por backtracking y escribe cada resultado al evaluarlo.
% Errores controlados se lanzan como cemestre_error/2.

flujo_principal :-
    (   current_prolog_flag(argv, Args),
        Args \= []
    ->  parse_args(Args, CombinacionesFile, PoliticaFile, SalidaFile)
    ;   ruta_combinaciones_defecto(CombinacionesFile),
        ruta_politica_defecto(PoliticaFile),
        ruta_salida_defecto(SalidaFile)
    ),
    (   modulo_politica(Modulo),
        cargar_politica(PoliticaFile, Modulo)
    ->  true
    ;   throw(cemestre_error("no se pudo cargar la política desde ~w", [PoliticaFile]))
    ),
    abrir_combinaciones(CombinacionesFile, Entrada),
    (   catch(open(SalidaFile, write, Salida), Error, manejo_error_apertura(SalidaFile, Error, Entrada))
    ->  call_cleanup(
            forall(combinacion_leida(Entrada, Combinacion),
                   evaluar_y_escribir(Modulo, Combinacion, Salida)),
            (   close(Entrada),
                close(Salida)
            )
        ),
        format("Evaluación completada. Resultados en ~w~n", [SalidaFile])
    ;   close(Entrada),
        throw(cemestre_error("no se pudo abrir el archivo de salida ~w", [SalidaFile]))
    ).

% manejo_error_apertura(+Ruta, +Error, +Entrada)
% El open/3 puede fallar con existence_error si la carpeta de salida no
% existe o con permission_error si no se puede escribir; en lugar de
% dejar que swipl informe una traza interna, se lanza un cemestre_error
% con un mensaje claro y se cierra la entrada para no dejarla abierta.
% El error de open/3 llega envuelto en error/2 (existence_error o
% permission_error como subtérmino, más el contexto de system:open/3).
manejo_error_apertura(Ruta, Error, Entrada) :-
    close(Entrada),
    (   Error = error(existence_error(_, Ruta), _)
    ->  throw(cemestre_error("no se puede crear el archivo de salida ~w: la carpeta no existe o no es accesible", [Ruta]))
    ;   Error = error(permission_error(_, _, Ruta), _)
    ->  throw(cemestre_error("no se puede escribir el archivo de salida ~w: permisos insuficientes", [Ruta]))
    ;   throw(cemestre_error("no se pudo abrir el archivo de salida ~w: ~w", [Ruta, Error]))
    ).

% ------------------------------------------------------------------------
% errores: mensaje claro y código de salida distinto de cero
% ------------------------------------------------------------------------

% imprimir_error(+Error)
% Informa el error y para con código distinto de cero.
imprimir_error(Error) :-
    (   Error = cemestre_error(Formato, Argumentos)
    ->  format(user_error, "error: ", []),
        format(user_error, Formato, Argumentos),
        nl(user_error)
    ;   format(user_error, "error inesperado: ~p~n", [Error])
    ),
    halt(1).

% ------------------------------------------------------------------------
% entrada: rutas por argumento o por defecto
% ------------------------------------------------------------------------

% parse_args/4 extrae las rutas de los argumentos o usa los valores por defecto
parse_args([CombFile, PolFile, SalFile | _], CombFile, PolFile, SalFile) :- !.
parse_args([CombFile, PolFile], CombFile, PolFile, SalidaFile) :-
    ruta_salida_defecto(SalidaFile).
parse_args([CombFile], CombFile, PoliticaFile, SalidaFile) :-
    ruta_politica_defecto(PoliticaFile),
    ruta_salida_defecto(SalidaFile).
parse_args([], CombFile, PoliticaFile, SalidaFile) :-
    ruta_combinaciones_defecto(CombFile),
    ruta_politica_defecto(PoliticaFile),
    ruta_salida_defecto(SalidaFile).

% ------------------------------------------------------------------------
% salida: un registro por combinación, escrito al evaluarla
% ------------------------------------------------------------------------

% evaluar_y_escribir/3 evalúa una combinación y escribe el resultado;
% la política se carga siempre en el módulo declarado en constantes:modulo_politica/1.
evaluar_y_escribir(Modulo, Combinacion, Salida) :-
    evaluar_combinacion(Modulo, Combinacion, Veredicto),
    escribir_resultado(Combinacion, Veredicto, Salida).

% uso desde la raiz del repositorio:
%   swipl -g main -t halt prolog/src/main.pl
%   swipl -g main -t halt prolog/src/main.pl data/combinaciones.jsonl data/politica.pl data/resultados.jsonl
% sin argumentos usa las rutas por defecto de constantes.pl
%
% errores: imprime el mensaje de cemestre_error/2 en stderr y termina con
% codigo de salida 1, distinto de cero, como exige el enunciado
%
% Nota de uso: no hay initialization(main, main) a propósito; el predicado se
% invoca desde la línea de comandos con -g main -t halt para que corra una
% sola vez por ejecución.

