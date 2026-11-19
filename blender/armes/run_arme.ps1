# Usage: .\run_arme.ps1 epee_fer.py   -> src\partage\ArmesVoxels\<Id>.lua + previews\armes\<Id>.png
param([Parameter(Mandatory)][string]$File)
$blender = if ($env:BLENDER_EXE) { $env:BLENDER_EXE } else { 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' }
& $blender -b --factory-startup --python (Join-Path $PSScriptRoot $File) | Select-String 'ARME_|Traceback|Error|line \d+'
