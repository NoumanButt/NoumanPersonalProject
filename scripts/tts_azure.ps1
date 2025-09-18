Param(
  [string]$TextPath,
  [string]$Text,
  [string]$Voice = 'ar-EG-SalmaNeural',
  [string]$OutPath = 'build/narration.wav',
  [string]$Locale = 'en-US',
  [string]$Format = 'riff-24000hz-16bit-mono-pcm',
  [string]$Key = $env:AZURE_TTS_KEY,
  [string]$Region = $env:AZURE_TTS_REGION
)

$ErrorActionPreference = 'Stop'

if (-not $Key -or -not $Region) {
  throw "Set AZURE_TTS_KEY and AZURE_TTS_REGION environment variables or pass -Key and -Region."
}

if (-not $Text -and -not $TextPath) {
  throw 'Provide -Text or -TextPath.'
}
if (-not $Text) {
  if (-not (Test-Path -LiteralPath $TextPath)) { throw "Text file not found: $TextPath" }
  $Text = Get-Content -LiteralPath $TextPath -Raw
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutPath) | Out-Null

$ssml = @"
<speak version='1.0' xml:lang='ar-EG'>
  <voice name='$Voice'>
    <lang xml:lang='$Locale'>
      $Text
    </lang>
  </voice>
  <mstts:express-as style='general' xmlns:mstts='https://www.w3.org/2001/mstts'>
  </mstts:express-as>
</speak>
"@

$uri = "https://$Region.tts.speech.microsoft.com/cognitiveservices/v1"
$headers = @{
  'Ocp-Apim-Subscription-Key' = $Key
  'Content-Type' = 'application/ssml+xml'
  'X-Microsoft-OutputFormat' = $Format
  'User-Agent' = 'CodexCLI-AzureTTS'
}

Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $ssml -OutFile $OutPath

if (-not (Test-Path -LiteralPath $OutPath)) { throw "Failed to create $OutPath" }
$fi = Get-Item -LiteralPath $OutPath
Write-Host "Azure TTS generated: $($fi.FullName) ($([Math]::Round($fi.Length/1KB,2)) KB)" -ForegroundColor Green

