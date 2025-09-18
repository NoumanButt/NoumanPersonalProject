Param(
    [string]$OutPath = "assets/background.jpg",
    [int]$Width = 1280,
    [int]$Height = 720,
    [string]$Background = "#111827",
    [string]$Foreground = "#F9FAFB",
    [string]$Text = "Your Channel"
)

$ErrorActionPreference = 'Stop'

function Ensure-Directory {
    param([string]$Path)
    $dir = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
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

Ensure-Directory -Path $OutPath
$bmp = New-Object System.Drawing.Bitmap $Width, $Height
$gfx = [System.Drawing.Graphics]::FromImage($bmp)
$gfx.SmoothingMode = 'AntiAlias'
$gfx.Clear((From-HexColor $Background))

$fontSize = [Math]::Max(28, [Math]::Min($Height/8, 72))
$font = New-Object System.Drawing.Font('Arial', $fontSize, [System.Drawing.FontStyle]::Bold)
$brush = New-Object System.Drawing.SolidBrush (From-HexColor $Foreground)

$fmt = New-Object System.Drawing.StringFormat
$fmt.Alignment = 'Center'
$fmt.LineAlignment = 'Center'

$rect = New-Object System.Drawing.RectangleF(0, 0, $Width, $Height)
$gfx.DrawString($Text, $font, $brush, $rect, $fmt)

# Save JPEG with quality
$codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
$encParams = New-Object System.Drawing.Imaging.EncoderParameters 1
$encParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter ([System.Drawing.Imaging.Encoder]::Quality), 90
$bmp.Save($OutPath, $codec, $encParams)

$brush.Dispose(); $font.Dispose(); $gfx.Dispose(); $bmp.Dispose()
$resolved = (Get-Item -LiteralPath $OutPath).FullName
Write-Host "Generated: $resolved" -ForegroundColor Green
