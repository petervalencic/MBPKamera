#!/bin/bash

export LD_LIBRARY_PATH=/usr/lib/

echo "predvajamo"

VBR="1000k" 		# Bitrate of the output video, bandwidth 1000k = 1Mbit/s
QUAL="ultrafast" 	# Encoding speed


YOUTUBE_URL="rtmp://live-ber.twitch.tv/app" # RTMP youtube URL
THREADS="0" 		# Number of cores, insert 0 for ffmpeg to autoselect, more threads = more FPS

#twitch ingest: https://bashtech.net/twitch/ingest.php

SOURCE="rtsp://192.168.1.188:554/user=admin&password=&channel=1&stream=0.sdp" # Camera source
KEY="##### TWITCH KEY####" # Twitch account key

# To download fonts
# wget -O /usr/local/share/fonts/open-sans.zip "https://www.fontsquirrel.com/fonts/download/open-sans";unzip open-sans.zip
FONT="/usr/local/share/fonts/OpenSans-Regular.ttf"
FONTSIZE="25"

# Text allingment
x="5"
y="60"

# Other
box="1" # enable box
boxcolor="blue@0.5" # box background color with transparency factor
textfile="/home/peter/MBP/podatki.txt"
reloadtext="1" # Reload textfile after each frame, usefull for overlaying changing data 
# like weather info. To update the textfile while streaming, you need to use mv command or a crash
# is going to happen when you update the textfile.
# Example:
# wget -q https://something.com/ -O - | grep somevalue > ffmpegraw.txt; mv ffmpegraw.txt ffmpeg.txt

boxborderwidth="5"

echo "start ffmpeg"

# Ffmpeg with drawtext, 
/usr/bin/ffmpeg -loglevel panic -f lavfi -i anullsrc \
-rtsp_transport tcp \
-i "$SOURCE" \
-vcodec libx264 -pix_fmt yuv420p -preset $QUAL -g 25 -b:v $VBR \
-vf "drawtext="fontfile=${FONT}":textfile=${textfile}:x=${x}:y=${y}:reload=${reloadtext}: \
fontcolor=white:fontsize=${FONTSIZE}:box=${box}:boxborderw=${boxborderwidth}:boxcolor=${boxcolor}" \
-threads $THREADS -bufsize 512k \
-f flv "$YOUTUBE_URL/$KEY"


