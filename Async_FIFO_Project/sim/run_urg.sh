#!/usr/bin/env bash
set -e

cd "$(dirname "$0")"

if [ ! -d simv.vdb ]; then
    echo "simv.vdb not found. Run ./run_vcs.sh first."
    exit 1
fi

rm -rf urgReport
urg -dir simv.vdb -report urgReport

echo "Coverage report: $(pwd)/urgReport/dashboard.html"
