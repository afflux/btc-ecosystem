#!/bin/bash
export LC_NUMERIC="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LANG="en_US.UTF-8"

source /opt/Xilinx/Vivado/2014.1/settings64.sh

tmpdir=$(mktemp -d)
pushd $tmpdir

vivado $@

popd
rm -rf $tmpdir
