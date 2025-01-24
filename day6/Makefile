# Makefile for compiling the C23 Patrol Program

# Compiler settings
CC := gcc
# If you're using Clang, you can set CC := clang

# Compiler flags
CFLAGS := -std=c2x -Wall -Wextra -pedantic -O2

# Target executable name
TARGET := main

# Source files
SRCS :=  main.c

# Object files
OBJS := $(SRCS:.c=.o)

# Default target
all: $(TARGET)

# Link the object files to create the executable
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS)

# Compile source files into object files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Clean up generated files
clean:
	rm -f $(TARGET) $(OBJS)

# Run the program with a specified input file
# Usage: make run INPUT=sample.txt
run: $(TARGET)
	./$(TARGET) $(INPUT)

# Phony targets to prevent conflicts with files of the same name
.PHONY: all clean run
