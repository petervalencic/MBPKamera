#!/bin/bash

#
# Skripta preveri če se izvaja ffmpeg
#

script=/home/peter/MBP/videoPredvajanje.sh

if ! pgrep -x "ffmpeg" > /dev/null
then
	echo "Ffmpeg se ne izvaja..."
	/bin/bash $script > /dev/null 2>&1 &
fi
