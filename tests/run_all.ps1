$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$godot = if ($env:GODOT) { $env:GODOT } else { "godot" }
& $godot --headless --path $root -s res://tests/run_all.gd
exit $LASTEXITCODE
