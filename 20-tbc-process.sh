#!/bin/bash
mkdir -p log

if [[ "-d" = "$1" ]]
then
    dts="--dts"
    audio_ext="dts"
else
    dts=""
    audio_ext="pcm"
fi


# Digital audio decode
ld-process-efm $dts *.efm digital-audio.$audio_ext 2>&1 | tee -a log/ld-process-efm.log

# VBI data for CC and chapters
ld-process-vbi *.tbc --input-json output.tbc.json --output-json output.vbi.json 2>&1 | tee -a log/ld-process-vbi.log

ld-export-metadata output.vbi.json --ffmetadata ffdata 2>&1 | tee -a log/ld-export-metadata-ffmetadata.log
ld-export-metadata output.vbi.json --closed-captions cc.scc 2>&1 | tee -a log/ld-export-metadata-closed-captions.log
tt convert -i cc.scc -o cc.srt 2>&1 | tee -a log/ttconv.log
