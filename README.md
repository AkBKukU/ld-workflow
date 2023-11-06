# ld-workflow
This is an overview of the process of using a Domesday Duplicator and
ld-decode to capture and convert a laserdisc to a video file. Laserdiscs
have a number of complexities and features that require determining the
best way to decode each disc on an individual basis.

This repository contains multiple scripts to be executed in sequence
for different steps of the process.

## Laserdisc Capture

When working with a Domesday Duplicator you should aim to get a complete
capture of an entire disc from start to finish. Depending on how the disc
works (CLV vs CAV) the resulting `LDS` file can be around 50-150GB. This
can be compressed with `flac` usin `ld-compress`.

## Decode

Begin with `00-preview.sh` to check that the starting frame can be detected. If not it will need to be manually set when running `10-decode.sh`

## Process

Run `20-tbc-process.sh` to extract digital data like the Digital audio track and subtitles

## Re-Encode

`30-multitrack-output.sh` can be run to create an `MOV` with all media and metadata from the laserdisc embedded into it.
