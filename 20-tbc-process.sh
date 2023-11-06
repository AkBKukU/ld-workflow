#!/bin/bash
mkdir -p log

# Digital audio decode
ld-process-efm *.efm digital-audio.pcm 2>&1 | tee -a log/ld-process-efm.log

# VBI data for CC and chapters
ld-process-vbi *.tbc --input-json output.tbc.json --output-json output.vbi.json 2>&1 | tee -a log/ld-process-vbi.log

ld-export-metadata output.vbi.json --ffmetadata ffdata 2>&1 | tee -a log/ld-export-metadata-ffmetadata.log
ld-export-metadata output.vbi.json --closed-captions cc.scc 2>&1 | tee -a log/ld-export-metadata-closed-captions.log
tt convert -i cc.scc -o cc.srt 2>&1 | tee -a log/ttconv.log
