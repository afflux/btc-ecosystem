obj-m += sha256_accel.o

KERNEL_ARM = ../../linux-Digilent-Dev
KERNEL_INTEL = /lib/modules/$(shell uname -r)/build


ifneq ("$(wildcard $(shell which arm-linux-gnueabihf-gcc))","")
	CCPREFIX_ARM=arm-linux-gnueabihf-
	CFLAGS=
else
	CFLAGS=-mfloat-abi=hard
	CCPREFIX_ARM=arm-none-eabi-
endif

.PHONY: all clean all-arm clean-arm all-intel clean-intel scp

all: all-arm
clean: clean-arm

all-arm:
	make -C $(KERNEL_ARM) ARCH=arm CROSS_COMPILE=$(CCPREFIX_ARM) CFLAGS=$(CFLAGS) M=$(PWD) modules
clean-arm:
	make -C $(KERNEL_ARM) ARCH=arm CROSS_COMPILE=$(CCPREFIX_ARM) CFLAGS=$(CFLAGS) M=$(PWD) clean

all-intel:
	make -C $(KERNEL_INTEL) M=$(PWD) modules
clean-intel:
	make -C $(KERNEL_INTEL) M=$(PWD) clean

scp: all
	scp sha256_accel.ko linaro:
