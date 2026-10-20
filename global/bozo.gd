extends Node

## Все enum проекта. NONE = 0 повторяется в каждом enum.
## Остальные значения общие: Shape 1…12, Type.SHAPE = 13, PieceSide 14…16, Type.PIECE_SIDE = 17, Part 18…19, Type.PART = 20, Layer 21…22, Type.LAYER = 23, Stratum 24…25, Direction 26…29.

enum Type {
	NONE = 0,
	SHAPE = 13,
	PIECE_SIDE = 17,
	PART = 20,
	LAYER = 23,
}

enum Shape {
	NONE = 0,
	F = 1,
	I = 2,
	L = 3,
	P = 4,
	N = 5,
	T = 6,
	U = 7,
	V = 8,
	W = 9,
	X = 10,
	Y = 11,
	Z = 12,
}

enum PieceSide {
	NONE = 0,
	LEFT = 14,
	CENTER = 15,
	RIGHT = 16,
}

enum Part {
	NONE = 0,
	SPINE = 18,
	BEVEL = 19,
}

enum Layer {
	NONE = 0,
	INGOT = 21,
	PART = 22,
}

enum Stratum {
	NONE = 0,
	RAZOR = 24,
	SPIKE = 25,
}

enum Direction {
	NONE = 0,
	RIGHT = 26,
	LEFT = 27,
	TOP = 28,
	BOTTOM = 29,
}

var type_to_index: Dictionary = {}
var type_to_enum: Dictionary = {}


#region init
func _ready() -> void:
	register_enums()
#endregion


func register_enums() -> void:
	register_enum(Type.SHAPE, Shape)
	register_enum(Type.PIECE_SIDE, PieceSide)
	register_enum(Type.PART, Part)
	register_enum(Type.LAYER, Layer)


func register_enum(type_: Type, enum_dict_: Dictionary) -> void:
	type_to_enum[type_] = enum_dict_
	var index := {}
	for key in enum_dict_.keys():
		index[int(enum_dict_[key])] = str(key).to_lower()
	type_to_index[type_] = index


func enum_to_string(type_: Type, value_: int) -> String:
	if not type_to_index.has(type_):
		return ""
	var index: Dictionary = type_to_index[type_]
	if not index.has(value_):
		return ""
	return str(index[value_])


func string_to_enum(type_: Type, key_: String) -> int:
	if not type_to_enum.has(type_):
		return Type.NONE
	var enum_dict: Dictionary = type_to_enum[type_]
	var key := key_.to_upper()
	if not enum_dict.has(key):
		return Type.NONE
	return int(enum_dict[key])
