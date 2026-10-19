class_name SolutionCanonicalizer
extends RefCounted

## Каноническая форма — лексикографически минимальная сетка среди образов группы симметрий доски.

var board: MaskBoardData
var pieces: PieceSetData
var group: SymmetryGroup


func _init(board_: MaskBoardData, pieces_: PieceSetData, group_: SymmetryGroup) -> void:
	board = board_
	pieces = pieces_
	group = group_


func canonical_hash(allocations: Array[AllocationData]) -> String:
	var grid := create_grid(allocations)
	var best := ""
	for op in group.ops:
		var hashed := hash_grid(transform_grid(grid, op))
		if best == "" or hashed < best:
			best = hashed
	return best


## Расстановки, чья сетка совпадает с каноническим хешем.
func canonicalize(allocations: Array[AllocationData]) -> Array[AllocationData]:
	var op := _best_op(allocations)
	if op == "identity":
		return allocations.duplicate()
	return transform_allocations(allocations, op)


func create_grid(allocations: Array[AllocationData]) -> Array:
	var grid: Array = []
	for _y in board.height:
		var row: Array = []
		row.resize(board.width)
		row.fill(-1)
		grid.append(row)
	for allocation in allocations:
		var piece_type := allocation.orientation.shape.type
		for cell in allocation.coords:
			grid[cell.y][cell.x] = piece_type
	return grid


func transform_grid(grid: Array, op: String) -> Array:
	var next: Array = []
	for _y in board.height:
		var row: Array = []
		row.resize(board.width)
		row.fill(-1)
		next.append(row)
	for y in board.height:
		for x in board.width:
			var mapped := SymmetryGroup.map_cell(x, y, board.width, board.height, op)
			next[mapped.y][mapped.x] = grid[y][x]
	return next


func hash_grid(grid: Array) -> String:
	var parts := PackedStringArray()
	for row in grid:
		for value in row:
			var number := int(value)
			if number < 0:
				parts.append("-1")
			else:
				parts.append("%02d" % number)
	return "".join(parts)


func transform_allocations(allocations: Array[AllocationData], op: String) -> Array[AllocationData]:
	var result: Array[AllocationData] = []
	for allocation in allocations:
		var moved: Array[Vector2i] = []
		for cell in allocation.coords:
			moved.append(SymmetryGroup.map_cell(cell.x, cell.y, board.width, board.height, op))
		var anchor := Vector2i(moved[0].x, moved[0].y)
		for cell in moved:
			anchor.x = mini(anchor.x, cell.x)
			anchor.y = mini(anchor.y, cell.y)
		var local: Array[Vector2i] = []
		for cell in moved:
			local.append(cell - anchor)
		var orientation := allocation.orientation.shape.orientation_for(local)
		if orientation == null:
			push_error("no orientation for %s at %s" % [allocation.orientation.shape.id, local])
			return []
		result.append(AllocationData.new(orientation, anchor))
	return result


func _best_op(allocations: Array[AllocationData]) -> String:
	var grid := create_grid(allocations)
	var best := ""
	var chosen := group.ops[0]
	for op in group.ops:
		var hashed := hash_grid(transform_grid(grid, op))
		if best == "" or hashed < best:
			best = hashed
			chosen = op
	return chosen
