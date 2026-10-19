class_name Background
extends TileMapLayer

## Чёрная подложка каждой свободной клетки шаблона.

var _painted_template: MoldTemplateData

var data: MoldData:
	set(value_):
		if data == value_:
			return
		if data != null and data.changed.is_connected(_on_changed):
			data.changed.disconnect(_on_changed)
		data = value_
		connect_datas()
		connect_signals()
		apply_cells()


func connect_datas() -> void:
	pass


func connect_signals() -> void:
	if data == null:
		return
	if not data.changed.is_connected(_on_changed):
		data.changed.connect(_on_changed)
	_on_changed()


func _on_changed() -> void:
	apply_cells()


func apply_cells() -> void:
	if data == null:
		clear()
		_painted_template = null
		return
	if _painted_template == data.template and get_used_cells().size() == data.coords.size():
		return
	clear()
	for cell in data.coords:
		set_cell(cell, 0, Vector2i.ZERO)
	_painted_template = data.template
