@echo off
setlocal EnableDelayedExpansion

set ARCH_BITS=64

rem If cl.exe is already on PATH (e.g. set up by a CI step such as
rem ilammy/msvc-dev-cmd), reuse that environment instead of hunting for a
rem specific MSVC install.
where cl.exe >nul 2>nul
if !errorlevel! equ 0 goto skipmsvc

for %%v in (2022 2019) do (
    for %%p in ("%programfiles%" "%programfiles(x86)%") do (
        for %%s in (Community Professional Enterprise BuildTools) do (
            set "MSVC_VCVARS_PATH=%%~p\Microsoft Visual Studio\%%v\%%s\VC\Auxiliary\Build\vcvars%ARCH_BITS%.bat"
            if exist "!MSVC_VCVARS_PATH!" goto foundmsvc
        )
    )
)

echo Could not find MSVC && goto error

:foundmsvc
call "!MSVC_VCVARS_PATH!"

:skipmsvc

rem If Qt's bin dir isn't already on PATH (e.g. via jurplel/install-qt-action),
rem fall back to a manually installed Qt under QT_DIR.
where qmake.exe >nul 2>nul
if !errorlevel! equ 0 (
    set QMAKE=qmake.exe
    set WINDEPLOYQT=windeployqt.exe
) else (
    if not defined QT_DIR set QT_DIR=C:\Qt
    if not defined QT_VERSION set QT_VERSION=6.4.2
    set QT_COMPILER=msvc2019_%ARCH_BITS%
    set "QT_BIN_DIR=!QT_DIR!\!QT_VERSION!\!QT_COMPILER!\bin"
    set "QMAKE=!QT_BIN_DIR!\qmake.exe"
    set "WINDEPLOYQT=!QT_BIN_DIR!\windeployqt.exe"
)

rem jom is a faster drop-in replacement for nmake, bundled with the Qt
rem Creator tools package. Fall back to plain nmake when it's not installed.
if not defined QT_DIR set QT_DIR=C:\Qt
set "JOM=%QT_DIR%\Tools\QtCreator\bin\jom\jom.exe"
if not exist "%JOM%" set JOM=nmake

rem Download here https://cdn.flipperzero.one/STM32_DFU_USB_Driver.zip
if not defined STM32_DRIVER_DIR set STM32_DRIVER_DIR="C:\STM32 Driver"

set TARGET=QPuter
set TARGET_CLI=%TARGET%-cli
set PROTO_TARGET=flipperproto
set DRIVER_TOOL=FlipperDriverTool

set PROJECT_DIR=%cd%
set BUILD_DIR=%PROJECT_DIR%\build
set QML_DIR=%PROJECT_DIR%\Application
set DIST_DIR=%BUILD_DIR%\%TARGET%
set PLUGINS_DIR=%DIST_DIR%\plugins
set DRIVER_TOOL_DIR=%PROJECT_DIR%\driver-tool

if not defined OPENSSL_DIR set "OPENSSL_DIR=%QT_DIR%\Tools\OpenSSL\Win_x%ARCH_BITS%\bin"
if not defined VCREDIST_DIR set "VCREDIST_DIR=%QT_DIR%\vcredist"

set NSIS="%programfiles(x86)%\NSIS\makensis.exe"

set VCREDIST2019_EXE=%VCREDIST_DIR%\vcredist_msvc2019_x%ARCH_BITS%.exe
rem Visual C++ 2010 from Qt5 package is outdated and have exe sign from 2014.
rem It should be replaced with new version that have year 2021 signature, downloaded from Microsoft website
set VCREDIST2010_EXE=%VCREDIST_DIR%\vcredist_x%ARCH_BITS%.exe

rem if exist %BUILD_DIR% (rmdir /S /Q %BUILD_DIR%)

rem Build the application
mkdir %BUILD_DIR%
cd %BUILD_DIR%

%QMAKE% %PROJECT_DIR%\%TARGET%.pro -spec win32-msvc "CONFIG+=qtquickcompiler" &&^
%JOM% qmake_all && %JOM% && %JOM% install || goto error

rem Deploy the application
cd %DIST_DIR%

%WINDEPLOYQT% --release --no-compiler-runtime --dir %DIST_DIR% %PLUGINS_DIR%/%PROTO_TARGET%0.dll &&^
%WINDEPLOYQT% --release --no-compiler-runtime --qmldir %QML_DIR% %TARGET%.exe &&^
%WINDEPLOYQT% --release --no-compiler-runtime %TARGET_CLI%.exe || goto error

rem Copy OpenSSL binaries, if bundled (Qt 6 can fall back to Schannel without them)
if exist "%OPENSSL_DIR%" copy /Y %OPENSSL_DIR%\*.dll .

rem Copy the driver, if available
if exist %STM32_DRIVER_DIR% xcopy /Y /E /I %STM32_DRIVER_DIR% %DIST_DIR%\"STM32 Driver"

rem Copy Microsoft Visual C++ redistributable packages, if available
if exist %VCREDIST2019_EXE% copy /Y %VCREDIST2019_EXE% .
if exist %VCREDIST2010_EXE% copy /Y %VCREDIST2010_EXE% .

if defined SIGNING_TOOL (
    rem Sign the executables
    call %SIGNING_TOOL% %DIST_DIR%\%TARGET%.exe || goto error
    call %SIGNING_TOOL% %DIST_DIR%\%TARGET_CLI%.exe || goto error
)

rem Make the zip archive as well
tar -a -cf %BUILD_DIR%\%TARGET%-%ARCH_BITS%bit.zip *

rem Make the installer
cd %PROJECT_DIR%
%NSIS% /DNAME=%TARGET% /DARCH_BITS=%ARCH_BITS% installer_windows.nsi || goto error

timeout /T 5 /NOBREAK > nul

if defined SIGNING_TOOL (
    rem Sign the installer
    call %SIGNING_TOOL% %BUILD_DIR%\%TARGET%Setup-%ARCH_BITS%bit.exe || goto error
)

echo The resulting installer is %BUILD_DIR%\%TARGET%Setup-%ARCH_BITS%bit.exe.
echo Finished.
exit 0

:error
echo There were errors during the build process!
exit 1
