Param(
  [switch]$Move = $false,
  [string]$OutRoot = "bundle"
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath '.\build\last_build.json')) {
  throw "No build manifest found at build/last_build.json. Run make_video.ps1 first."
}

$m = Get-Content .\build\last_build.json -Raw | ConvertFrom-Json
$title = if ($m.title) { $m.title } else { 'Video' }
$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$safe = (($title -replace "[^A-Za-z0-9-_ ]", '').Trim() -replace '\s+','_')
$bundleDir = Join-Path . $OutRoot
New-Item -ItemType Directory -Force -Path $bundleDir | Out-Null
$bundle = Join-Path $bundleDir ("{0}_{1}" -f $stamp, $safe)
New-Item -ItemType Directory -Force -Path $bundle | Out-Null

function CopyOrMove([string]$src,[string]$dst){
  if (-not $src) { return }
  if (-not (Test-Path -LiteralPath $src)) { return }
  $dstDir = Split-Path -Parent $dst
  New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
  if ($Move) {
    Move-Item -LiteralPath $src -Destination $dst -Force
  } else {
    if (Test-Path -LiteralPath $src -PathType Container) {
      Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
    } else {
      Copy-Item -LiteralPath $src -Destination $dst -Force
    }
  }
}

# Inputs
$inputsDir = Join-Path $bundle 'inputs'
New-Item -ItemType Directory -Force -Path $inputsDir | Out-Null

if ($m.text_path) {
  $src = $m.text_path
  $dst = Join-Path $inputsDir (Join-Path 'content' (Split-Path -Leaf $src))
  CopyOrMove $src $dst
}

if ($m.storyboard) {
  $src = $m.storyboard
  $dst = Join-Path $inputsDir (Join-Path 'storyboard' (Split-Path -Leaf $src))
  CopyOrMove $src $dst
}

if ($m.inputs.background) {
  $src = $m.inputs.background
  $dst = Join-Path $inputsDir (Join-Path 'assets' 'background.jpg')
  CopyOrMove $src $dst
}
if ($m.inputs.broll_dir) {
  $src = $m.inputs.broll_dir
  $dst = Join-Path $inputsDir (Join-Path 'assets' 'broll')
  CopyOrMove $src $dst
}
if ($m.inputs.music) {
  $src = $m.inputs.music
  $dst = Join-Path $inputsDir (Join-Path 'assets' 'music.mp3')
  CopyOrMove $src $dst
}

# Outputs (from release dir if available else from build)
$outputsDir = Join-Path $bundle 'outputs'
New-Item -ItemType Directory -Force -Path $outputsDir | Out-Null

$releaseDir = $m.outputs.release_dir
if (-not $releaseDir -or -not (Test-Path -LiteralPath $releaseDir)) { $releaseDir = '.' }

$video = $m.outputs.video
if (-not $video -and $releaseDir -ne '.') {
  $video = (Get-ChildItem $releaseDir -Filter *.mp4 -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName)
}
if ($video) {
  $dst = Join-Path $outputsDir (Split-Path -Leaf $video)
  CopyOrMove $video $dst
}

$thumb = $m.outputs.thumbnail
if (-not $thumb -and $releaseDir -ne '.') {
  $thumb = (Get-ChildItem $releaseDir -Filter *.jpg -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName)
}
if ($thumb) {
  $dst = Join-Path $outputsDir (Split-Path -Leaf $thumb)
  CopyOrMove $thumb $dst
}

$subs = $m.outputs.captions
if (-not $subs -and $releaseDir -ne '.') {
  $subs = (Get-ChildItem $releaseDir -Filter *.srt -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty FullName)
}
if ($subs) {
  $dst = Join-Path $outputsDir (Split-Path -Leaf $subs)
  CopyOrMove $subs $dst
}

Write-Host "Bundle created at: $((Resolve-Path -LiteralPath $bundle))" -ForegroundColor Green

# Create ZIP archive of the bundle
$zipPath = "$bundle.zip"
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
Compress-Archive -Path (Join-Path $bundle '*') -DestinationPath $zipPath -Force
Write-Host "ZIP created at: $((Resolve-Path -LiteralPath $zipPath))" -ForegroundColor Green
