$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
& '.\.venv\Scripts\python.exe' '.\app\manage.py' check
if ($LASTEXITCODE -ne 0) { throw 'La configuración no es válida.' }
& '.\.venv\Scripts\python.exe' '.\app\manage.py' runserver 127.0.0.1:8000
