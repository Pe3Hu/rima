class_name OrientationData
extends RefCounted


var shape: ShapeData

var is_flipped: bool = false
var twist: int = 0

var coords: Array[Vector2i]


#region init
func _init(shape_: ShapeData, is_flipped_: bool, twist_: int) -> void:
	shape = shape_
	is_flipped = is_flipped_
	twist = twist_
	
	init_coords()

func init_coords() -> void:
	coords.clear()
	var offset: Vector2i = Vector2i(999, 999)
	
	for _coord in shape.coords:
		var coord := OrientationData.apply_flip(_coord, is_flipped)
		coord = OrientationData.apply_twist(coord, twist)
		coords.append(coord)
		
		if offset.x > coord.x:
			offset.x = coord.x
		
		if offset.y > coord.y:
			offset.y = coord.y
	
	for _i in coords.size():
		coords[_i] = coords[_i] - offset
#endregion

static func apply_flip(coord_: Vector2i, is_flipped_: bool) -> Vector2i:
	if not is_flipped_:
		return coord_
	return Vector2i(-coord_.x, coord_.y)


static func apply_twist(coord_: Vector2i, twist_: int) -> Vector2i:
	if twist_ == 0:
		return coord_
	var angle := PI / 2.0 * float(twist_)
	var rotated := Vector2(coord_).rotated(angle).round()
	return Vector2i(rotated)


func get_hash() -> String:

	var sorted := coords.duplicate()

	sorted.sort_custom(
		func(a: Vector2i, b: Vector2i) -> bool:
			if a.x == b.x:
				return a.y < b.y

			return a.x < b.x
	)

	var result := ""

	for c in sorted:
		result += "%d:%d;" % [c.x, c.y]

	return result
func debug_coords() -> void:
	var min_coord := Vector2i(999, 999)

	for coord in coords:
		min_coord.x = min(min_coord.x, coord.x)
		min_coord.y = min(min_coord.y, coord.y)

	print(
		shape.type,
		" flip:",
		is_flipped,
		" twist:",
		twist,
		" coords:",
		coords,
		" min:",
		min_coord
	)
