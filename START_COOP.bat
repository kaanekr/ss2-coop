@echo off
setlocal
where python >nul 2>&1
if errorlevel 1 (
    where py >nul 2>&1
    if errorlevel 1 (
        echo [SS2 Co-op] ERROR: Python was not found in PATH.
        echo Install Python 3.10+ ^(tested on Python 3.14^) and ensure "Add python.exe to PATH" is enabled.
        pause
        exit /b 1
    )
    py -3 "%~dp0src\launcher\ss2_coop_launcher.py" %*
    exit /b %ERRORLEVEL%
)
python "%~dp0src\launcher\ss2_coop_launcher.py" %*
exit /b %ERRORLEVEL%
