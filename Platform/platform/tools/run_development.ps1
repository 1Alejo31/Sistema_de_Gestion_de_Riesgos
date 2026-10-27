$ErrorActionPreference = 'Stop'
$frontendDirectory = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $frontendDirectory
$settings = Get-Content -LiteralPath 'config/development.json' -Raw | ConvertFrom-Json
$frontendPort = ([Uri]$settings.frontendOrigin).Port
Write-Host "Frontend: $($settings.frontendOrigin)"
Write-Host 'API: http://3.148.192.204/'
& flutter run -d web-server --web-hostname=localhost "--web-port=$frontendPort"
if ($LASTEXITCODE -ne 0) { throw 'Flutter no pudo iniciar.' }
