OBJS = main.o
EXEC = sha256
CFLAGS = -O2 -Wall -g
LFLAGS =
INCLUDES = ../kernel_module/include/
CC = gcc

.PHONY: all

all: $(EXEC)

clean:
	rm -rf $(EXEC) $(OBJS)

%.o: %.c
	$(CC) -o $@ -c $(CFLAGS) -I $(INCLUDES) $<

$(EXEC): $(OBJS)
	$(CC) -o $@ $^ $(LFLAGS)
