class_name CoverageData
extends RefCounted

## Строки точного покрытия: фигура × ориентация × позиция, где все клетки свободны.
##
## Якорь — угол ограничивающего прямоугольника. Он может попасть в вырез, если
## ни одна клетка фигуры там не лежит. Перебор пробует каждую клетку фигуры как
## точку опоры и схлопывает одинаковые покрытия.

var board: MaskBoardData
var pieces: PieceSetData
var anchor_policy: String = "any_free_cell"

var orientations: Array[OrientationData] = []
var allocations: Array[AllocationData] = []
var matrix: Array[Array] = []

var cell_columns: int = 0
var piece_columns: int = 0
var total_columns: int = 0
var skipped_anchor_on_hole: int = 0
var rows_per_piece: Dictionary = {}


func _init(board_: MaskBoardData, pieces_: PieceSetData, anchor_policy_: String = "any_free_cell") -> void:
	board = board_
	pieces = pieces_
	anchor_policy = anchor_policy_
	cell_columns = board.free_cells().size()
	piece_columns = pieces.pieces.size()
	total_columns = cell_columns + piece_columns
	_init_orientations()
	_build_matrix()


func fit_errors() -> Array[String]:
	var errors: Array[String] = []
	for piece in pieces.pieces:
		if int(rows_per_piece.get(piece.id, 0)) == 0:
			errors.append("piece '%s' has no placement" % piece.id)
	return errors


func diagnostics() -> Dictionary:
	return {
		"rows_built": allocations.size(),
		"columns": total_columns,
		"skipped_anchor_on_hole": skipped_anchor_on_hole,
		"rows_per_piece": rows_per_piece.duplicate(),
	}


func _init_orientations() -> void:
	orientations.clear()
	for piece in pieces.pieces:
		for orientation in piece.generate_orientations():
			orientations.append(orientation)


func _build_matrix() -> void:
	matrix.clear()
	allocations.clear()
	rows_per_piece.clear()
	skipped_anchor_on_hole = 0
	for orientation in orientations:
		_add_orientations(orientation)


## Каждая клетка фигуры по очереди ставится на свободную клетку доски.
func _add_orientations(orientation: OrientationData) -> void:
	var seen: Dictionary = {}
	for local in orientation.coords:
		for origin in board.free_cells():
			var anchor: Vector2i = origin - local
			if not board.can_place(orientation, anchor):
				continue
			var key := _placement_key(orientation, anchor)
			if seen.has(key):
				continue
			seen[key] = true
			if not board.is_free(anchor.x, anchor.y):
				skipped_anchor_on_hole += 1
			_add_allocation(orientation, anchor)


func _add_allocation(orientation: OrientationData, anchor: Vector2i) -> void:
	var row: Array[int] = []
	row.resize(total_columns)
	row.fill(0)
	var covered: Array[int] = []
	for local in orientation.coords:
		var world: Vector2i = anchor + local
		var column := board.cell_index(world.x, world.y)
		row[column] = 1
		covered.append(column)
	var piece_index := orientation.shape.piece_index
	row[cell_columns + piece_index] = 1
	matrix.append(row)
	var allocation := AllocationData.new(orientation, anchor)
	allocation.covered_columns = covered
	allocations.append(allocation)
	var piece_id := orientation.shape.id
	rows_per_piece[piece_id] = int(rows_per_piece.get(piece_id, 0)) + 1


func _placement_key(orientation: OrientationData, anchor: Vector2i) -> String:
	var parts := PackedStringArray()
	for local in orientation.coords:
		var world: Vector2i = anchor + local
		parts.append("%d,%d" % [world.x, world.y])
	parts.sort()
	return ";".join(parts)
