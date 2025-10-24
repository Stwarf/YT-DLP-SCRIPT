
# 🎬 YouTube Video Downloader With Subtitle Embedder Using Faster-Whisper (macOS)

This script downloads a YouTube video, checks for manually uploaded subtitles, and if not found, generates them using [Faster Whisper](https://github.com/guillaumekln/faster-whisper). It then embeds the subtitles into the final MKV file.

## ✅ Features

- Detects and uses manually uploaded subtitles if available
- Converts `.vtt` subtitles to `.srt` and cleans them up
- Uses `Faster Whisper` (large-v2 or small model) for high-quality speech-to-text transcription if subtitles are missing
- Embeds `.srt` subtitles directly into the downloaded `.mkv`
- Uses macOS system temporary directory
- Handles virtual environment and model downloads automatically

## 🧰 Requirements

- macOS
- Python 3.8+
- Homebrew (used to install dependencies)
- Get cookies.txt LOCALLY (browser extension) (saved to `~/cookies.txt`)

### Dependencies installed via Homebrew:

- `yt-dlp`
- `ffmpeg`
- `mkvtoolnix`

### Python Packages (installed in a virtual environment `~/whisper-env`):

- `faster-whisper`
- `yt-dlp`
- `ffmpeg`
- `mkvtoolnix`

## 🚀 Setup Instructions

1. **Install Homebrew** (if not installed):
    ```sh
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ```

2. **Export your Web Browser cookies** (e.g., with an extension like Get cookies.txt LOCALLY) and save them to:
    ```
    ~/cookies.txt
    ```

3. **Run the script:**
    ```sh
    ./yt-video-downloader-v1.0.0.sh
    ```

4. Paste your desired YouTube URL when prompted.

## 📂 Output

Final `.mkv` with embedded subtitles is saved to:
```
~/Downloads/
```

## ⚠️ Notes

- cookies.txt must be saved in root of home directory because that's where the script looks for cookies file.
- If no manually uploaded subtitles are found, the script transcribes audio using Faster Whisper.
- It uses the macOS system temp directory (`/var/folders/...`) for temporary operations.
- If `large-v2` Faster Whisper model is not found locally, it defaults to `small`.

## 🧹 Cleanup

All temporary files are automatically deleted after the script finishes.

## 📜 License

MIT License. Free to use and modify.
