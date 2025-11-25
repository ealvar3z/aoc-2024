CC       ?= cc
CFLAGS   ?= -std=c2x -Wall -Wextra -Wpedantic -O2
CPPFLAGS ?= -I../lib

BIN = main
SRC = main.c
OBJ = $(SRC:.c=.o)

all: $(BIN)

$(BIN): $(OBJ)
	$(CC) $(CFLAGS) $(OBJ) -o $(BIN)

%.o: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

clean:
	rm -f $(OBJ) $(BIN)

.PHONY: all clean


