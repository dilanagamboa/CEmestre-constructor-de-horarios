CC      = gcc
CFLAGS  = -Wall -Wextra -Wpedantic -std=c99 -g

MODULES = utils catalog history conflicts validation export
OBJS    = $(patsubst %,build/%.o,$(MODULES))
HEADERS = $(wildcard include/*.h)

.PHONY: all run clean

all: cemestre

cemestre: build/main.o $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@

build/%.o: src/%.c $(HEADERS) | build
	$(CC) $(CFLAGS) -c $< -o $@

build:
	mkdir -p build

run: cemestre
	./cemestre

clean:
	rm -rf build cemestre data/salida.json