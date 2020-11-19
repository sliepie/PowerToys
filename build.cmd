@echo off
setlocal

cd /D "%~dp0"

SET SOLUTION=.\PowerToys.sln
SET APPS_DIR=D:\apps\powertoys
SET RUNNER_EXE=powertoys.exe
SET OUTPUT_DIR=.\x64\Release

REM if "%~1" equ "clean" goto gitclean
if "%~1" equ "update" goto gitupdate
if "%~1" equ "restore" goto restore_nuget
if "%~1" equ "build" goto build
if "%~1" equ "publish" goto publish
if "%~1" equ "start" goto pt_start

:gitconfig
echo :: Set local git config
call git config --local core.autocrlf false
call git config --local core.safecrlf true
echo Done

:gitclean
echo :: Clean repo
call git clean -fd > nul
call rd /s /q x64 2> nul
call git reset --hard HEAD~0 > nul

if "%errorlevel%" neq "0" (
    echo Error
    exit /b %errorlevel%
)
echo Done

:gitupdate
echo :: Fetch latest changes
call git pull --rebase origin master > nul
call git submodule update --init --recursive > nul

if "%errorlevel%" neq "0" (
    echo Error
    exit /b %errorlevel%
)
echo Done

:restore_nuget
echo :: Restore NuGet
call nuget restore %SOLUTION% > nul

if "%errorlevel%" neq "0" (
    echo Error
    exit /b %errorlevel%
)
echo Done

:build
echo :: Build PowerToys
@REM call msbuild %SOLUTION% /p:Configuration=Release /p:Platform=x64 /p:CIBuild=true || exit /b 1
call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Preview\Common7\Tools\VsDevCmd.bat" -arch=amd64 -host_arch=amd64 -winsdk=10.0.18362.0
call msbuild %SOLUTION% /p:Configuration=Release /p:Platform=x64 /p:CIBuild=true > ../powertoys.log

if "%errorlevel%" neq "0" (
    echo Error
    exit /b %errorlevel%
)
echo Done

:publish
REM echo :: Publish dir
REM echo Done
REM call rd /s /q %OUTPUT_DIR%\obj 2> nul
REM call del /s /q *.*pdb 2>&1 > nul
REM call del /s /q *.*obj 2>&1 > nul

REM if "%errorlevel%" neq "0" (
REM     exit /b %errorlevel%
REM )

echo :: Kill running powertoys.exe
call taskkill /IM %RUNNER_EXE% /F 2>&1 > nul
echo Done

echo :: Publish PowerToys to apps folder
call rd /s /q %APPS_DIR% 2> nul
call robocopy %OUTPUT_DIR%\modules %APPS_DIR%\modules /MIR > nul
call robocopy %OUTPUT_DIR%\settings-html %APPS_DIR%\settings-html /MIR > nul
call robocopy %OUTPUT_DIR%\SettingsUIRunner %APPS_DIR%\SettingsUIRunner /MIR > nul
call robocopy %OUTPUT_DIR%\svgs %APPS_DIR%\svgs /MIR > nul

call copy %OUTPUT_DIR%\action_runner.exe %APPS_DIR% > nul
call copy %OUTPUT_DIR%\PowerToys.exe %APPS_DIR% > nul
call copy %OUTPUT_DIR%\PowerToysSettings.exe %APPS_DIR% > nul
echo Done!

:pt_start
echo :: Start powertoys.exe
start %APPS_DIR%\%RUNNER_EXE%
echo Done

exit /b %errorlevel%
