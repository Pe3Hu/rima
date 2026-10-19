extends SceneTree

## Headless-вход: godot --headless --path . -s res://tools/run_task.gd -- <task.json>


func _initialize() -> void:
	var runner := TaskRunner.new()
	var path := runner.path_from_args()
	if path.is_empty():
		push_error("Usage: godot --headless --path . -s res://tools/run_task.gd -- <task.json>")
		quit(1)
		return
	quit(runner.run(path))
