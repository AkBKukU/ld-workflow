#!/bin/bash

input="output.tbc"
#vcodec="-c:v v210 -colorspace smpte170m -color_range tv -pix_fmt yuv422p10le"
vcodec="-c:v libx265 -crf 20 -preset medium "
#vcodec="-c copy"
stereo="pcm_s16le"

# Video filtering
if [[ "60" == "$1" ]]
then
    echo "60 FPS Deinterlacing"
    deinterlace=",dedot=m=rainbows,yadif=mode=send_field:parity=auto" # 30 to 60 correction
elif [[ "N" == "$1" ]]
then
    echo "No deinterlacing"
    deinterlac=""
else
    echo "24 FPS Deinterlacing"
    deinterlace=",dedot=m=rainbows,fieldmatch=order=auto:field=auto,decimate" # 24 to 30 correction
fi

scale=",scale=2*iw:2*ih:flags=neighbor"
vfilter="-vf setdar=4/3,setfield=tff$deinterlace$scale"
#vfilter=""
analog_rate=44089

# Comment out this like to not include the original AC3 track in the output
#ac3pass="-map 2:a:0 -metadata:s:a:3 title=AC3-Surround -c:a:3 ac3 "

function encode_ac3
{
# AC3 discs used the right analog audio channel to hold AC3 data
# Digital stereo is relied on for standard sound. The remaining analog
# channel may contain a mono track or something else like commentary.
# There may be matrix encoded dolby surround in the digital track

    # Build inputs
    if [[ -s "cc.srt" ]]
    then
        srt=" -i cc.srt -map 5:s:0 -c:s mov_text -metadata:s:s:0 language=eng "
    else
        srt=""
    fi

    ld-chroma-decoder --decoder ntsc3d -p y4m -q "$input" | ffmpeg -y -i - \
    -f s16le -ar 44.1k -ac 2 -i digital-audio.pcm \
    -itsoffset 0.19 -i *.ac3 \
    -f s16le -ar $analog_rate -ac 2 -i output.pcm \
    -i ffdata \
    $srt \
    $vcodec $vfilter \
    -map 0:v:0 \
    -map 1:a:0 \
    -metadata:s:a:0 title="Digital Stereo" \
    -c:a:0 $stereo \
    -map 2:a:0 \
    -metadata:s:a:1 title="PCM Surround" \
    -channel_layout:a:1 "5.1" \
    -c:a:1 pcm_s16le \
    -map 3:a:0 \
    -metadata:s:a:2 title="Analog Left Channel" \
    -c:a:2 $stereo -ar 44100 \
    -map_channel 3.0.0 \
    $ac3pass \
    -map_metadata 4 \
    output.mov  2>&1 | tee -a log/ffmpeg.log

}

function encode_dts
{
# DTS discs both channels of the digital audio track to hold DTS data
# Analog stereo is relied on for standard sound.

    # Build inputs
    if [[ -s "cc.srt" ]]
    then
        srt=" -i cc.srt -map 4:s:0 -c:s mov_text -metadata:s:s:0 language=eng "
    else
        srt=""
    fi

    ld-chroma-decoder --decoder ntsc3d -p y4m -q "$input" | ffmpeg -y -i - \
    -i digital-audio.dts \
    -f s16le -ar $analog_rate -ac 2 -i output.pcm \
    -i ffdata \
    $srt \
    $vcodec $vfilter \
    -map 0:v:0 \
    -map 2:a:0 \
    -metadata:s:a:0 title="Analog Stereo" \
    -c:a:0 $stereo -ar 44100 \
    -map 1:a:0 \
    -metadata:s:a:1 title="PCM Surround" \
    -channel_layout:a:1 "5.1" \
    -c:a:1 pcm_s16le \
    -map_metadata 4 \
    output.mov 2>&1 | tee -a log/ffmpeg.log

}


function encode_dstereo_split
{
# Digital stereo discs will contain two stereo tracks
# There may be matrix encoded dolby surround in the digital track

    # Build inputs
    if [[ -s "cc.srt" ]]
    then
        srt=" -i cc.srt -map 4:s:0 -c:s mov_text -metadata:s:s:0 language=eng "
    else
        srt=""
    fi

    ld-chroma-decoder --decoder ntsc3d -p y4m -q "$input" | ffmpeg -y -i - \
    -f s16le -ar 44.1k -ac 2 -i digital-audio.pcm \
    -f s16le -ar $analog_rate -ac 2 -i output.pcm \
    -i ffdata \
    $srt \
    $vcodec $vfilter \
    -map 0:v:0 \
    -map 1:a:0 \
    -metadata:s:a:0 title="Digital Stereo" \
    -c:a:0 $stereo  \
    -filter_complex "[2:a]channelsplit=channel_layout=stereo[left][right]" \
    -map "[left]" \
    -metadata:s:a:1 title="Analog Left Channel" \
    -c:a:1 $stereo  \
    -map "[right]" \
    -metadata:s:a:2 title="Analog Right Channel" \
    -c:a:2 $stereo  \
    -map_metadata 3 \
    output.mov  2>&1 | tee -a log/ffmpeg.log
}

function encode_dstereo
{
# Digital stereo discs will contain two stereo tracks
# There may be matrix encoded dolby surround in the digital track

    # Build inputs
    if [[ -s "cc.srt" ]]
    then
        srt=" -i cc.srt -map 4:s:0 -c:s mov_text -metadata:s:s:0 language=eng "
    else
        srt=""
    fi

    ld-chroma-decoder --decoder ntsc3d -p y4m -q "$input" | ffmpeg -y -i - \
    -f s16le -ar 44.1k -ac 2 -i digital-audio.pcm \
    -f s16le -ar $analog_rate -ac 2 -i output.pcm \
    -i ffdata \
    $srt \
    -map 0:v:0 \
    $vcodec $vfilter \
    -map 1:a:0 \
    -metadata:s:a:0 title="Digital Stereo" \
    -c:a:0 $stereo  \
    -map 2:a:0 \
    -metadata:s:a:1 title="Analog Stereo" \
    -c:a:1 $stereo -ar 44100 \
    -map_metadata 3 \
    output.mov  2>&1 | tee -a log/ffmpeg.log

}


function encode_astereo
{
# Non-digital sound discs will contain analog stereo audio

    # Build inputs
    if [[ -s "cc.srt" ]]
    then
        srt=" -i cc.srt -map 3:s:0 -c:s mov_text -metadata:s:s:0 language=eng "
    else
        srt=""
    fi

    ld-chroma-decoder --decoder ntsc3d -p y4m -q "$input" | ffmpeg -y -i - \
    -f s16le -ar $analog_rate -ac 2 -i output.pcm \
    -i ffdata \
    $srt \
    $vcodec $vfilter\
    -map 0:v:0 \
    -map 1:a:0 \
    -metadata:s:a:0 title="Analog Stereo" \
    -c:a:1 $stereo  \
    -map_metadata 2 \
    output.mov  2>&1 | tee -a log/ffmpeg.log
}

function encode_silent
{
# Non-digital sound discs will contain analog stereo audio
    ld-chroma-decoder --decoder ntsc3d -p y4m -q "$input" | ffmpeg -y -i - \
    $vcodec $vfilter \
    output-silent.mov  2>&1 | tee -a log/ffmpeg.log
}

if [[ -s output.ac3 ]]
then
    echo "Processing with AC3, Digital, and Analog Audio"
    encode_ac3
elif [[ -s digital-audio.dts ]]
then
    echo "Processing with DTS and Analog Audio"
    encode_dts
elif [[ -s digital-audio.pcm ]]
then
    echo "Processing with Digital and Analog Audio"
    encode_dstereo
else
    echo "Processing with Analog Audio"
    encode_astereo
fi

