class_name Ingot
extends TileMapLayer

## Тайлы фигуры в мировых клетках get_world_cells(). Узел остаётся в (0, 0).
## Цвет — modulate всего слоя. Выбранный слиток осветляется.

var data: IngotData:
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
	if data == null:
		modulate = Color.WHITE
		return
	var color := Digest.color_of_shape(data.shape)
	if _is_selected():
		color = color.lightened(0.45)
	modulate = color


func _same_cells(cells_: Array[Vector2i]) -> bool:
	var used := get_used_cells()
	if used.size() != cells_.size():
		return false
	for cell in cells_:
		if not used.has(cell):
			return false
	return true


func _is_selected() -> bool:
	var node := get_parent()
	while node != null:
		if node is Mold:
			var mold := node as Mold
			return mold.data != null and mold.data.selected_ingot == data
		node = node.get_parent()
	return false
