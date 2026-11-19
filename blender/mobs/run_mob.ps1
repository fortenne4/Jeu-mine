# Usage: .\run_mob.ps1 <fichier.py> [all|render|export]   -> out\<Name>\ (sheet.png, loop.gif, Data/Clips .luau)
param([Parameter(Mandatory)][string]$File, [string]$Mode = 'all')
$env:BLENDER_EXE = 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe'
$p = Join-Path $PSScriptRoot $File
powershell -File "C:\Users\Owen\.claude\skills\lihfolk-stud-voxel\scripts\run.ps1" $p $Mode | Select-String 'STUD_RESULT|POST_OK|Traceback|Error|line \d+'
