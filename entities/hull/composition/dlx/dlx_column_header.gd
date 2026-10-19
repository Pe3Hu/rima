class_name DlxColumnHeader
extends RefCounted

var cell: DlxCell  # Заголовок колонки (sentinel узел)
var size: int = 0  # Количество единиц в колонке
var column_id: int  # ID колонки в исходной матрице

func _init(column_id_: int) -> void:
	column_id = column_id_
	cell = DlxCell.new(self)
