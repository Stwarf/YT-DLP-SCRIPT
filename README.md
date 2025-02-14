# YT-DLP-SCRIPT
A script to download YT videos at best audio/video quality that utilizes yt-dlp, ffmpeg, mkvmerge and faster-whisper ai to generate subtitles and embed them to an mkv formatted video. 
The script will prefer manually uploaded subtitles by skipping the faster-whisper ai generation section to then download the manual subtitles and merge those instead.
I notcied when writing the script that I had to use python 3.11 in a venv so there are checks in place to assist with that.
Also tmp files are stored in $HOME/Documents/tmp and you can change that to how you see see fit
Scripts Outputs to $HOME/Downloads
Lastly I want to add a diclaimer that I did not write most of this for I'm still learning scripting and used a ton of chat gpt.
If anyone has any suggestions to help either trim some of the fat of this script or add things to make it more efficient I'm very open to it.
Built out of necessity and works great on my Macbook Pro M4 Pro.
Scripts Outputs to $HOME/Downloads
