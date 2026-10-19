class_name SymmetryGroup
extends RefCounted

## Группа симметрий доски. Имя берётся из описания задачи, не из кода канонизатора.
##
## Строковые группы: `identity`, `rotate90` (циклическая четвёрка), `rotate180`,
## `rotate270` (та же четвёрка), `flipH`, `flipV`, `rect4`, `square8`.
## Массив в JSON — это `custom`: явный список операций.
## Операции: identity, rotate90, rotate180, rotate270, flipH, flipV, transpose, anti_transpose.
## Ось Y направлена вниз, поворот rotate90 идёт по часовой стрелке.

var name: String = "identity"
var ops: Array[String] = ["identity"]
var error: String = ""


static func name_of(value: Variant) -> String:
	if value is Array:
		return "custom"
	return str(value)


static func from_spec(value: Variant) -> SymmetryGroup:
	var group := SymmetryGroup.new()
	if value == null:
		group.name = "identity"
		group.ops = ["identity"]
		return group
	if value is Array:
		group.name = "custom"
		for item in value:
			var op := str(item)
			if not is_operation(op):
				group.error = "unknown symmetry op: " + op
				return group
			if not group.ops.has(op):
				group.ops.append(op)
		if group.ops.is_empty():
			group.error = "custom symmetry is empty"
			return group
		if not group.ops.has("identity"):
			group.ops.push_front("identity")
		return group

	group.name = str(value)
	match group.name:
		"identity":
			group.ops = ["identity"]
		"rotate180":
			group.ops = ["identity", "rotate180"]
		"rotate90", "rotate270":
			group.ops = ["identity", "rotate90", "rotate180", "rotate270"]
		"flipH":
			group.ops = ["identity", "flipH"]
		"flipV":
			group.ops = ["identity", "flipV"]
		"rect4":
			group.ops = ["identity", "rotate180", "flipH", "flipV"]
		"square8":
			group.ops = [
				"identity", "rotate90", "rotate180", "rotate270",
				"flipH", "flipV", "transpose", "anti_transpose",
			]
		_:
			group.error = "unknown symmetry group: " + group.name
	return group


static func is_operation(op: String) -> bool:
	match op:
		"identity", "rotate90", "rotate180", "rotate270", "flipH", "flipV", "transpose", "anti_transpose":
			return true
		_:
			return false


## Образ клетки. Для поворота на 90° размеры меняются местами, поэтому
## на неквадратной доске такая операция не сохраняет маску.
static func map_cell(x: int, y: int, width: int, height: int, op: String) -> Vector2i:
	match op:
		"identity":
			return Vector2i(x, y)
		"rotate90":
			return Vector2i(height - 1 - y, x)
		"rotate180":
			return Vector2i(width - 1 - x, height - 1 - y)
		"rotate270":
			return Vector2i(y, width - 1 - x)
		"flipH":
			return Vector2i(width - 1 - x, y)
		"flipV":
			return Vector2i(x, height - 1 - y)
		"transpose":
			return Vector2i(y, x)
		"anti_transpose":
			return Vector2i(height - 1 - y, width - 1 - x)
		_:
			return Vector2i(x, y)


## Пустая строка, если каждая операция переставляет свободные клетки между собой.
func preservation_error(board: MaskBoardData) -> String:
	if error != "":
		return error
	var free := board.free_cells()
	for op in ops:
		var seen: Dictionary = {}
		for cell in free:
			var mapped := map_cell(cell.x, cell.y, board.width, board.height, op)
			if not board.is_free(mapped.x, mapped.y):
				return "symmetry %s/%s moves free cell (%d, %d) off the mask" % [name, op, cell.x, cell.y]
			var key := "%d,%d" % [mapped.x, mapped.y]
			if seen.has(key):
				return "symmetry %s/%s is not bijective" % [name, op]
			seen[key] = true
	return ""
