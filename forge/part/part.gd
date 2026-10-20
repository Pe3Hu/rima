class_name Part
extends TileMapLayer

## Тайлы Part в клетках шаблона. Узел остаётся в (0, 0).
## Цвет — modulate всего слоя, из Digest.part_to_color.

var data: PartData:
	set(value_):
		data = value_
		connect_datas()
		connect_signals()
		apply_cells()


func connect_datas() -> void:
	pass


func connect_signals() -> void:
	pass


func apply_cells() -> void:
	if data == null:
		clear()
		modulate = Color.WHITE
		return
	var cells := data.get_world_cells()
	if _same_cells(cells):
		apply_color()
		return
	clear()
	if not cells.is_empty():
		set_cells_terrain_connect(cells, 0, 0, true)
	apply_color()


func apply_color() -> void:
	if data == null or not Digest.part_to_color.has(data.part):
		modulate = Color.WHITE
		return
	modulate = Digest.part_to_color[data.part]


func _same_cells(cells_: Array[Vector2i]) -> bool:
	var used := get_used_cells()
	if used.size() != cells_.size():
		return false
	for cell in cells_:
		if not used.has(cell):
			return false
	return true
