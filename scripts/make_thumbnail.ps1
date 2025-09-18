Param(
    [string]$Text = "Sample Video",
    [string]$OutPath = "build/thumbnail.jpg",
    [string]$Background = "#0F172A",
    [string]$Foreground = "#FDE047"
)

$ErrorActionPreference = 'Stop'

# Reuse the image generator to create a 1280x720 thumbnail
powershell -NoProfile -ExecutionPolicy Bypass -File "$PSScriptRoot/make_image.ps1" -Text $Text -OutPath $OutPath -Width 1280 -Height 720 -Background $Background -Foreground $Foreground
Write-Host "Thumbnail created at: $((Resolve-Path -LiteralPath $OutPath))" -ForegroundColor Green

