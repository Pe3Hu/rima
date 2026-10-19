class_name WarehouseData
extends RefCounted

## Склад слитков: по Catalog.COPIES_PER_SHAPE на каждую форму.
## Толщины только Catalog.THICKNESS_MIN..THICKNESS_MAX. Ноль сюда не попадает.

var shape_to_variants: Dictionary[Bozo.Shape, Array] = {}


#region init
func _init(forge_: ForgeData) -> void:
	forge_.warehouse = self
	init_variants()
#endregion


func init_variants() -> void:
	for shape in Catalog.pentomino_shapes:
		var variants: Array[IngotData] = []
		for _copy in Catalog.COPIES_PER_SHAPE:
			variants.append(_init_ingot(shape))
		shape_to_variants[shape] = variants


func get_variants(shape_: Bozo.Shape) -> Array[IngotData]:
	if not shape_to_variants.has(shape_):
		var empty: Array[IngotData] = []
		return empty
	var variants: Array[IngotData] = []
	variants.assign(shape_to_variants[shape_])
	return variants


func get_variant_count(shape_: Bozo.Shape) -> int:
	return get_variants(shape_).size()


func get_variant(shape_: Bozo.Shape, index_: int) -> IngotData:
	var variants := get_variants(shape_)
	if variants.is_empty():
		return null
	return variants[posmod(index_, variants.size())]


func has_variant(shape_: Bozo.Shape, thicknesses_: Array) -> bool:
	if not shape_to_variants.has(shape_):
		return false
	for item in shape_to_variants[shape_]:
		var stored := item as IngotData
		if stored != null and _same_thickness_values(stored.thicknesses, thicknesses_):
			return true
	return false


func apply_removal(ingot_data_: IngotData) -> bool:
	if ingot_data_ == null or not shape_to_variants.has(ingot_data_.shape):
		return false
	var variants: Array = shape_to_variants[ingot_data_.shape]
	for index in variants.size():
		var stored := variants[index] as IngotData
		if stored == null or not _same_thicknesses(stored, ingot_data_):
			continue
		variants.remove_at(index)
		return true
	return false


func get_total_count() -> int:
	var total := 0
	for shape in Catalog.pentomino_shapes:
		total += get_variant_count(shape)
	return total


func _init_ingot(shape_: Bozo.Shape) -> IngotData:
	var thicknesses: Array[int] = []
	var count: int = Digest.shape_to_cells[shape_].size()
	for _cell in count:
		thicknesses.append(Helper.rng.randi_range(Catalog.THICKNESS_MIN, Catalog.THICKNESS_MAX))
	var ingot := IngotData.new()
	ingot.init_with_thicknesses(shape_, thicknesses)
	return ingot


func _same_thicknesses(left_: IngotData, right_: IngotData) -> bool:
	if left_.shape != right_.shape:
		return false
	return _same_thickness_values(left_.thicknesses, right_.thicknesses)


func _same_thickness_values(left_: Array, right_: Array) -> bool:
	if left_.size() != right_.size():
		return false
	for index in left_.size():
		if int(left_[index]) != int(right_[index]):
			return false
	return true
