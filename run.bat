@echo off
cls
echo 1. synth
call winmake synth_vlog
if errorlevel 1 exit /b 1
echo 2. impl
call winmake impl
if errorlevel 1 exit /b 2
echo 3. jtag
call winmake jtag
if errorlevel 1 exit /b 3
