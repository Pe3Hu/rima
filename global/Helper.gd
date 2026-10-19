extends Node


var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()


func clear_children(parent_: Node) -> void:
	while parent_.get_child_count() > 0:
		var child := parent_.get_child(0)
		parent_.remove_child(child)
		child.queue_free()


func get_random_key(dict_: Dictionary) -> Variant:
	if dict_.is_empty():
		push_error("empty dictionary in get_random_key")
		return null

	var keys: Array = dict_.keys()
	var total := 0.0

	for key in keys:
		total += float(dict_[key])

	if total <= 0.0:
		return null

	var roll := rng.randf() * total
	var cumulative := 0.0

	for key in keys:
		cumulative += float(dict_[key])
		if roll < cumulative:
			return key

	push_error("random selection failed")
	return null


func apply_flip(coord_: Vector2i, is_flipped_: bool) -> Vector2i:
	return OrientationData.apply_flip(coord_, is_flipped_)


func apply_twist(coord_: Vector2i, twist_: int) -> Vector2i:
	return OrientationData.apply_twist(coord_, twist_)


func read_json(path_: String) -> Variant:
	if not FileAccess.file_exists(path_):
		push_error("file not found: " + path_)
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path_))
