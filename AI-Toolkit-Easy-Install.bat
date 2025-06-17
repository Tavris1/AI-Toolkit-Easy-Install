@Echo off
set "version_title=AI-Toolkit by Ostris Easy Install - ivo v0.1.0"
Title %version_title%

:: Set colors ::
call :set_colors

:: Set No Cache & Warnings ::
set "silent=--no-cache-dir --no-warn-script-location"

:: Set Local Paths (if broken) ::
if exist %windir%\system32 set path=%PATH%;%windir%\System32
if exist %windir%\system32\WindowsPowerShell\v1.0 set path=%PATH%;%windir%\system32\WindowsPowerShell\v1.0
if exist %localappdata%\Microsoft\WindowsApps set path=%PATH%;%localappdata%\Microsoft\WindowsApps

:: Check for Existing ComfyUI Folder ::
if exist Ai-Toolkit (
	echo %warning%WARNING:%reset% '%bold%Ai-Toolkit%reset%' folder already exists!
	echo %green%Move this file to another folder and run it again.%reset%
	echo Press any key to Exit...&Pause>nul
	goto :eof
)

:: Capture the start time ::
for /f %%i in ('powershell -command "Get-Date -Format HH:mm:ss"') do set start=%%i

:: Clear Pip Cache ::
if exist "%localappdata%\pip\cache" rd /s /q "%localappdata%\pip\cache"&&md "%localappdata%\pip\cache"
echo %green%::::::::::::::: Clearing Pip Cache %yellow%Done%green% :::::::::::::::%reset%
echo.

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
md Ai-Toolkit
if not exist Ai-Toolkit (
	cls
	echo %warning%WARNING:%reset% Cannot create folder %yellow%Ai-Toolkit%reset%
	echo Make sure you are NOT using system folders like %yellow%Program Files, Windows%reset% or system root %yellow%C:\%reset%
	echo %green%Move this file to another folder and run it again.%reset%
	echo Press any key to Exit...&Pause>nul
	exit /b
)

:: Install Node.js ::
call :nodejs_install

:: Install Python & pip embedded ::
call :python_embedded_install

:: Install Ai-Toolkit ::
call :ai-toolkit_install

:: Create 'Start Ai-Toolkit.bat' ::
call :create_start-ai-toolkit-bat

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

:install_git
:: https://git-scm.com/
echo %green%::::::::::::::: Installing/Updating%yellow% Git %green%:::::::::::::::%reset%
echo.
winget install --id Git.Git -e --source winget
set path=%PATH%;%ProgramFiles%\Git\cmd
echo.
goto :eof

:nodejs_install
:: https://nodejs.org/en
echo %green%::::::::::::::: Installing%yellow% Node.js Portable %green%:::::::::::::::%reset%
echo.
winget install --id=OpenJS.NodeJS -e
set path=%PATH%;%ProgramFiles%\nodejs
CALL npm i --save-dev prisma@latest
CALL npm i @prisma/client@latest
CALL npm audit fix
Title %version_title%
echo.
goto :eof

:python_embedded_install
:: https://www.python.org/downloads/release/python-31011/
echo %green%::::::::::::::: Installing%yellow% Python embedded %green%:::::::::::::::%reset%
echo.
curl -OL https://www.python.org/ftp/python/3.10.11/python-3.10.11-embed-amd64.zip --ssl-no-revoke
md python_embeded&&cd python_embeded
tar -xf ..\python-3.10.11-embed-amd64.zip
erase ..\python-3.10.11-embed-amd64.zip
echo.
echo %green%::::::::::::::: Installing%yellow% pip %green%:::::::::::::::%reset%
echo.
curl -sSL https://bootstrap.pypa.io/get-pip.py -o get-pip.py --ssl-no-revoke
python get-pip.py %silent%
python.exe -m pip install --upgrade pip %silent%
python.exe -m pip install virtualenv %silent%
Echo Lib/site-packages> python310._pth
Echo python310.zip>> python310._pth
Echo .>> python310._pth
Echo.>> python310._pth
Echo import site>> python310._pth
echo.
goto :eof

:ai-toolkit_install
echo %green%::::::::::::::: Installing%yellow% Ai-Toolkit %green%:::::::::::::::%reset%
echo.
cd ..\
git clone https://github.com/ostris/ai-toolkit.git
cd ai-toolkit
..\python_embeded\python.exe -m virtualenv venv
CALL venv\Scripts\activate.bat
..\python_embeded\python.exe -m pip install poetry-core
..\python_embeded\python.exe -m pip install -r requirements.txt %silent%
..\python_embeded\python.exe -m pip install --upgrade torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu128 %silent%
echo.
goto :eof

:create_start-ai-toolkit-bat
echo %green%::::::::::::::: Creating%yellow% Start Ai-Toolkit.bat %green%:::::::::::::::%reset%
cd..\
Echo :: Set this time (in seconds) according to your needs ::> "Start Ai-Toolkit.bat"
Echo @set StartDelay=40>> "Start Ai-Toolkit.bat"
Echo.>> "Start Ai-Toolkit.bat"
Echo @echo off>> "Start Ai-Toolkit.bat"
Echo cd ./ai-toolkit/ui>> "Start Ai-Toolkit.bat"
Echo Start cmd.exe /k npm run build_and_start>> "Start Ai-Toolkit.bat"
Echo timeout /t %%StartDelay%%>> "Start Ai-Toolkit.bat"
Echo start "" http://localhost:8675>> "Start Ai-Toolkit.bat"
echo %green%::::::::::::::: Creating%yellow% Done %reset%
echo.
goto :eof