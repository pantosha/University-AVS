@echo off

set file_name=Lab3

if exist "%file_name%.obj" del "%file_name%.obj"
if exist "%file_name%" del "%file_name%.exe"

\masm32\bin\ml /c /coff "%file_name%.asm"
if errorlevel 1 goto errasm

 \masm32\bin\PoLink /SUBSYSTEM:CONSOLE "%file_name%.obj"
 if errorlevel 1 goto errlink
dir "%file_name%.*"
goto TheEnd

:errlink
 echo _
echo Link error
goto TheEnd

:errasm
 echo _
echo Assembly Error
goto TheEnd

:TheEnd
 
pause
