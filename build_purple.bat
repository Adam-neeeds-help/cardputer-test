@echo off
setlocal EnableDelayedExpansion

call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat" || goto error

set QT_BIN_DIR=C:\Qt\6.4.2\msvc2019_64\bin
set QMAKE=%QT_BIN_DIR%\qmake.exe
set WINDEPLOYQT=%QT_BIN_DIR%\windeployqt.exe
set JOM=C:\Qt\Tools\QtCreator\bin\jom\jom.exe

set TARGET=qFlipper
set PROJECT_DIR=%~dp0
set PROJECT_DIR=%PROJECT_DIR:~0,-1%
set BUILD_DIR=%PROJECT_DIR%\build
set QML_DIR=%PROJECT_DIR%\application
set DIST_DIR=%BUILD_DIR%\%TARGET%

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
cd /d "%BUILD_DIR%"

"%QMAKE%" "%PROJECT_DIR%\%TARGET%.pro" -spec win32-msvc "CONFIG+=qtquickcompiler" || goto error
"%JOM%" qmake_all || goto error
"%JOM%" || goto error
"%JOM%" install || goto error

cd /d "%DIST_DIR%"
"%WINDEPLOYQT%" --release --no-compiler-runtime --qmldir "%QML_DIR%" %TARGET%.exe || goto error

echo BUILD_OK
echo App is at: %DIST_DIR%\%TARGET%.exe
exit /b 0

:error
echo BUILD_FAILED with errorlevel %errorlevel%
exit /b 1
