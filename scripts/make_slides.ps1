Param(
    [string]$Storyboard = "content/episode_002_storyboard.json",
    [string]$OutDir = "build/slides"
)

$ErrorActionPreference = 'Stop'

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

Add-Type -AssemblyName System.Drawing

function From-HexColor([string]$hex) {
    $h = $hex.TrimStart('#')
    [System.Drawing.Color]::FromArgb(
        [Convert]::ToInt32($h.Substring(0,2),16),
        [Convert]::ToInt32($h.Substring(2,2),16),
        [Convert]::ToInt32($h.Substring(4,2),16)
    )
}

if (-not (Test-Path -LiteralPath $Storyboard)) { throw "Storyboard not found: $Storyboard" }
$spec = Get-Content -LiteralPath $Storyboard -Raw | ConvertFrom-Json

$W = [int](@($spec.width)[0]); $H = [int](@($spec.height)[0])
$bg = From-HexColor (@($spec.background)[0])
$primary = From-HexColor (@($spec.primary)[0])
$secondary = From-HexColor (@($spec.secondary)[0])
$fontName = (@($spec.font)[0])

Ensure-Directory -Path $OutDir
Remove-Item -LiteralPath $OutDir\* -Force -Recurse -ErrorAction SilentlyContinue
Ensure-Directory -Path $OutDir

$slideIndex = 0
$manifest = @()

foreach ($s in $spec.slides) {
    $slideIndex++
    $bmp = New-Object System.Drawing.Bitmap $W, $H
    $gfx = [System.Drawing.Graphics]::FromImage($bmp)
    $gfx.SmoothingMode = 'AntiAlias'
    $gfx.TextRenderingHint = 'AntiAliasGridFit'
    $gfx.Clear($bg)

    if ($s.title) {
        $titleFont = New-Object System.Drawing.Font($fontName, 56, [System.Drawing.FontStyle]::Bold)
        $availW = [single]($W - 120)
        $titleRect = New-Object System.Drawing.RectangleF([single]60, [single]60, $availW, [single]180)
        $brush = New-Object System.Drawing.SolidBrush $primary
        $format = New-Object System.Drawing.StringFormat
        $format.Alignment = 'Near'; $format.LineAlignment = 'Near'
        $gfx.DrawString([string]$s.title, $titleFont, $brush, $titleRect, $format)
        $titleFont.Dispose(); $brush.Dispose()
    }

    if ($s.subtitle) {
        $subFont = New-Object System.Drawing.Font($fontName, 28, [System.Drawing.FontStyle]::Regular)
        $availW = [single]($W - 120)
        $subRect = New-Object System.Drawing.RectangleF([single]60, [single]180, $availW, [single]120)
        $brush = New-Object System.Drawing.SolidBrush $secondary
        $format = New-Object System.Drawing.StringFormat
        $format.Alignment = 'Near'; $format.LineAlignment = 'Near'
        $gfx.DrawString([string]$s.subtitle, $subFont, $brush, $subRect, $format)
        $subFont.Dispose(); $brush.Dispose()
    }

    if ($s.lines) {
        $y = [single]300
        foreach ($line in $s.lines) {
            $fontSize = 40
            if ($line -match '^(Dua:|Protection:|Verses:|Hook:)') { $fontSize = 34 }
            $font = New-Object System.Drawing.Font($fontName, $fontSize, [System.Drawing.FontStyle]::Bold)
            $brush = New-Object System.Drawing.SolidBrush $secondary
            if ($line -match '(^It has|^We will|^O Allah|Jahannam|Jannah|Qur)') {
                $brush.Dispose(); $brush = New-Object System.Drawing.SolidBrush $primary
            }
            $availW = [single]($W - 120)
            $rect = New-Object System.Drawing.RectangleF([single]60, $y, $availW, [single]100)
            $fmt = New-Object System.Drawing.StringFormat
            $fmt.Alignment = 'Near'; $fmt.LineAlignment = 'Near'
            $gfx.DrawString([string]$line, $font, $brush, $rect, $fmt)
            $y = [single]($y + 80)
            $font.Dispose(); $brush.Dispose()
        }
    }

    $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
    $encParams = New-Object System.Drawing.Imaging.EncoderParameters 1
    $encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), 92
    $outPath = Join-Path $OutDir ('slide{0:D2}.jpg' -f $slideIndex)
    $bmp.Save($outPath, $codec, $encParams)
    $gfx.Dispose(); $bmp.Dispose()

    $manifest += [PSCustomObject]@{ file = (Resolve-Path -LiteralPath $outPath).Path; duration = [double]$s.duration }
}

$manifest | ConvertTo-Json | Out-File -Encoding utf8 (Join-Path $OutDir 'manifest.json')
Write-Host "Slides written to $OutDir" -ForegroundColor Green
