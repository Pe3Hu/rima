class_name TaskRunner
extends Node

## Запускает задачу из JSON и записывает решения в `task.output.path`.

@export var task_path: String = ""
@export var quit_when_done: bool = true


func _ready() -> void:
	var path := task_path
	if path.is_empty():
		path = path_from_args()
	var code := 1
	if path.is_empty():
		push_error("Usage: pass task_path or -- <task.json>")
	else:
		code = run(path)
	if quit_when_done and is_inside_tree():
		get_tree().quit(code)


func path_from_args() -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		args = OS.get_cmdline_args()
	for arg in args:
		var text := str(arg)
		if text.ends_with(".json"):
			return text
	return ""


func run(path: String) -> int:
	var task := TaskData.load_from_json(path)
	var solver := PuzzleSolver.new()
	solver.progress.connect(func(done: int, total: int) -> void:
		if done % Catalog.PROGRESS_EVERY == 0:
			print("progress raw=%d limit=%d" % [done, total])
	)
	var result := solver.solve(task)
	print(result.summary())
	if result.diagnostics.has("errors"):
		return 1
	if task.output_path == "":
		push_error("task output path is empty")
		return 1
	if not result.save(task.output_path):
		return 1
	print("wrote: ", task.output_path)
	return 0
