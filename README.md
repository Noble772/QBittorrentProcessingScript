These scripts get rid of the stuttering from RARBG releases.

I've included 2 processing scripts with the simple_processing.bat only remuxing the rarbg mp4 files into mkv, reordering the subtitles, and then moving the files to the torrent blackhole and then processing.bat is my own personal processing script.

How to Setup:
First you will need to edit the script to include your own desired directories. You will then need to setup torrent blackholes in your -arr stack.
You will also need to get mkvtoolnix and make sure you have python installed.

Radarr Example:
![image](https://github.com/user-attachments/assets/fb01552c-a200-4d0b-a20e-be982b3df4a9)

(Change the directories to your own directories)

You will then need to add a watch folder in QBittorrent to import the torrent files from your torrent blackhole.
![image](https://github.com/user-attachments/assets/a88ef250-f142-4ca4-a1c4-e533984ce6ca)
![image](https://github.com/user-attachments/assets/36b7dc2c-2177-4d23-b5d7-166c9356a9cb)

Don't forget to add the tag depending on which -arr you're using

You will then need to add the following line to the Run on Torrent Finished in Run External Program section

cmd.exe /c "C:\Scripts\processing.bat" "%R" "%G"

(Change "C:\Scripts\processing.bat" to the location of your script)
