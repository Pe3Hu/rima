class_name MaskBoardData
extends RefCounted

## Прямоугольная доска с вырезами. Единственный источник размера и маски.
##
## Свободная клетка — та, что внутри `width`×`height` и не входит в `holes`.
## `cell_index` нумерует только свободные клетки (колонки DLX). Линейный индекс
## файла решений считает и вырезы: `width * y + x`.

var width: int = 0
var height: int = 0
var holes: Array[Vector2i] = []
var symmetry_group: String = "identity"

var parse_errors: Array[String] = []

var _holes: Dictionary = {}
var _column: Dictionary = {}
var _free: Array[Vector2i] = []
var _ready: bool = false


func _init() -> void:
	holes = []
	parse_errors = []


## Загружает доску из JSON. Файл может быть объектом доски или полной задачей с ключом `board`.
static func load_from_json(path: String) -> MaskBoardData:
	var board := MaskBoardData.new()
	if not FileAccess.file_exists(path):
		board.parse_errors.append("file not found: " + path)
		return board
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null or not (parsed is Dictionary):
		board.parse_errors.append("board json must be an object: " + path)
		return board
	var data: Dictionary = parsed
	if data.has("board") and data["board"] is Dictionary:
		data = data["board"]
		if parsed.has("symmetry"):
			board.symmetry_group = SymmetryGroup.name_of(parsed["symmetry"])
	return from_dictionary(data, board.symmetry_group)


## Собирает доску из словаря формата задачи.
static func from_dictionary(data: Dictionary, symmetry: String = "") -> MaskBoardData:
	var board := MaskBoardData.new()
	if symmetry != "":
		board.symmetry_group = symmetry
	elif data.has("symmetry"):
		board.symmetry_group = SymmetryGroup.name_of(data["symmetry"])

	board.width = int(data.get("width", 0))
	board.height = int(data.get("height", 0))
	if board.width <= 0 or board.height <= 0:
		board.parse_errors.append("board width and height must be positive")

	var board_type := str(data.get("type", ""))
	if board_type == "":
		board.parse_errors.append("board.type is required")
		board.build()
		return board

	if board_type == "mask":
		board._read_mask(data)
	elif board_type == "rect_with_holes":
		board._read_holes(data.get("holes", []))
	else:
		board.parse_errors.append("unsupported board.type: " + board_type)

	board.build()
	return board


func build() -> void:
	_holes.clear()
	_column.clear()
	_free.clear()
	var seen_holes: Dictionary = {}
	for hole in holes:
		if hole.x < 0 or hole.y < 0 or hole.x >= width or hole.y >= height:
			parse_errors.append("hole out of range: (%d, %d)" % [hole.x, hole.y])
			continue
		if seen_holes.has(hole):
			parse_errors.append("duplicate hole: (%d, %d)" % [hole.x, hole.y])
			continue
		seen_holes[hole] = true
		_holes[hole] = true

	var column := 0
	for y in height:
		for x in width:
			var coord := Vector2i(x, y)
			if _holes.has(coord):
				continue
			_column[coord] = column
			_free.append(coord)
			column += 1
	_ready = true


## Клетка внутри доски и не вырезана.
func is_free(x: int, y: int) -> bool:
	if not _ready:
		build()
	if x < 0 or y < 0 or x >= width or y >= height:
		return false
	return not _holes.has(Vector2i(x, y))


## Свободные клетки по рядам, слева направо.
func free_cells() -> Array[Vector2i]:
	if not _ready:
		build()
	return _free


## Колонка DLX свободной клетки или -1, если клетка вырезана либо вне доски.
func cell_index(x: int, y: int) -> int:
	if not _ready:
		build()
	var coord := Vector2i(x, y)
	if not _column.has(coord):
		return -1
	return int(_column[coord])


## Линейный индекс полной сетки, включая вырезы.
func file_index(x: int, y: int) -> int:
	return width * y + x


func can_place(orientation: OrientationData, anchor: Vector2i) -> bool:
	for local in orientation.coords:
		var world: Vector2i = anchor + local
		if not is_free(world.x, world.y):
			return false
	return true


func _read_holes(raw: Variant) -> void:
	if raw == null:
		return
	if not (raw is Array):
		parse_errors.append("board.holes must be an array")
		return
	for pair in raw:
		var hole := _as_cell(pair)
		if hole.x < 0 and hole == Vector2i(-1, -1):
			parse_errors.append("hole must be [x, y]")
			continue
		holes.append(hole)


func _read_mask(data: Dictionary) -> void:
	var raw: Variant = data.get("mask", data.get("rows", null))
	if raw == null or not (raw is Array):
		parse_errors.append("mask board requires mask rows")
		return
	var rows: Array = raw
	if rows.size() != height:
		parse_errors.append("mask height %d != board height %d" % [rows.size(), height])
	for y in rows.size():
		var row: Variant = rows[y]
		if row is String:
			var line := str(row)
			if line.length() != width:
				parse_errors.append("mask row %d width %d != %d" % [y, line.length(), width])
			for x in line.length():
				_mark_mask_char(x, y, line[x])
		elif row is Array:
			var cells: Array = row
			if cells.size() != width:
				parse_errors.append("mask row %d width %d != %d" % [y, cells.size(), width])
			for x in cells.size():
				_mark_mask_value(x, y, cells[x])
		else:
			parse_errors.append("mask row %d must be a string or array" % y)


func _mark_mask_char(x: int, y: int, ch: String) -> void:
	if ch == "#" or ch == "1":
		return
	if ch == "." or ch == "0":
		if x >= 0 and y >= 0 and x < width and y < height:
			holes.append(Vector2i(x, y))
		return
	parse_errors.append("mask char '%s' at (%d, %d) is not # . 1 or 0" % [ch, x, y])


func _mark_mask_value(x: int, y: int, value: Variant) -> void:
	var cell := int(value)
	if cell == 1:
		return
	if cell == 0:
		if x >= 0 and y >= 0 and x < width and y < height:
			holes.append(Vector2i(x, y))
		return
	parse_errors.append("mask value %s at (%d, %d) is not 0 or 1" % [str(value), x, y])


func _as_cell(pair: Variant) -> Vector2i:
	if pair is Array and pair.size() >= 2:
		return Vector2i(int(pair[0]), int(pair[1]))
	return Vector2i(-1, -1)
