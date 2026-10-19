class_name TaskData
extends RefCounted

## Описание задачи: доска, набор фигур, симметрии и параметры солвера.
## Собирается из JSON (`load_from_json`) и больше нигде не зашито в код.

var id: String = ""
var task_name: String = ""
var board: MaskBoardData
var pieces: PieceSetData
var max_solutions: int = 0
var dedupe_by_symmetry: bool = true
var anchor_policy: String = "any_free_cell"
var output_format: String = "json"
var output_path: String = ""

var symmetry: SymmetryGroup = SymmetryGroup.from_spec("identity")
var load_errors: Array[String] = []


static func load_from_json(path: String) -> TaskData:
	var task := TaskData.new()
	if not FileAccess.file_exists(path):
		task.load_errors.append("file not found: " + path)
		return task
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null or not (parsed is Dictionary):
		task.load_errors.append("task json must be an object: " + path)
		return task
	var data: Dictionary = parsed
	task.id = str(data.get("id", ""))
	task.task_name = str(data.get("name", ""))
	if task.id == "":
		task.load_errors.append("task id is required")

	if not data.has("board") or not (data["board"] is Dictionary):
		task.load_errors.append("task.board is required")
	else:
		var symmetry_value: Variant = data.get("symmetry", "identity")
		task.symmetry = SymmetryGroup.from_spec(symmetry_value)
		task.board = MaskBoardData.from_dictionary(data["board"], task.symmetry.name)
		task.load_errors.append_array(task.board.parse_errors)

	if not data.has("pieces") or not (data["pieces"] is Dictionary):
		task.load_errors.append("task.pieces is required")
	else:
		task.pieces = PieceSetData.load_spec(data["pieces"])
		task.load_errors.append_array(task.pieces.load_errors)

	var solver: Dictionary = {}
	if data.has("solver") and data["solver"] is Dictionary:
		solver = data["solver"]
	task.max_solutions = int(solver.get("max_solutions", 0))
	task.dedupe_by_symmetry = bool(solver.get("dedupe_by_symmetry", true))
	task.anchor_policy = str(solver.get("anchor_policy", "any_free_cell"))

	var output: Dictionary = {}
	if data.has("output") and data["output"] is Dictionary:
		output = data["output"]
	task.output_format = str(output.get("format", "json"))
	task.output_path = str(output.get("path", ""))
	return task


## Проверки до построения матрицы: площадь, политика якоря, симметрия маски.
func validate() -> Array[String]:
	var errors: Array[String] = []
	if anchor_policy != "any_free_cell":
		errors.append("unsupported anchor_policy: " + anchor_policy)
	if output_format != "" and output_format != "json":
		errors.append("unsupported output format: " + output_format)
	if board == null or pieces == null:
		errors.append("task is incomplete")
		return errors
	if board.free_cells().is_empty():
		errors.append("board has no free cells")
	if pieces.pieces.is_empty():
		errors.append("piece set is empty")
	var free_count := board.free_cells().size()
	var area := pieces.expected_area()
	if free_count != area:
		errors.append("free cells %d != piece area %d" % [free_count, area])
	if symmetry != null:
		var symmetry_error := symmetry.preservation_error(board)
		if symmetry_error != "":
			errors.append(symmetry_error)
	return errors
