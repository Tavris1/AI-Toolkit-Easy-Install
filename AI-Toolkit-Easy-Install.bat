@echo off&&cd /d %~dp0
set "version_title=AI-Toolkit-Easy-Install v0.3.27 by ivo"
Title %version_title%

:: Set colors ::
call :set_colors

:: Set arguments ::
set "PIPargs=--no-cache-dir --no-warn-script-location --timeout=1000 --retries 200"
set "UVargs=--no-cache --link-mode=copy"

:: CRITICAL: Clear all Python-related environment variables ::
set PYTHONPATH=
set PYTHONHOME=
set PYTHON=
set PYTHONSTARTUP=
set PYTHONUSERBASE=
set PIP_CONFIG_FILE=
set PIP_REQUIRE_VIRTUALENV=
set VIRTUAL_ENV=
set CONDA_PREFIX=
set CONDA_DEFAULT_ENV=
set PYENV_ROOT=
set PYENV_VERSION=

:: Set local path only (temporarily) ::
for /f "delims=" %%G in ('cmd /c "where.exe git.exe 2>nul"') do (set "GIT_PATH=%%~dpG")
for /f "delims=" %%G in ('cmd /c "where.exe node.exe 2>nul"') do (set "NODE_PATH=%%~dpG")

:: Build minimal PATH without system Python ::
set "path="
if defined GIT_PATH set "path=%GIT_PATH%"
if defined NODE_PATH set "path=%path%;%NODE_PATH%"
if exist "%windir%\system32" set "path=%PATH%;%windir%\System32"
if exist "%windir%\system32\WindowsPowerShell\v1.0" set "path=%PATH%;%windir%\system32\WindowsPowerShell\v1.0"
if exist "%localappdata%\Microsoft\WindowsApps" set "path=%PATH%;%localappdata%\Microsoft\WindowsApps"

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

:: Clear Pip and uv Cache ::
call :clear_pip_uv_cache

:: Install/Update Git ::
call :install_git

::----------------------------------------------------
:: Check if git is installed
git.exe --version>nul 2>&1
if errorlevel 1 (
    echo %warning%WARNING:%reset% %bold%'git'%reset% is NOT installed
	echo Please install %bold%'git'%reset% manually from %yellow%https://git-scm.com/%reset% and run this installer again
    echo Press any key to Exit...&pause>nul
    exit /b
)
::----------------------------------------------------

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
call :create_bat_files

:: Clear Pip and uv Cache ::
call :clear_pip_uv_cache

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

:clear_pip_uv_cache
if exist "%localappdata%\pip\cache" rd /s /q "%localappdata%\pip\cache"&&md "%localappdata%\pip\cache"
if exist "%localappdata%\uv\cache" rd /s /q "%localappdata%\uv\cache"&&md "%localappdata%\uv\cache"
echo.
echo %green%:::::::::: Clearing Pip and uv Cache %yellow%Done%green% :::::::::::%reset%
echo.
goto :eof

:install_git
:: https://git-scm.com/
echo %green%:::::::::::::: Installing/Updating%yellow% Git %green%::::::::::::::%reset%
echo.

winget.exe install --id Git.Git -e --source winget
set "path=%PATH%;%ProgramFiles%\Git\cmd"
echo.
goto :eof

:nodejs_install
:: https://nodejs.org/en
echo %green%:::::::::::: Installing/Updating%yellow% Node.js %green%::::::::::::%reset%
echo.
winget.exe install --id=OpenJS.NodeJS -e
set "path=%PATH%;%ProgramFiles%\nodejs"
Title %version_title%
echo.
goto :eof

:python_embedded_install
:: https://www.python.org/downloads/release/python-31210/
echo %green%::::::::::::: Installing%yellow% Python embedded %green%::::::::::::%reset%
echo.

:: Disable only CRL/OCSP checks for SSL ::
powershell -Command "[System.Net.ServicePointManager]::CheckCertificateRevocationList = $false"

:: Ignore SSL certificate errors ::
REM powershell -Command "Add-Type @'using System.Net;using System.Security.Cryptography.X509Certificates;public class TrustAllCertsPolicy : ICertificatePolicy {public bool CheckValidationResult(ServicePoint srvPoint,X509Certificate certificate,WebRequest request,int certificateProblem){return true;}}'@;[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy"

powershell -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.10/python-3.12.10-embed-amd64.zip' -OutFile 'python-3.12.10-embed-amd64.zip' -UseBasicParsing"
md python_embeded&&cd python_embeded
tar.exe -xf ..\python-3.12.10-embed-amd64.zip
erase ..\python-3.12.10-embed-amd64.zip
echo.
echo %green%::::::::::::::::::: Installing%yellow% pip %green%::::::::::::::::::%reset%
echo.
powershell -Command "Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'get-pip.py' -UseBasicParsing"

echo ../AI-Toolkit> python312._pth
echo Lib/site-packages>> python312._pth
echo Lib>> python312._pth
echo Scripts>> python312._pth
echo python312.zip>> python312._pth
echo .>> python312._pth
echo # import site>> python312._pth

"%CD%\python.exe" -I get-pip.py %PIPargs%
"%CD%\python.exe" -I -m pip install uv==0.9.7 %PIPargs%
"%CD%\python.exe" -I -m pip install --upgrade pip %PIPargs%
"%CD%\python.exe" -I -m pip install virtualenv %PIPargs%

powershell -Command "Invoke-WebRequest -Uri 'https://github.com/woct0rdho/triton-windows/releases/download/v3.0.0-windows.post1/python_3.12.7_include_libs.zip' -OutFile 'python_3.12.7_include_libs.zip' -UseBasicParsing"

tar.exe -xf python_3.12.7_include_libs.zip
erase python_3.12.7_include_libs.zip

echo.
goto :eof

:ai-toolkit_install
echo %green%::::::::::::::: Installing%yellow% AI-Toolkit %green%:::::::::::::::%reset%
echo.
cd ..\
git.exe clone https://github.com/ostris/ai-toolkit.git
cd ai-toolkit
"..\python_embeded\python.exe" -I -m virtualenv --clear --no-download venv
CALL venv\Scripts\activate.bat

:: Clear environment again inside venv for safety ::
set PYTHONPATH=
set PYTHONHOME=
set PIP_CONFIG_FILE=

:: Check if uv.exe exists in python_embeded ::
if exist "..\python_embeded\Scripts\uv.exe" pip install uv==0.9.7 %PIPargs%

if exist "venv\Scripts\uv.exe" (
    echo %green%Using UV for package installation%reset%
    uv pip install torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cu128 %UVargs%
    uv pip install -r requirements.txt %UVargs%
    uv pip install poetry-core %UVargs%
    uv pip install triton-windows==3.4.0.post20 %UVargs%
) else (
    echo %warning%UV not available - using standard pip%reset%
    pip install torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cu128 %PIPargs%
    pip install -r requirements.txt %PIPargs%
    pip install poetry-core %PIPargs%
    pip install triton-windows==3.4.0.post20 %PIPargs%
)

echo.
goto :eof

:create_bat_files
:: Create Start-AI-Toolkit.bat ::
echo %green%:::::::::: Creating%yellow%  Start-AI-Toolkit.bat %green%:::::::::::%reset%
cd..\
set "start_bat_name=Start-AI-Toolkit.bat"
echo @echo off^&^&cd /d %%~dp0>%start_bat_name%
echo Title %version_title%>>%start_bat_name%
echo setlocal enabledelayedexpansion>>%start_bat_name%
echo.>>%start_bat_name%

:: Isolate from system Python ::
echo set PYTHONPATH=>>%start_bat_name%
echo set PYTHONHOME=>>%start_bat_name%
echo set PYTHON=>>%start_bat_name%
echo set PYTHONSTARTUP=>>%start_bat_name%
echo set PYTHONUSERBASE=>>%start_bat_name%
echo set PIP_CONFIG_FILE=>>%start_bat_name%
echo set PIP_REQUIRE_VIRTUALENV=>>%start_bat_name%
echo set VIRTUAL_ENV=>>%start_bat_name%
echo set CONDA_PREFIX=>>%start_bat_name%
echo set CONDA_DEFAULT_ENV=>>%start_bat_name%
echo set PYENV_ROOT=>>%start_bat_name%
echo set PYENV_VERSION=>>%start_bat_name%
echo.>>%start_bat_name%

echo set GIT_LFS_SKIP_SMUDGE=^1>>%start_bat_name%
echo set "local_serv=http://localhost:8675">>%start_bat_name%
echo echo.>>%start_bat_name%
echo cd ./ai-toolkit>>%start_bat_name%

echo     echo ^[92m::::::::::::  Starting AI-Toolkit ...  ::::::::::::::^[0m>>%start_bat_name%
echo     echo.>>%start_bat_name%

echo git.exe fetch>>%start_bat_name%
echo git.exe status -uno ^| findstr /C:"Your branch is behind" ^>nul>>%start_bat_name%
echo if !errorlevel!==0 ^(>>%start_bat_name%
echo     echo ^[93m:::::::::::: ^[91mNew updates^[93m are available ::::::::::::::^[0m>>%start_bat_name%
echo     echo ^[92m:::::::::::: Run Update-AI-Toolkit.bat ::::::::::::::^[0m>>%start_bat_name%
echo     echo.>>%start_bat_name%
echo ^)>>%start_bat_name%
echo.>>%start_bat_name%

echo echo ^[1;93mTips for beginners:^[0m>>%start_bat_name%
echo echo.>>%start_bat_name%
echo echo ^[1;93mGeneral:^[0m>>%start_bat_name%
echo echo  ^[1;32m1.^[0m Set your ^[1;92mHugging Face Token^[0m in Settings>>%start_bat_name%
echo echo  ^[1;32m2.^[0m Close server with ^[1;92mCtrl+C twice^[0m, not the ^[1;91mX^[0m button>>%start_bat_name%
echo echo  ^[1;32m3.^[0m To activate the ^[1;92mvirtual environment^[0m (if needed):>>%start_bat_name%
echo echo     - Open ^[1;92mCMD^[0m where ^[1;92mStart-AI-Toolkit.bat^[0m is located>>%start_bat_name%
echo echo       and Run ^[1;92mAI-Toolkit\venv\Scripts\activate.bat^[0m>>%start_bat_name%
echo echo     ^[1;93mOR^[0m just start ^[1;92mvenv-AI-Toolkit.bat^[0m>>%start_bat_name%
echo echo.>>%start_bat_name%
echo echo ^[92m:::::::: ^[93mWaiting for the server to start...^[92m :::::::::^[0m>>%start_bat_name%
echo.>>%start_bat_name%

echo cd ./ui>>%start_bat_name%
echo start cmd.exe /k npm run build_and_start>>%start_bat_name%
echo :loop>>%start_bat_name%
echo if exist "%%windir%%\System32\WindowsPowerShell\v1.0" set "PATH=%%PATH%%;%%windir%%\System32\WindowsPowerShell\v1.0">>"%start_bat_name%"
echo powershell -Command "try { $response = Invoke-WebRequest -Uri '!local_serv!' -TimeoutSec 2 -UseBasicParsing; exit 0 } catch { exit 1 }" ^>nul 2^>^&^1>>%start_bat_name%
echo if !errorlevel! neq 0 ^(timeout /t 2 /nobreak ^>nul^&^&goto :loop^)>>%start_bat_name%
echo start !local_serv!>>%start_bat_name%

:: Create venv-AI-Toolkit.bat ::
echo %green%:::::::::: Creating%yellow%   venv-AI-Toolkit.bat %green%:::::::::::%reset%

echo @echo off^&^&cd /d %%~dp0>venv-AI-Toolkit.bat
echo.>>venv-AI-Toolkit.bat

:: Isolate from system Python ::
echo set PYTHONPATH=>>venv-AI-Toolkit.bat
echo set PYTHONHOME=>>venv-AI-Toolkit.bat
echo set PYTHON=>>venv-AI-Toolkit.bat
echo set PYTHONSTARTUP=>>venv-AI-Toolkit.bat
echo set PYTHONUSERBASE=>>venv-AI-Toolkit.bat
echo set PIP_CONFIG_FILE=>>venv-AI-Toolkit.bat
echo set PIP_REQUIRE_VIRTUALENV=>>venv-AI-Toolkit.bat
echo set VIRTUAL_ENV=>>venv-AI-Toolkit.bat
echo set CONDA_PREFIX=>>venv-AI-Toolkit.bat
echo set CONDA_DEFAULT_ENV=>>venv-AI-Toolkit.bat
echo set PYENV_ROOT=>>venv-AI-Toolkit.bat
echo set PYENV_VERSION=>>venv-AI-Toolkit.bat
echo.>>venv-AI-Toolkit.bat

echo call AI-Toolkit\venv\Scripts\activate.bat>>venv-AI-Toolkit.bat
echo cmd /k>>venv-AI-Toolkit.bat

:: Create Update-AI-Toolkit.bat ::
echo %green%:::::::::: Creating%yellow% Update-AI-Toolkit.bat %green%:::::::::::%reset%

echo @echo off^&^&cd /d %%~dp0>Update-AI-Toolkit.bat
echo Title AI-Toolkit Update by ivo>>Update-AI-Toolkit.bat
echo.>>Update-AI-Toolkit.bat

:: Isolate from system Python ::
echo set PYTHONPATH=>>Update-AI-Toolkit.bat
echo set PYTHONHOME=>>Update-AI-Toolkit.bat
echo set PYTHON=>>Update-AI-Toolkit.bat
echo set PYTHONSTARTUP=>>Update-AI-Toolkit.bat
echo set PYTHONUSERBASE=>>Update-AI-Toolkit.bat
echo set PIP_CONFIG_FILE=>>Update-AI-Toolkit.bat
echo set PIP_REQUIRE_VIRTUALENV=>>Update-AI-Toolkit.bat
echo set VIRTUAL_ENV=>>Update-AI-Toolkit.bat
echo set CONDA_PREFIX=>>Update-AI-Toolkit.bat
echo set CONDA_DEFAULT_ENV=>>Update-AI-Toolkit.bat
echo set PYENV_ROOT=>>Update-AI-Toolkit.bat
echo set PYENV_VERSION=>>Update-AI-Toolkit.bat
echo.>>Update-AI-Toolkit.bat

echo set GIT_LFS_SKIP_SMUDGE=^1>>Update-AI-Toolkit.bat
echo cd ./ai-toolkit>>Update-AI-Toolkit.bat
echo.>>Update-AI-Toolkit.bat

echo echo.>>Update-AI-Toolkit.bat
echo echo ^[92m::::::::::::::: Installing ^[93mAI-Toolkit^[92m updates... :::::::::::::::^[0m>>Update-AI-Toolkit.bat
echo echo.>>Update-AI-Toolkit.bat
echo git.exe pull>>Update-AI-Toolkit.bat
echo echo.>>Update-AI-Toolkit.bat
echo echo ^[92m::::::: Installing ^[93mrequirements ^[92mand updating ^[93mdiffusers^[92m :::::::::^[0m>>Update-AI-Toolkit.bat
echo echo.>>Update-AI-Toolkit.bat
echo CALL venv\Scripts\activate.bat>>Update-AI-Toolkit.bat
echo pip uninstall diffusers -y>>Update-AI-Toolkit.bat
echo pip install -r requirements.txt --no-cache>>Update-AI-Toolkit.bat
echo CALL venv\Scripts\deactivate.bat>>Update-AI-Toolkit.bat

echo.>>Update-AI-Toolkit.bat
echo echo.>>Update-AI-Toolkit.bat
echo echo ^[92m:::::::::::::::   Update completed    :::::::::::::::^[0m>>Update-AI-Toolkit.bat
echo if "%%~1"=="" ^(>>Update-AI-Toolkit.bat
echo     echo ^[93m::::::::::::::: Press any key to exit :::::::::::::::^[0m^&Pause^>nul>>Update-AI-Toolkit.bat
echo     exit>>Update-AI-Toolkit.bat
echo ^)>>Update-AI-Toolkit.bat

goto :eof