@echo off
echo Setting kitserver compile environment
@call "c:\program files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsx86_amd64.bat"
set INCLUDE="soft\xinput1_3\include";%INCLUDE%
set LIB="soft\xinput1_3\lib\x64";%LIB%
echo Environment set

