class_name MoldData
extends RefCounted

## Замощение: до 12 слитков на шаблоне. Правая Mold — обычные слитки, не virtual.

signal changed
signal strata_changed
signal highlight_changed

var template: MoldTemplateData
var ingots: Array = []
var coords: Array[Vector2i] = []
var strata: Array = []
var highlighted_pieces: Array = []
var selected_ingot: IngotData
var is_silent: bool = false

var _coord_to_piece: Dictionary = {}


func init_with_template(template_: MoldTemplateData) -> void:
	template = template_
	ingots = []
	selected_ingot = null
	_cache_coords()
	_notify()


func init_with_ingots(template_: MoldTemplateData, ingots_: Array) -> void:
	template = template_
	ingots = []
	for item in ingots_:
		ingots.append(item)
	selected_ingot = null
	_cache_coords()
	_notify()


func get_thickness_at(cell_: Vector2i) -> int:
	var total := 0
	var found := false
	for item in ingots:
		var ingot := item as IngotData
		if ingot == null:
			continue
		var thickness := ingot.get_thickness_at(cell_)
		if thickness < 0:
			continue
		total += thickness
		found = true
	if not found:
		return 0
	return total


func get_thickness_map() -> Dictionary:
	var map: Dictionary[Vector2i, int] = {}
	for cell in coords:
		var thickness := get_thickness_at(cell)
		if thickness > 0:
			map[cell] = thickness
	return map


func fill_cell_maps(ingot_map_: Dictionary, thickness_map_: Dictionary) -> void:
	ingot_map_.clear()
	thickness_map_.clear()
	for item in ingots:
		var ingot := item as IngotData
		if ingot == null:
			continue
		var cells := ingot.get_world_cells()
		for index in cells.size():
			var cell: Vector2i = cells[index]
			ingot_map_[cell] = ingot
			thickness_map_[cell] = ingot.get_thickness(index)


func get_ingot_at(cell_: Vector2i) -> IngotData:
	if template == null or not template.is_cell_inside(cell_):
		return null
	for item in ingots:
		var ingot := item as IngotData
		if ingot == null:
			continue
		if ingot.get_world_cells().has(cell_):
			return ingot
	return null


func apply_highlight(pieces_: Array) -> void:
	var copy: Array = []
	copy.assign(pieces_)
	highlighted_pieces = copy
	highlight_changed.emit()


func apply_piece_datas(pieces_: Array) -> void:
	_coord_to_piece.clear()
	for item in pieces_:
		var piece := item as PieceData
		if piece == null:
			continue
		_coord_to_piece[piece.coord] = piece


func recalc_strata() -> void:
	strata.clear()
	if template == null:
		strata_changed.emit()
		return
	for config in template.get_strata_config():
		var entry: Dictionary = config
		var subtype: Bozo.Stratum = entry.get("subtype", Bozo.Stratum.NONE)
		var direction: Bozo.Direction = entry.get("direction", Bozo.Direction.NONE)
		_append_direction(subtype, direction)
	strata_changed.emit()


func add_ingot(ingot_data_: IngotData) -> void:
	ingots.append(ingot_data_)
	_notify()


func update_ingot(ingot_data_: IngotData) -> void:
	if ingot_data_ == null or selected_ingot == null:
		return
	for index in ingots.size():
		if ingots[index] != selected_ingot:
			continue
		ingots[index] = ingot_data_
		selected_ingot = ingot_data_
		_notify()
		return


func apply_selection(ingot_data_: IngotData) -> void:
	selected_ingot = ingot_data_
	_notify()


func clear_ingots() -> void:
	ingots.clear()
	selected_ingot = null
	_notify()


func is_cell_free(cell_: Vector2i) -> bool:
	if template == null or not template.is_cell_inside(cell_):
		return false
	return get_ingot_at(cell_) == null


func _notify() -> void:
	if is_silent:
		return
	changed.emit()


func _append_direction(subtype_: Bozo.Stratum, direction_: Bozo.Direction) -> void:
	var horizontal := direction_ == Bozo.Direction.RIGHT or direction_ == Bozo.Direction.LEFT
	var limit := template.height
	if not horizontal:
		limit = template.width
	for index in limit:
		if not _line_has_ingot(direction_, index):
			continue
		var pieces := _collect_line(direction_, index)
		if not _is_valid_stratum(pieces):
			continue
		var stratum := StratumData.new()
		stratum.init_line(subtype_, direction_, pieces)
		strata.append(stratum)


func _line_has_ingot(direction_: Bozo.Direction, index_: int) -> bool:
	var horizontal := direction_ == Bozo.Direction.RIGHT or direction_ == Bozo.Direction.LEFT
	if horizontal:
		for x in template.width:
			if get_ingot_at(Vector2i(x, index_)) != null:
				return true
		return false
	for y in template.height:
		if get_ingot_at(Vector2i(index_, y)) != null:
			return true
	return false


func _collect_line(direction_: Bozo.Direction, index_: int) -> Array:
	var pieces: Array = []
	var cell := Vector2i.ZERO
	var step := Vector2i.ZERO
	match direction_:
		Bozo.Direction.RIGHT:
			cell = Vector2i(template.width - 1, index_)
			step = Vector2i(-1, 0)
		Bozo.Direction.LEFT:
			cell = Vector2i(0, index_)
			step = Vector2i(1, 0)
		Bozo.Direction.TOP:
			cell = Vector2i(index_, 0)
			step = Vector2i(0, 1)
		Bozo.Direction.BOTTOM:
			cell = Vector2i(index_, template.height - 1)
			step = Vector2i(0, -1)
		_:
			return pieces
	while _is_on_board(cell):
		if get_ingot_at(cell) == null:
			break
		if not _coord_to_piece.has(cell):
			break
		var piece := _coord_to_piece[cell] as PieceData
		if piece == null or piece.part == Bozo.Part.NONE:
			break
		if piece.part == Bozo.Part.BEVEL and _pieces_have_bevel(pieces):
			break
		if piece.part != Bozo.Part.BEVEL and piece.part != Bozo.Part.SPINE:
			break
		pieces.append(piece)
		cell += step
	return pieces


func _pieces_have_bevel(pieces_: Array) -> bool:
	for item in pieces_:
		var piece := item as PieceData
		if piece != null and piece.part == Bozo.Part.BEVEL:
			return true
	return false


func _is_valid_stratum(pieces_: Array) -> bool:
	if pieces_.size() < 2:
		return false
	var first := pieces_[0] as PieceData
	var last := pieces_[pieces_.size() - 1] as PieceData
	if first == null or last == null:
		return false
	return first.part == Bozo.Part.BEVEL and last.part == Bozo.Part.SPINE


func _is_on_board(cell_: Vector2i) -> bool:
	return cell_.x >= 0 and cell_.y >= 0 and cell_.x < template.width and cell_.y < template.height


func _cache_coords() -> void:
	coords.clear()
	if template == null:
		return
	for cell in template.cells:
		coords.append(cell)
	coords.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if a.y == b.y:
			return a.x < b.x
		return a.y < b.y
	)
