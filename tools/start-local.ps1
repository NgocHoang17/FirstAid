param([switch]$Stop)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot
$runtimePython = Join-Path $projectRoot 'ai/.venv/Scripts/python.exe'
if (-not (Test-Path -LiteralPath $runtimePython)) {
    if (Get-Command py -ErrorAction SilentlyContinue) {
        py -3.11 -m venv ai/.venv
    } elseif (Get-Command python -ErrorAction SilentlyContinue) {
        python -m venv ai/.venv
    } else {
        throw 'Install Python 3.11 or later, then run this command again.'
    }
    if ($LASTEXITCODE -ne 0) { throw 'Cannot create the Python environment.' }
}
& $runtimePython -m pip install --quiet -r ai/requirements-lock.txt -r tools/runtime-requirements.txt
if ($LASTEXITCODE -ne 0) { throw 'Cannot install Python dependencies.' }
if ($Stop) {
    & $runtimePython tools/run_local.py --stop
} else {
    & $runtimePython tools/run_local.py
}
exit $LASTEXITCODE
