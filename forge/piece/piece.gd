class_name Piece
extends Node2D

## Показывает толщину по центру клетки. Подсветку включает Mold.

var data: PieceData:
	set(value_):
		data = value_
		connect_datas()
		connect_signals()
		_show_thickness()


func connect_datas() -> void:
	pass


func connect_signals() -> void:
	if data != null and not data.thickness_changed.is_connected(_show_thickness):
		data.thickness_changed.connect(_show_thickness)
	_show_thickness()


func _show_thickness() -> void:
	if not is_node_ready() or data == null:
		return
	var span := float(Catalog.MOLD_CELL_SIZE)
	var center := Vector2(data.coord) * span + Vector2(span, span) * 0.5
	%ThicknessLabel.position = center - Vector2(span, span) * 0.5
	%ThicknessLabel.size = Vector2(span, span)
	%ThicknessLabel.text = str(data.thickness)


func _ready() -> void:
	_show_thickness()
