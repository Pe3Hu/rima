class_name MoldData
extends RefCounted

## Замощение: до 12 слитков на шаблоне. Правая Mold — обычные слитки, не virtual.

signal changed

var template: MoldTemplateData
var ingots: Array = []
var coords: Array[Vector2i] = []
var selected_ingot: IngotData
var is_silent: bool = false


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
