CC       ?= cc
CFLAGS   ?= -std=c2x -Wall -Wextra -Wpedantic -O0 -ggdb
CPPFLAGS ?= -I../lib

BIN = main
SRC = main.c
ARG = input.txt
OBJ = $(SRC:.c=.o)

all: $(BIN)

$(BIN): $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $(BIN)

%.o: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ) $(BIN) $(ARG)

.PHONY: all clean


