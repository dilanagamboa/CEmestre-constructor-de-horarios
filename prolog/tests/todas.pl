% corre todas las suites de prolog
% uso desde la raiz del repositorio:
%   swipl -g run_tests -t halt prolog/tests/todas.pl

:- ensure_loaded(test_cargar).
:- ensure_loaded(test_reglas).