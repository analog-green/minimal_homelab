@echo off
chcp 65001 > nul
:: ==============================================================================
:: Copyright (c) 2026 https://github.com/analog-green/minimal_minimal_homelab
:: Licensed under the MIT License.
:: Encoding: UTF-8 
:: ==============================================================================
set WSL_OS=Ubuntu-24.04
set AUTO_EXIT_SEC=2


:: ==============================================================================
:: 	MAIN-WORK.
:: ==============================================================================
echo ABOUT.
echo  Copyright (c) 2026 https://github.com/analog-green/minimal_homelab
echo  Licensed under the MIT License.

echo  Initial Contributor: MTG
echo  Edit: 2026-09-25 (UTC+9)
echo  Version: 0.9.2
echo ==============================================================================


:: ==============================================================================
:: WSL 배포판
:: ==============================================================================
where wsl >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo  [ERROR] 'wsl --install' PLZ
	echo  ------------------------------
    echo.
    pause
    exit
) else (
	echo.
	echo  WSL installed.
	echo ------------------------------
)
wsl -d %WSL_OS% --status >nul 2>&1
if %errorlevel% neq 0 (
    echo.
	wsl -l
	echo  ------------------------------
    echo.
    echo  [ERROR] "%WSL_OS%" not exist
    echo.
    pause
    exit
) else (
	echo.
	echo  "%WSL_OS%" checked.
	echo ------------------------------
)
wsl -d %WSL_OS% --exec true


:: ==============================================================================
:: terminal client
:: ==============================================================================
echo.
echo  start terminal client (default: Tabby)
echo ------------------------------

:WITH_TABBY
if not exist "%LOCALAPPDATA%\Programs\Tabby\Tabby.exe" (
    echo  [ERROR] Tabby not exist
    goto WITH_PS
)
echo  start Tabby
timeout %AUTO_EXIT_SEC% /nobreak > nul
start "" "%LOCALAPPDATA%\Programs\Tabby\Tabby.exe" open 'WSL / %WSL_OS%'
exit

:WITH_PS
echo  start powershell
timeout %AUTO_EXIT_SEC% /nobreak > nul
powershell.exe -command "Start-Process powershell -ArgumentList '-NoExit', '-Command', 'wsl -d %WSL_OS% --cd ~'"
exit
