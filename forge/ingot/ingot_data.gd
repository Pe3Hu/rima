class_name IngotData
extends RefCounted

## Слиток на Mold: форма, толщины и положение. После init не меняется.

var shape: Bozo.Shape = Bozo.Shape.NONE
var thicknesses: Array[int] = []
var origin: Vector2i = Vector2i.ZERO
var rotation_steps: int = 0
var is_flipped: bool = false
var variant_index: int = 0

var _is_built: bool = false


func init_with_shape(shape_: Bozo.Shape) -> void:
	if _is_built:
		return
	shape = shape_
	var empty: Array[int] = []
	empty.resize(get_cell_count())
	thicknesses = empty
	_is_built = true


func init_with_thicknesses(shape_: Bozo.Shape, thicknesses_: Array[int], origin_: Vector2i = Vector2i.ZERO, rotation_steps_: int = 0, is_flipped_: bool = false, variant_index_: int = 0) -> void:
	if _is_built:
		return
	shape = shape_
	var copy: Array[int] = []
	copy.assign(thicknesses_)
	thicknesses = copy
	origin = origin_
	rotation_steps = rotation_steps_
	is_flipped = is_flipped_
	variant_index = variant_index_
	_is_built = true


func get_cell_count() -> int:
	if not Digest.shape_to_cells.has(shape):
		return 0
	return Digest.shape_to_cells[shape].size()


func get_thickness(cell_index_: int) -> int:
	if cell_index_ < 0 or cell_index_ >= thicknesses.size():
		return 0
	return thicknesses[cell_index_]


func get_world_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if not Digest.shape_to_cells.has(shape):
		return result
	var steps := posmod(rotation_steps, 4)
	var locals: Array = Digest.shape_to_cells[shape]
	for local in locals:
		var coord := local as Vector2i
		coord = Helper.apply_flip(coord, is_flipped)
		coord = Helper.apply_twist(coord, steps)
		result.append(origin + coord)
	return result


func get_thickness_at(world_cell_: Vector2i) -> int:
	var cells := get_world_cells()
	for index in cells.size():
		if cells[index] == world_cell_:
			return get_thickness(index)
	return -1


func is_valid() -> bool:
	if not Digest.shape_to_cells.has(shape):
		return false
	if rotation_steps < 0 or rotation_steps > 3:
		return false
	if thicknesses.size() != get_cell_count():
		return false
	for thickness in thicknesses:
		if thickness < 0:
			return false
	return true
