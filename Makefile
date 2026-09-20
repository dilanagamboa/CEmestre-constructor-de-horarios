CC      = gcc
CFLAGS  = -Wall -Wextra -Wpedantic -std=c99 -g

MODULES = utils catalog history conflicts validation export
OBJS    = $(patsubst %,build/%.o,$(MODULES))
HEADERS = $(wildcard include/*.h)
VG      = valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes --error-exitcode=1
TESTS   = tests/run_tests tests/run_phase4

.PHONY: all run test valgrind clean

all: cemestre

cemestre: build/main.o $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@

build/%.o: src/%.c $(HEADERS) | build
	$(CC) $(CFLAGS) -c $< -o $@

build:
	mkdir -p build

tests/run_tests: tests/test_phase123.c $(OBJS) $(HEADERS)
	$(CC) $(CFLAGS) tests/test_phase123.c $(OBJS) -o $@

tests/run_phase4: tests/test_phase4.c $(OBJS) $(HEADERS)
	$(CC) $(CFLAGS) tests/test_phase4.c $(OBJS) -o $@

test: $(TESTS)
	./tests/run_tests
	./tests/run_phase4

valgrind: cemestre $(TESTS)
	$(VG) ./cemestre
	$(VG) ./tests/run_tests
	$(VG) ./tests/run_phase4

run: cemestre
	./cemestre

clean:
	rm -rf build cemestre $(TESTS) data/salida.json