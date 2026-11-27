#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

if [ ! -f async_fifo.vpd ]; then
    echo "async_fifo.vpd not found. Run ./run_vcs.sh first."
    exit 1
fi

verdi -ssf async_fifo.vpd -nologo &
