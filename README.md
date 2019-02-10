# MBP Aquarium CAM
This repository contains the _MBP Aquarium CAM_ support scripts. This is, a
script for retrieving data from the Arduino data acquisition unit, as well for
start the FFmpeg streaming process of the video from the underwater camera to
the TWitch on-line streaming service.

## Installation instructions
1. Set up a user to run the process

   We suggest to set up a dedicated user to run the _FFmpeg_ streamer and
   other commands. This especially aplies for cases when these script are
   hosted on a shared system.

   The below set of commands created the user `aquarium-cam` with
   `GID = UID = 5001`. If you're going to run it as suggested, please
   adopt this to your system:
   ```
   groupadd -g 5001 aquarium-cam
   useradd -u 5001 -g aquarium-cam -m -s /bin/bash -c "MBP Aquarium CAM" aquarium-cam
   ```

   **NOTE / ATTENTION:** The rest of this document supposed the mentioned
   user was created, as well its home directory, etc. So, adopt acordigly.


1. TTF fonts setup

   Data from the measurement unit is written as an overlay to the streamed
   video. For this, Open-Sans fonts are being used which are NOT included in
   this repository, but the end-user has to set them up. That is, download
   the _.zip_ archive and extract the `OpenSans-Regular.ttf` fond file from
   it.
   ```
   cd ~aquarium-cam

   wget -O open-sans.zip "https://www.fontsquirrel.com/fonts/download/open-sans"

   unzip open-sans.zip OpenSans-Regular.ttf

   rm open-sans.zip
   ```


1. Clone the code and copy needed scripts
   ```
   cd ~aquarium-cam
   
   git clone https://github.com/petervalencic/MBPKamera.git aquarium-cam.git

   cp -v aquarium-cam.git/aquarium-cam.* .
   ```


1. Update the configuration file

   Please, edit `aquarium-cam.conf`. You'll need to update at least following settings:
   - `ARDUINO_ROOT_URI`
   - `AQUARIUM_CAM_IP`
   - `FFMPEG_TWITCH_KEY`


1. Create the temporary data storage directory

   On _Ubuntu 18.04_ LTS we used _tmpfiles.d_ facility for this (see `man
   tmpfiles.d` for details).

   So, create `/etc/tmpfiles.d/aquarium-cam.conf` with following content:
   ```
   #Type Path               Mode UID           GID             Age Argument
   D    /run/aquarium-cam   2755 aquarium-cam  aquarium-cam    3d  -
   ```


1. Check if all is OK

   **NOTE:** Make sure you're running these commands as user `aquarium-cam` - use
    `id` to check what user you're logged in currently.

    - Retrieve a new set of measurements from Arduino and check its content
      ```
      ./aquarium-cam.sh --op GET-DATA
      cat /var/run/aquarium-cam/data.txt
      ```

    - Check if FFmpeg is running and if not, start it
      ```
      ./aquarium-cam.sh --op CHECK-PROC

      ./aquarium-cam.sh --op CHECK-PROC
      ```
      ^^^ <br/>
      The second command should have output: <br/>
      `Aquarium CAM streaming   -> OK`


1. Create cron jobs
   The target is to retrieve fresh measurement data every minute, as well to
   check if _FFmpeg_ is still running every minute and if not, reastart it.
   Therefore edit the user crontab - as root use `crontab -u aquarium-cam -e`
   and add following commands:
   ```
   # Retrieve fresh data from Arduino measurement unit
   * * * * *   cd ~aquarium-cam && ./aquarium-cam.sh --op GET-DATA   1>/dev/null
 
   # Check if FFmpeg is running, if not, start it
   * * * * *   cd ~aquarium-cam && sleep 5 && ./aquarium-cam.sh --op CHECK-PROC 1>/dev/null
   ```
   ^^^ <br/>
   **ATTENTION:** The script logic check if two instances of the same script are
   running at the same time. Therefore, the _FFmpeg_ check should be deferred -
   this is what `sleep 5` is there for.
