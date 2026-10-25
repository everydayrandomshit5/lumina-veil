@echo off
title Godot 4 Editor - Lumina Veil
set GODOT="C:\Users\ankoo\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
start "" %GODOT% --path "%~dp0." -e
