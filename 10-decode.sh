#!/bin/bash
mkdir -p log

if [[ "" = "$1" ]]
then
    start=500
else
    start="$1"
fi


time ld-decode --AC3 --start "$start" -S 1 -t 6 *.lds output 2>&1 | tee -a log/ld-decode.log
