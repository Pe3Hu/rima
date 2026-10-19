class_name DlxCell
extends RefCounted

var up: DlxCell
var down: DlxCell
var left: DlxCell
var right: DlxCell

var header: DlxColumnHeader
var row_id: int  # ID строки в исходной матрице

func _init(header_: DlxColumnHeader) -> void:
	header = header_
	up = self
	down = self
	left = self
	right = self
	row_id = -1
