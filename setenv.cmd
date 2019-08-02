@echo off
echo Setting kitserver compile environment
@call "c:\vs11\vc\bin\x86_amd64\vcvarsx86_amd64.bat"
set INCLUDE="soft\xinput1_3\include";%INCLUDE%
set LIB="soft\xinput1_3\lib\x64";%LIB%
echo Environment set

