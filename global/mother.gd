extends Node

## Корень состояния. Оружия и кузница.

var weapons: Array = []
var current_weapon_index: int = 0
var forge: ForgeData


#region init
func _ready() -> void:
	_load_weapons()
	current_weapon_index = 0
	forge = ForgeData.new()
	forge.init_with_weapon(get_current_weapon())
#endregion


func get_current_weapon() -> WeaponData:
	if weapons.is_empty():
		return null
	return weapons[current_weapon_index]


func apply_current_weapon_index(index_: int) -> void:
	if weapons.is_empty():
		return
	current_weapon_index = posmod(index_, weapons.size())


func _load_weapons() -> void:
	weapons.clear()
	var directory := DirAccess.open(Catalog.TASKS_PATH)
	if directory == null:
		push_error("tasks folder missing: " + Catalog.TASKS_PATH)
		return
	var names: Array[String] = []
	for file_name in directory.get_files():
		var text := str(file_name)
		if text.ends_with(".json"):
			names.append(text)
	names.sort()
	for file_name in names:
		var weapon := _weapon_from_file(Catalog.TASKS_PATH.path_join(file_name))
		if weapon == null or weapon.name == "":
			continue
		weapons.append(weapon)
	_put_chokuto_first()


func _weapon_from_file(path_: String) -> WeaponData:
	var template := MoldTemplateData.load_from_file(path_)
	var mold := _mold_from_output(template)
	var weapon := WeaponData.new()
	weapon.init_with_mold(template.weapon_name, mold)
	return weapon


func _mold_from_output(template_: MoldTemplateData) -> MoldData:
	var mold := MoldData.new()
	var out_path := Catalog.OUT_PATH.path_join(template_.weapon_name + ".json")
	var task := TaskData.load_from_json(template_.source_path)
	if task.board == null or task.pieces == null or not FileAccess.file_exists(out_path):
		push_warning("weapon %s has no starting mold at %s" % [template_.weapon_name, out_path])
		mold.init_with_template(template_)
		return mold
	var loader := CompositionLoader.new()
	var compositions := loader.load_compositions(out_path, task.board, task.pieces)
	if compositions.is_empty():
		push_warning("weapon %s has an empty solution file %s" % [template_.weapon_name, out_path])
		mold.init_with_template(template_)
		return mold
	mold.init_with_ingots(template_, _ingots_from_composition(compositions[0]))
	return mold


func _ingots_from_composition(composition_: CompositionData) -> Array:
	var ingots: Array = []
	for allocation in composition_.allocations:
		var shape_id := allocation.orientation.shape.id
		var shape := Bozo.string_to_enum(Bozo.Type.SHAPE, shape_id)
		var flipped := allocation.orientation.is_flipped
		var steps := allocation.orientation.twist
		var origin := _origin_for(shape, flipped, steps, allocation.anchor)
		var thicknesses: Array[int] = []
		var count: int = Digest.shape_to_cells[shape].size()
		thicknesses.resize(count)
		thicknesses.fill(1)
		var ingot := IngotData.new()
		ingot.init_with_thicknesses(shape, thicknesses, origin, steps, flipped, 0)
		ingots.append(ingot)
	return ingots


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


func _put_chokuto_first() -> void:
	var found := -1
	for index in weapons.size():
		var weapon := weapons[index] as WeaponData
		if weapon != null and weapon.name == "chokuto":
			found = index
			break
	if found <= 0:
		return
	var chokuto: WeaponData = weapons[found]
	weapons.remove_at(found)
	weapons.insert(0, chokuto)
