# Laserdisc Ripping Workflow
This is an overview of the process of using a 
[Domesday Duplicator](https://github.com/simoninns/DomesdayDuplicator) and
[ld-decode](https://github.com/happycube/ld-decode) 
to capture and convert a laserdisc to a video file. Laserdiscs
have a number of complexities and features that require determining the
best way to decode each disc on an individual basis.

This repository contains multiple scripts to be executed in sequence
for different steps of the process.

## Feature Identification

Laserdiscs have many different features and video encoding differences.
You should take note of the following things when you are assessing a 
disc to capture, note I do mean disc not "movie" as different discs in
a release can be different:  
  
 - CLV vs CAV
 - Analog Audio
 - Digital Audio
 - AC3 Audio / Mono Analog
 - DTS Audio
 - Closed Captioning (Subtitles)

It can be helpful to take a photo of the front and back of the jacket for
the release to have this information on hand later when processing files.

## Laserdisc Capture

When working with a Domesday Duplicator you should aim to get a complete
capture of an entire disc from start to finish. Depending on how the disc
works (CLV vs CAV) the resulting `LDS` file can be around 50-150GB. These
files are not watchable and can be a little sloppy due to how the player
spins up the disc to play.

The capture stage and resulting files are the "source" files that you 
derive everthing else from. This can be compressed using `ld-compress`.
If you are making long term backups these are the only files you need
to keep as everything else can be remade from them and the software may
be improved later and yeild better results.


## Initial Decode

After getting a raw capture you need to convert it to a usable format 
using `ld-decode`. This will give you a TBC file that can be viewed with
`ld-analysis`. This process needs different options depending on the 
features your disc has.

First you need to determine the starting frame of the program recorded on
the disc. When doing an automated capture of a laserdisc using a serial 
connection controlled by the Domesday Duplicator software the read head will 
seek into the disc to start, then move backwards to find the start of the 
program. This section of head movement needs to be skipped for the decode.

Each frame has a timecode number embedded in it. CLV starts at
frame `0` and CAV starts at frame `1`. Frame numbers are different from 
"sample" numbers though which are an approximation of frame counts. It 
is best to have your TBC file start from the first frame of the program
or you can have issues with the analog audio track.

`00-preview.sh` provided here can help find the starting frame sample which 
can be  detected automatically sometimes. A If not, `00-preview.sh` takes two 
parammeters, first the starting frame number, and then the number of samples
to skip into the raw file. `ld-decode` will seek backwards to find the starting
frame, so overshooting the samples to let it work backwards is a good option.
It may take multiple rounds of tweaking the starting sample to dial into the
starting frame.

`00-preview.sh` will output files into a `preview/` directory that you can
use to verify you have the correct decode parameters. One thing to pay 
attention to is the AC3 audio file. If it is empty or the AC3 log is huge then
the disc does not have AC3 audio and you should disable that parameter in the
`10-decode.sh` script.

Once you know where to start the decode and if there is AC3 you can run 
`10-decode.sh` to fully decode the raw disc data. This will take hours to 
process a full disc even on powerful modern hardware. `ld-decode` supports
multiple threads, but after testing any more than 6 adds no benefit and can 
make it slower.

## Process Decoded Data

`ld-decode` will produce a number of different files:  

 - **TBC**: The timebase corrected video data
 - **PCM**: Analog audio track as signed 16 bit little endian PCM data
 - **EFM**: Digitial data track raw data
 - **TBC.JSON**: Metadata from disc

The files need to be processed again though to get some additional data.
`ld-process-efm` will extract the digital audio to a similar PCM file.
`ld-process-vbi` will extract some additional data from the TBC file that can
be added to the JSON file. With that data added the `ld-export-metadata` can 
get the chapters and closed captions.

`20-tbc-process.sh` does all of this and uses `ttconv` to create an SRT from
SCC file normally created.

## Create Video File

More detailed information:  

 - [NTSC Deinterlacing](https://github.com/happycube/ld-decode/wiki/Creating-video-from-NTSC-decodes)

After extracting all possible data you can create a multi-stream video file
with everthing the laserdisc had on it. `ld-chroma-decoder` is intended to be
used with `ffmpeg` as a piped input for re-encoding. How you choose to create 
your final will depend on your prefrences. `30-multitrack-output.sh` has 
everything automated as much as I could for how I prefer to create resulting 
videos.

### Video Compression

If you opt to compress your video files I would recommend scaling them to be
larger, *as nearest neighbor*. Laserdisc is low resolution, and the 
macroblocking of modern video codecs aren't well suited to it. If you scale
2x with `-vf scale=2*iw:2*ih:flags=neighbor` your video quality will be much 
better after the compression.


### Multiple Audio Tracks

Using `ffmpeg` you can embedd multuple audio tracks into a video container 
like MOV. For any PCM files you will need to tell `ffmpeg` the format of the
audio before you include it with `-f s16le -r 44.1k -ac 2`. Then you can use
the normal `-i $filename` include it. You can then `-map` the included audio 
files using the ID numbers for the streams (which start at 0 and include all 
inputs). You will likely always be outputting to a single file as well. So to
map the second included file's audio to the output video you would map 
`-map 1:a:0`. This can be done for any kind of audio inputs.
  
You may also want to adjust the channel of tracks, for AC3 discs you may want
to convert from AC3 encoded audio to PCM and specifying 
`-channel_layout:a:1 "5.1" -c:a:1 pcm_s16le -osr 44100` where `a:1` is the 
*output* audio track will correct the sample rate, re-encode it, and set it as
5.1 surround. You will then likely want to use 
`-filter_complex "[3:a]channelsplit=channel_layout=stereo[left][right]"` 
where `3:a` is the *input* ID for the analog audio. Then you can 
`-map "[left]"` to only include the left channel in your output file.

### Chapters and Subtitles

`ld-export-metadata` chapters and subtitles(as SRT) can be embedded in the 
output file. Chapters from the `--ffmetadata` option and be included with
`-map_metadata 4` where `4` is the *input* file ID. Subtites can be included
with `-map 5:s:0 -c:s mov_text -metadata:s:s:0 language=eng` where `5:s` is 
the *input* ID. The `-c:s mov_text` is for an MOV file and will be different 
for other video containers.
