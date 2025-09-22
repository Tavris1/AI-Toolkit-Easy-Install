@Echo off
set "version_title=AI-Toolkit-Easy-Install v0.3.12 by ivo"
Title %version_title%

:: Set colors ::
call :set_colors

:: Set arguments ::
set "PIPargs=--no-cache-dir --no-warn-script-location --timeout=1000 --retries 200"
set "CURLargs=--retry 200 --retry-all-errors"

:: Set local path only (temporarily) ::
for /f "delims=" %%G in ('cmd /c "where git.exe 2>nul"') do (set "GIT_PATH=%%~dpG")
for /f "delims=" %%G in ('cmd /c "where node.exe 2>nul"') do (set "NODE_PATH=%%~dpG")
set path=%GIT_PATH%;%NODE_PATH%

if exist %windir%\system32 set path=%PATH%;%windir%\System32
if exist %windir%\system32\WindowsPowerShell\v1.0 set path=%PATH%;%windir%\system32\WindowsPowerShell\v1.0
if exist %localappdata%\Microsoft\WindowsApps set path=%PATH%;%localappdata%\Microsoft\WindowsApps

:: Check for Existing ComfyUI Folder ::
if exist AI-Toolkit (
	echo %warning%WARNING:%reset% '%bold%AI-Toolkit%reset%' folder already exists!
	echo %green%Move this file to another folder and run it again.%reset%
	echo Press any key to Exit...&Pause>nul
	goto :eof
)

:: Capture the start time ::
for /f %%i in ('powershell -command "Get-Date -Format HH:mm:ss"') do set start=%%i

:: Skip downloading LFS (Large File Storage) files ::
set GIT_LFS_SKIP_SMUDGE=1

:: Clear Pip Cache ::
call :clear_pip_cache

:: Install/Update Git ::
call :install_git

:: Check if git is installed ::
for /F "tokens=*" %%g in ('git --version') do (set gitversion=%%g)
Echo %gitversion% | findstr /C:"version">nul&&(
	Echo %bold%git%reset% %yellow%is installed%reset%
	Echo.) || (
    Echo %warning%WARNING:%reset% %bold%'git'%reset% is NOT installed
	Echo Please install %bold%'git'%reset% manually from %yellow%https://git-scm.com/%reset% and run this installer again
	Echo Press any key to Exit...&Pause>nul
	exit /b
)

:: System folder? ::
md AI-Toolkit
if not exist AI-Toolkit (
	cls
	echo %warning%WARNING:%reset% Cannot create folder %yellow%AI-Toolkit%reset%
	echo Make sure you are NOT using system folders like %yellow%Program Files, Windows%reset% or system root %yellow%C:\%reset%
	echo %green%Move this file to another folder and run it again.%reset%
	echo Press any key to Exit...&Pause>nul
	exit /b
)

:: Install Node.js ::
call :nodejs_install

:: Install Python & pip embedded ::
call :python_embedded_install

:: Install AI-Toolkit ::
call :ai-toolkit_install

:: Create 'Start-AI-Toolkit.bat' ::
call :create_start-ai-toolkit-bat

:: Clear Pip Cache ::
call :clear_pip_cache

:: Capture the end time ::
for /f %%i in ('powershell -command "Get-Date -Format HH:mm:ss"') do set end=%%i
for /f %%i in ('powershell -command "(New-TimeSpan -Start (Get-Date '%start%') -End (Get-Date '%end%')).TotalSeconds"') do set diff=%%i

:: Final Messages ::
echo.
echo %green%::::::::::::::: Installation Complete :::::::::::::::%reset%
echo %green%::::::::::::::: Total Running Time:%red% %diff% %green%seconds%reset%
echo %yellow%::::::::::::::: Press any key to exit :::::::::::::::%reset%&Pause>nul
goto :eof

::::::::::::::::::::::::::::::::: END :::::::::::::::::::::::::::::::::

:set_colors
set warning=[33m
set     red=[91m
set   green=[92m
set  yellow=[93m
set    bold=[1m
set   reset=[0m
goto :eof

:clear_pip_cache
if exist "%localappdata%\pip\cache" rd /s /q "%localappdata%\pip\cache"&&md "%localappdata%\pip\cache"
echo %green%::::::::::::::: Clearing Pip Cache %yellow%Done%green% :::::::::::::::%reset%
echo.
goto :eof

:install_git
:: https://git-scm.com/
echo %green%::::::::::::::: Installing/Updating%yellow% Git %green%:::::::::::::::%reset%
echo.

winget.exe install --id Git.Git -e --source winget
set path=%PATH%;%ProgramFiles%\Git\cmd
echo.
goto :eof

:nodejs_install
:: https://nodejs.org/en
echo %green%::::::::::::::: Installing/Updating%yellow% Node.js %green%:::::::::::::::%reset%
echo.
winget.exe install --id=OpenJS.NodeJS -e
set path=%PATH%;%ProgramFiles%\nodejs
Title %version_title%
echo.
goto :eof

:python_embedded_install
:: https://www.python.org/downloads/release/python-31011/
echo %green%::::::::::::::: Installing%yellow% Python embedded %green%:::::::::::::::%reset%
echo.
curl.exe -OL https://www.python.org/ftp/python/3.10.11/python-3.10.11-embed-amd64.zip --ssl-no-revoke %CURLargs%
md python_embeded&&cd python_embeded
tar.exe -xf ..\python-3.10.11-embed-amd64.zip
erase ..\python-3.10.11-embed-amd64.zip
echo.
echo %green%::::::::::::::: Installing%yellow% pip %green%:::::::::::::::%reset%
echo.
curl.exe -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py --ssl-no-revoke %CURLargs%

Echo ../AI-Toolkit> python310._pth
Echo Lib/site-packages> python310._pth
Echo Lib>> python310._pth
Echo Scripts>> python310._pth
Echo python310.zip>> python310._pth
Echo .>> python310._pth
Echo # import site>> python310._pth

.\python.exe -I get-pip.py %PIPargs%
.\python.exe -I -m pip install --upgrade pip %PIPargs%
.\python.exe -I -m pip install virtualenv %PIPargs%

curl.exe -OL https://github.com/woct0rdho/triton-windows/releases/download/v3.0.0-windows.post1/python_3.10.11_include_libs.zip --ssl-no-revoke %CURLargs%
tar.exe -xf python_3.10.11_include_libs.zip
erase python_3.10.11_include_libs.zip

echo.
goto :eof

:ai-toolkit_install
echo %green%::::::::::::::: Installing%yellow% AI-Toolkit %green%:::::::::::::::%reset%
echo.
cd ..\
git.exe clone https://github.com/ostris/ai-toolkit.git
cd ai-toolkit
..\python_embeded\python.exe -I -m virtualenv venv
CALL venv\Scripts\activate.bat
REM pip install --upgrade torch torchvision torchaudio --pre --index-url https://download.pytorch.org/whl/nightly/cu128 %PIPargs%
pip install --upgrade torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 %PIPargs%
pip install poetry-core %PIPargs%
pip install triton-windows %PIPargs%
REM pip install hf_xet %PIPargs%
pip install -r requirements.txt %PIPargs%
echo.
goto :eof

:create_start-ai-toolkit-bat
echo %green%::::::::::::::: Creating%yellow%  Start-AI-Toolkit.bat %green%:::::::::::::::%reset%
cd..\
set "start_bat_name=Start-AI-Toolkit.bat"
Echo @echo off>%start_bat_name%
Echo Title %version_title%>>%start_bat_name%
Echo cd /d %%^~dp0>>%start_bat_name%
Echo setlocal enabledelayedexpansion>>%start_bat_name%
Echo set GIT_LFS_SKIP_SMUDGE=^1>>%start_bat_name%
Echo set "local_serv=http://localhost:8675">>%start_bat_name%
Echo echo.>>%start_bat_name%
Echo cd ./ai-toolkit>>%start_bat_name%
Echo.>>%start_bat_name%

Echo echo ^[92m:::::::::::::::   Checking for updates...  :::::::::::::::^[0m>>%start_bat_name%
Echo echo.>>%start_bat_name%
Echo git fetch>>%start_bat_name%
Echo git status -uno ^| findstr /C:"Your branch is behind" ^>nul>>%start_bat_name%
Echo if !errorlevel!==0 ^(>>%start_bat_name%
Echo     echo.>>%start_bat_name%
Echo     echo ^[92m:::::::::::::::    Installing updates...   :::::::::::::::^[0m>>%start_bat_name%
Echo     echo.>>%start_bat_name%
Echo     git pull>>%start_bat_name%
Echo     echo.>>%start_bat_name%
Echo     echo ^[92m::::::::::::::: Installing requirements... :::::::::::::::^[0m>>%start_bat_name%
Echo     echo.>>%start_bat_name%
Echo     CALL venv\Scripts\activate.bat>>%start_bat_name%
Echo     pip install -r requirements.txt --no-cache>>%start_bat_name%
Echo     CALL venv\Scripts\deactivate.bat>>%start_bat_name%
Echo ^) else ^(>>%start_bat_name%
Echo     echo ^[92m:::::::::::::::     Already up to date     :::::::::::::::^[0m>>%start_bat_name%
Echo     echo.>>%start_bat_name%
Echo ^)>>%start_bat_name%
Echo.>>%start_bat_name%

Echo echo.>>%start_bat_name%
Echo echo ^[92m:::::::::::::::  Waiting for the server... :::::::::::::::^[0m>>%start_bat_name%
Echo echo ^[93m:::::::::::::::  ^[91mDo not close ^[93mthis window  :::::::::::::::^[0m>>%start_bat_name%
Echo cd ./ui>>%start_bat_name%
Echo start cmd.exe /k npm run build_and_start>>%start_bat_name%
Echo :loop>> %start_bat_name%
Echo powershell -Command "try { $response = Invoke-WebRequest -Uri '!local_serv!' -TimeoutSec 2 -UseBasicParsing; exit 0 } catch { exit 1 }" ^>nul 2^>^&^1>> %start_bat_name%
Echo if !errorlevel! neq 0 ^(timeout /t 2 /nobreak ^>nul^&^&goto :loop^)>> %start_bat_name%
Echo start !local_serv!>> %start_bat_name%
goto :eof
