#!/bin/bash
mkdir -p log
mkdir -p preview

if [[ "" = "$1" ]]
then
    start=400
else
    start="$1"
fi

time ld-decode --AC3 -s "$start" -S 1 -l 250 -t 6 *.lds preview/preview 2>&1 | tee -a log/preview.log
