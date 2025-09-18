# Quick Start: YouTube Video Builder (Windows)

This repo lets you create videos fast using PowerShell scripts and open tools. It supports a one‑command build, optional captions, thumbnails, and a bundler that zips everything used into a single folder.

## Prerequisites
- Windows + PowerShell
- FFmpeg installed (winget recommended: `winget install Gyan.FFmpeg`)
- Optional captions: Python 3 + `py -m pip install whisper-ctranslate2`

## 1) Clean (optional)
Start from a clean state:
- `powershell -ExecutionPolicy Bypass -File .\scripts\clean_repo.ps1`

## 2) Add Your Script
- Put your narration text in `content/your_script.txt` (see sample `content/episode_002_en_v2.txt`).

## 3) Build The Video (one command)
Slideshow (recommended):
- `powershell -ExecutionPolicy Bypass -File .\scripts\make_video.ps1 -Title "Your Title" -TextPath .\content\your_script.txt -Mode slideshow -Storyboard .\content\episode_002_storyboard.json`

Single background image:
- `powershell -ExecutionPolicy Bypass -File .\scripts\make_video.ps1 -Title "Your Title" -TextPath .\content\your_script.txt -Mode image`

What it does:
- Generates narration (Windows TTS)
- Creates visuals (slides with fades or single image)
- Generates `.srt` captions if `whisper-ctranslate2` is installed
- Creates a thumbnail
- Packages results in `release/<timestamp>/` and opens the MP4

## 4) Bundle + Zip (archive everything used)
Copy inputs/outputs into a single folder and create a ZIP:
- `powershell -ExecutionPolicy Bypass -File .\scripts\bundle_last_build.ps1`

Move (cut) files into the bundle instead of copying:
- `powershell -ExecutionPolicy Bypass -File .\scripts\bundle_last_build.ps1 -Move`

Result: `bundle/<timestamp>_<Title>/` with `inputs/` + `outputs/` and a `.zip` next to it.

## 5) Upload To YouTube
- Upload the MP4 from `release/` (or from the bundle `outputs/`)
- Subtitles tab: upload the `.srt` (if generated)
- Set the `.jpg` thumbnail
- Add title/description/tags and publish

## Editing & Customization
- Script text: edit files under `content/`
- Slideshow text/length/colors/font: `content/episode_002_storyboard.json`
- Background for image mode: `assets/background.jpg` (auto‑generated if missing)

## Troubleshooting
- FFmpeg not found: restart PowerShell, or ensure it’s on PATH
- Captions skipped: install with `py -m pip install whisper-ctranslate2`
- Execution policy errors: use `-ExecutionPolicy Bypass` as shown above

For more details, see `youtube_ai_workflow.md`.

## Better Voices (Optional)
Windows’ built‑in voice is convenient but basic. For higher quality:

- Piper (offline, fast, open‑source)
  1) Install Piper and download a high‑quality voice (.onnx + .json).
  2) Generate narration:
     `powershell -ExecutionPolicy Bypass -File .\scripts\tts_piper.ps1 -TextPath .\content\your_script.txt -VoiceModel .\voices\en_US-amy-medium.onnx -VoiceConfig .\voices\en_US-amy-medium.onnx.json -OutPath .\build\narration.wav`
  3) Build the video using the existing audio (skip TTS):
     `powershell -ExecutionPolicy Bypass -File .\scripts\make_video.ps1 -Title "Your Title" -Mode slideshow -Storyboard .\content\episode_002_storyboard.json -UseExistingAudio`

- Coqui TTS (offline, high quality, heavier):
  `py -m pip install TTS` then `tts --text "..." --model_name tts_models/en/vctk/vits --out_path build/narration.wav`

- Cloud (best quality, paid): Azure Neural TTS, ElevenLabs, Amazon Polly. Export WAV to `build/narration.wav` and run `make_video.ps1 -UseExistingAudio`.
