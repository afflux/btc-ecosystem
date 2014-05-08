CC = gcc
CFLAGS = -Wall -c -O2
LD = gcc

OBJS = main.o sha256.o
EXEC = sha256

.PHONY: all

all: $(EXEC)

$(EXEC): $(OBJS)
	$(LD) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm -f $(OBJS) $(EXEC)