# AI YouTube Workflow (Free & Open‑Source Guide)

This repo helps you quickly create YouTube videos with open tools on Windows. It includes one‑command build, captions, thumbnails, and a bundler that collects all inputs/outputs into a single zipped folder.

---

## Prerequisites
- Windows with PowerShell
- FFmpeg installed (winget: Gyan.FFmpeg). If a new session can’t find it, restart PowerShell.
- Optional for captions: Python 3 + `pip install whisper-ctranslate2`

---

## Quick Start (One Command)
- Put your narration text in `content/your_script.txt`.
- Run slideshow build:
  `powershell -ExecutionPolicy Bypass -File .\scripts\make_video.ps1 -Title "Your Title" -TextPath .\content\your_script.txt -Mode slideshow -Storyboard .\content\episode_002_storyboard.json`
- Or single‑image build:
  `powershell -ExecutionPolicy Bypass -File .\scripts\make_video.ps1 -Title "Your Title" -TextPath .\content\your_script.txt -Mode image`
- Output appears in `release/<timestamp>/` and opens automatically.

---

## Bundle And Zip
- Collect the exact inputs/outputs used (and auto‑zip):
  `powershell -ExecutionPolicy Bypass -File .\scripts\bundle_last_build.ps1`
- Move (cut) the files into the bundle instead of copying:
  `powershell -ExecutionPolicy Bypass -File .\scripts\bundle_last_build.ps1 -Move`
- Result: `bundle/<timestamp>_<Title>/` with `inputs/` and `outputs/` + a `.zip` next to it.

---

## Clean Reset
- Start from a clean state (removes `build/`, `release/`, `bundle/`, recreates `assets/`):
  `powershell -ExecutionPolicy Bypass -File .\scripts\clean_repo.ps1`

---

## What The One‑Command Does
- Generates narration from your text using Windows TTS (`scripts/tts.ps1`).
- Creates visuals:
  - `-Mode slideshow`: builds slides from a JSON storyboard and assembles a video with fades.
  - `-Mode image`: uses a single background image.
- Generates captions (`.srt`) if `whisper-ctranslate2` is installed.
- Creates a thumbnail (`build/thumbnail.jpg`).
- Packages results in `release/<timestamp>/`.
- Writes a build manifest to `build/last_build.json` for bundling.

---

## Files You Can Edit
- `content/episode_002_en_v2.txt` — sample script (edit or add your own).
- `content/episode_002_storyboard.json` — slideshow text, durations, colors, font.
- `assets/background.jpg` — optional background for `-Mode image` (auto‑generated if missing).

---

## Tips
- Keep scripts 60–120s for faster production and better retention.
- Prefer separate `.srt` captions when uploading (more accessible and searchable).
- For richer visuals, add `assets/broll/` images and extend the storyboard.

---

## Policy Notes
- Disclose realistic AI/altered content per YouTube rules.
- Avoid repetitive, low‑effort uploads; always add originality and value.
- Respect API quotas if you automate uploads.

