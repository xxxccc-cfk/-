param([string]$GodotPath = (Join-Path $PSScriptRoot '../../work/godot/Godot_v4.7.2-stable_win64_console.exe'))
if (-not (Test-Path -LiteralPath $GodotPath)) { throw 'Godot not found. Pass -GodotPath with your Godot 4.x executable.' }
& $GodotPath --path $PSScriptRoot
exit $LASTEXITCODE
