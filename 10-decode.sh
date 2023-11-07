#!/bin/bash
mkdir -p log


if [[ "" = "$1" ]]
then
    frame_start="1"
else
    frame_start="$1"
fi


if [[ "" = "$2" ]]
then
    start=500
    frame="-S $frame_start"
else
    start="$2"
    frame=""
fi


time ld-decode --AC3 --start "$start" $frame -t 6 *.lds output 2>&1 | tee -a log/ld-decode.log
