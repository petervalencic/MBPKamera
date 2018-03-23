#!/bin/bash

# Rtsp to youtube streaming with ffmpeg
VBR="1000k" # Bitrate of the output video, bandwidth 1000k = 1Mbit/s
QUAL="ultrafast" # Encoding speed
YOUTUBE_URL="rtmp://a.rtmp.youtube.com/live2" # RTMP youtube URL
THREADS="0" # Number of cores, insert 0 for ffmpeg to autoselect, more threads = more FPS


SOURCE="rtsp://172.16.201.88:554/user=admin&password=&channel=1&stream=0.sdp?real_stream" #Naslov RTSP stream-a
KEY="YOUTUBE KLJUČ" # Youtube key za online predvajanje

#v ta folder odloži font
FONT="/usr/local/share/fonts/OpenSans-Regular.ttf"
FONTSIZE="15"

# Pozicioniranje teksta
x="5"
y="60"

# Ostalo
box="1" # omogoči obrobo
boxcolor="black@0.5" 
textfile="ffmpeg.txt"
reloadtext="1" # naloži podatke iz tekstovne datoteke v vsakem frame-u
boxborderwidth="5"

#Ta flag dodaj, da se ne izpisujejo smeti v konzolo -loglevel panic \

    ffmpeg -f lavfi -i anullsrc \
    -rtsp_transport tcp \
    -i "$SOURCE" \
    -vcodec libx264 -pix_fmt yuv420p -preset $QUAL -g 20 -b:v $VBR \
    -vf "drawtext="fontfile=${FONT}":textfile=${textfile}:x=${x}:y=${y}:reload=${reloadtext}: \
    fontcolor=white:fontsize=${FONTSIZE}:box=${box}:boxborderw=${boxborderwidth}:boxcolor=${boxcolor}" \
    -threads $THREADS -bufsize 512k \
    -f flv "$YOUTUBE_URL/$KEY"

