extends Node

## Все enum проекта. NONE = 0 повторяется в каждом enum.
## Остальные значения общие: Shape 1…12, Type.SHAPE = 13, PieceSide 14…16, Type.PIECE_SIDE = 17.

enum Type {
	NONE = 0,
	SHAPE = 13,
	PIECE_SIDE = 17,
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

var type_to_index: Dictionary = {}
var type_to_enum: Dictionary = {}


#region init
func _ready() -> void:
	register_enums()
#endregion


func register_enums() -> void:
	register_enum(Type.SHAPE, Shape)
	register_enum(Type.PIECE_SIDE, PieceSide)


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
