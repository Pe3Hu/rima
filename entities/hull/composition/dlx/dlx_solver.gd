class_name DlxSolver
extends RefCounted

## Algorithm X. `false` из `on_solution` останавливает весь обход.
## Тупик ветки (пустая колонка) обход не останавливает.

var matrix: DlxMatrix
var receiver: DlxSolutionReceiver
var current_solution: Array[int] = []
var stop_requested: bool = false


func _init(coverage: CoverageData, receiver_: DlxSolutionReceiver) -> void:
	matrix = DlxMatrix.new(coverage)
	receiver = receiver_


func solve() -> void:
	current_solution.clear()
	stop_requested = false
	search()


func search() -> void:
	if stop_requested:
		return

	if matrix.is_solved():
		if not receiver.on_solution(current_solution):
			stop_requested = true
		return

	var column := matrix.select_column()
	if column == null or column.size == 0:
		return

	matrix.cover(column)
	var row := column.cell.down
	while row != column.cell:
		if stop_requested:
			break
		var next_row := row.down
		current_solution.append(row.row_id)

		var node := row.right
		while node != row:
			matrix.cover(node.header)
			node = node.right

		search()

		node = row.left
		while node != row:
			matrix.uncover(node.header)
			node = node.left

		current_solution.pop_back()
		row = next_row

	matrix.uncover(column)
