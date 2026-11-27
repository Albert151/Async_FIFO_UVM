#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

rm -rf csrc simv simv.daidir ucli.key \
       compile.log sim.log async_fifo.vpd DVEfiles

vcs \
    -full64 \
    -sverilog \
    -timescale=1ns/1ps \
    -f filelist.f \
    -debug_access+all \
    -kdb \
    -cm line+cond+tgl+branch+assert \
    -cm_dir simv.vdb \
    +define+VCS \
    -l compile.log \
    -o simv

./simv -cm line+cond+tgl+branch+assert -cm_dir simv.vdb -l sim.log

echo
echo "Simulation finished."
echo "Log      : $(pwd)/sim.log"
echo "Waveform : $(pwd)/async_fifo.vpd"
