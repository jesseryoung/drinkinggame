@echo off
cd %~dp0

SETLOCAL
SET SOURCE=src\dgplugin.sp
SET PROGRAM=dgplugin.smx
SET CC=sourcemod\scripting\spcomp

del %PROGRAM%
call %CC% %SOURCE%