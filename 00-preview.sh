#!/bin/bash
mkdir -p log
mkdir -p preview

if [[ "" = "$1" ]]
then
    frame_start="1"
else
    frame_start="$1"
fi


if [[ "" = "$2" ]]
then
    start=500
else
    start="$2"
fi


time ld-decode --AC3 -s "$start" -S $frame_start -l 250 -t 6 *.lds preview/preview 2>&1 | tee -a log/preview.log
