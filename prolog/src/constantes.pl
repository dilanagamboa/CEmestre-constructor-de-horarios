% constantes de la etapa 3
% rutas por defecto, carreras validas y nombres de las reglas en un solo
% lugar, para que ningun otro modulo tenga estos valores escritos

:- module(constantes, [
    ruta_combinaciones_defecto/1,
    ruta_politica_defecto/1,
    ruta_salida_defecto/1,
    modulo_politica/1,
    carrera_valida/1,
    orden_reglas/1,
    regla/2
]).

% rutas relativas a la raiz del repositorio
ruta_combinaciones_defecto('data/combinaciones.jsonl').
ruta_politica_defecto('data/politica.pl').
ruta_salida_defecto('data/resultados.jsonl').

% modulo donde se cargan los hechos de data/politica.pl; las reglas reciben
% este nombre como argumento, asi que dos politicas pueden convivir en las
% pruebas sin estado global
modulo_politica(politica).

% carreras que puede nombrar el archivo de politica
carrera_valida(computadores).
carrera_valida(fisica).

% orden de evaluacion de las reglas (decision D5); la razon de rechazo es
% la primera regla de esta lista que la combinacion viola, de modo que
% cambiar el orden aqui cambia la razon reportada sin tocar nada mas
orden_reglas([balance_carreras, limite_por_area, incompatibilidad]).

% codigo de cada regla y su descripcion para la salida
regla(balance_carreras, "Balance entre carreras").
regla(limite_por_area, "Limite de cursos por area").
regla(incompatibilidad, "Cursos incompatibles").