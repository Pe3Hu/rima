class_name CompositionLoader
extends RefCounted

## Читает JSON решений. Ширина якоря и фигуры берутся из задачи, а не из глобальных констант.


func load_compositions(path: String, board: MaskBoardData, piece_set: PieceSetData) -> Array[CompositionData]:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open: " + path)
		return []

	var json: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if json == null or not (json is Array):
		push_error("Invalid json")
		return []

	var result: Array[CompositionData] = []
	for data in json:
		if not (data is Dictionary):
			continue
		var composition := CompositionData.new()
		composition.allocations = create_allocations(data, board, piece_set)
		result.append(composition)
	return result


func create_allocations(data: Dictionary, board: MaskBoardData, piece_set: PieceSetData) -> Array[AllocationData]:
	var result: Array[AllocationData] = []
	var indexs: Array = data["indexs"]
	var flips: Array = data["flips"]
	var twists: Array = data["twists"]
	var letters: Array = data["letters"]

	for i in indexs.size():
		var index := int(indexs[i])
		var anchor := Vector2i(index % board.width, int(float(index) / float(board.width)))
		var shape := piece_set.get_by_id(str(letters[i]))
		if shape == null:
			push_error("unknown piece id: " + str(letters[i]))
			continue
		var orientation := OrientationData.new(shape, int(flips[i]) != 0, int(twists[i]))
		result.append(AllocationData.new(orientation, anchor))
	return result
