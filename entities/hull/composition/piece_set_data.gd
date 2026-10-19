class_name PieceSetData
extends RefCounted

## Набор фигур и его площадь. Колонка DLX фигуры — это индекс в `pieces`.

var source_id: String = ""
var set_name: String = ""
var pieces: Array[ShapeData] = []

var load_errors: Array[String] = []


func _init() -> void:
	pieces = []
	load_errors = []


static func load_spec(spec: Dictionary) -> PieceSetData:
	if spec.is_empty():
		var empty := PieceSetData.new()
		empty.load_errors.append("pieces section is missing")
		return empty
	var source := str(spec.get("source", ""))
	if source == "inline" or spec.has("items"):
		var inline := _from_items(spec)
		inline.source_id = "inline" if source == "" else source
		return _finish(inline, spec)
	if source == "":
		var missing := PieceSetData.new()
		missing.load_errors.append("pieces.source is required")
		return missing
	var path := source
	if not path.begins_with("res://") and not path.begins_with("user://"):
		path = "res://tasks/pieces/%s.json" % source
	var loaded := load_from_json(path)
	loaded.source_id = source
	return _finish(loaded, spec)


static func load_from_json(path: String) -> PieceSetData:
	var piece_set := PieceSetData.new()
	if not FileAccess.file_exists(path):
		piece_set.load_errors.append("piece set not found: " + path)
		return piece_set
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed == null or not (parsed is Dictionary):
		piece_set.load_errors.append("piece set json must be an object: " + path)
		return piece_set
	var data: Dictionary = parsed
	piece_set.source_id = str(data.get("id", ""))
	piece_set.set_name = str(data.get("name", ""))
	var entries: Variant = data.get("pieces", [])
	if not (entries is Array):
		piece_set.load_errors.append("piece set pieces must be an array")
		return piece_set
	for entry in entries:
		if entry is String:
			piece_set._append_resource(str(entry), "", -1, Vector3i.ZERO, true)
		elif entry is Dictionary:
			var item: Dictionary = entry
			if item.has("resource"):
				var keep_symmetry := not item.has("symmetry")
				piece_set._append_resource(
					str(item["resource"]),
					str(item.get("id", "")),
					int(item.get("type", -1)),
					_read_symmetry(item.get("symmetry", null)),
					keep_symmetry
				)
			else:
				piece_set.pieces.append(_shape_from_item(item, piece_set.load_errors))
		else:
			piece_set.load_errors.append("piece entry must be a path or an object")
	piece_set.assign_indexes()
	return piece_set


func expected_area() -> int:
	var area := 0
	for piece in pieces:
		area += piece.coords.size()
	return area


func get_by_id(piece_id: String) -> ShapeData:
	for piece in pieces:
		if piece.id == piece_id:
			return piece
	return null


func assign_indexes() -> void:
	var seen_ids: Dictionary = {}
	var seen_types: Dictionary = {}
	for i in pieces.size():
		var piece := pieces[i]
		piece.piece_index = i
		if piece.id == "":
			load_errors.append("piece at index %d has no id" % i)
		elif seen_ids.has(piece.id):
			load_errors.append("duplicate piece id: " + piece.id)
		else:
			seen_ids[piece.id] = true
		if piece.type == 0:
			piece.type = i + 1
		if seen_types.has(piece.type):
			load_errors.append("duplicate piece type %d" % piece.type)
		else:
			seen_types[piece.type] = true
		if piece.coords.is_empty():
			load_errors.append("piece '%s' has no cells" % piece.id)


func _append_resource(path: String, piece_id: String, numeric_type: int, symmetry: Vector3i, keep_symmetry: bool) -> void:
	if not ResourceLoader.exists(path):
		load_errors.append("shape resource not found: " + path)
		return
	var loaded: Resource = load(path)
	if loaded == null or not (loaded is ShapeData):
		load_errors.append("shape resource is not ShapeData: " + path)
		return
	var shape := (loaded as ShapeData).duplicate(true) as ShapeData
	if piece_id != "":
		shape.id = piece_id
	if numeric_type >= 0:
		shape.type = numeric_type
	if not keep_symmetry:
		shape.symmetry = symmetry
	pieces.append(shape)


static func _finish(piece_set: PieceSetData, spec: Dictionary) -> PieceSetData:
	if spec.has("include"):
		piece_set = piece_set.filtered(spec["include"])
	if spec.has("name") and str(spec["name"]) != "":
		piece_set.set_name = str(spec["name"])
	return piece_set


func filtered(ids: Variant) -> PieceSetData:
	var subset := PieceSetData.new()
	subset.source_id = source_id
	subset.set_name = set_name
	for message in load_errors:
		subset.load_errors.append(message)
	if not (ids is Array):
		subset.load_errors.append("pieces.include must be an array")
		return subset
	var wanted: Dictionary = {}
	for piece_id in ids:
		wanted[str(piece_id)] = true
	for piece in pieces:
		if wanted.has(piece.id):
			subset.pieces.append(piece.duplicate(true))
			wanted.erase(piece.id)
	if not wanted.is_empty():
		subset.load_errors.append("unknown piece ids: %s" % [wanted.keys()])
	subset.assign_indexes()
	return subset


static func _from_items(spec: Dictionary) -> PieceSetData:
	var piece_set := PieceSetData.new()
	piece_set.set_name = str(spec.get("name", ""))
	var items: Variant = spec.get("items", [])
	if not (items is Array):
		piece_set.load_errors.append("pieces.items must be an array")
		return piece_set
	for item in items:
		if item is Dictionary:
			piece_set.pieces.append(_shape_from_item(item, piece_set.load_errors))
		else:
			piece_set.load_errors.append("inline piece must be an object")
	piece_set.assign_indexes()
	return piece_set


static func _shape_from_item(item: Dictionary, errors: Array[String]) -> ShapeData:
	var shape := ShapeData.new()
	shape.id = str(item.get("id", ""))
	shape.type = int(item.get("type", 0))
	if item.has("symmetry"):
		shape.symmetry = _read_symmetry(item["symmetry"])
	var raw_cells: Variant = item.get("cells", item.get("coords", []))
	if raw_cells is Array:
		for pair in raw_cells:
			if pair is Array and pair.size() >= 2:
				shape.coords.append(Vector2i(int(pair[0]), int(pair[1])))
			else:
				errors.append("piece '%s' has a cell that is not [x, y]" % shape.id)
	else:
		errors.append("piece '%s' cells must be an array" % shape.id)
	return shape


static func _read_symmetry(raw: Variant) -> Vector3i:
	if raw is Array and raw.size() >= 3:
		return Vector3i(int(raw[0]), int(raw[1]), int(raw[2]))
	return Vector3i.ZERO
