class_name PieceData
extends RefCounted

## Одна клетка слитка на Mold. Толщина меняется на месте, остальное — нет.

signal thickness_changed

var coord: Vector2i = Vector2i.ZERO
var thickness: int = 0:
	set(value_):
		if thickness == value_:
			return
		thickness = value_
		thickness_changed.emit()
var ingot_data: IngotData
var side: int = Bozo.PieceSide.NONE
var part: Bozo.Part = Bozo.Part.NONE

var _is_built: bool = false


func init_cell(coord_: Vector2i, thickness_: int, ingot_data_: IngotData, side_: int = Bozo.PieceSide.NONE, part_: Bozo.Part = Bozo.Part.NONE) -> void:
	if _is_built:
		return
	coord = coord_
	thickness = thickness_
	ingot_data = ingot_data_
	side = side_
	part = part_
	_is_built = true
