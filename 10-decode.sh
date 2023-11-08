#!/bin/bash
mkdir -p log

if [[ "" = "$1" ]]
then
    frame_start=""
else
    if [[ "-1" != "$1" ]]
    then
        frame_start="-S $1"
    fi
fi

if [[ "" = "$2" ]]
then
    start=500
else
    start="$2"
fi

if [[ -s "preview/preview.ac3" ]]
then
    echo "Decoding with AC3"
    ac3="--AC3"
else
    ac3=""
fi

time ld-decode $ac3 --start "$start" $frame_start -t 6 *.lds output 2>&1 | tee -a log/ld-decode.log
