SHELL = /bin/bash
TOP = $(shell pwd)

all: system.bit
clean:
	rm -rf out

system.bit: out out/system.bit
	cp -a out/system.bit $@

out:
	mkdir $@

out/system.bit:
	export LC_NUMERIC="en_US.UTF-8" ; \
	export LC_CTYPE="en_US.UTF-8" ; \
	export LANG="en_US.UTF-8" ; \
	source $(VIVADO)/settings64.sh ; \
	tmpdir=$$(mktemp -d) ; \
	cd $$tmpdir ; \
	vivado -mode tcl -source $(TOP)/impl.tcl ; \
	rm -rf $tmpdir

