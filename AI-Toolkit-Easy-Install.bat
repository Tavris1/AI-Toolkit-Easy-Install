@echo off&&cd /d %~dp0
set "version_title=AI-Toolkit-Easy-Install v0.4.3 by ivo"
Title %version_title%

:: Set colors ::
call :set_colors

:: Set arguments ::
set "PIPargs=--no-cache-dir --no-warn-script-location --timeout=1000 --retries 20"
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

:: Show Logo ::
set BGR=%yellow%
set FGR=%green%
echo.
echo    %BGR%0000000000000000000000000000
echo    %BGR%000000000000%FGR%0000%BGR%000000000000
echo    %BGR%0000%FGR%0000000%BGR%0%FGR%0000%BGR%0%FGR%0000000%BGR%0000
echo    %BGR%0000%FGR%0000000%BGR%0%FGR%0000%BGR%0%FGR%0000000%BGR%0000
echo    %BGR%0000%FGR%0000%BGR%0000%FGR%0000%BGR%0000%FGR%0000%BGR%0000
echo    %BGR%0000%FGR%0000%BGR%0000%FGR%0000%BGR%0000%FGR%0000%BGR%0000
echo    %BGR%0000%FGR%0000%BGR%000000000000%FGR%0000%BGR%0000
echo    %BGR%0000%FGR%00000000000000000000%BGR%0000
echo    %BGR%0000%FGR%00000000000000000000%BGR%0000
echo    %BGR%0000000000000000000000000000
echo    %BGR%0000000000000000000000000000%reset%
echo.

:: Install/Update Git ::
call :install_git

::----------------------------------------------------
:: Check if git is installed
git.exe --version>nul 2>&1
if not "%errorlevel%"=="0" (
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
echo.

:: Clear Pip and uv Cache ::
call :clear_pip_uv_cache

:: Capture the end time ::
for /f %%i in ('powershell -command "Get-Date -Format HH:mm:ss"') do set end=%%i
for /f %%i in ('powershell -command "(New-TimeSpan -Start (Get-Date '%start%') -End (Get-Date '%end%')).TotalSeconds"') do set diff=%%i

:: Final Messages ::
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
set    bold=[97m
set   reset=[0m
goto :eof

:clear_pip_uv_cache
echo %green%::::::::::::: Clearing Pip and uv Cache%green% :::::::::::::%reset%

set CACHE_DRIVE=%localappdata:~0,2%

for /f "delims=" %%A in ('
powershell -NoProfile -Command "$t=0;@('%localappdata%\pip\cache','%localappdata%\uv\cache')|%%{if(Test-Path $_){Get-ChildItem $_ -Recurse -Force -File -ErrorAction SilentlyContinue|%%{$t+=$_.Length};Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue}};New-Item -ItemType Directory '%localappdata%\pip\cache' -Force|Out-Null;New-Item -ItemType Directory '%localappdata%\uv\cache' -Force|Out-Null;if($t -eq 0){'Cache is already clean on %CACHE_DRIVE%'} elseif($t -ge 1GB){'Cleared {0:N1} GB on %CACHE_DRIVE%' -f ($t/1GB)} else {'Cleared {0} MB on %CACHE_DRIVE%' -f [math]::Floor($t/1MB)}"
') do set MSG=%%A

echo %green%::::::::::::: %yellow%%MSG%%reset%
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

REM powershell -Command "Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.10/python-3.12.10-embed-amd64.zip' -OutFile 'python-3.12.10-embed-amd64.zip' -UseBasicParsing"
powershell -Command "try { Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.10/python-3.12.10-embed-amd64.zip' -OutFile 'python-3.12.10-embed-amd64.zip' -UseBasicParsing } catch { exit 1 }" || curl.exe -L -o python-3.12.10-embed-amd64.zip https://www.python.org/ftp/python/3.12.10/python-3.12.10-embed-amd64.zip --ssl-no-revoke


md python_embeded&&cd python_embeded
tar.exe -xf ..\python-3.12.10-embed-amd64.zip
erase ..\python-3.12.10-embed-amd64.zip
echo.
echo %green%::::::::::::::::::: Installing%yellow% pip %green%::::::::::::::::::%reset%
echo.
REM powershell -Command "Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'get-pip.py' -UseBasicParsing"
powershell -Command "try { Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'get-pip.py' -UseBasicParsing } catch { exit 1 }" || curl.exe -L -o get-pip.py https://bootstrap.pypa.io/get-pip.py --ssl-no-revoke


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

REM powershell -Command "Invoke-WebRequest -Uri 'https://github.com/woct0rdho/triton-windows/releases/download/v3.0.0-windows.post1/python_3.12.7_include_libs.zip' -OutFile 'python_3.12.7_include_libs.zip' -UseBasicParsing"
powershell -Command "try { Invoke-WebRequest -Uri 'https://github.com/woct0rdho/triton-windows/releases/download/v3.0.0-windows.post1/python_3.12.7_include_libs.zip' -OutFile 'python_3.12.7_include_libs.zip' -UseBasicParsing } catch { exit 1 }" || curl.exe -L -o python_3.12.7_include_libs.zip https://github.com/woct0rdho/triton-windows/releases/download/v3.0.0-windows.post1/python_3.12.7_include_libs.zip --ssl-no-revoke


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

if exist "..\python_embeded\Scripts\uv.exe" (
    echo %green%Using UV for package installation%reset%
    "..\python_embeded\python.exe" -I -m uv pip install torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cu128 %UVargs%
    "..\python_embeded\python.exe" -I -m uv pip install -r requirements.txt %UVargs%
    "..\python_embeded\python.exe" -I -m uv pip install poetry-core %UVargs%
	"..\python_embeded\python.exe" -I -m uv pip install wheel %UVargs%
    "..\python_embeded\python.exe" -I -m uv pip install triton-windows==3.4.0.post20 %UVargs%
	"..\python_embeded\python.exe" -I -m uv pip install hf_xet %UVargs%
) else (
    echo %warning%UV not available - using standard pip%reset%
    "..\python_embeded\python.exe" -I -m pip install torch==2.8.0 torchvision==0.23.0 torchaudio==2.8.0 --index-url https://download.pytorch.org/whl/cu128 %PIPargs%
    "..\python_embeded\python.exe" -I -m pip install -r requirements.txt %PIPargs%
    "..\python_embeded\python.exe" -I -m pip install poetry-core %PIPargs%
	"..\python_embeded\python.exe" -I -m pip install wheel %PIPargs%
    "..\python_embeded\python.exe" -I -m pip install triton-windows==3.4.0.post20 %PIPargs%
	"..\python_embeded\python.exe" -I -m pip install hf_xet %PIPargs%
)

echo.
goto :eof




:create_bat_files
cd..\

:::::::::::::::::::::::::::::::::
:: Create Start-AI-Toolkit.bat ::
:::::::::::::::::::::::::::::::::

set "bat_file_name=Start-AI-Toolkit.bat"
echo %green%:::::::::: Creating%yellow% %bat_file_name%%reset%

echo @echo off^&^&cd /d %%~dp0>%bat_file_name%
echo Title AI-Toolkit-Easy-Install v0.4.1 by ivo>>%bat_file_name%
echo setlocal enabledelayedexpansion>>%bat_file_name%
echo.>>%bat_file_name%

echo set PYTHONPATH=>>%bat_file_name%
echo set PYTHONHOME=>>%bat_file_name%
echo set PYTHON=>>%bat_file_name%
echo set PYTHONSTARTUP=>>%bat_file_name%
echo set PYTHONUSERBASE=>>%bat_file_name%
echo set PIP_CONFIG_FILE=>>%bat_file_name%
echo set PIP_REQUIRE_VIRTUALENV=>>%bat_file_name%
echo set VIRTUAL_ENV=>>%bat_file_name%
echo set CONDA_PREFIX=>>%bat_file_name%
echo set CONDA_DEFAULT_ENV=>>%bat_file_name%
echo set PYENV_ROOT=>>%bat_file_name%
echo set PYENV_VERSION=>>%bat_file_name%
echo.>>%bat_file_name%

echo set warning=[33m>>%bat_file_name%
echo set     red=[91m>>%bat_file_name%
echo set   green=[92m>>%bat_file_name%
echo set  yellow=[93m>>%bat_file_name%
echo set    bold=[97m>>%bat_file_name%
echo set   reset=[0m>>%bat_file_name%
echo.>>%bat_file_name%

echo set "path=%%~dp0\python_embeded;%%~dp0\python_embeded\Scripts;%%path%%">>%bat_file_name%
echo if not exist .\AI-Toolkit\ ^(>>%bat_file_name%
echo 	echo %%warning%%WARNING:%%reset%% '%%bold%%AI-Toolkit%%reset%%' folder NOT exists!>>%bat_file_name%
echo 	echo %%green%%Please reinstall 'AI-Toolkit-Easy-Install'.%%reset%%>>%bat_file_name%
echo 	echo Press any key to Exit...^&Pause^>nul>>%bat_file_name%
echo 	goto :eof>>%bat_file_name%
echo ^)>>%bat_file_name%
echo if not exist .\python_embeded\ ^(>>%bat_file_name%
echo 	echo %%warning%%WARNING:%%reset%% '%%bold%%python_embeded%%reset%%' folder NOT exists!>>%bat_file_name%
echo 	echo %%green%%Please reinstall 'AI-Toolkit-Easy-Install'.%%reset%%>>%bat_file_name%
echo 	echo Press any key to Exit...^&Pause^>nul>>%bat_file_name%
echo 	goto :eof>>%bat_file_name%
echo ^)>>%bat_file_name%
echo.>>%bat_file_name%

echo set GIT_LFS_SKIP_SMUDGE^=^1>>%bat_file_name%
echo set "local_serv=http://localhost:8675">>%bat_file_name%
echo echo.>>%bat_file_name%
echo cd ./ai-toolkit>>%bat_file_name%
echo     echo %%green%%:::::::::::::  Starting AI-Toolkit ...  :::::::::::::::%%reset%%>>%bat_file_name%
echo     echo.>>%bat_file_name%
echo git.exe fetch>>%bat_file_name%
echo git.exe status -uno ^| findstr /C:"Your branch is behind" ^>nul>>%bat_file_name%
echo if !errorlevel!==0 ^(>>%bat_file_name%
echo     echo  - %%red%%New updates%%reset%% are available.%%green%% Run Update-AI-Toolkit.bat%%reset%%>>%bat_file_name%
echo     echo.>>%bat_file_name%
echo ^)>>%bat_file_name%
echo.>>%bat_file_name%

echo if exist ".\aitk_db.db" ^(>>%bat_file_name%
echo     type ".\aitk_db.db" 2^>nul ^| findstr /i /c:"HF_TOKEN" ^>nul 2^>^&^1>>%bat_file_name%
echo     if errorlevel 1 ^(echo  - %%green%%Hugging Face Token%%reset%% not found. Set it in Settings.^)>>%bat_file_name%
echo ^)>>%bat_file_name%
echo echo  - Stop the server with %%green%%Ctrl+C twice%%reset%%, not %%red%%X%%reset%%>>%bat_file_name%
echo echo.>>%bat_file_name%
echo echo %%yellow%%::::::::: Waiting for the server to start... ::::::::::%%reset%%>>%bat_file_name%
echo.>>%bat_file_name%

echo cd ./ui>>%bat_file_name%
echo start cmd.exe /k npm run build_and_start>>%bat_file_name%
echo :loop>>%bat_file_name%
echo if exist "%%windir%%\System32\WindowsPowerShell\v1.0" set "path=%%path%%;%%windir%%\System32\WindowsPowerShell\v1.0">>%bat_file_name%
echo powershell -Command "try { $response = Invoke-WebRequest -Uri '!local_serv!' -TimeoutSec 2 -UseBasicParsing; exit 0 } catch { exit 1 }" ^>nul 2^>^&^1>>%bat_file_name%
echo if ^!errorlevel^! neq 0 ^(timeout /t 2 /nobreak ^>nul^&^&goto :loop^)>>%bat_file_name%
echo start ^!local_serv^!>>%bat_file_name%



::::::::::::::::::::::::::::
:: Create %bat_file_name% ::
::::::::::::::::::::::::::::

set "bat_file_name=Update-AI-Toolkit.bat"
echo %green%:::::::::: Creating%yellow% %bat_file_name%%reset%

echo @echo off^&^&cd /d %%~dp0>%bat_file_name%
echo Title AI-Toolkit Update by ivo>>%bat_file_name%
echo.>>%bat_file_name%
echo.>>%bat_file_name%


echo set PYTHONPATH=>>%bat_file_name%
echo set PYTHONHOME=>>%bat_file_name%
echo set PYTHON=>>%bat_file_name%
echo set PYTHONSTARTUP=>>%bat_file_name%
echo set PYTHONUSERBASE=>>%bat_file_name%
echo set PIP_CONFIG_FILE=>>%bat_file_name%
echo set PIP_REQUIRE_VIRTUALENV=>>%bat_file_name%
echo set VIRTUAL_ENV=>>%bat_file_name%
echo set CONDA_PREFIX=>>%bat_file_name%
echo set CONDA_DEFAULT_ENV=>>%bat_file_name%
echo set PYENV_ROOT=>>%bat_file_name%
echo set PYENV_VERSION=>>%bat_file_name%
echo.>>%bat_file_name%

echo set warning=[33m>>%bat_file_name%
echo set     red=[91m>>%bat_file_name%
echo set   green=[92m>>%bat_file_name%
echo set  yellow=[93m>>%bat_file_name%
echo set    bold=[97m>>%bat_file_name%
echo set   reset=[0m>>%bat_file_name%
echo.>>%bat_file_name%

echo set "path=%%~dp0\python_embeded;%%~dp0\python_embeded\Scripts;%%path%%">>%bat_file_name%
echo if not exist .\AI-Toolkit\ ^(>>%bat_file_name%
echo 	echo %%warning%%WARNING:%%reset%% '%%bold%%AI-Toolkit%%reset%%' folder NOT exists!>>%bat_file_name%
echo 	echo %%green%%Please reinstall 'AI-Toolkit-Easy-Install'.%%reset%%>>%bat_file_name%
echo 	echo Press any key to Exit...^&Pause^>nul>>%bat_file_name%
echo 	goto :eof>>%bat_file_name%
echo ^)>>%bat_file_name%
echo if not exist .\python_embeded\ ^(>>%bat_file_name%
echo 	echo %%warning%%WARNING:%%reset%% '%%bold%%python_embeded%%reset%%' folder NOT exists!>>%bat_file_name%
echo 	echo %%green%%Please reinstall 'AI-Toolkit-Easy-Install'.%%reset%%>>%bat_file_name%
echo 	echo Press any key to Exit...^&Pause^>nul>>%bat_file_name%
echo 	goto :eof>>%bat_file_name%
echo ^)>>%bat_file_name%
echo.>>%bat_file_name%

echo set GIT_LFS_SKIP_SMUDGE=^1>>%bat_file_name%
echo cd ./ai-toolkit>>%bat_file_name%
echo.>>%bat_file_name%

echo echo.>>%bat_file_name%
echo echo %%green%%::::::::::::::: Installing %%yellow%%AI-Toolkit%%green%% updates... :::::::::::::::%%reset%%>>%bat_file_name%
echo echo.>>%bat_file_name%
echo git.exe reset --hard>>%bat_file_name%
echo git.exe clean -fd>>%bat_file_name%
echo git.exe pull>>%bat_file_name%
echo echo.>>%bat_file_name%
echo echo %%green%%::::::: Installing %%yellow%%requirements %%green%%and updating %%yellow%%diffusers%%green%% :::::::::%%reset%%>>%bat_file_name%
echo echo.>>%bat_file_name%
echo ..\python_embeded\python.exe -I -m pip uninstall diffusers -y>>%bat_file_name%
echo ..\python_embeded\python.exe -I -m pip install -r requirements.txt --no-cache --no-warn-script-location>>%bat_file_name%
echo.>>%bat_file_name%

echo echo.>>%bat_file_name%
echo echo %%green%%:::::::::::::::   Update completed    :::::::::::::::%%reset%%>>%bat_file_name%
echo if "%%~1"=="" ^(>>%bat_file_name%
echo     echo %%yellow%%::::::::::::::: Press any key to exit :::::::::::::::%%reset%%^&Pause^>nul>>%bat_file_name%
echo     exit>>%bat_file_name%
echo ^)>>%bat_file_name%
echo.>>%bat_file_name%

echo exit>>%bat_file_name%


goto :eof