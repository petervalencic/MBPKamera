#!/bin/bash

# Rtsp to youtube streaming with ffmpeg

VBR="1000k" # Bitrate of the output video, bandwidth 1000k = 1Mbit/s
QUAL="ultrafast" # Encoding speed
YOUTUBE_URL="rtmp://a.rtmp.youtube.com/live2" # RTMP youtube URL
THREADS="0" # Number of cores, insert 0 for ffmpeg to autoselect, more threads = more FPS


SOURCE="rtsp://172.16.201.88:554/user=admin&password=&channel=1&stream=0.sdp?real_stream" # Camera source
KEY="a9v0-hks6-tdfr-3tgy" # Youtube account key

# To download fonts
# wget -O /usr/local/share/fonts/open-sans.zip "https://www.fontsquirrel.com/fonts/download/open-sans";unzip open-sans.zip

FONT="/usr/local/share/fonts/OpenSans-Regular.ttf"
FONTSIZE="15"

# Text allingment
x="5"
y="60"

# Other
box="1" # enable box
boxcolor="black@0.5" # box background color with transparency factor
textfile="ffmpeg.txt"
reloadtext="1" # Reload textfile after each frame, usefull for overlaying changing data 
# like weather info. To update the textfile while streaming, you need to use mv command or a crash
# is going to happen when you update the textfile.
# Example:
# wget -q https://something.com/ -O - | grep somevalue > ffmpegraw.txt; mv ffmpegraw.txt ffmpeg.txt

boxborderwidth="5"
#-loglevel panic \
# Ffmpeg with drawtext, 
    ffmpeg -f lavfi -i anullsrc \
    -rtsp_transport tcp \
    -i "$SOURCE" \
    -vcodec libx264 -pix_fmt yuv420p -preset $QUAL -g 20 -b:v $VBR \
    -vf "drawtext="fontfile=${FONT}":textfile=${textfile}:x=${x}:y=${y}:reload=${reloadtext}: \
    fontcolor=white:fontsize=${FONTSIZE}:box=${box}:boxborderw=${boxborderwidth}:boxcolor=${boxcolor}" \
    -threads $THREADS -bufsize 512k \
    -f flv "$YOUTUBE_URL/$KEY"

