class_name ForgeData
extends RefCounted

## Состояние кузницы. Сцену не знает.

signal center_changed
signal right_changed
signal selection_changed
signal fusion_applied
signal display_layer_changed
signal weapon_switched

var warehouse: WarehouseData
var left: MoldData
var center: MoldData
var right: MoldData
var selected_ingot: IngotData
var display_layer: Bozo.Layer = Bozo.Layer.INGOT
var weapon_name_to_solutions: Dictionary[String, Array] = {}
var is_batching: bool = false


func init_with_weapon(weapon_: WeaponData) -> void:
	if weapon_ == null or weapon_.mold == null or weapon_.mold.template == null:
		return
	_disconnect_molds()
	var template := weapon_.mold.template
	left = MoldData.new()
	center = MoldData.new()
	right = MoldData.new()
	left.init_with_ingots(template, _clone_ingots(weapon_.mold.ingots, false))
	center.init_with_template(template)
	right.init_with_template(template)
	selected_ingot = null
	left.changed.connect(recalc_right)
	center.changed.connect(recalc_right)
	refill_center()
	recalc_right()
	center_changed.emit()


func apply_weapon_switch(delta_: int) -> void:
	if warehouse == null:
		return
	var count := warehouse.get_weapons().size()
	if count == 0:
		return
	var new_index := posmod(warehouse.current_weapon_index + delta_, count)
	warehouse.apply_current_weapon_index(new_index)
	init_with_weapon(warehouse.get_current_weapon())
	apply_selection(null)
	if left != null:
		left.apply_highlight([])
	weapon_switched.emit()


func recalc_right() -> void:
	if left == null or left.template == null or right == null:
		return
	var center_thickness := {}
	if center != null:
		var unused := {}
		center.fill_cell_maps(unused, center_thickness)
	var ingots: Array = []
	var reused := true
	var index := 0
	for item in left.ingots:
		var source := item as IngotData
		if source == null:
			continue
		var thicknesses: Array[int] = []
		var cells := source.get_world_cells()
		for cell_index in cells.size():
			var extra := int(center_thickness.get(cells[cell_index], 0))
			var base := 0
			if cell_index < source.thicknesses.size():
				base = source.thicknesses[cell_index]
			thicknesses.append(base + extra)
		var existing: IngotData = null
		if index < right.ingots.size():
			existing = right.ingots[index] as IngotData
		if existing != null and _same_geometry(existing, source) and _same_thickness_values(existing.thicknesses, thicknesses):
			ingots.append(existing)
		else:
			reused = false
			var copy := IngotData.new()
			copy.init_with_thicknesses(source.shape, thicknesses, source.origin, source.rotation_steps, source.is_flipped, -1)
			ingots.append(copy)
		index += 1
	if reused:
		return
	right.init_with_ingots(left.template, ingots)
	if not is_batching:
		right_changed.emit()


func get_current_weapon_name() -> String:
	var weapon := Mother.get_current_weapon()
	if weapon == null:
		return ""
	return weapon.name


func apply_display_layer(layer_: Bozo.Layer) -> void:
	if display_layer == layer_:
		return
	display_layer = layer_
	display_layer_changed.emit()


func apply_stratum_highlight(stratum_: StratumData) -> void:
	if left == null:
		return
	if stratum_ == null or _is_same_highlight(stratum_.pieces):
		left.apply_highlight([])
		return
	left.apply_highlight(stratum_.pieces)


func _is_same_highlight(pieces_: Array) -> bool:
	var current: Array = left.highlighted_pieces
	if current.size() != pieces_.size() or current.is_empty():
		return false
	for index in current.size():
		if current[index] != pieces_[index]:
			return false
	return true


func apply_selection(ingot_data_: IngotData) -> void:
	selected_ingot = ingot_data_
	if center != null:
		center.apply_selection(ingot_data_)
	selection_changed.emit()


func apply_fusion() -> bool:
	if not is_fusion_available():
		return false
	var weapon := Mother.get_current_weapon()
	if weapon == null or right == null or right.template == null:
		return false
	is_batching = true
	_set_silent(left, true)
	_set_silent(center, true)
	_set_silent(right, true)
	weapon.apply_mold(_copy_mold(right))
	for item in center.ingots:
		var ingot := item as IngotData
		if ingot == null:
			continue
		if not warehouse.apply_removal(ingot):
			push_warning("fusion did not find a warehouse ingot for shape %s" % Bozo.enum_to_string(Bozo.Type.SHAPE, ingot.shape))
	_replace_left(_copy_mold(right))
	_set_silent(left, true)
	selected_ingot = null
	center.apply_selection(null)
	var previous_center := center
	refill_center()
	var stock_ran_out := center == previous_center
	if stock_ran_out:
		_replace_center(left.template, [])
	recalc_right()
	is_batching = false
	_set_silent(left, false)
	_set_silent(center, false)
	_set_silent(right, false)
	fusion_applied.emit()
	if stock_ran_out:
		push_warning("warehouse cannot fill the center, fusion unavailable")
	return true


func is_fusion_available() -> bool:
	if center == null or warehouse == null or center.ingots.size() != 12:
		return false
	for item in center.ingots:
		var ingot := item as IngotData
		if ingot == null or not warehouse.has_variant(ingot.shape, ingot.thicknesses):
			return false
	return true


func refill_center() -> void:
	if left == null or left.template == null:
		return
	var weapon := Mother.get_current_weapon()
	if weapon == null or weapon.name == "":
		push_warning("refill_center: no current weapon, fusion unavailable")
		return
	if not _warehouse_has_every_shape():
		return
	var solutions := _get_solutions(weapon)
	if solutions.is_empty():
		push_warning("weapon %s has no solutions, fusion unavailable" % weapon.name)
		return
	var pool := _solutions_except_left(solutions)
	if pool.is_empty():
		pool = solutions
	var picked: Array = pool[Helper.rng.randi_range(0, pool.size() - 1)]
	var ingots := _ingots_from_solution(picked)
	if ingots.is_empty():
		return
	_replace_center(left.template, ingots)


func apply_variant_change(delta_: int) -> void:
	if delta_ == 0 or selected_ingot == null or center == null or warehouse == null:
		return
	var shape := selected_ingot.shape
	var count := warehouse.get_variant_count(shape)
	if count == 0:
		return
	var new_index := posmod(selected_ingot.variant_index + delta_, count)
	var source := warehouse.get_variant(shape, new_index)
	if source == null:
		return
	var replacement := IngotData.new()
	replacement.init_with_thicknesses(shape, source.thicknesses, selected_ingot.origin, selected_ingot.rotation_steps, selected_ingot.is_flipped, new_index)
	center.update_ingot(replacement)
	selected_ingot = replacement
	selection_changed.emit()


func _warehouse_has_every_shape() -> bool:
	for shape in Catalog.pentomino_shapes:
		if warehouse.get_variant_count(shape) <= 0:
			return false
	return true


func _set_silent(mold_: MoldData, is_silent_: bool) -> void:
	if mold_ == null:
		return
	mold_.is_silent = is_silent_


func _same_geometry(left_: IngotData, right_: IngotData) -> bool:
	return left_.shape == right_.shape and left_.origin == right_.origin and left_.rotation_steps == right_.rotation_steps and left_.is_flipped == right_.is_flipped


func _same_thickness_values(left_: Array, right_: Array) -> bool:
	if left_.size() != right_.size():
		return false
	for index in left_.size():
		if int(left_[index]) != int(right_[index]):
			return false
	return true


func _copy_mold(source_: MoldData) -> MoldData:
	var mold := MoldData.new()
	if source_ == null or source_.template == null:
		return mold
	mold.init_with_ingots(source_.template, _clone_ingots(source_.ingots, false))
	return mold


func _replace_left(mold_: MoldData) -> void:
	if left != null and left.changed.is_connected(recalc_right):
		left.changed.disconnect(recalc_right)
	left = mold_
	if left != null:
		left.changed.connect(recalc_right)


func _clone_ingots(source_: Array, is_result_: bool) -> Array:
	var copies: Array = []
	for item in source_:
		var source := item as IngotData
		if source == null:
			continue
		var copy := IngotData.new()
		var variant := -1 if is_result_ else source.variant_index
		copy.init_with_thicknesses(source.shape, source.thicknesses, source.origin, source.rotation_steps, source.is_flipped, variant)
		copies.append(copy)
	return copies


func _disconnect_molds() -> void:
	if left != null and left.changed.is_connected(recalc_right):
		left.changed.disconnect(recalc_right)
	if center != null and center.changed.is_connected(recalc_right):
		center.changed.disconnect(recalc_right)


func _get_solutions(weapon_: WeaponData) -> Array:
	if weapon_name_to_solutions.has(weapon_.name):
		return weapon_name_to_solutions[weapon_.name]
	var solutions := _load_solutions(weapon_)
	weapon_name_to_solutions[weapon_.name] = solutions
	return solutions


func _load_solutions(weapon_: WeaponData) -> Array:
	var solutions: Array = []
	if weapon_.mold == null or weapon_.mold.template == null:
		return solutions
	var out_path := Catalog.OUT_PATH.path_join(weapon_.name + ".json")
	if not FileAccess.file_exists(out_path):
		return solutions
	var task := TaskData.load_from_json(weapon_.mold.template.source_path)
	if task.board == null or task.pieces == null:
		return solutions
	var loader := CompositionLoader.new()
	var compositions := loader.load_compositions(out_path, task.board, task.pieces)
	for composition in compositions:
		var placements: Array = []
		for allocation in composition.allocations:
			if allocation.orientation == null or allocation.orientation.shape == null:
				continue
			var shape := Bozo.string_to_enum(Bozo.Type.SHAPE, allocation.orientation.shape.id)
			if not Digest.shape_to_cells.has(shape):
				placements.clear()
				break
			var is_flipped := allocation.orientation.is_flipped
			var steps := allocation.orientation.twist
			var origin := _origin_for(shape, is_flipped, steps, allocation.anchor)
			placements.append({
				"shape": shape,
				"origin": origin,
				"rotation_steps": steps,
				"is_flipped": is_flipped,
			})
		if placements.size() == 12:
			solutions.append(placements)
	return solutions


func _solutions_except_left(solutions_: Array) -> Array:
	var left_key := _key_from_ingots(left.ingots)
	var pool: Array = []
	for item in solutions_:
		var placements: Array = item
		if _key_from_placements(placements) == left_key:
			continue
		pool.append(placements)
	return pool


func _ingots_from_solution(placements_: Array) -> Array:
	var ingots: Array = []
	for item in placements_:
		var placement: Dictionary = item
		var shape: Bozo.Shape = placement["shape"]
		var count := warehouse.get_variant_count(shape)
		if count <= 0:
			push_warning("warehouse has no variants for shape %s" % Bozo.enum_to_string(Bozo.Type.SHAPE, shape))
			return []
		var variant_index := Helper.rng.randi_range(0, count - 1)
		var source := warehouse.get_variant(shape, variant_index)
		if source == null:
			return []
		var ingot := IngotData.new()
		ingot.init_with_thicknesses(shape, source.thicknesses, placement["origin"], int(placement["rotation_steps"]), bool(placement["is_flipped"]), variant_index)
		ingots.append(ingot)
	return ingots


func _replace_center(template_: MoldTemplateData, ingots_: Array) -> void:
	if center != null and center.changed.is_connected(recalc_right):
		center.changed.disconnect(recalc_right)
	center = MoldData.new()
	center.is_silent = is_batching
	center.changed.connect(recalc_right)
	if selected_ingot != null:
		selected_ingot = null
		if not is_batching:
			selection_changed.emit()
	center.init_with_ingots(template_, ingots_)
	if not is_batching:
		center_changed.emit()


func _key_from_ingots(ingots_: Array) -> String:
	var parts: Array[String] = []
	for item in ingots_:
		var ingot := item as IngotData
		if ingot == null:
			continue
		parts.append(_placement_token(ingot.shape, ingot.origin, ingot.rotation_steps, ingot.is_flipped))
	parts.sort()
	return "\n".join(parts)


func _key_from_placements(placements_: Array) -> String:
	var parts: Array[String] = []
	for item in placements_:
		var placement: Dictionary = item
		parts.append(_placement_token(int(placement["shape"]), placement["origin"], int(placement["rotation_steps"]), bool(placement["is_flipped"])))
	parts.sort()
	return "\n".join(parts)


func _placement_token(shape_: int, origin_: Vector2i, steps_: int, is_flipped_: bool) -> String:
	var flipped := 0
	if is_flipped_:
		flipped = 1
	return "%d|%d|%d|%d|%d" % [shape_, origin_.x, origin_.y, steps_, flipped]


func _origin_for(shape_: int, is_flipped_: bool, steps_: int, anchor_: Vector2i) -> Vector2i:
	var min_coord := Vector2i(999, 999)
	var locals: Array = Digest.shape_to_cells[shape_]
	for local in locals:
		var coord := local as Vector2i
		coord = Helper.apply_flip(coord, is_flipped_)
		coord = Helper.apply_twist(coord, steps_)
		min_coord.x = mini(min_coord.x, coord.x)
		min_coord.y = mini(min_coord.y, coord.y)
	return anchor_ - min_coord
