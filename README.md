# MBPKamera
Program in skripta za stream RTSP na youtube


1.)  Poberi fonte:
- wget -O /usr/local/share/fonts/open-sans.zip "https://www.fontsquirrel.com/fonts/download/open-sans";unzip open-sans.zip

2.)  Editiraj videopredvajanje.sh
- Določi RTSP naslov kamere
- Določi "youtube key" za online predvajanje na youtube-u

3.) Poženeš skripto nohup bash videopredvajanje.sh &

4.) Ker se zna FFMpeg občasno sesuti, je potrebno proces preverjati z crontab-om vsako minuto

crontab -e
* * * * * sudo bash /path_to_script/check_ffmpeg.sh

