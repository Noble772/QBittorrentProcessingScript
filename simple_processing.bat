@echo off
setlocal enabledelayedexpansion

cd /d "%1"
for %%I in (.) do set DirName=%%~nxI

set mkvmerge="C:\Programs\mkvtoolnix\mkvtoolnix\mkvmerge.exe"
set python="C:\Users\Admin\AppData\Local\Programs\Python\Python311\python.exe"
set options_json="C:\Scripts\options.json"
set subtitlescript="C:\Scripts\renamer.py"

set importdir=G:\Import
set cachedir="B:\%DirName%"
set downloaddir="%cd%"

:: Create .tag file for import
copy NUL %2.tag

if EXIST readarr.tag (
    robocopy /e /mir %downloaddir% "%importdir%\Readarr\%DirName%"
	exit
)

if EXIST lidarr.tag (
    robocopy /e /mir %downloaddir% "%importdir%\Lidarr\%DirName%"
	exit
)

:: Copy files to cache drive
robocopy /e /mir %downloaddir% %cachedir%
cd /d %cachedir%

:: Apply changes to files
copy "%options_json%" options.json
for /r %%x in (*.mp4) do ren "%%x" *.old
for /r %%f in (*.old) do (
    %mkvmerge% @options.json -o "%%~dpnf.mkv" "%%f"
	TIMEOUT /T 1
    del /s "%%f"
)

:: Run renamer script
%python% "C:\Scripts\renamer.py" %cachedir%

:: Move files to appropriate import directories
:IMPORT
if EXIST sonarr.tag (
    robocopy /e /move %cachedir% "%importdir%\Sonarr\%DirName%"
	exit
)
if EXIST radarr4k.tag (
    robocopy /e /move %cachedir% "%importdir%\Radarr4k\%DirName%"
	exit
)
if EXIST radarr.tag (
    robocopy /e /move %cachedir% "%importdir%\Radarr\%DirName%"
	exit
)
robocopy /e /move %cachedir% "%importdir%\Manual\%DirName%"
exit