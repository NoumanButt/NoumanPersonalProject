Param(
  [string]$BrollDir = "assets/broll",
  [string]$Audio = "build/narration.wav",
  [string]$Music = "assets/music.mp3",
  [int]$Duration = 6,
  [string]$OutVideo = "build/broll_video.mp4"
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Audio)) { throw "Audio not found: $Audio" }

$env:Path = [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')

function Ensure-Dir([string]$p){ if (-not (Test-Path -LiteralPath $p)) { New-Item -ItemType Directory -Force -Path $p | Out-Null } }

if (-not (Test-Path -LiteralPath $BrollDir)) { throw "B-roll directory not found: $BrollDir" }
$items = Get-ChildItem -LiteralPath $BrollDir -File -Include *.jpg,*.jpeg,*.png,*.mp4,*.mov | Sort-Object Name
if (-not $items) { throw "No media found in $BrollDir (jpg/png/mp4)" }

$tmp = Join-Path 'build' 'broll_tmp'
Ensure-Dir $tmp
Remove-Item -LiteralPath $tmp\* -Force -Recurse -ErrorAction SilentlyContinue
Ensure-Dir $tmp

$fps = 25
$fade = 0.6

$segs = @()
$idx = 0
foreach ($it in $items) {
  $idx++
  $seg = Join-Path $tmp ('seg{0:D2}.mp4' -f $idx)
  $ext = $it.Extension.ToLower()
  if ($ext -in @('.jpg','.jpeg','.png')) {
    $frames = $Duration * $fps
    ffmpeg -y -hide_banner -loglevel error -loop 1 -t $Duration -i "$($it.FullName)" -vf "scale=1280:720,format=yuv420p,zoompan=z='min(zoom+0.002,1.15)':d=$frames:s=1280x720,fade=t=in:st=0:d=0.5,fade=t=out:st=$([Math]::Max(0,[Math]::Round($Duration-0.5,2))):d=0.5" -r $fps -c:v libx264 -pix_fmt yuv420p -an "$seg"
  } else {
    ffmpeg -y -hide_banner -loglevel error -t $Duration -i "$($it.FullName)" -vf "scale=1280:720,format=yuv420p,fade=t=in:st=0:d=0.5,fade=t=out:st=$([Math]::Max(0,[Math]::Round($Duration-0.5,2))):d=0.5" -r $fps -c:v libx264 -pix_fmt yuv420p -an "$seg"
  }
  $segs += $seg
}

if ($segs.Count -eq 1) {
  Copy-Item $segs[0] $OutVideo -Force
} else {
  $current = $segs[0]
  for ($i=1; $i -lt $segs.Count; $i++) {
    $next = $segs[$i]
    $tmpOut = Join-Path $tmp ('mix{0:D2}.mp4' -f $i)
    $off = [Math]::Max(0,[Math]::Round($Duration - $fade,2))
    ffmpeg -y -hide_banner -loglevel error -i "$current" -i "$next" -filter_complex "[0:v][1:v]xfade=transition=fade:duration=$fade:offset=$off,format=yuv420p[v]" -map "[v]" -c:v libx264 -pix_fmt yuv420p "$tmpOut"
    $current = $tmpOut
  }
  Copy-Item $current $OutVideo -Force
}

# Mix audio (narration + optional music with ducking)
if (Test-Path -LiteralPath $Music) {
  ffmpeg -y -hide_banner -loglevel error -i "$OutVideo" -i "$Audio" -i "$Music" -filter_complex "[2:a]volume=0.12[m];[1:a][m]sidechaincompress=threshold=0.05:ratio=8:attack=5:release=350:makeup=3[a]" -map 0:v -map "[a]" -shortest -c:v copy -c:a aac -b:a 192k "$OutVideo.tmp.mp4"
} else {
  ffmpeg -y -hide_banner -loglevel error -i "$OutVideo" -i "$Audio" -map 0:v -map 1:a -shortest -c:v copy -c:a aac -b:a 192k "$OutVideo.tmp.mp4"
}
Move-Item -Force "$OutVideo.tmp.mp4" "$OutVideo"

Write-Host "B-roll video assembled: $((Resolve-Path -LiteralPath $OutVideo))" -ForegroundColor Green

