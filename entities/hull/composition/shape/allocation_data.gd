class_name AllocationData
extends RefCounted


var orientation: OrientationData
var anchor: Vector2i

var coords: Array[Vector2i] = []
## Колонки свободных клеток, которые закрывает эта строка матрицы.
var covered_columns: Array[int] = []


func _init(orientation_: OrientationData, anchor_: Vector2i) -> void:
	orientation = orientation_
	anchor = anchor_
	init_coords()
	
func init_coords() -> void:
	for _coord in orientation.coords:
		var coord = _coord + anchor
		coords.append(coord)
