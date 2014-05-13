OBJS = main.o
EXEC = sha256
CFLAGS = -O2 -Wall -g
LFLAGS =
INCLUDES = ../kernel_module/include/
ARM_CC = 
INTEL_CC = gcc

.PHONY: all all-arm all-intel scp

all: all-arm

all-arm: CC = arm-linux-gnueabihf-gcc
all-arm: $(EXEC)

all-intel: CC = gcc
all-intel: $(EXEC)

clean:
	rm -rf $(EXEC) $(OBJS)

%.o: %.c
	$(CC) -o $@ -c $(CFLAGS) -I $(INCLUDES) $<

$(EXEC): $(OBJS)
	$(CC) -o $@ $^ $(LFLAGS)

scp: all
	scp $(EXEC) linaro:
