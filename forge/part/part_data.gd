class_name PartData
extends RefCounted

## Клетки одного Part на шаблоне. После init не меняется.

var part: Bozo.Part = Bozo.Part.NONE
var cells: Array[Vector2i] = []

var _is_built: bool = false


func init_cells(part_: Bozo.Part, cells_: Array[Vector2i]) -> void:
	if _is_built:
		return
	part = part_
	var copy: Array[Vector2i] = []
	copy.assign(cells_)
	cells = copy
	_is_built = true


func get_world_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(cells)
	return result
