#!/bin/bash
mkdir -p log

if [[ "" = "$1" ]]
then
    start=500
    frame="-S 1"
else
    start="$1"
				 frame""
fi


time ld-decode --AC3 --start "$start" $frame -t 6 *.lds output 2>&1 | tee -a log/ld-decode.log
