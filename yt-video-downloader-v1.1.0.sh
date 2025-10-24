
#!/bin/bash

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed. Please install Homebrew from https://brew.sh/ before continuing."
    exit 1
fi

# Check if Python 3.8+ is installed
PYTHON_VERSION=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:3])))')
PYTHON_MAJOR=$(echo "$PYTHON_VERSION" | cut -d. -f1)
PYTHON_MINOR=$(echo "$PYTHON_VERSION" | cut -d. -f2)

if [ "$PYTHON_MAJOR" -lt 3 ] || { [ "$PYTHON_MAJOR" -eq 3 ] && [ "$PYTHON_MINOR" -lt 8 ]; }; then
    echo "❌ Python 3.8 or higher is required. You have version $PYTHON_VERSION"
    echo "Please install a newer version of Python using Homebrew:"
    echo "  brew install python"
    exit 1
fi

# Set directories
VENV_DIR="$HOME/whisper-env"
TMP_DIR="$(mktemp -d)"
OUTPUT_DIR="$HOME/Downloads"
MODEL_DIR="$HOME/whisper-env/models"

# Use manually exported cookies from Web Browser.
# Make sure to export your cookies (e.g., using a browser extension)
# and save them as "$HOME/cookies.txt".
COOKIES_OPTION="--cookies $HOME/cookies.txt"

# Check for cookies file
if [ ! -f "$HOME/cookies.txt" ]; then
    echo "❌ Cookies file not found at $HOME/cookies.txt."
    echo "Please export your Arc cookies and save them to this file."
    exit 1
fi

# Ensure temp and output directories exist
mkdir -p "$TMP_DIR"
mkdir -p "$OUTPUT_DIR"

# Function to activate the virtual environment
activate_venv() {
    source "$VENV_DIR/bin/activate"
    echo "✅ Activated virtual environment: $VENV_DIR"
}

# Check if we are inside the "whisper-env" virtual environment
if [[ -z "$VIRTUAL_ENV" || "$(basename "$VIRTUAL_ENV")" != "whisper-env" ]]; then
    echo "🔍 Not inside the 'whisper-env' virtual environment."

    # If the virtual environment does not exist, create it in the home directory
    if [ ! -d "$VENV_DIR" ]; then
        echo "⚙️ Creating virtual environment '$VENV_DIR'..."
        python3 -m venv "$VENV_DIR"
        activate_venv
        echo "📦 Installing dependencies in '$VENV_DIR'..."
        pip install --upgrade pip yt-dlp ffmpeg mkvtoolnix faster-whisper
    fi

    # Activate the virtual environment
    activate_venv
fi

# Ensure required tools are installed
if ! command -v yt-dlp &> /dev/null; then
    echo "❌ yt-dlp is not installed. Install it first."
    exit 1
fi

if ! command -v ffmpeg &> /dev/null; then
    echo "❌ ffmpeg is not installed. Install it first."
    exit 1
fi

if ! command -v mkvmerge &> /dev/null; then
    echo "❌ MKVToolNix (mkvmerge) is not installed. Install it first."
    exit 1
fi

if ! python3 -c "import faster_whisper" 2>/dev/null; then
    echo "❌ Faster Whisper is not installed in '$VENV_DIR'. Installing it now..."
    pip install faster-whisper
fi

# Ask for YouTube video URL
read -p "Enter the YouTube video URL: " VIDEO_URL

# Get the original YouTube title, remove extra spaces and trim it
VIDEO_TITLE=$(yt-dlp $COOKIES_OPTION --get-filename -o "%(title)s" "$VIDEO_URL" | sed 's/[^a-zA-Z0-9 ._-]/ /g' | tr -s ' ' | xargs)

# Define file paths
VIDEO_FILE="$TMP_DIR/${VIDEO_TITLE}.mkv"
SUBTITLE_FILE="$TMP_DIR/${VIDEO_TITLE}.srt"
FINAL_OUTPUT="$OUTPUT_DIR/${VIDEO_TITLE}.mkv"  # No "_final" in filename

echo "🎥 Downloading best quality video and audio..."
yt-dlp $COOKIES_OPTION -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best" --merge-output-format mkv -o "$VIDEO_FILE" "$VIDEO_URL"

# Ensure video file exists
if [ ! -f "$VIDEO_FILE" ]; then
    echo "❌ Error: No video file found!"
    exit 1
fi

# Download subtitles (if available)
echo "📥 Checking for manually uploaded subtitles..."
yt-dlp $COOKIES_OPTION --write-subs --skip-download -o "$TMP_DIR/${VIDEO_TITLE}.%(ext)s" "$VIDEO_URL"

# Detect any English subtitle variant
SUBTITLE_VTT=$(find "$TMP_DIR" -type f -iname "*en*.vtt" | head -n 1)
SUBTITLE_SRT=$(find "$TMP_DIR" -type f -iname "*.srt" | head -n 1)
AUDIO_FILE="$TMP_DIR/${VIDEO_TITLE}.m4a"

# Convert VTT to SRT if needed
if [ -n "$SUBTITLE_VTT" ]; then
    echo "🔄 Converting detected VTT subtitle to SRT..."
    ffmpeg -i "$SUBTITLE_VTT" "$SUBTITLE_FILE"
    rm "$SUBTITLE_VTT"
    echo "✅ Subtitles converted and ready."
elif [ -n "$SUBTITLE_SRT" ]; then
    mv "$SUBTITLE_SRT" "$SUBTITLE_FILE"
    echo "✅ Using manually uploaded SRT subtitles."
else
    echo "⚠️ No manually uploaded subtitles found. Generating new ones with Faster Whisper..."

    echo "🎵 Downloading best quality audio for Faster Whisper..."
    yt-dlp $COOKIES_OPTION -f "bestaudio/best" --extract-audio --audio-format m4a -o "$AUDIO_FILE" "$VIDEO_URL"
    
    if [ ! -f "$AUDIO_FILE" ]; then
        echo "❌ Error: No valid audio file found for Faster Whisper! Check if yt-dlp downloaded an audio file."
        exit 1
    else
        echo "✅ Found audio file: $AUDIO_FILE"
    fi

    # Generate subtitles using Faster Whisper with real-time status updates
    python3 - <<EOF
import os
import sys
from faster_whisper import WhisperModel

model_size = "large-v2" if os.path.exists("$MODEL_DIR/large-v2") else "small"
print(f"🧠 Using Faster Whisper model: {model_size}")

model = WhisperModel(model_size, compute_type="int8", download_root="$MODEL_DIR")

print("📝 Transcribing audio... This may take a while.")
segments, _ = model.transcribe("$AUDIO_FILE", word_timestamps=True)

def format_time(seconds):
    millisec = int((seconds - int(seconds)) * 1000)
    return f"{int(seconds // 3600):02}:{int((seconds % 3600) // 60):02}:{int(seconds % 60):02},{millisec:03}"

with open("$SUBTITLE_FILE", "w", encoding="utf-8") as srt_file:
    for i, segment in enumerate(segments):
        start = format_time(segment.start)
        end = format_time(segment.end)
        text = segment.text.strip()
        print(f"⏳ Segment {i+1}: {start} --> {end} | {text}")
        srt_file.write(f"{i+1}\n{start} --> {end}\n{text}\n\n")

print("✅ Whisper-generated subtitles saved as SRT.")
EOF

    if [ -f "$SUBTITLE_FILE" ] && [ -s "$SUBTITLE_FILE" ]; then
        echo "✅ Whisper AI subtitles generated."
    else
        echo "❌ Error: Failed to generate subtitles."
        exit 1
    fi
fi

# Step 1: Deep Clean and Reconstruct SRT Using Python
echo "🧹 Deep cleaning and reconstructing SRT file..."
python3 - <<EOF
import re

input_file = "$SUBTITLE_FILE"
output_file = "$TMP_DIR/cleaned.srt"

try:
    with open(input_file, 'r', encoding='utf-8') as infile:
        content = infile.readlines()

    # Debug: Show first few lines of the original SRT
    print("🔍 Sample of Original SRT:")
    for line in content[:10]:
        print(line.strip())

    cleaned_content = []
    timestamp_pattern = re.compile(r'\d{2}:\d{2}:\d{2},\d{3}')

    index = 1
    for line in content:
        line = line.strip()
        if line.isdigit():
            continue
        if timestamp_pattern.match(line):
            cleaned_content.append(f"{index}")
            index += 1
            cleaned_content.append(line)
        elif line:
            cleaned_content.append(line)
        else:
            cleaned_content.append("")

    if not cleaned_content:
        print("❌ No valid subtitle blocks found.")
        exit(1)

    with open(output_file, 'w', encoding='utf-8') as outfile:
        outfile.write("\n".join(cleaned_content))

    print("✅ Deep clean completed: Cleaned SRT saved.")
except Exception as e:
    print(f"❌ Failed to reconstruct SRT: {e}")
    exit(1)
EOF

# Step 2: Validate the cleaned SRT using ffmpeg
echo "🔧 Validating and reformatting cleaned SRT with ffmpeg..."
if [ -f "$TMP_DIR/cleaned.srt" ]; then
    ffmpeg -y -i "$TMP_DIR/cleaned.srt" -c:s srt "$TMP_DIR/formatted.srt"
    if [ -f "$TMP_DIR/formatted.srt" ]; then
        mv "$TMP_DIR/formatted.srt" "$SUBTITLE_FILE"
        echo "✅ SRT successfully cleaned and reformatted for mkvmerge."
    else
        echo "❌ Failed to reformat SRT with ffmpeg."
        exit 1
    fi
else
    echo "❌ Cleaned SRT not found."
    exit 1
fi

# Merge video, audio, and subtitles into final MKV
echo "📀 Embedding subtitles into final MKV..."
if [ -f "$SUBTITLE_FILE" ]; then
    mkvmerge -o "$FINAL_OUTPUT" \
      --track-name 0:"English Subtitles" \
      --default-track 0:yes --forced-track 0:yes \
      "$VIDEO_FILE" --language 0:eng "$SUBTITLE_FILE"
    rm -f "$SUBTITLE_FILE"  # ✅ Delete .srt file after merging
else
    mkvmerge -o "$FINAL_OUTPUT" "$VIDEO_FILE"
fi

# Cleanup temporary files
echo "🧹 Cleaning up temporary files..."
rm -rf "$TMP_DIR"/*

echo "✅ Done! Your final MKV file with subtitles is saved in: $FINAL_OUTPUT"
