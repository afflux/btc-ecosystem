OBJS = main.o sha256.o
EXEC = sha256
CFLAGS = -O2 -Wall -g
LFLAGS = -s
INCLUDE_SHA256 = ../sha256
INCLUDE_KERNEL = ../kernel_module/include
ARM_CC = arm-linux-gnueabihf-gcc
INTEL_CC = gcc

.PHONY: all all-arm all-intel scp

all: all-arm

all-arm: CC = $(ARM_CC)
all-arm: $(EXEC)

all-intel: CC = $(INTEL_CC)
all-intel: $(EXEC)

clean:
	rm -rf $(EXEC) $(OBJS)

sha256.o: $(INCLUDE_SHA256)/sha256.c $(INCLUDE_SHA256)/sha256.h
	$(CC) -o $@ -c $(CFLAGS) -I $(INCLUDE_SHA256) $<

%.o: %.c $(INCLUDE_SHA256)/sha256.h $(INCLUDE_KERNEL)/sha256_accel.h
	$(CC) -o $@ -c $(CFLAGS) -I $(INCLUDE_KERNEL) -I $(INCLUDE_SHA256) $<

$(EXEC): $(OBJS)
	$(CC) -o $@ $^ $(LFLAGS)

scp: all
	scp $(EXEC) linaro:
