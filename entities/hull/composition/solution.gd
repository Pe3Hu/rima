class_name Solution
extends RefCounted

## Одно замощение: расстановки фигур и канонический хеш орбиты.

var allocations: Array[AllocationData] = []
var index: int = 0
var task_id: String = ""
var symmetry_group: String = ""
var canonical_hash: String = ""


## Старые поля `indexs`, `flips`, `twists`, `letters` сохраняются.
## Дополнительно пишутся `task_id`, `symmetry_group`, `solution_index`.
func to_dictionary(board_width: int) -> Dictionary:
	var indexs: Array[int] = []
	var flips: Array[int] = []
	var twists: Array[int] = []
	var letters: Array[String] = []
	var ordered: Array[AllocationData] = allocations.duplicate()
	ordered.sort_custom(func(a: AllocationData, b: AllocationData) -> bool:
		var a_type := a.orientation.shape.type
		var b_type := b.orientation.shape.type
		if a_type == b_type:
			if a.anchor.y == b.anchor.y:
				return a.anchor.x < b.anchor.x
			return a.anchor.y < b.anchor.y
		return a_type < b_type
	)
	for allocation in ordered:
		indexs.append(board_width * allocation.anchor.y + allocation.anchor.x)
		flips.append(1 if allocation.orientation.is_flipped else 0)
		twists.append(allocation.orientation.twist)
		letters.append(allocation.orientation.shape.id)
	return {
		"indexs": indexs,
		"flips": flips,
		"twists": twists,
		"letters": letters,
		"task_id": task_id,
		"symmetry_group": symmetry_group,
		"solution_index": index,
	}


## Пустая строка, если свободные клетки покрыты ровно один раз, вырезы пусты и фигуры не повторяются.
static func invalid_reason(board: MaskBoardData, piece_set: PieceSetData, found: Array[AllocationData]) -> String:
	if board == null or piece_set == null:
		return "missing board or pieces"
	if found.size() != piece_set.pieces.size():
		return "allocation count %d != pieces %d" % [found.size(), piece_set.pieces.size()]
	var covered: Dictionary = {}
	var used: Dictionary = {}
	for allocation in found:
		var piece := allocation.orientation.shape
		if used.has(piece.id):
			return "piece repeated: " + piece.id
		used[piece.id] = true
		if allocation.coords.size() != piece.coords.size():
			return "piece '%s' covers %d cells" % [piece.id, allocation.coords.size()]
		for cell in allocation.coords:
			if not board.is_free(cell.x, cell.y):
				return "blocked cell (%d, %d)" % [cell.x, cell.y]
			var key := "%d,%d" % [cell.x, cell.y]
			if covered.has(key):
				return "overlap at " + key
			covered[key] = true
	for piece in piece_set.pieces:
		if not used.has(piece.id):
			return "missing piece " + piece.id
	if covered.size() != board.free_cells().size():
		return "covered %d of %d free cells" % [covered.size(), board.free_cells().size()]
	return ""
