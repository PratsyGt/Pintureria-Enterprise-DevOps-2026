$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
if (-not (Test-Path -LiteralPath '.venv\Scripts\python.exe')) {
    py -3 -m venv .venv
    if ($LASTEXITCODE -ne 0) { throw 'No se pudo crear el entorno. Instale Python 3.11 o superior.' }
}
& '.\.venv\Scripts\python.exe' -m pip install -r '.\app\requirements.txt'
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron instalar las dependencias.' }
if (-not (Test-Path -LiteralPath 'app\.env')) {
    Copy-Item -LiteralPath 'app\.env.example' -Destination 'app\.env'
    & '.\.venv\Scripts\python.exe' -c "from pathlib import Path; import secrets; p=Path('app/.env'); p.write_text(p.read_text(encoding='utf-8').replace('SECRET_KEY=', 'SECRET_KEY='+secrets.token_urlsafe(64),1),encoding='utf-8')"
}
& '.\.venv\Scripts\python.exe' '.\app\manage.py' check
Write-Host 'Configure app\.env y ejecute los scripts SQL indicados en README.md. Después: .\Iniciar.ps1'
