#!/bin/bash
mkdir -p log
mkdir -p preview

if [[ "" = "$1" ]]
then
    frame_start=""
else
    if [[ "-1" < "$1" ]]
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


time ld-decode --AC3 -s "$start" $frame_start -l 250 -t 6 *.lds preview/preview 2>&1 | tee -a log/preview.log
