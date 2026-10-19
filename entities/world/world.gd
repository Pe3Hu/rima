class_name World
extends Node


func _ready() -> void:
	pass


func test_dlx(task_path: String) -> void:
	var task := TaskData.load_from_json(task_path)
	var solver := PuzzleSolver.new()
	var result := solver.solve(task)
	print(result.summary())
	if task.output_path != "":
		result.save(task.output_path)


func test_loader(task_path: String) -> void:
	var task := TaskData.load_from_json(task_path)
	var loader := CompositionLoader.new()
	var compositions := loader.load_compositions(task.output_path, task.board, task.pieces)
	print("loaded compositions:", compositions.size())
	for composition in compositions:
		print(composition.get_data(task.board.width))


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		match event.keycode:
			KEY_ESCAPE:
				get_tree().quit()
