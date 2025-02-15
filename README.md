# YT-DLP-BASH/Python-SCRIPT

Required to be installed before running
yt-dlp
ffmpeg
mkvmerge
faster_whisper(int8) for macOS Compatability
python3.11 or newer

Description:
Simply a Bash script to download YT videos at best audio/video quality that utilizes Python, yt-dlp, ffmpeg, mkvmerge and faster-whisper AI to generate subtitles and embed them to an mkv formatted video. 
The script will prefer manually uploaded subtitles by skipping the faster-whisper ai generation section to then download the manual subtitles and merge those instead.
I notcied when writing the script that I had to use python 3.11 in a venv so there are checks in place to assist with that.
Lastly I want to add a diclaimer that I did not write most of this for I'm still learning scripting and used a ton of chatgpt.
If anyone has any suggestions to help either trim some of the fat of this script or add things to make it more efficient I'm very open to it.
Built out of necessity and works great on my Macbook Pro M4 Pro.


NOTES:
* Script Outputs to $HOME/Downloads
* faster-whisper precision int8 must be run in a venv of python3.11 or else it won't work. The script should help walk you through it
* tempfiles will be deleted a the end of a successful execution of the script
