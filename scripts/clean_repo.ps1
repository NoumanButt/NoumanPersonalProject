Param()

$ErrorActionPreference = 'Stop'

function Remove-PathSafe([string]$p){
  if (Test-Path -LiteralPath $p) {
    Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue
  }
}

# Remove generated artifacts
Remove-PathSafe 'build'
Remove-PathSafe 'release'
Remove-PathSafe 'bundle'
Remove-PathSafe 'assets'

# Recreate minimal folders as needed
New-Item -ItemType Directory -Force -Path 'assets' | Out-Null

Write-Host 'Repository cleaned: build/, release/, bundle/, assets/ reset.' -ForegroundColor Green

