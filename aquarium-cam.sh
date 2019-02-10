#!/bin/bash

#
# Description:
#  This is the MBP Aquarium data preparation, CAM streaming and streaming
#  control script.
#
#  The script supports 3 invocation modes. These are controlled by the
#  '--op' script argument. Please invoke the script with '--help' for more
#  details.
#
#  The script reads its configuration from 'aquarium-cam.conf' files located
#  in /etc/, /~ and script running directory. Parameters from the latest one
#  takes precedence from the former ones.
#


#
# -- Configuration file in order of precedence - last overrides previous ones --
#
aquarium_conf_files="/etc/aquarium-cam.conf ~/aquarium-cam.conf aquarium-cam.conf"


#
# -- Individual script operations / functions --
#

# -- Help --
function Help() {
  cat <<__EOF__
Description:
 MBP aquarium video streaming control script.

Usage:
 $0 --help | --op <operation>

 <operation> is one of:
  - STREAM     ... start FFmpeg camera vide encoding and streaming to Twitch.

  - GET-DATA   ... retrieve the last temperature and salinity from the.
                   measurement unit

  - CHECK-PROC ... check if FFmpeg is running and if not, restart it.

__EOF__
  exit 0
}



# -- Data retrival from Arduino data acquisition unit --
function GetData() {
  data=$(wget -O - ${ARDUINO_ROOT_URI} 2>/dev/null)
  [[ -z "${data}" ]] && {
    echo "ERROR: Failed retrieving data from ${ARDUINO_ROOT_URI}!  Exiting ..."
    exit 1101
  }

  temperature=$(echo "${data}" | xmllint --xpath '/root/temp/value/text()' -)
  salinity=$(echo "${data}" | xmllint --xpath '/root/sal/value/text()' -)

  cat <<__EOF__ | tee ${AQUARIUM_DATA_FILE}
T: ${temperature} °C
S: ${salinity} PSU
__EOF__
}


# -- Starts FFmpeg streaming --
function StreamVideo() {
  ffmpeg \
    -loglevel ${FFMPEG_LOG_LEVEL} -f lavfi -i anullsrc \
    -rtsp_transport tcp \
    -i "${FFMPEG_CAM_RTSP_SRC}" \
    -vcodec libx264 -pix_fmt yuv420p -preset ${FFMPEG_QUAL} -g 75 -b:v ${FFMPEG_VBR} \
    -vf "\
drawtext=fontfile=${FFMPEG_TEXT_OVERLAY_FONT_PATH}:textfile=${AQUARIUM_DATA_FILE}:\
x=${FFMPEG_TEXT_OVERLAY_OFFSET_X}:y=${FFMPEG_TEXT_OVERLAY_OFFSET_X}:\
reload=${FFMPEG_TEXT_OVERLAY_RELOAD}: \
fontcolor=white:fontsize=${FFMPEG_TEXT_OVERLAY_FONT_SIZE}:\
box=${FFMPEG_TEXT_OVERLAY_BOX}:boxborderw=${FFMPEG_TEXT_OVERLAY_BOX_BORDER_WIDTH}:\
boxcolor=${FFMPEG_TEXT_OVERLAY_BOX_COLOR}"\
    -threads ${FFMPEG_THREADS} -bufsize 512k \
    -f flv "${FFMPEG_TWITCH_STREAM_URL_DST}/${FFMPEG_TWITCH_KEY}"
}


# -- Checks if the streaming is running, otherwise starts it --
function CheckProcRunning() {
  # First find out if ffmpeg as a child of this script is running
  this_pid="$$"
  script_name=$(basename "$0")
  tmp_file=$(mktemp --dry-run)
  pgrep "${script_name}" | grep -v ${this_pid} > ${tmp_file}
  num_of_pids=$(wc -l ${tmp_file} | awk '{ print $1 }')

  is_ffmpeg_running=0
  if [ ${num_of_pids} -gt 1 ]; then
    echo "ERROR: More than 1 cam control scripts found running - found ${num_of_pids} instances!  Exiting ..."
    rm ${tmp_file}
    exit 12001
  elif [ ${num_of_pids} -eq 1 ]; then
    ffmpeg_parent_pid=$(head -1 ${tmp_file})
    ffmpeg_pid=$(pgrep --parent ${ffmpeg_parent_pid} ffmpeg)
    if [ ! -z "${ffmpeg_pid}" ]; then
      is_ffmpeg_running=1
    fi
  else
    uid=$(id -u)
    ffmpeg_pid=$(pgrep --uid ${uid} ffmpeg)
    if [ ! -z "${ffmpeg_pid}" ]; then
      echo "WARNING: Killing residual ffmpeg without a controlling CAM script!"
      kill -9 ${ffmpeg_pid}
    fi
  fi

  if [ ${is_ffmpeg_running} -eq 1 ]; then
    echo "Aquarium CAM streaming   -> OK"
  else
    echo "Aquarium CAM streaming   -> FAIL   ... starting new instance"
    nohup ${0} --op STREAM &>/dev/null &
  fi

  exit 0
}


#
# -- Read in config and check if configuration was loaded and it seems at least valid --
#
for f in ${aquarium_conf_files}; do
  source ${f} 2>/dev/null
done
[[ -z "${AQUARIUM_DATA_FILE}" || -z "${ARDUINO_ROOT_URI}" || -z "${AQUARIUM_CAM_IP}" ]] && {
  echo "ERROR: Invalid configuration file!  Exiting ..."
  exit 1001
}
cat <<__EOF__
Configuration:
 AQUARIUM_DATA_FILE = '${AQUARIUM_DATA_FILE}'
 ARDUINO_ROOT_URI = '${ARDUINO_ROOT_URI}'
 AQUARIUM_CAM_IP = '${AQUARIUM_CAM_IP}'
__EOF__


#
# -- CLI parser --
#
TEMP=`getopt -o p:,h --long op:,help \
     -n "${0}" -- "${@}"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

eval set -- "$TEMP"

while true ; do
  case "$1" in
    -p|--op)
      operation=$(echo "${2}" | tr [:lower:] [:upper:])
      [[ ! $operation =~  ^(STREAM|GET-DATA|CHECK-PROC)$ ]] && {
        echo "ERROR: Invalid operation specified - supported ones STREAM, GET-DATA and CHECK-PROC!  Exiting ..."
        exit 1
      }
      shift
      ;;

    -h|--help)
      Help
      exit 0
      ;;

    --)
      break
      ;;

    *)
      echo "arg: '${arg}'"
      echo "Internal error!"
      exit 1
      ;;
  esac
  shift
done
[[ ${#} -gt 1 ]] && {
  echo "ERROR: Invalid arguments specified!  Exiting ..."
  exit 1001
}


#
# -- Run selected operation --
#
if [ "${operation}" = "STREAM" ]; then
  StreamVideo
elif [ "${operation}" = "GET-DATA" ]; then
  GetData
elif [ "${operation}" = "CHECK-PROC" ]; then
  CheckProcRunning
else
  echo "ERROR: Unsupported operation '${operation}'!  Use '--help'.  Exiting ..."
  exit 1002
fi

exit 0
