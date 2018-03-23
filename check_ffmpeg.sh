#!/bin/bash
#
# Preveri če teče ffmpeg in če ne teče reštarta proces
#
script=/path/to/videopredvajanje.sh

if ! pgrep -x "ffmpeg" > /dev/null
then
    /bin/bash $script > /dev/null 2>&1 &
fi
