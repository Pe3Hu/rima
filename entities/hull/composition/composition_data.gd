class_name CompositionData
extends RefCounted

## Одно замощение в виде, который читает сцена.

var allocations: Array[AllocationData] = []


func _init(allocations_: Array[AllocationData] = []) -> void:
	allocations = allocations_


## `board_width` — ширина доски из `MaskBoardData`, не отдельная константа.
func get_data(board_width: int) -> Dictionary:
	var indexs: Array[int] = []
	var flips: Array[int] = []
	var twists: Array[int] = []
	var letters: Array[String] = []

	for allocation in allocations:
		indexs.append(board_width * allocation.anchor.y + allocation.anchor.x)
		flips.append(1 if allocation.orientation.is_flipped else 0)
		twists.append(allocation.orientation.twist)
		letters.append(allocation.orientation.shape.id)

	return {
		"indexs": indexs,
		"flips": flips,
		"twists": twists,
		"letters": letters,
	}
