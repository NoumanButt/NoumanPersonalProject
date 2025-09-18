Param(
    [Parameter(Mandatory=$true)][string]$Title,
    [string]$TextPath,
    [string]$Text,
    [ValidateSet('slideshow','image')][string]$Mode = 'slideshow',
    [string]$Storyboard = "content/episode_002_storyboard.json",
    [string]$BackgroundText,
    [switch]$GenerateCaptions = $true,
    [switch]$UseExistingAudio = $false
)

$ErrorActionPreference = 'Stop'
$scripts = $PSScriptRoot

function Ensure-Path() {
  $env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
}

function Run-TTS([string]$inTextPath, [string]$inlineText) {
  $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File', (Join-Path $scripts 'tts.ps1'))
  if ($inTextPath) { $args += @('-TextPath', $inTextPath) }
  if ($inlineText) { $args += @('-Text', $inlineText) }
  $args += @('-OutPath','build/narration.wav')
  powershell @args | Out-Null
}

function Make-Background([string]$text) {
  $t = if ($text) { $text } elseif ($Title) { $Title } else { 'Your Channel' }
  powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scripts 'make_image.ps1') -Text $t -OutPath 'assets/background.jpg' | Out-Null
}

function Build-ImageVideo() {
  Ensure-Path
  if (-not (Test-Path 'assets/background.jpg')) { Make-Background $BackgroundText }
  ffmpeg -y -hide_banner -loglevel error -loop 1 -i .\assets\background.jpg -i .\build\narration.wav -shortest -c:v libx264 -tune stillimage -vf "scale=1280:720,format=yuv420p" -c:a aac -b:a 192k .\build\video_base.mp4
  return (Resolve-Path .\build\video_base.mp4).Path
}

function Build-Slideshow([string]$storyboardPath) {
  if (-not (Test-Path -LiteralPath $storyboardPath)) { throw "Storyboard not found: $storyboardPath" }
  powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scripts 'make_slides.ps1') -Storyboard $storyboardPath -OutDir 'build/slides' | Out-Null
  powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scripts 'assemble_storyboard.ps1') -SlidesDir 'build/slides' -Audio 'build/narration.wav' -OutVideo 'build/story_video.mp4' | Out-Null
  return (Resolve-Path .\build\story_video.mp4).Path
}

function Maybe-Captions() {
  if (-not $GenerateCaptions) { return }
  $hasWhisper = (Get-Command whisper-ctranslate2 -ErrorAction SilentlyContinue)
  if (-not $hasWhisper) {
    Write-Warning 'whisper-ctranslate2 not found; skipping captions. Install with: py -m pip install whisper-ctranslate2'
    return
  }
  $env:PYTHONIOENCODING='utf-8'
  whisper-ctranslate2 .\build\narration.wav --model base.en --task transcribe --language en --output_format srt --output_dir .\build | Out-Null
}

function Make-Thumbnail() {
  powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scripts 'make_thumbnail.ps1') -Text $Title -OutPath 'build/thumbnail.jpg' | Out-Null
}

# 1) TTS (or reuse existing narration)
if ($UseExistingAudio -and (Test-Path 'build/narration.wav')) {
  Write-Host 'Using existing build/narration.wav' -ForegroundColor Yellow
} else {
  if (-not $Text -and -not $TextPath) { throw 'Provide -Text or -TextPath for narration (or pass -UseExistingAudio with build/narration.wav present).' }
  Run-TTS -inTextPath $TextPath -inlineText $Text
}

# 2) Visuals
$videoPath = if ($Mode -eq 'slideshow') { Build-Slideshow $Storyboard } else { Build-ImageVideo }

# 3) Captions (optional)
Maybe-Captions

# 4) Thumbnail
Make-Thumbnail

# 5) Package
powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $scripts 'prepare_release.ps1') -Title $Title -Video $videoPath -Captions 'build/narration.srt' -Thumbnail 'build/thumbnail.jpg' | Out-Null

$rel = Get-ChildItem .\release -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
Write-Host "Release ready: $rel" -ForegroundColor Green
$mp4 = Get-ChildItem $rel -Filter *.mp4 | Select-Object -First 1 -ExpandProperty FullName
if ($mp4) { Start-Process -FilePath $mp4 }

# 6) Write build manifest
$capPath = $null; if (Test-Path 'build/narration.srt') { $capPath = (Resolve-Path 'build/narration.srt').Path }
$thumbPath = (Resolve-Path 'build/thumbnail.jpg').Path
$bgPath = $null; if (Test-Path 'assets/background.jpg') { $bgPath = (Resolve-Path 'assets/background.jpg').Path }
$brollPath = $null; if (Test-Path 'assets/broll') { $brollPath = (Resolve-Path 'assets/broll').Path }
$musicPath = $null; if (Test-Path 'assets/music.mp3') { $musicPath = (Resolve-Path 'assets/music.mp3').Path }

$manifest = [PSCustomObject]@{
  title = $Title
  mode = $Mode
  text_path = $TextPath
  storyboard = if ($Mode -eq 'slideshow') { $Storyboard } else { $null }
  outputs = [PSCustomObject]@{
    release_dir = $rel
    video = $videoPath
    captions = $capPath
    thumbnail = $thumbPath
  }
  inputs = [PSCustomObject]@{
    background = $bgPath
    broll_dir = $brollPath
    music = $musicPath
  }
  timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
}
$manifest | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 .\build\last_build.json
