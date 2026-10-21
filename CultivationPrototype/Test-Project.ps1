param([string]$GodotPath = (Join-Path $PSScriptRoot '../../work/godot/Godot_v4.7.2-stable_win64_console.exe'))
if (-not (Test-Path -LiteralPath $GodotPath)) { throw 'Godot not found. Pass -GodotPath with your Godot 4.x executable.' }
& $GodotPath --headless --path $PSScriptRoot --editor --quit
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
foreach ($suite in @('smoke', 'feedback', 'save')) {
    & $GodotPath --headless --path $PSScriptRoot --script "res://tests/$suite.gd"
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
exit 0
