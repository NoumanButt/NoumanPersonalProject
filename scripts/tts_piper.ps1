Param(
  [string]$TextPath,
  [string]$Text,
  [Parameter(Mandatory=$true)][string]$VoiceModel,   # path to .onnx model
  [string]$VoiceConfig,                              # optional .json config
  [string]$OutPath = "build/narration.wav",
  [double]$LengthScale = 1.0,
  [double]$NoiseScale = 0.667,
  [double]$NoiseW = 0.8,
  [int]$Speaker = -1
)

$ErrorActionPreference = 'Stop'

function Ensure-Directory {
  param([string]$Path)
  $dir = Split-Path -Parent $Path
  if (-not [string]::IsNullOrWhiteSpace($dir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
  }
}

Ensure-Directory -Path $OutPath

$piper = Get-Command piper -ErrorAction SilentlyContinue
if (-not $piper) { throw "piper not found on PATH. Install Piper and ensure 'piper' is available in your shell." }

if (-not (Test-Path -LiteralPath $VoiceModel)) { throw "Voice model not found: $VoiceModel" }

$args = @('--model', $VoiceModel, '--output-file', $OutPath, '--length-scale', ([string]$LengthScale), '--noise-scale', ([string]$NoiseScale), '--noise-w-scale', ([string]$NoiseW))
if ($VoiceConfig) { $args += @('--config', $VoiceConfig) }
if ($Speaker -ge 0) { $args += @('--speaker', ([string]$Speaker)) }

if (-not $Text -and -not $TextPath) {
  throw 'Provide -Text or -TextPath for narration.'
}

if (-not $Text) {
  if (-not (Test-Path -LiteralPath $TextPath)) { throw "Text file not found: $TextPath" }
  $Text = Get-Content -LiteralPath $TextPath -Raw
}

# Write text to a temp file and call Piper with -i for better compatibility
$tmpIn = Join-Path (Split-Path -Parent $OutPath) 'piper_input.txt'
Set-Content -Encoding UTF8 -LiteralPath $tmpIn -Value $Text

if (Test-Path -LiteralPath $OutPath) { Remove-Item -LiteralPath $OutPath -Force }
& piper @args -i $tmpIn

if (-not (Test-Path -LiteralPath $OutPath)) { throw "Failed to create $OutPath" }
$fi = Get-Item -LiteralPath $OutPath
Write-Host "Generated with Piper: $($fi.FullName) ($([Math]::Round($fi.Length/1KB,2)) KB)" -ForegroundColor Green
