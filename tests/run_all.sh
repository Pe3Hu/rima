#!/bin/sh
root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
godot=${GODOT:-godot}
exec "$godot" --headless --path "$root" -s res://tests/run_all.gd
