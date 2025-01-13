@echo off
setlocal enabledelayedexpansion

cd /d "%1"

set mkvmerge="C:\Programs\mkvtoolnix\mkvtoolnix\mkvmerge.exe"
set whisper="C:\Programs\Faster-Whisper-XXL\faster-whisper-xxl.exe"
set subtitleedit="C:\Program Files\Subtitle Edit\SubtitleEdit.exe"
set python="C:\Users\Admin\AppData\Local\Programs\Python\Python311\python.exe"
set options_json="C:\Scripts\options.json"
set importdir=G:\Import
for %%I in (.) do set DirName=%%~nxI
set cachedir="B:\%DirName%"
set downloaddir="%cd%"

:: Check if Whisper should be used to generate subtitles
set generate_subs=no

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

:: Delete Featurettes folder if it exists
del /s /q Featurettes

:: Apply changes to files
copy "%options_json%" options.json
for /r %%x in (*.mp4) do ren "%%x" *.old
for /r %%f in (*.old) do (
    %mkvmerge% @options.json -o "%%~dpnf.mkv" "%%f"
	TIMEOUT /T 1
    del /s "%%f"
)
TIMEOUT /T 1
:: Renames .avi files to .mkv (For subtitle generation and easier tdarr processing)
for /r %%x in (*.avi) do ren "%%x" *.mkv
:: Run renamer script
%python% "C:\Scripts\renamer.py" %cachedir%
TIMEOUT /T 1
:: Rename subtitle files
for /r %%f in (*.mkv) do ren "%%~dpnf.srt" "%%~nf.eng.srt"
:: Convert subtitles to SRT format
%subtitleedit% /convert *.mkv srt /FixCommonErrors
for /d %%a in (*) do (
    cd "%%a"
    %subtitleedit% /convert *.mkv srt /FixCommonErrors
    cd ..
)
TIMEOUT /T 1
:: Rename subtitle files with .en.srt tag to .eng.srt
for /r %%f in (*.mkv) do ren "%%~dpnf.en.srt" "%%~nf.eng.srt"
:: Rename subtitle files with .und.srt tag to .eng.srt
for /r %%f in (*.mkv) do ren "%%~dpnf.und.srt" "%%~nf.eng.srt"
TIMEOUT /T 1
:: Delete subtitles under 5KB
for /f "usebackq delims=;" %%A in (`dir /b /A:-D *.srt`) do If %%~zA LSS 5000 del "%%A"
:: Delete incomplete .mkv files
for /f "usebackq delims=;" %%A in (`dir /b /A:-D *.mkv`) do If %%~zA LSS 50000000 del "%%A"
:: Delete unnecessary subtitle files
for /f "delims=" %%A in ('dir /b *.srt ^| findstr /vi ".eng.srt"') do del "%%A"
del *.#4.eng.srt
for /r %%f in (*.ign) do del "%%f"
for /d %%a in (*) do (
    cd "%%a"
	for /f "usebackq delims=;" %%F in (`dir /b /A:-D *.srt`) do If %%~zF LSS 5000 del "%%F"
	for /f "usebackq delims=;" %%F in (`dir /b /A:-D *.mkv`) do If %%~zF LSS 50000000 del "%%F"
    for /f "usebackq delims=;" %%F in (`dir /b /A:-D *.srt ^| findstr /v /i /c:".eng.srt"`) do del "%%F"
	del *.#4.eng.srt
    cd ..
)
del /s /q Subs
:: Check if Whisper is allowed to generate subs
if "%generate_subs%"=="yes" ( 
    goto SUBCHECK
) else ( 
    goto IMPORT
)
:SUBCHECK
for %%f in (*.mkv) do (
    if not EXIST "%%~nf.eng.srt" (
        goto WHISPERQUEUE
    )
)
for /d %%a in (*) do (
    cd "%%a"
    for %%f in (*.mkv) do (
        if not EXIST "%%~nf.eng.srt" (
            goto WHISPERQUEUE
        )
    )
    cd ..
)
goto IMPORT
:WHISPERQUEUE
:: Check if Whisper is already running, if not generate subtitles
tasklist /NH /FI "imagename eq faster-whisper-xxl.exe" 2>nul | find /i "faster-whisper-xxl.exe" >nul
If not errorlevel 1 (
    echo Queueing...
    TIMEOUT /T 30
    goto WHISPERQUEUE
) else (
    echo Generating Subs!
    goto SUBGEN
)

:SUBGEN
for /r %%f in (*.mkv) do (
    if not EXIST "%%~dpnf.eng.srt" (
        %whisper% "%%f" --language=en --model=large-v3 --output_format=srt --device=cpu -o=source --compute_type="int8" --best_of=3 --beam_size=3
    )
    ren "%%~dpnf.srt" "%%~nf.eng.srt"
)
TIMEOUT /T 1
:: Second pass to make sure all subtitles were generated since sometimes whisper will run out of memory
for /r %%f in (*.mkv) do (
    if not EXIST "%%~dpnf.eng.srt" (
        %whisper% "%%f" --language=en --model=large-v3 --output_format=srt --device=cpu -o=source --compute_type="int8" --best_of=3 --beam_size=3
    )
    ren "%%~dpnf.srt" "%%~nf.eng.srt"
)
TIMEOUT /T 1
:: Triple pass cus I'm paranoid
for /r %%f in (*.mkv) do (
    if not EXIST "%%~dpnf.eng.srt" (
        %whisper% "%%f" --language=en --model=large-v3 --output_format=srt --device=cpu -o=source --compute_type="int8" --best_of=3 --beam_size=3
    )
    ren "%%~dpnf.srt" "%%~nf.eng.srt"
)
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
if EXIST radarr-anime.tag (
    robocopy /e /move %cachedir% "%importdir%\Radarr-Anime\%DirName%"
	exit
)
robocopy /e /move %cachedir% "%importdir%\Manual\%DirName%"
exit
