class_name DlxMatrix
extends RefCounted


var coverage_data: CoverageData

var master_header: DlxCell
var column_headers: Array[DlxColumnHeader]


func _init(coverage_data_: CoverageData) -> void:
	coverage_data = coverage_data_

	master_header = DlxCell.new(null)
	master_header.left = master_header
	master_header.right = master_header
	master_header.up = master_header
	master_header.down = master_header

	column_headers.clear()

	init_columns()
	init_rows()

func init_columns() -> void:
	var previous: DlxCell = master_header

	for column_id in coverage_data.total_columns:
		var header := DlxColumnHeader.new(column_id)
		column_headers.append(header)

		header.cell.left = previous
		header.cell.right = master_header

		previous.right = header.cell
		master_header.left = header.cell

		previous = header.cell

	if column_headers.size() > 0:
		master_header.right = column_headers[0].cell

func init_rows() -> void:
	for row_id in coverage_data.matrix.size():
		var first: DlxCell = null
		var previous: DlxCell = null
		var row = coverage_data.matrix[row_id]

		for column_id in row.size():
			if row[column_id] == 0:
				continue

			var header := column_headers[column_id]
			var node := DlxCell.new(header)

			node.row_id = row_id

			node.down = header.cell
			node.up = header.cell.up

			header.cell.up.down = node
			header.cell.up = node

			header.size += 1

			if first == null:
				first = node
				node.left = node
				node.right = node
			else:
				node.left = previous
				node.right = first

				previous.right = node
				first.left = node

			previous = node

func cover(header: DlxColumnHeader) -> void:
	header.cell.right.left = header.cell.left
	header.cell.left.right = header.cell.right

	var row = header.cell.down

	while row != header.cell:
		var node = row.right

		while node != row:
			node.down.up = node.up
			node.up.down = node.down

			node.header.size -= 1

			node = node.right

		row = row.down

func uncover(header: DlxColumnHeader) -> void:
	var row = header.cell.up

	while row != header.cell:
		var node = row.left

		while node != row:
			node.header.size += 1

			node.down.up = node
			node.up.down = node

			node = node.left

		row = row.up

	header.cell.right.left = header.cell
	header.cell.left.right = header.cell

func select_column() -> DlxColumnHeader:
	var best: DlxColumnHeader = null
	var best_size: int = 2147483647

	var cell: DlxCell = master_header.right

	while cell != master_header:
		var header: DlxColumnHeader = cell.header

		if header.size < best_size:
			best = header
			best_size = header.size

			if best_size == 1:
				break

		cell = cell.right

	return best

func is_solved() -> bool:
	return master_header.right == master_header
