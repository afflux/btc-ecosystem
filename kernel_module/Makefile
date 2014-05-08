obj-m += sha256_accel.o

KERNEL_ARM = ../../linux-Digilent-Dev
KERNEL_INTEL = /lib/modules/$(shell uname -r)/build

CCPREFIX_ARM = arm-linux-gnueabihf-

.PHONY: all clean all-arm clean-arm all-intel clean-intel

all: all-intel
clean: clean-intel

all-arm:
	make -C $(KERNEL_ARM) ARCH=arm CROSS_COMPILE=$(CCPREFIX_ARM) M=$(PWD) modules
clean-arm:
	make -C $(KERNEL_ARM) ARCH=arm CROSS_COMPILE=$(CCPREFIX_ARM) M=$(PWD) clean

all-intel:
	make -C $(KERNEL_INTEL) M=$(PWD) modules
clean-intel:
	make -C $(KERNEL_INTEL) M=$(PWD) clean
