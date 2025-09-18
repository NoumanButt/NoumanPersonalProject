Param(
    [string]$Title = "Your First Video",
    [string]$Video = "build/video_base.mp4",
    [string]$Captions = "build/narration.srt",
    [string]$Thumbnail = "build/thumbnail.jpg"
)

$ErrorActionPreference = 'Stop'

$srcVideo = $Video
$srcSubs  = $Captions
$srcThumb = $Thumbnail

if (-not (Test-Path -LiteralPath $srcVideo)) { throw "Missing video: $srcVideo" }

$stamp = (Get-Date).ToString('yyyyMMdd_HHmmss')
$outDir = Join-Path -Path "." -ChildPath "release/$stamp"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$safeTitle = ($Title -replace "[^A-Za-z0-9-_ ]", "").Trim() -replace "\s+","_"

Copy-Item $srcVideo -Destination (Join-Path $outDir "$safeTitle.mp4") -Force
if (Test-Path -LiteralPath $srcSubs)  { Copy-Item $srcSubs  -Destination (Join-Path $outDir "$safeTitle.srt") -Force }
if (Test-Path -LiteralPath $srcThumb) { Copy-Item $srcThumb -Destination (Join-Path $outDir "$safeTitle.jpg") -Force }

Write-Host "Release prepared in: $((Resolve-Path -LiteralPath $outDir))" -ForegroundColor Green
Get-ChildItem $outDir | Select-Object Name, Length | Format-Table -AutoSize
