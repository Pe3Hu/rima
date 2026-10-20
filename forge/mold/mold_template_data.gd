class_name MoldTemplateData
extends RefCounted

## Неизменяемый шаблон Mold. Поле JSON weapon читается как weapon_name.

var id: String = ""
var weapon_name: String = ""
var cells: Array[Vector2i] = []
var holes: Array[Vector2i] = []
var cell_to_part: Dictionary = {}
var parts: Array[PartData] = []
var is_horizontal_symmetric: bool = false
var is_fully_symmetric: bool = false
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


func get_part_at(cell_: Vector2i) -> Bozo.Part:
	if not cell_to_part.has(cell_):
		return Bozo.Part.NONE
	return cell_to_part[cell_]


## Полная симметрия заменяет горизонтальную: четыре RAZOR, без SPIKE.
func get_strata_config() -> Array:
	var config: Array = []
	if is_fully_symmetric:
		config.append({"subtype": Bozo.Stratum.RAZOR, "direction": Bozo.Direction.RIGHT})
		config.append({"subtype": Bozo.Stratum.RAZOR, "direction": Bozo.Direction.LEFT})
		config.append({"subtype": Bozo.Stratum.RAZOR, "direction": Bozo.Direction.TOP})
		config.append({"subtype": Bozo.Stratum.RAZOR, "direction": Bozo.Direction.BOTTOM})
		return config
	config.append({"subtype": Bozo.Stratum.RAZOR, "direction": Bozo.Direction.RIGHT})
	if is_horizontal_symmetric:
		config.append({"subtype": Bozo.Stratum.RAZOR, "direction": Bozo.Direction.LEFT})
	config.append({"subtype": Bozo.Stratum.SPIKE, "direction": Bozo.Direction.TOP})
	return config


func _read_dictionary(data_: Dictionary) -> void:
	id = str(data_.get("id", ""))
	weapon_name = str(data_.get("weapon", ""))
	is_horizontal_symmetric = data_.get("is_horizontal_symmetric", false) == true
	is_fully_symmetric = data_.get("is_fully_symmetric", false) == true
	var board: Dictionary = data_.get("board", {})
	width = int(board.get("width", 0))
	height = int(board.get("height", 0))
	var board_type := str(board.get("type", ""))
	_read_holes(board.get("holes", []))
	_read_parts(board)
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


## spine и bevel лежат в board, формат пар как у holes. Нет ключа — пустой массив.
func _read_parts(board_: Dictionary) -> void:
	cell_to_part.clear()
	parts.clear()
	_read_part_cells(board_.get("spine", []), Bozo.Part.SPINE, "board.spine")
	_read_part_cells(board_.get("bevel", []), Bozo.Part.BEVEL, "board.bevel")


func _read_part_cells(raw_: Variant, part_: Bozo.Part, label_: String) -> void:
	if raw_ == null:
		return
	if not (raw_ is Array):
		load_errors.append(label_ + " must be an array")
		return
	var cells: Array[Vector2i] = []
	for pair in raw_:
		if pair is Array and pair.size() >= 2:
			var cell := Vector2i(int(pair[0]), int(pair[1]))
			cells.append(cell)
			cell_to_part[cell] = part_
		else:
			load_errors.append(label_ + " cell must be [x, y]")
	if cells.is_empty():
		return
	var part_data := PartData.new()
	part_data.init_cells(part_, cells)
	parts.append(part_data)
