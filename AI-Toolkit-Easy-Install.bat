@echo off&&cd /D "%~dp0"
set "version_title=AI-Toolkit-Easy-Install v0.6.5 by ivo"
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

set "FATAL="

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "if(([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){exit 10}else{exit 0}"
if %errorlevel% equ 10 (
	if /I "%~1"=="CEI_NOADMIN" (
		cls
		echo %warning%WARNING:%reset% This installer cannot run with %yellow%Administrator%reset% rights
		echo %green%Start it with a normal double-click, NOT with %yellow%Run as administrator%reset%
		echo Press any key to Exit...&Pause>nul
		exit /b 1
	)
	echo %warning%WARNING:%reset% Administrator rights detected. Restarting without them...
	if exist "%TEMP%\CEI_deelevate.flag" (
		runas.exe /trustlevel:0x20000 "cmd.exe /c \"\"%~f0\" CEI_NOADMIN\""
		if errorlevel 1 (
			echo.
			echo %red%Failed to restart without Administrator rights%reset%
			echo %green%Start this file with a normal double-click, NOT with %yellow%Run as administrator%reset%
			echo Press any key to Exit...&Pause>nul
			exit /b 1
		)
		exit /b 0
	)
	(echo.>"%TEMP%\CEI_deelevate.flag") 2>nul
	"%SystemRoot%\explorer.exe" "%~f0"
	exit /b 0
)
del "%TEMP%\CEI_deelevate.flag" >nul 2>&1

set "CEI_HOME=%~dp0"
set "CEI_SELF=%~f0"
if "%CEI_HOME:~0,2%"=="\\" (
	cls
	echo %warning%WARNING:%reset% Network paths ^(UNC^) are not supported
	echo %green%Copy the entire package to a local drive and run it again.%reset%
	echo Press any key to Exit...&Pause>nul
	exit /b 1
)

call :NVIDIA_DRIVER_CHECK
if defined FATAL exit /b 1

:: Check for Existing AI-Toolkit Folder ::
if exist AI-Toolkit (
	echo %warning%WARNING:%reset% '%bold%AI-Toolkit%reset%' folder already exists!
	echo %green%Move this file to another folder and run it again.%reset%
	echo Press any key to Exit...&Pause>nul
	goto :eof
)

call :CHECK_LOCATION
if defined FATAL exit /b 1
call :CHECK_NON_ASCII

:: Capture the start time ::
for /f "delims=" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -command "Get-Date -Format yyyy-MM-dd_HH:mm:ss"') do set start=%%i

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
call :install_nodejs

:: Install FFmpeg 8 ::
call :install_ffmpeg8

:: Install Python & pip embedded ::
call :python_embedded_install
if defined FATAL exit /b 1

:: Install AI-Toolkit ::
call :ai-toolkit_install

:: Create 'Start-AI-Toolkit.bat' ::
call :create_bat_files

:: Create shortcut ::
call :create_shortcut
echo.

:: Capture the end time ::
for /f "delims=" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -command "Get-Date -Format yyyy-MM-dd_HH:mm:ss"') do set end=%%i
for /f "delims=" %%i in ('powershell -NoProfile -ExecutionPolicy Bypass -command "$s=[datetime]::ParseExact('%start%','yyyy-MM-dd_HH:mm:ss',$null); $e=[datetime]::ParseExact('%end%','yyyy-MM-dd_HH:mm:ss',$null); if($e -lt $s){$e=$e.AddDays(1)}; ($e-$s).TotalSeconds"') do set diff=%%i

:: Final Messages ::
echo %green%::::::::::::::: Installation Complete :::::::::::::::%reset%
echo %green%::::::::::::::: Total Running Time:%red% %diff% %green%seconds%reset%

(goto) 2>nul & (timeout /t 2 /nobreak >nul & del /f /q "%CD%\%~nx0" & echo. & echo %yellow%::::::::::::::: Press any key to exit :::::::::::::::%reset% & pause >nul & exit)

::::::::::::::::::::::::::::::::: END :::::::::::::::::::::::::::::::::

:set_colors
set warning=[33m
set     red=[91m
set   green=[92m
set  yellow=[93m
set    bold=[97m
set   reset=[0m
goto :eof

:CHECK_LOCATION
set "CEI_ROOT=%CD%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$r=[IO.Path]::GetFullPath($env:CEI_ROOT).TrimEnd('\')+'\'; if($r -ieq ($env:SystemDrive+'\')){exit 1}; foreach($d in @($env:SystemRoot,$env:ProgramFiles,${env:ProgramFiles(x86)},$env:ProgramW6432)){if($d -and $r.StartsWith($d.TrimEnd('\')+'\',[StringComparison]::OrdinalIgnoreCase)){exit 1}}; exit 0"
if errorlevel 1 (
	cls
	echo %warning%WARNING:%reset% Cannot install into system folders like %yellow%Program Files, Windows%reset% or system root %yellow%C:\%reset%
	echo %green%Move this file to another folder and run it again.%reset%
	echo Press any key to Exit...&Pause>nul
	set "FATAL=1"
	goto :eof
)

set "CEI_TEST=.cei_test_%RANDOM%%RANDOM%"
(md "%CEI_TEST%") 2>nul
(echo test>"%CEI_TEST%\write.tmp") 2>nul
if not exist "%CEI_TEST%\write.tmp" (
	rd /s /q "%CEI_TEST%" 2>nul
	cls
	echo %warning%WARNING:%reset% No permission to create folders/files here
	echo Move this file to a folder you own, for example in your user folder or on another drive
	echo %green%Then run it again.%reset%
	echo Press any key to Exit...&Pause>nul
	set "FATAL=1"
	goto :eof
)
rd /s /q "%CEI_TEST%" 2>nul
goto :eof

:CHECK_NON_ASCII
set "CEI_ROOT=%CD%"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$c=0; if($env:CEI_ROOT -cmatch '[^\x00-\x7F]'){$c+=1}; if($env:USERPROFILE -cmatch '[^\x00-\x7F]'){$c+=2}; exit $c"
set "CEI_NA=%errorlevel%"
if %CEI_NA% equ 0 goto :eof
echo.
if %CEI_NA% equ 1 echo %red%WARNING: The installation path contains non-English characters. Installation problems are possible.%reset%
if %CEI_NA% equ 3 echo %red%WARNING: The installation path contains non-English characters. Installation problems are possible.%reset%
if %CEI_NA% equ 2 echo %red%WARNING: Your Windows user folder name contains non-English characters. Installation problems are possible.%reset%
if %CEI_NA% equ 3 echo %red%WARNING: Your Windows user folder name contains non-English characters. Installation problems are possible.%reset%
echo %red%Recommended: use a short English-only path, for example D:\AI\AI-Toolkit\%reset%
echo.
timeout /t 3 /nobreak >nul
goto :eof

:NVIDIA_DRIVER_CHECK
set "NV_MIN=580"
set "NV_FULL="
set "NV_MAJOR="

if exist "%ProgramFiles%\NVIDIA Corporation\NVSMI\nvidia-smi.exe" set "path=%path%;%ProgramFiles%\NVIDIA Corporation\NVSMI"

where.exe nvidia-smi.exe >nul 2>&1
if errorlevel 1 (
	echo.
	echo %warning%WARNING:%reset% %red%NVIDIA driver not detected%reset%
	echo This installer requires an %yellow%NVIDIA GPU%reset% with an installed driver
	echo Install the latest driver from %yellow%https://www.nvidia.com/drivers%reset% and run this installer again
	echo Press any key to Exit...&Pause>nul
	set "FATAL=1"
	goto :eof
)

for /f %%a in ('nvidia-smi --query-gpu^=driver_version --format^=csv^,noheader 2^>nul') do set "NV_FULL=%%a"
for /f "tokens=1 delims=." %%a in ("%NV_FULL%") do set "NV_MAJOR=%%a"

echo %NV_MAJOR%| findstr /R "^[0-9][0-9]*$" >nul
if errorlevel 1 (
	echo.
	echo %warning%WARNING:%reset% %red%Unable to read NVIDIA driver version%reset%
	echo Make sure the NVIDIA driver is working ^(run %yellow%nvidia-smi%reset% in a terminal to check^)
	echo Press any key to Exit...&Pause>nul
	set "FATAL=1"
	goto :eof
)

if %NV_MAJOR% LSS %NV_MIN% (
	echo.
	echo %red%   Your NVIDIA driver %yellow%^(%NV_FULL%^)%red% is below %yellow%%NV_MIN%%reset%
	echo %warning%   Drivers below %yellow%%NV_MIN%%warning% do not support %yellow%CUDA 13%warning% or newer%reset%
	echo %warning%   Recommendation: Update NVIDIA drivers%reset%
	echo %green%   Install the latest driver from %yellow%https://www.nvidia.com/drivers%green% and run this installer again%reset%
	echo Press any key to Exit...&Pause>nul
	set "FATAL=1"
	goto :eof
)
goto :eof

:install_git
:: https://git-scm.com/
echo %green%:::::::::::::: Installing/Updating%yellow% Git %green%::::::::::::::%reset%
echo.

winget.exe install --id Git.Git -e --source winget
set "path=%PATH%;%ProgramFiles%\Git\cmd"
echo.
goto :eof

:install_nodejs
:: https://nodejs.org/en
echo %green%:::::::::::: Installing/Updating%yellow% Node.js %green%::::::::::::%reset%
echo.
winget.exe install --id=OpenJS.NodeJS -e
set "path=%PATH%;%ProgramFiles%\nodejs"
Title %version_title%
echo.
goto :eof

:install_ffmpeg8
echo %green%:::::::::::: Installing/Updating%yellow% FFmpeg 8 %green%:::::::::::%reset%
echo.
winget.exe install --id Gyan.FFmpeg.Shared --version 8.0 --accept-package-agreements --accept-source-agreements
Title %version_title%
echo.
goto :eof

:python_embedded_install
:: https://www.python.org/downloads/release/python-31210/
echo %green%::::::::::::: Installing%yellow% Python embedded %green%::::::::::::%reset%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -Uri 'https://www.python.org/ftp/python/3.12.10/python-3.12.10-embed-amd64.zip' -OutFile 'python-3.12.10-embed-amd64.zip' -UseBasicParsing } catch { exit 1 }" || curl.exe -L --ssl-no-revoke -o python-3.12.10-embed-amd64.zip https://www.python.org/ftp/python/3.12.10/python-3.12.10-embed-amd64.zip

if not exist "python-3.12.10-embed-amd64.zip" (
	echo.
	echo %red%Failed to download python-3.12.10-embed-amd64.zip%reset%
	echo Check your date and time, Windows updates and antivirus HTTPS scanning
	echo Press any key to Exit...&Pause>nul
	set "FATAL=1"
	goto :eof
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "try{if((Get-FileHash -LiteralPath 'python-3.12.10-embed-amd64.zip' -Algorithm SHA256).Hash -eq '4acbed6dd1c744b0376e3b1cf57ce906f9dc9e95e68824584c8099a63025a3c3'){exit 0}else{exit 1}}catch{exit 1}"
if errorlevel 1 (
	erase "python-3.12.10-embed-amd64.zip"
	echo.
	echo %red%Python archive checksum does not match%reset%
	echo The download may be corrupted or modified. Delete the %yellow%AI-Toolkit%reset% folder and run this installer again
	echo Press any key to Exit...&Pause>nul
	set "FATAL=1"
	goto :eof
)

md python_embeded&&cd python_embeded
tar.exe -xmf ..\python-3.12.10-embed-amd64.zip
if errorlevel 1 powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '..\python-3.12.10-embed-amd64.zip' -DestinationPath '.' -Force"

erase ..\python-3.12.10-embed-amd64.zip
echo.
echo %green%::::::::::::::::::: Installing%yellow% pip %green%::::::::::::::::::%reset%
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -Uri 'https://bootstrap.pypa.io/get-pip.py' -OutFile 'get-pip.py' -UseBasicParsing } catch { exit 1 }" || curl.exe -L --ssl-no-revoke -o get-pip.py https://bootstrap.pypa.io/get-pip.py


echo ../AI-Toolkit> python312._pth
echo Lib/site-packages>> python312._pth
echo Lib>> python312._pth
echo Scripts>> python312._pth
echo python312.zip>> python312._pth
echo .>> python312._pth
echo # import site>> python312._pth

echo [global]> pip.ini
echo trusted-host =>> pip.ini
echo     pypi.org>> pip.ini
echo     files.pythonhosted.org>> pip.ini
echo     pypi.python.org>> pip.ini

"%CD%\python.exe" -I get-pip.py %PIPargs% --trusted-host pypi.org --trusted-host files.pythonhosted.org --trusted-host pypi.python.org
REM "%CD%\python.exe" -I -m pip config set global.trusted-host "pypi.org files.pythonhosted.org pypi.python.org"
REM "%CD%\python.exe" -I -m pip install uv==0.9.7 %PIPargs%
"%CD%\python.exe" -I -m pip install uv %PIPargs%
"%CD%\python.exe" -I -m pip install --upgrade pip %PIPargs%

powershell -NoProfile -ExecutionPolicy Bypass -Command "try { Invoke-WebRequest -Uri 'https://github.com/woct0rdho/triton-windows/releases/download/v3.0.0-windows.post1/python_3.12.7_include_libs.zip' -OutFile 'python_3.12.7_include_libs.zip' -UseBasicParsing } catch { exit 1 }" || curl.exe -L --ssl-no-revoke -o python_3.12.7_include_libs.zip https://github.com/woct0rdho/triton-windows/releases/download/v3.0.0-windows.post1/python_3.12.7_include_libs.zip

tar.exe -xmf python_3.12.7_include_libs.zip
if errorlevel 1 powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath 'python_3.12.7_include_libs.zip' -DestinationPath '.' -Force"

erase python_3.12.7_include_libs.zip

echo.
goto :eof

:AI-TOOLKIT_INSTALL
echo %green%::::::::::::::: Installing%yellow% AI-Toolkit %green%:::::::::::::::%reset%
echo.
cd ..\
git.exe clone https://github.com/ostris/ai-toolkit.git
cd ai-toolkit

set "PY_EXE=..\python_embeded\python.exe"

if exist "..\python_embeded\Scripts\uv.exe" (
    echo %green%Using UV for package installation%reset%
    set "INSTALL_CMD=-I -m uv pip install %UVargs%"
) else (
    echo %warning%UV not available - using standard pip%reset%
    set "INSTALL_CMD=-I -m pip install %PIPargs%"
)

%PY_EXE% %INSTALL_CMD% torch==2.13.0 torchvision==0.28.0 --index-url https://download.pytorch.org/whl/cu130
%PY_EXE% %INSTALL_CMD% torchaudio==2.11.0 --index-url https://download.pytorch.org/whl/cu130
%PY_EXE% %INSTALL_CMD% -r requirements.txt
%PY_EXE% %INSTALL_CMD% poetry-core
%PY_EXE% %INSTALL_CMD% wheel
%PY_EXE% %INSTALL_CMD% hf_xet
%PY_EXE% %INSTALL_CMD% -U torchcodec==0.15
%PY_EXE% %INSTALL_CMD% "triton-windows<3.8"
%PY_EXE% %INSTALL_CMD% https://github.com/mjun0812/flash-attention-prebuild-wheels/releases/download/v0.9.52/flash_attn-2.8.3+cu130torch2.13-cp312-cp312-win_amd64.whl

echo.

GOTO :EOF




:create_shortcut
set "LNK_NAME=AI-Toolkit.lnk"
set "ICON_NAME=AI-Toolkit.ico"
set "ICON_URL=https://github.com/Tavris1/AI-Toolkit-Easy-Install/releases/download/assets/AI-Toolkit.ico"
set "ROOT_DIR=%CD%"
set "ICON_PATH=%CD%\python_embeded\%ICON_NAME%"

if not exist "%ICON_PATH%" curl.exe -L -f -s --ssl-no-revoke -o "%ICON_PATH%" "%ICON_URL%"

echo %green%:::::::::: Creating shortcut to%yellow% Start-AI-Toolkit%reset%
powershell -NoProfile -ExecutionPolicy Bypass -command "$p=$env:ROOT_DIR; $i=$env:ICON_PATH; $q=[string][char]34; $s=(New-Object -ComObject WScript.Shell).CreateShortcut($p+'\'+$env:LNK_NAME); $s.TargetPath=$env:SystemRoot+'\explorer.exe'; $s.Arguments=$q+$p+'\Start-AI-Toolkit.bat'+$q; $s.WorkingDirectory=$p; if(Test-Path -LiteralPath $i){$s.IconLocation=$i}; $s.Save()"

if exist "%ROOT_DIR%\%LNK_NAME%" powershell -NoProfile -ExecutionPolicy Bypass -command "Copy-Item -LiteralPath ($env:ROOT_DIR+'\'+$env:LNK_NAME) -Destination ([Environment]::GetFolderPath('Desktop')) -Force -ErrorAction Stop" >nul 2>&1 && echo %green%:::::::::: Shortcut copied to Desktop%reset%
goto :eof

:create_bat_files
cd..\

:::::::::::::::::::::::::::::::::
:: Create Start-AI-Toolkit.bat ::
:::::::::::::::::::::::::::::::::

set "bat_file_name=Start-AI-Toolkit.bat"
echo %green%:::::::::: Creating%yellow% %bat_file_name%%reset%

echo @echo off^&^&cd /d "%%~dp0">%bat_file_name%
echo Title %version_title%>>%bat_file_name%
echo setlocal>>%bat_file_name%
echo.>>%bat_file_name%

echo set "delay=2">>%bat_file_name%
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
echo set    gray=[90m>>%bat_file_name%
echo set     red=[91m>>%bat_file_name%
echo set   green=[92m>>%bat_file_name%
echo set  yellow=[93m>>%bat_file_name%
echo set    blue=[94m>>%bat_file_name%
echo set magenta=[95m>>%bat_file_name%
echo set    cyan=[96m>>%bat_file_name%
echo set   white=[97m>>%bat_file_name%
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

echo set "LNK_ROOT=%%~dp0">>%bat_file_name%
echo start /b powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -LiteralPath '%%~f0' -Raw) -split ('#L'+'N#'))[1]">>%bat_file_name%
echo.>>%bat_file_name%

echo set GIT_LFS_SKIP_SMUDGE^=^1>>%bat_file_name%
echo set "local_serv=http://localhost:8675">>%bat_file_name%
echo echo.>>%bat_file_name%
echo cd /d "%%~dp0ai-toolkit">>%bat_file_name%
echo     echo %%green%%::::::::::::::: Starting AI-Toolkit ::::::::::::::%%reset%%>>%bat_file_name%
echo     echo.>>%bat_file_name%
echo git.exe fetch --quiet ^>nul ^2^>^&^1>>%bat_file_name%
echo set "BEHIND=">>%bat_file_name%
echo for /f %%%%A in ^('git.exe rev-list --count HEAD..@{u} 2^^^>nul'^) do set "BEHIND=%%%%A">>%bat_file_name%
echo if defined BEHIND if not "%%BEHIND%%"=="0" ^(>>%bat_file_name%
echo     powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -LiteralPath '%%~f0' -Raw) -split ('#P'+'S#'))[1]">>%bat_file_name%
echo     if errorlevel 1 ^(>>%bat_file_name%
echo         call "%%~dp0Update-AI-Toolkit.bat" nopause>>%bat_file_name%
echo         cd /d "%%~dp0ai-toolkit">>%bat_file_name%
echo         Title %version_title%>>%bat_file_name%
echo     ^) else ^(>>%bat_file_name%
echo         echo  - %%red%%UPDATES%%reset%% available.%%green%% Run Update-AI-Toolkit.bat%%reset%%>>%bat_file_name%
echo         echo.>>%bat_file_name%
echo     ^)>>%bat_file_name%
echo ^)>>%bat_file_name%
echo.>>%bat_file_name%

echo echo  - Stop the server with %%green%%Ctrl+C twice%%reset%%, not with %%red%%X%%reset%%>>%bat_file_name%
echo echo.>>%bat_file_name%
echo echo %%green%%::::::: Starting the server. Please wait... ::::::>>%bat_file_name%
echo.>>%bat_file_name%

echo timeout %%delay%%>>%bat_file_name%
echo.>>%bat_file_name%

echo echo %%reset%%>>%bat_file_name%
echo.>>%bat_file_name%

echo set "path=%%windir%%\System32\WindowsPowerShell\v1.0;%%path%%">>%bat_file_name%
echo.>>%bat_file_name%

echo start /b powershell -NoProfile -ExecutionPolicy Bypass -Command "while(1){Start-Sleep 2;try{Invoke-WebRequest 'http://localhost:8675' -TimeoutSec 2 -UseBasicParsing -EA Stop|Out-Null;Start-Process 'http://localhost:8675';break}catch{}}">>%bat_file_name%
echo.>>%bat_file_name%

echo npm --prefix "%%~dp0AI-Toolkit\ui" run build_and_start>>%bat_file_name%
echo exit /b>>%bat_file_name%
set "CEI_OUT=%CD%\%bat_file_name%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$b=[IO.File]::ReadAllText($env:CEI_SELF).Split(@('#P'+'S#'),[StringSplitOptions]::None)[1]; [IO.File]::AppendAllText($env:CEI_OUT,'#P'+'S#'+$b+'#P'+'S#',[Text.Encoding]::ASCII)"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$b=[IO.File]::ReadAllText($env:CEI_SELF).Split(@('#L'+'N#'),[StringSplitOptions]::None)[1]; [IO.File]::AppendAllText($env:CEI_OUT,'#L'+'N#'+$b+'#L'+'N#',[Text.Encoding]::ASCII)"

::::::::::::::::::::::::::::::::::
:: Create Update-AI-Toolkit.bat ::
::::::::::::::::::::::::::::::::::

set "bat_file_name=Update-AI-Toolkit.bat"
echo %green%:::::::::: Creating%yellow% %bat_file_name%%reset%

echo @echo off^&^&cd /d "%%~dp0">%bat_file_name%
echo Title AI-Toolkit Update by ivo>>%bat_file_name%
echo setlocal>>%bat_file_name%
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
echo cd /d "%%~dp0ai-toolkit">>%bat_file_name%
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
echo ..\python_embeded\python.exe -I -m pip install -U torchcodec==0.15 >>%bat_file_name%
echo.>>%bat_file_name%

echo echo.>>%bat_file_name%
echo echo %%green%%:::::::::::::::   Update completed    :::::::::::::::%%reset%%>>%bat_file_name%
echo echo.>>%bat_file_name%
echo if "%%~1"=="" ^(>>%bat_file_name%
echo     echo %%yellow%%::::::::::::::: Press any key to exit :::::::::::::::%%reset%%^&Pause^>nul>>%bat_file_name%
echo     exit /b>>%bat_file_name%
echo ^)>>%bat_file_name%
echo.>>%bat_file_name%

echo exit /b>>%bat_file_name%


goto :eof

#LN#
$ErrorActionPreference='SilentlyContinue'
$p=$env:LNK_ROOT.TrimEnd('\')
$bat=$p+'\Start-AI-Toolkit.bat'
$ico=$p+'\python_embeded\AI-Toolkit.ico'
$exe=$env:SystemRoot+'\explorer.exe'
$q=[string][char]34
$arg=$q+$bat+$q
$lnk=$p+'\AI-Toolkit.lnk'
if(-not(Test-Path -LiteralPath $ico)){& curl.exe -L -f -s --ssl-no-revoke -o $ico 'https://github.com/Tavris1/AI-Toolkit-Easy-Install/releases/download/assets/AI-Toolkit.ico'}
$hasIco=Test-Path -LiteralPath $ico
$w=New-Object -ComObject WScript.Shell
$ok=$false
if(Test-Path -LiteralPath $lnk){
    $c=$w.CreateShortcut($lnk)
    $ok=($c.TargetPath -ieq $exe) -and ($c.Arguments -ieq $arg) -and ($c.WorkingDirectory -ieq $p) -and ((-not $hasIco) -or ($c.IconLocation -ieq ($ico+',0')))
}
if(-not $ok){
    $s=$w.CreateShortcut($lnk)
    $s.TargetPath=$exe
    $s.Arguments=$arg
    $s.WorkingDirectory=$p
    if($hasIco){$s.IconLocation=$ico}
    $s.Save()
}
#LN#

#PS#
Add-Type -AssemblyName System.Windows.Forms,System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()
[Console]::OutputEncoding=[Text.Encoding]::UTF8
$total=5
$n=$env:BEHIND
$msg=''
try{$msg=(& git.exe log -1 --format=%s '@{u}' 2>$null|Select-Object -First 1)}catch{}
if([string]::IsNullOrWhiteSpace($msg)){$msg='No description'}
$c={param($h) [Drawing.ColorTranslator]::FromHtml($h)}
$f=New-Object Windows.Forms.Form
$f.FormBorderStyle='None'
$f.StartPosition='CenterScreen'
$f.TopMost=$true
$f.ShowInTaskbar=$false
$f.ClientSize=New-Object Drawing.Size(420,200)
$f.BackColor=&$c '#1e1e24'
$bar=New-Object Windows.Forms.Panel
$bar.Location=New-Object Drawing.Point(0,0)
$bar.Size=New-Object Drawing.Size(420,4)
$bar.BackColor=&$c '#4ade80'
$t1=New-Object Windows.Forms.Label
$t1.Text='Update available'
$t1.Font=New-Object Drawing.Font('Segoe UI',16,[Drawing.FontStyle]::Bold)
$t1.ForeColor=&$c '#ffffff'
$t1.Location=New-Object Drawing.Point(20,22)
$t1.AutoSize=$true
$t2=New-Object Windows.Forms.Label
$t2.Text="$n new commit(s) in AI-Toolkit"
$t2.Font=New-Object Drawing.Font('Segoe UI',10)
$t2.ForeColor=&$c '#9ca3af'
$t2.Location=New-Object Drawing.Point(22,58)
$t2.AutoSize=$true
$t3=New-Object Windows.Forms.Label
$t3.Text="Latest: $msg"
$t3.Font=New-Object Drawing.Font('Segoe UI',10)
$t3.ForeColor=&$c '#e5e7eb'
$t3.Location=New-Object Drawing.Point(22,86)
$t3.Size=New-Object Drawing.Size(376,40)
$t3.AutoEllipsis=$true
$ok=New-Object Windows.Forms.Button
$ok.Text='UPDATE NOW'
$ok.Font=New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold)
$ok.Location=New-Object Drawing.Point(20,138)
$ok.Size=New-Object Drawing.Size(190,42)
$ok.FlatStyle='Flat'
$ok.FlatAppearance.BorderSize=0
$ok.BackColor=&$c '#4ade80'
$ok.ForeColor=&$c '#0b0b0f'
$ok.DialogResult='OK'
$no=New-Object Windows.Forms.Button
$no.Text="Later ($total)"
$no.Font=New-Object Drawing.Font('Segoe UI',10)
$no.Location=New-Object Drawing.Point(210,138)
$no.Size=New-Object Drawing.Size(190,42)
$no.FlatStyle='Flat'
$no.FlatAppearance.BorderSize=0
$no.BackColor=&$c '#2f2f38'
$no.ForeColor=&$c '#e5e7eb'
$no.DialogResult='Cancel'
$f.Controls.AddRange(@($bar,$t1,$t2,$t3,$ok,$no))
$f.AcceptButton=$ok
$f.CancelButton=$no
$sw=New-Object Diagnostics.Stopwatch
$tm=New-Object Windows.Forms.Timer
$tm.Interval=50
$tm.Add_Tick({
    $left=$total-$sw.Elapsed.TotalSeconds
    if($left -le 0){$f.DialogResult='Cancel';$f.Close();return}
    $bar.Width=[int](420*$left/$total)
    $no.Text="Later ($([math]::Ceiling($left)))"
})
$f.Add_Shown({$f.Activate();$sw.Start();$tm.Start()})
$r=$f.ShowDialog()
if($r -eq 'OK'){exit 1}else{exit 0}
#PS#