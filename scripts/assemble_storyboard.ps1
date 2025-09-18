Param(
    [string]$SlidesDir = "build/slides",
    [string]$Audio = "build/narration.wav",
    [string]$OutVideo = "build/story_video.mp4"
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $SlidesDir)) { throw "Slides not found: $SlidesDir" }
if (-not (Test-Path -LiteralPath $Audio)) { throw "Audio not found: $Audio" }
$audioAbs = (Resolve-Path -LiteralPath $Audio).Path

$manifestPath = Join-Path $SlidesDir 'manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath)) { throw "Missing manifest: $manifestPath" }
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json

# Probe audio duration with ffprobe
$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')
$duration = & ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$audioAbs"
$audioDur = [double]::Parse($duration, [System.Globalization.CultureInfo]::InvariantCulture)

$segments = @()
$totalDur = 0.0
foreach ($m in $manifest) { $totalDur += [double]$m.duration }

if ($totalDur -lt $audioDur) {
    # Extend last slide to cover audio
    $delta = $audioDur - $totalDur
    $manifest[-1].duration = [double]$manifest[-1].duration + $delta
}

# Render per-slide video segments with fade in/out
$tempDir = Join-Path $SlidesDir 'segments'
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

$idx = 0
foreach ($m in $manifest) {
    $idx++
    $d = [double]$m.duration
    if ($d -lt 2.0) { $d = 2.0 }
    $segName = 'seg{0:D2}.mp4' -f $idx
    $outSeg = Join-Path $tempDir $segName
    & ffmpeg -y -hide_banner -loglevel error -loop 1 -i "$($m.file)" -t $d -vf "scale=1280:720,format=yuv420p,fade=t=in:st=0:d=0.5,fade=t=out:st=$([Math]::Max(0,[Math]::Round($d-0.7,2))):d=0.7" -r 25 -c:v libx264 -pix_fmt yuv420p -an "$outSeg"
    $segments += $segName
}

# Concat segments
$listPath = Join-Path $tempDir 'list.txt'
Push-Location $tempDir
$segments | ForEach-Object { "file '$_'" } | Out-File -Encoding ascii (Split-Path -Leaf $listPath)
& ffmpeg -y -hide_banner -loglevel error -f concat -safe 0 -i "list.txt" -i "$audioAbs" -c:v libx264 -pix_fmt yuv420p -c:a aac -b:a 192k -shortest "$([IO.Path]::GetFullPath($OutVideo))"
Pop-Location

Write-Host "Assembled: $((Resolve-Path -LiteralPath $OutVideo))" -ForegroundColor Green
