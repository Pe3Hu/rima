class_name MoldTemplateData
extends RefCounted

## Неизменяемый шаблон Mold. Поле JSON weapon читается как weapon_name.

var id: String = ""
var weapon_name: String = ""
var cells: Array[Vector2i] = []
var holes: Array[Vector2i] = []
var source_path: String = ""
var width: int = 0
var height: int = 0
var load_errors: Array[String] = []

var _cell_lookup: Dictionary = {}


static func load_from_file(path_: String) -> MoldTemplateData:
	var template := MoldTemplateData.new()
	template.source_path = path_
	var parsed: Variant = Helper.read_json(path_)
	if parsed == null or not (parsed is Dictionary):
		template.load_errors.append("task json must be an object: " + path_)
		return template
	template._read_dictionary(parsed)
	return template


func get_cell_count() -> int:
	return cells.size()


func is_cell_inside(cell_: Vector2i) -> bool:
	return _cell_lookup.has(cell_)


func _read_dictionary(data_: Dictionary) -> void:
	id = str(data_.get("id", ""))
	weapon_name = str(data_.get("weapon", ""))
	var board: Dictionary = data_.get("board", {})
	width = int(board.get("width", 0))
	height = int(board.get("height", 0))
	var board_type := str(board.get("type", ""))
	_read_holes(board.get("holes", []))
	if board_type != "rect_with_holes":
		load_errors.append("unsupported board.type: " + board_type)
		return
	if width <= 0 or height <= 0:
		load_errors.append("board width and height must be positive")
		return
	var hole_lookup: Dictionary = {}
	for hole in holes:
		hole_lookup[hole] = true
	for y in height:
		for x in width:
			var cell := Vector2i(x, y)
			if hole_lookup.has(cell):
				continue
			cells.append(cell)
			_cell_lookup[cell] = true


func _read_holes(raw_: Variant) -> void:
	if raw_ == null:
		return
	if not (raw_ is Array):
		load_errors.append("board.holes must be an array")
		return
	for pair in raw_:
		if pair is Array and pair.size() >= 2:
			holes.append(Vector2i(int(pair[0]), int(pair[1])))
		else:
			load_errors.append("hole must be [x, y]")
