SRC = $(wildcard src/*.vhd)
BIT = system.bit
OUTDIR = out
BAKDIR = bak
SHELL = /bin/bash
TOP = $(shell pwd)

.PHONY: all clean scp

all: $(OUTDIR)/$(BIT)

clean:
	rm -rf $(OUTDIR)

scp: $(OUTDIR)/$(BIT)
	scp $^ linaro:/mnt/

$(OUTDIR):
	mkdir $@

$(OUTDIR)/$(BIT): $(OUTDIR) $(SRC)
	export LC_NUMERIC="en_US.UTF-8" ; \
	export LC_CTYPE="en_US.UTF-8" ; \
	export LANG="en_US.UTF-8" ; \
	source $(VIVADO)/settings64.sh ; \
	tmpdir=$$(mktemp -d) ; \
	cd $$tmpdir ; \
	vivado -mode tcl -source $(TOP)/impl.tcl ; \
	rm -rf $$tmpdir ; \
	cp $(TOP)/$@ $(TOP)/$(BAKDIR)/$(shell date "+%s")_$(BIT)
