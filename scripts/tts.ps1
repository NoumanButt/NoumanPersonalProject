Param(
    [string]$TextPath,
    [string]$Text,
    [string]$OutPath = "build/narration.wav",
    [string]$Voice = $null,
    [int]$Rate = 0,
    [int]$Volume = 100
)

$ErrorActionPreference = 'Stop'

function Ensure-Directory {
    param([string]$Path)
    $dir = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
}

try {
    # Resolve text content
    if (-not $Text -and -not $TextPath) {
        $Text = @'
This is a sample narration generated with Windows built-in text to speech.
You can replace this with your own script to create voiceovers for your videos.
'@
    }
    if (-not $Text) {
        if (-not (Test-Path -LiteralPath $TextPath)) {
            throw "Text file not found: $TextPath"
        }
        $Text = Get-Content -LiteralPath $TextPath -Raw
    }

    Ensure-Directory -Path $OutPath

    Add-Type -AssemblyName System.Speech
    $synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
    try {
        if ($Voice) {
            $synth.SelectVoice($Voice)
        }
    } catch {
        Write-Warning "Voice '$Voice' not available; using default."
    }
    $synth.Rate = [Math]::Max(-10, [Math]::Min(10, $Rate))
    $synth.Volume = [Math]::Max(0, [Math]::Min(100, $Volume))

    $resolved = Resolve-Path -LiteralPath (Split-Path -Parent $OutPath) | Select-Object -First 1 -ExpandProperty Path
    $fileName = Split-Path -Leaf $OutPath
    $fullOut = Join-Path $resolved $fileName

    $synth.SetOutputToWaveFile($fullOut)
    $synth.Speak($Text)
    $synth.SetOutputToDefaultAudioDevice()
    $synth.Dispose()

    $fi = Get-Item -LiteralPath $fullOut
    Write-Host "Generated: $($fi.FullName) ($([Math]::Round($fi.Length/1KB,2)) KB)" -ForegroundColor Green
} catch {
    Write-Error $_
    exit 1
}

