class_name Fulcrum
extends Button

## Сумма stratum'а. Нажатие отдаёт Button.pressed. Данные не меняет.

var is_highlighted: bool = false:
	set(value_):
		if is_highlighted == value_:
			return
		is_highlighted = value_
		_show_sum()

var data: FulcrumData:
	set(value_):
		data = value_
		connect_datas()
		connect_signals()
		_show_sum()


func connect_datas() -> void:
	pass


func connect_signals() -> void:
	pass


func _ready() -> void:
	_show_sum()


func _show_sum() -> void:
	if not is_node_ready():
		return
	var color := Digest.fulcrum_color
	var outline := 0
	if is_highlighted:
		color = Digest.fulcrum_color_highlight
		outline = 6
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_outline_color", Digest.fulcrum_color_highlight)
	add_theme_constant_override("outline_size", outline)
	if data == null:
		text = ""
		return
	var span := float(Catalog.MOLD_CELL_SIZE)
	var origin := Vector2(data.coord) * span
	position = origin
	size = Vector2(span, span)
	custom_minimum_size = Vector2(span, span)
	text = str(data.sum)
