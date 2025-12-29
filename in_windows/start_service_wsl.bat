@echo off
chcp 65001 > nul
:: ==============================================================================
:: Copyright (c) 2025 https://github.com/analog-green/devOps
:: Licensed under the MIT License.
:: 이 스크립트는 DevOps에 유용한 공개 템플릿을 초안 형태로 제공합니다. MIT라이센스하에 누구나 자유롭게 수정 및 재배포 가능합니다.
:: 인코딩: UTF-8 
:: ==============================================================================
set WSL_OS=Ubuntu-24.04
set TIMEOUT_SEC=3
set AUTO_EXIT_SEC=3


:: ==============================================================================
:: 	MAIN-WORK.
:: ==============================================================================
echo ABOUT.
echo  Original Template:  https://github.com/analog-green/devOps
echo  Licensed under the MIT License.
echo  Initial Contributor:  MTG
echo  License:  MIT
echo =======================================================


:: 1. WSL 배포판
wsl -d %WSL_OS% --exec true

:: 2. 터미널 선택
echo.
echo  터미널 클라이언가 실행됩니다. (기본값: Tabby)
echo  %TIMEOUT_SEC%초 내로 [Q]키를 누르면 PowerShell로 변경됩니다.
echo ---------------
choice /c qt /t %TIMEOUT_SEC% /d t /n > nul

:: 3. 분기점
if errorlevel 2 goto WITH_TABBY
if errorlevel 1 goto WITH_PS

:WITH_TABBY
echo  터미널 클라이언트 Tabby가 실행됩니다.
timeout %AUTO_EXIT_SEC% /nobreak > nul
start "" "%LOCALAPPDATA%\Programs\Tabby\Tabby.exe" open 'WSL / %WSL_OS%'
exit

:WITH_PS
echo  터미널 클라이언트 powershell이 실행됩니다.
timeout %AUTO_EXIT_SEC% /nobreak > nul
powershell.exe -command "Start-Process powershell -ArgumentList '-NoExit', '-Command', 'wsl -d %WSL_OS%'"
exit